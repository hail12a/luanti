-- AkititoCraft Create World dialog (Bedrock-style).
--
-- The original Luanti dialog exposed every mapgen flag (caves, dungeons,
-- caverns, floatlands, biome dropdowns, ...). AkititoCraft hides all of that
-- and keeps only what a player cares about: a name, an optional seed and a
-- game mode. The world is still generated with the game's default mapgen and
-- the default flags, so nothing about world generation actually changes.

local function table_to_flags(ftable)
	-- Convert e.g. { jungles = true, caves = false } to "jungles,nocaves"
	local str = {}
	for flag, is_set in pairs(ftable) do
		str[#str + 1] = is_set and flag or ("no" .. flag)
	end
	return table.concat(str, ",")
end

-- Resolve the game's default mapgen (never shown to the player).
local function default_mapgen()
	local game = pkgmgr.find_by_gameid(core.settings:get("menu_last_game"))
	if game then
		local gameconfig = Settings(game.path .. "/game.conf")
		if gameconfig then
			return gameconfig:get("default_mapgen") or core.settings:get("mg_name") or "v7"
		end
	end
	return core.settings:get("mg_name") or "v7"
end

local function esc(t)
	return core.formspec_escape(defaulttexturedir .. t)
end

local function create_world_formspec(dialogdata)
	dialogdata.mg = dialogdata.mg or default_mapgen()

	local btn   = esc("akititocraft_btn.png")
	local btn_h = esc("akititocraft_btn_hover.png")
	local btn_p = esc("akititocraft_btn_press.png")
	local grn   = esc("akititocraft_btn_green.png")
	local grn_h = esc("akititocraft_btn_green_hover.png")

	local creative = core.settings:get_bool("creative_mode")
	local mode_idx = creative and 2 or 1

	return table.concat({
		"formspec_version[6]size[13,8.7]",
		("style_type[button;border=false;font=bold;textcolor=#ffffff;bgimg=%s;bgimg_hovered=%s;bgimg_pressed=%s;bgimg_middle=8]")
			:format(btn, btn_h, btn_p),
		("style[world_create_confirm;border=false;font=bold;textcolor=#ffffff;bgimg=%s;bgimg_hovered=%s;bgimg_pressed=%s;bgimg_middle=8]")
			:format(grn, grn_h, grn),

		-- Panel with a green header.
		"box[0.5,0.4;12,7.9;#0e1a2ef2]",
		"box[0.5,0.4;12,0.9;#3aa856]",
		"hypertext[0.85,0.5;11,0.7;h_t;<global valign=middle size=26 color=#ffffff><b>Create World</b>]",

		-- World name.
		"label[0.9,1.75;" .. fgettext("World name") .. "]",
		("field[0.9,2.1;11.2,0.85;te_world_name;;%s]"):format(core.formspec_escape(dialogdata.worldname)),
		"set_focus[te_world_name;false]",

		-- Seed.
		"label[0.9,3.2;" .. fgettext("Seed (optional)") .. "]",
		("field[0.9,3.55;11.2,0.85;te_seed;;%s]"):format(core.formspec_escape(dialogdata.seed)),

		-- Game mode.
		"label[0.9,4.65;" .. fgettext("Game mode") .. "]",
		("dropdown[0.9,5.0;5.4,0.85;dd_gamemode;%s,%s;%d]")
			:format(fgettext("Survival"), fgettext("Creative"), mode_idx),

		"hypertext[0.9,6.15;11.2,0.9;h_hint;<global size=14 color=#8a97a5>" ..
			fgettext("Leave the seed blank for a random world. Survival has health and hunger; Creative gives unlimited blocks and flight.") .. "]",

		-- Buttons.
		("button[2.4,7.2;4,0.9;world_create_confirm;%s]"):format(fgettext("Create")),
		("button[6.8,7.2;4,0.9;world_create_cancel;%s]"):format(fgettext("Cancel")),
	})
end

local function create_world_buttonhandler(this, fields)
	-- Note: a dropdown resubmits its value on *every* button press, so we must
	-- handle the real buttons FIRST and only read dd_gamemode, never early-
	-- return on it (that was swallowing the Create/Cancel clicks).

	if fields.world_create_cancel then
		this:delete()
		return true
	end

	if fields.world_create_confirm or fields.key_enter then
		-- Apply the selected game mode.
		if fields.dd_gamemode then
			core.settings:set_bool("creative_mode", fields.dd_gamemode == fgettext("Creative"))
		end
		if fields.key_enter then
			-- HACK: prevents double-triggering when pressing Enter on a field
			-- and releasing on a button due to instant formspec updates.
			this.parent.dlg_create_world_closed_at = core.get_us_time()
		end

		local worldname = fields.te_world_name
		local game = pkgmgr.find_by_gameid(core.settings:get("menu_last_game"))

		local message
		if game == nil then
			message = fgettext_ne("No game selected")
		end

		if message == nil then
			-- Auto-name unnamed worlds 'world<n>'.
			if worldname == "" then
				local worldnum_max = 0
				for _, world in ipairs(menudata.worldlist:get_list()) do
					if world.name:match("^world%d+$") then
						worldnum_max = math.max(worldnum_max, tonumber(world.name:sub(6)))
					end
				end
				worldname = "world" .. worldnum_max + 1
			end

			if menudata.worldlist:uid_exists_raw(worldname) then
				message = fgettext_ne("A world named \"$1\" already exists", worldname)
			end
		end

		if message == nil then
			this.data.seed = fields.te_seed or ""

			-- Generate with the game's default mapgen and the default flags.
			local settings = {
				fixed_map_seed = this.data.seed,
				mg_name = this.data.mg,
				mg_flags = table_to_flags(this.data.flags.main),
				mgv5_spflags = table_to_flags(this.data.flags.v5),
				mgv6_spflags = table_to_flags(this.data.flags.v6),
				mgv7_spflags = table_to_flags(this.data.flags.v7),
				mgfractal_spflags = table_to_flags(this.data.flags.fractal),
				mgcarpathian_spflags = table_to_flags(this.data.flags.carpathian),
				mgvalleys_spflags = table_to_flags(this.data.flags.valleys),
				mgflat_spflags = table_to_flags(this.data.flags.flat),
			}
			message = core.create_world(worldname, game.id, settings)
		end

		if message == nil then
			core.settings:set("menu_last_game", game.id)
			menudata.worldlist:set_filtercriteria(game.id)
			menudata.worldlist:refresh()
			core.settings:set("mainmenu_last_selected_world",
					menudata.worldlist:raw_index_by_uid(worldname))
		end

		gamedata.errormessage = message
		this:delete()
		return true
	end

	-- Remember typed values across refreshes.
	this.data.worldname = fields.te_world_name
	this.data.seed = fields.te_seed or ""

	return false
end

function create_create_world_dlg()
	local retval = dialog_create("sp_create_world",
					create_world_formspec,
					create_world_buttonhandler,
					nil)
	retval.data = {
		worldname = "",
		mg = default_mapgen(),
		seed = core.settings:get("fixed_map_seed") or "",
		-- Default generation flags (never shown, kept so worlds generate normally).
		flags = {
			main = core.settings:get_flags("mg_flags"),
			v5 = core.settings:get_flags("mgv5_spflags"),
			v6 = core.settings:get_flags("mgv6_spflags"),
			v7 = core.settings:get_flags("mgv7_spflags"),
			fractal = core.settings:get_flags("mgfractal_spflags"),
			carpathian = core.settings:get_flags("mgcarpathian_spflags"),
			valleys = core.settings:get_flags("mgvalleys_spflags"),
			flat = core.settings:get_flags("mgflat_spflags"),
		}
	}

	return retval
end
