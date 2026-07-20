-- Luanti
-- Copyright (C) 2014 sapier
-- SPDX-License-Identifier: LGPL-2.1-or-later


local current_game, singleplayer_refresh_gamebar
local valid_disabled_settings = {
	["enable_damage"]=true,
	["creative_mode"]=true,
	["enable_server"]=true,
}

-- Name and port stored to persist when updating the formspec
local current_name = core.settings:get("name")
local current_port = core.settings:get("port")

-- Currently chosen game in gamebar for theming and filtering
function current_game()
	local gameid = core.settings:get("menu_last_game")
	local game = gameid and pkgmgr.find_by_gameid(gameid)
	-- Fall back to first game installed if one exists.
	if not game and #pkgmgr.games > 0 then

		-- If devtest is the first game in the list and there is another
		-- game available, pick the other game instead.
		local picked_game
		if pkgmgr.games[1].id == "devtest" and #pkgmgr.games > 1 then
			picked_game = 2
		else
			picked_game = 1
		end

		game = pkgmgr.games[picked_game]
		gameid = game.id
		core.settings:set("menu_last_game", gameid)
	end

	return game
end

-- Apply menu changes from given game
function apply_game(game)
	core.settings:set("menu_last_game", game.id)
	menudata.worldlist:set_filtercriteria(game.id)

	mm_game_theme.set_game(game)

	local index = filterlist.get_current_index(menudata.worldlist,
		tonumber(core.settings:get("mainmenu_last_selected_world")))
	if not index or index < 1 then
		local selected = core.get_textlist_index("sp_worlds")
		if selected ~= nil and selected < #menudata.worldlist:get_list() then
			index = selected
		else
			index = #menudata.worldlist:get_list()
		end
	end
	menu_worldmt_legacy(index)
end

function singleplayer_refresh_gamebar()
	-- AkititoCraft ships a single game, so the game-selection bar is removed
	-- entirely. The active game is applied via current_game()/apply_game()
	-- in on_change, so no bar is needed; always report that none is shown.
	local old_bar = ui.find_by_name("game_button_bar")
	if old_bar ~= nil then
		old_bar:delete()
	end
	return false
end

local function get_disabled_settings(game)
	if not game then
		return {}
	end

	local gameconfig = Settings(game.path .. "/game.conf")
	local disabled_settings = {}
	if gameconfig then
		local disabled_settings_str = (gameconfig:get("disabled_settings") or ""):split()
		for _, value in pairs(disabled_settings_str) do
			local state = false
			value = value:trim()
			if string.sub(value, 1, 1) == "!" then
				state = true
				value = string.sub(value, 2)
			end
			if valid_disabled_settings[value] then
				disabled_settings[value] = state
			else
				core.log("error", "Invalid disabled setting in game.conf: "..tostring(value))
			end
		end
	end
	return disabled_settings
end

