-- AkititoCraft "Friends" tab.
--
-- A full friends system (accounts, presence, invites) needs a backend that
-- doesn't exist yet, so this is an honest placeholder that also routes the
-- player to the two things that DO let them play with friends today: hosting
-- a world, or joining one by address on the Servers tab.

local function esc(t)
	return core.formspec_escape(defaulttexturedir .. t)
end

local function get_formspec(tabview, name, tabdata)
	local btn   = esc("akititocraft_btn.png")
	local btn_h = esc("akititocraft_btn_hover.png")
	local btn_p = esc("akititocraft_btn_press.png")

	local fs = {
		-- Card panel with a blue header strip, matching the Worlds screen.
		"box[0.375,0.375;14.75,6.35;#0b0b0bcc]",
		"box[0.375,0.375;14.75,0.65;#1e88e5cc]",
		"hypertext[0.65,0.45;10,0.55;h_head;" ..
			"<global valign=middle size=22 color=#ffffff><b>Friends</b>]",

		"hypertext[0.375,1.9;14.75,1.2;h_soon;" ..
			"<global valign=middle halign=center size=26 color=#ffd54f><b>Coming soon</b>]",

		"hypertext[1.5,3.1;12.5,1.8;h_info;" ..
			"<global valign=middle halign=center size=16 color=#cfd8dc>" ..
			"A friends list with invites and online status is on the way.\n" ..
			"For now, you can still play together right away:</global>]",

		-- Skin the two shortcut buttons.
		("style_type[button;border=false;font=bold;textcolor=#ffffff;bgimg=%s;bgimg_hovered=%s;bgimg_pressed=%s;bgimg_middle=8]")
			:format(btn, btn_h, btn_p),

		"button[2.6,4.9;4.6,0.95;friends_host;" .. fgettext("Host a world") .. "]",
		"button[8.3,4.9;4.6,0.95;friends_servers;" .. fgettext("Join by address") .. "]",

		"hypertext[1.5,6.0;12.5,0.7;h_hint;" ..
			"<global valign=middle halign=center size=13 color=#8a97a5>" ..
			"Host a world and share your IP (or playit.gg address), or open Servers to enter a friend's address.</global>]",
	}
	return table.concat(fs)
end

local function button_handler(tabview, fields, name, tabdata)
	if fields.friends_host then
		tabview:set_tab("local")
		return true
	end
	if fields.friends_servers then
		tabview:set_tab("online")
		return true
	end
	return false
end

return {
	name = "friends",
	caption = fgettext("Friends"),
	cbf_formspec = get_formspec,
	cbf_button_handler = button_handler,
}
