-- AkititoCraft "Servers" page.
--
-- The public server browser is disabled for AkititoCraft, so this is a clean
-- "join a server" screen: your saved servers on the left, and a direct-connect
-- card (address / port / name / password) on the right. Join a server by
-- entering its address (your public IP, or a playit.gg address) and pressing
-- Join, exactly like Minecraft's "Add Server".

-- Persist the selection into the address/remote_port settings.
local function remember(address, port)
	if address and port then
		core.settings:set("address", address)
		core.settings:set("remote_port", port)
	end
end

local function do_connect(address, port, fields)
	gamedata.mode        = "join"
	gamedata.playername  = fields.te_name
	gamedata.password    = fields.te_pwd
	gamedata.address     = address
	gamedata.port        = port
	gamedata.selected_world = 0
	gamedata.allow_login_or_register = "any"

	remember(address, port)
	serverlistmgr.add_favorite({ address = address, port = port })
	core.start()
end

local function render_favorites()
	local rows = {}
	for _, fav in ipairs(serverlistmgr.get_favorites()) do
		local label
		if fav.name and fav.name ~= "" and fav.name ~= fav.address then
			label = ("%s  (%s:%s)"):format(fav.name, fav.address, tostring(fav.port))
		else
			label = ("%s:%s"):format(fav.address or "?", tostring(fav.port or "?"))
		end
		rows[#rows + 1] = core.formspec_escape(label)
	end
	return table.concat(rows, ",")
end

local function get_formspec(frame, name, tabdata)
	local px, pw = AC.PX, AC.PW
	local ix = px + 0.35
	local grn   = core.formspec_escape(defaulttexturedir .. "akititocraft_btn_green.png")
	local grn_h = core.formspec_escape(defaulttexturedir .. "akititocraft_btn_green_hover.png")

	local address = core.settings:get("address") or ""
	local port    = core.settings:get("remote_port") or "30000"
	local pname   = core.settings:get("name") or ""

	-- Two columns inside the panel.
	local lx, lw = ix, 6.1                 -- left: saved servers
	local rx, rw = ix + 6.6, pw - 0.7 - 6.6 -- right: direct connect

	local fs = {
		"style[btn_join;border=false;font=bold;textcolor=#ffffff;bgimg=" .. grn ..
			";bgimg_hovered=" .. grn_h .. ";bgimg_pressed=" .. grn .. ";bgimg_middle=8]",

		-- Panel with a blue "Servers" header strip.
		string.format("box[%f,0.2;%f,8.4;#0e1a2ecc]", px, pw),
		string.format("box[%f,0.2;%f,0.85;%s]", px, pw, AC.ACCENT.servers),
		string.format("hypertext[%f,0.3;10,0.6;h_head;" ..
			"<global valign=middle size=24 color=#ffffff><b>Servers</b>]", ix),

		-- Left: saved servers list.
		string.format("label[%f,1.35;%s]", lx, fgettext("Saved servers")),
		string.format("box[%f,1.6;%f,5.4;#00000066]", lx, lw),
		string.format("textlist[%f,1.7;%f,5.2;fav_list;%s]", lx, lw, render_favorites()),
		string.format("button[%f,7.15;%f,0.75;btn_fav_del;%s]", lx, lw, fgettext("Remove selected")),

		-- Right: direct connect card.
		string.format("label[%f,1.35;%s]", rx, fgettext("Server address")),
		string.format("field[%f,1.7;%f,0.75;te_address;;%s]", rx, rw, core.formspec_escape(address)),
		string.format("label[%f,2.7;%s]", rx, fgettext("Port")),
		string.format("field[%f,3.05;%f,0.75;te_port;;%s]", rx, rw, core.formspec_escape(port)),
		string.format("label[%f,4.05;%s]", rx, fgettext("Your name")),
		string.format("field[%f,4.4;%f,0.75;te_name;;%s]", rx, rw, core.formspec_escape(pname)),
		string.format("label[%f,5.4;%s]", rx, fgettext("Password (if the server has one)")),
		string.format("pwdfield[%f,5.75;%f,0.75;te_pwd;]", rx, rw),

		string.format("button[%f,6.75;%f,0.9;btn_join;%s]", rx, rw, fgettext("Join Server")),
		string.format("button[%f,7.75;%f,0.55;btn_fav_add;%s]", rx, rw, fgettext("Save to list")),

		"field_close_on_enter[te_address;false]",
		"field_close_on_enter[te_port;false]",
	}
	return table.concat(fs)
end

local function main_button_handler(frame, fields, name, tabdata)
	if fields.te_name then
		core.settings:set("name", fields.te_name)
	end

	local favs = serverlistmgr.get_favorites()

	-- Selecting / double-clicking a saved server.
	if fields.fav_list then
		local ev = core.explode_textlist_event(fields.fav_list)
		local fav = favs[ev.index]
		if fav then
			if ev.type == "CHG" then
				remember(fav.address, fav.port)
				return true
			elseif ev.type == "DCL" then
				do_connect(fav.address, fav.port, fields)
				return true
			end
		end
	end

	if fields.btn_fav_del then
		local sel = core.get_textlist_index("fav_list")
		if sel and favs[sel] then
			serverlistmgr.delete_favorite(favs[sel])
		end
		return true
	end

	if fields.btn_fav_add then
		local port = tonumber(fields.te_port)
		if fields.te_address ~= "" and port then
			serverlistmgr.add_favorite({
				address = fields.te_address,
				port = port,
				name = fields.te_address,
			})
			remember(fields.te_address, port)
		end
		return true
	end

	if fields.btn_join or fields.key_enter then
		local address = fields.te_address
		local port = tonumber(fields.te_port)
		if address and address ~= "" and port then
			do_connect(address, port, fields)
		end
		return true
	end

	return false
end

return {
	name = "servers",
	caption = fgettext("Servers"),
	cbf_formspec = get_formspec,
	cbf_button_handler = main_button_handler,
}