local function get_formspec(tabview, name, tabdata)

	-- Point the player to ContentDB when no games are found
	if #pkgmgr.games == 0 then
		local W = tabview.width
		local H = tabview.height

		local hypertext = "<global valign=middle halign=center size=18>" ..
				fgettext_ne("AkititoCraft is a Minecraft-style voxel game.") .. "\n" ..
				fgettext_ne("The built-in game wasn't installed with this build.") .. " " ..
				fgettext_ne("You need to install a game before you can create a world.")

		local button_y = H * 2/3 - 0.6
		return table.concat({
			"hypertext[0.375,0;", W - 2*0.375, ",", button_y, ";ht;", core.formspec_escape(hypertext), "]",
			"button[5.25,", button_y, ";5,1.2;game_open_cdb;", fgettext("Install a game"), "]"})
	end

	-- Green primary-button skin (the grey skin is emitted by the frame).
	local grn   = core.formspec_escape(defaulttexturedir .. "akititocraft_btn_green.png")
	local grn_h = core.formspec_escape(defaulttexturedir .. "akititocraft_btn_green_hover.png")

	local index = core.get_textlist_index("sp_worlds") or filterlist.get_current_index(menudata.worldlist,
				tonumber(core.settings:get("mainmenu_last_selected_world"))) or 0

	local list = menudata.worldlist:get_list()
	-- When changing tabs to a world list with fewer entries, the last index is
	-- selected (visually). The formspec fields lag behind, thus 'index > #list'
	-- can be a valid choice.
	local world = list and list[math.min(index, #list)]
	local game
	if world then
		game = pkgmgr.find_by_gameid(world.gameid)
	else
		game = current_game()
	end
	local disabled_settings = get_disabled_settings(game)

	local host_mode = core.settings:get_bool("enable_server")
			and disabled_settings["enable_server"] == nil

	-- Content-region geometry (shared with the frame via the AC table).
	local px, pw = AC.PX, AC.PW
	local ix = px + 0.35
	local iw = pw - 0.7

	local retval =
		"style[play;border=false;font=bold;textcolor=#ffffff;bgimg=" .. grn ..
			";bgimg_hovered=" .. grn_h .. ";bgimg_pressed=" .. grn .. ";bgimg_middle=8]" ..
		-- Panel with a green "Worlds" header strip.
		string.format("box[%f,0.2;%f,8.4;#0e1a2ecc]", px, pw) ..
		string.format("box[%f,0.2;%f,0.85;%s]", px, pw, AC.ACCENT.worlds) ..
		string.format("hypertext[%f,0.3;10,0.6;h_worlds;" ..
			"<global valign=middle size=24 color=#ffffff><b>Worlds</b>]", ix) ..
		string.format("button[%f,1.25;%f,0.85;world_create;%s]", ix, iw, fgettext("Create New"))

	-- The world list shrinks in host mode to make room for the server fields.
	local list_h = host_mode and 2.45 or 3.65
	retval = retval ..
		string.format("textlist[%f,2.25;%f,%f;sp_worlds;", ix, iw, list_h) ..
		menu_render_worldlist() .. ";" .. index .. "]"

	local y = 2.25 + list_h + 0.15

	-- Per-world actions (Delete / Select Mods).
	if world then
		local half = (iw - 0.3) / 2
		retval = retval ..
			string.format("button[%f,%f;%f,0.6;world_delete;%s]", ix, y, half, fgettext("Delete")) ..
			string.format("button[%f,%f;%f,0.6;world_configure;%s]",
				ix + half + 0.3, y, half, fgettext("Select Mods"))
	end
	y = y + 0.75

	-- Game option checkboxes laid out in a row.
	if world then
		local cx = ix
		if disabled_settings["creative_mode"] == nil then
			retval = retval .. string.format("checkbox[%f,%f;cb_creative_mode;%s;%s]",
				cx, y + 0.1, fgettext("Creative"), dump(core.settings:get_bool("creative_mode")))
			cx = cx + 3.2
		end
		if disabled_settings["enable_damage"] == nil then
			retval = retval .. string.format("checkbox[%f,%f;cb_enable_damage;%s;%s]",
				cx, y + 0.1, fgettext("Damage"), dump(core.settings:get_bool("enable_damage")))
			cx = cx + 3.2
		end
		if disabled_settings["enable_server"] == nil then
			retval = retval .. string.format("checkbox[%f,%f;cb_server;%s;%s]",
				cx, y + 0.1, fgettext("Host Server"), dump(core.settings:get_bool("enable_server")))
			cx = cx + 3.9
		end
		if host_mode then
			retval = retval .. string.format("checkbox[%f,%f;cb_server_announce;%s;%s]",
				cx, y + 0.1, fgettext("Announce"), dump(core.settings:get_bool("server_announce")))
		end
	end
	y = y + 0.7

	-- Server fields, only while hosting.
	if host_mode then
		retval = retval .. string.format("field[%f,%f;4.0,0.7;te_playername;%s;%s]",
			ix, y, fgettext("Name"), core.formspec_escape(current_name))
		retval = retval .. string.format("pwdfield[%f,%f;4.0,0.7;te_passwd;%s]",
			ix + 4.3, y, fgettext("Password"))
		local bind_addr = core.settings:get("bind_address")
		if bind_addr ~= nil and bind_addr ~= "" then
			retval = retval ..
				string.format("field[%f,%f;2.6,0.7;te_serveraddr;%s;%s]",
					ix + 8.6, y, fgettext("Bind"), core.formspec_escape(bind_addr)) ..
				string.format("field[%f,%f;1.9,0.7;te_serverport;%s;%s]",
					ix + 11.4, y, fgettext("Port"), core.formspec_escape(current_port))
		else
			retval = retval .. string.format("field[%f,%f;4.6,0.7;te_serverport;%s;%s]",
				ix + 8.6, y, fgettext("Port"), core.formspec_escape(current_port))
		end
	end

	-- Primary Play / Host button pinned to the bottom of the panel.
	local play_label = host_mode and fgettext("Host Game")
			or (world and fgettext("Play Game") or fgettext("Select a world"))
	retval = retval .. string.format("button[%f,7.55;%f,0.85;play;%s]", ix, iw, play_label)

	return retval
end

local function main_button_handler(this, fields, name, tabdata)

	assert(name == "local")

	if fields.game_open_cdb then
		local dlg = create_contentdb_dlg("game")
		dlg:set_parent(this)
		this:hide()
		dlg:show()
		return true
	end

	if this.dlg_create_world_closed_at == nil then
		this.dlg_create_world_closed_at = 0
	end

	local world_doubleclick = false

	if fields["te_playername"] then
		current_name = fields["te_playername"]
	end

	if fields["te_serverport"] then
		current_port = fields["te_serverport"]
	end

	if fields["sp_worlds"] ~= nil then
		local event = core.explode_textlist_event(fields["sp_worlds"])
		local selected = core.get_textlist_index("sp_worlds")

		menu_worldmt_legacy(selected)

		if event.type == "DCL" then
			world_doubleclick = true
		end

		if event.type == "CHG" and selected ~= nil then
			core.settings:set("mainmenu_last_selected_world",
				menudata.worldlist:get_raw_index(selected))
			return true
		end
	end

	if menu_handle_key_up_down(fields,"sp_worlds","mainmenu_last_selected_world") then
		return true
	end

	if fields["cb_creative_mode"] then
		core.settings:set("creative_mode", fields["cb_creative_mode"])
		local selected = core.get_textlist_index("sp_worlds")
		menu_worldmt(selected, "creative_mode", fields["cb_creative_mode"])

		return true
	end

	if fields["cb_enable_damage"] then
		core.settings:set("enable_damage", fields["cb_enable_damage"])
		local selected = core.get_textlist_index("sp_worlds")
		menu_worldmt(selected, "enable_damage", fields["cb_enable_damage"])

		return true
	end

	if fields["cb_server"] then
		core.settings:set("enable_server", fields["cb_server"])

		return true
	end

	if fields["cb_server_announce"] then
		core.settings:set("server_announce", fields["cb_server_announce"])
		local selected = core.get_textlist_index("srv_worlds")
		menu_worldmt(selected, "server_announce", fields["cb_server_announce"])

		return true
	end

	if fields["play"] ~= nil or world_doubleclick or fields["key_enter"] then
		local enter_key_duration = core.get_us_time() - this.dlg_create_world_closed_at
		if world_doubleclick and enter_key_duration <= 200000 then -- 200 ms
			this.dlg_create_world_closed_at = 0
			return true
		end

		local selected = core.get_textlist_index("sp_worlds")
		gamedata.selected_world = menudata.worldlist:get_raw_index(selected)

		if selected == nil or gamedata.selected_world == 0 then
			return true
		end

		-- Update last game
		local world = menudata.worldlist:get_raw_element(gamedata.selected_world)
		local game_obj
		if world then
			game_obj = pkgmgr.find_by_gameid(world.gameid)
			core.settings:set("menu_last_game", game_obj.id)
		end

		local disabled_settings = get_disabled_settings(game_obj)
		for k, _ in pairs(valid_disabled_settings) do
			local v = disabled_settings[k]
			if v ~= nil then
				if k == "enable_server" and v == true then
					error("Setting 'enable_server' cannot be force-enabled! The game.conf needs to be fixed.")
				end
				core.settings:set_bool(k, disabled_settings[k])
			end
		end

		if core.settings:get_bool("enable_server") then
			gamedata.mode       = "host"
			gamedata.playername = fields["te_playername"]
			gamedata.password   = fields["te_passwd"]
			-- If the port field is empty or non-numeric, fall back to the
			-- default 30000. Passing "" here caused the server to bind to
			-- port 0 (a random ephemeral port) which nobody could connect to.
			local port_field = fields["te_serverport"]
			if port_field == nil or tonumber(port_field) == nil then
				port_field = "30000"
			end
			gamedata.port       = port_field
			gamedata.address    = ""

			core.settings:set("port", gamedata.port)
			if fields["te_serveraddr"] ~= nil then
				core.settings:set("bind_address",fields["te_serveraddr"])
			end
		else
			gamedata.mode = "singleplayer"
		end

		core.start()
		return true
	end

	if fields["world_create"] ~= nil then
		this.dlg_create_world_closed_at = 0
		local create_world_dlg = create_create_world_dlg()
		create_world_dlg:set_parent(this)
		this:hide()
		create_world_dlg:show()
		return true
	end

	if fields["world_delete"] ~= nil then
		local selected = core.get_textlist_index("sp_worlds")
		if selected ~= nil and
			selected <= menudata.worldlist:size() then
			local world = menudata.worldlist:get_list()[selected]
			if world ~= nil and
				world.name ~= nil and
				world.name ~= "" then
				local index = menudata.worldlist:get_raw_index(selected)
				local delete_world_dlg = create_delete_world_dlg(world.name,index)
				delete_world_dlg:set_parent(this)
				this:hide()
				delete_world_dlg:show()
			end
		end

		return true
	end

	if fields["world_configure"] ~= nil then
		local selected = core.get_textlist_index("sp_worlds")
		if selected ~= nil then
			local configdialog =
				create_configure_world_dlg(
						menudata.worldlist:get_raw_index(selected))

			if (configdialog ~= nil) then
				configdialog:set_parent(this)
				this:hide()
				configdialog:show()
			end
		end

		return true
	end
end

local function on_change(type)
	if type == "ENTER" then
		local game = current_game()
		if game then
			apply_game(game)
		else
			mm_game_theme.set_engine()
		end

		if singleplayer_refresh_gamebar() then
			ui.find_by_name("game_button_bar"):show()
		end
	elseif type == "LEAVE" then
		menudata.worldlist:set_filtercriteria(nil)
		local gamebar = ui.find_by_name("game_button_bar")
		if gamebar then
			gamebar:hide()
		end
	end
end

--------------------------------------------------------------------------------
return {
	name = "local",
	caption = fgettext("Worlds"),
	cbf_formspec = get_formspec,
	cbf_button_handler = main_button_handler,
	on_change = on_change
}
