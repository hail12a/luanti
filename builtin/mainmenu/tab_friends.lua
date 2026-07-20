-- AkititoCraft "Friends" page.
--
-- A full friends system (accounts, presence, invites) needs a backend that
-- doesn't exist yet, so this is an honest placeholder that also routes the
-- player to the two things that DO let them play with friends today: hosting
-- a world, or joining one by address on the Servers page.

local function get_formspec(frame, name, tabdata)
	local px, pw = AC.PX, AC.PW
	local ix = px + 0.35
	local iw = pw - 0.7
	local cx = px + pw / 2   -- panel horizontal centre

	local fs = {
		-- Panel with a purple "Friends" header strip.
		string.format("box[%f,0.2;%f,8.4;#0e1a2ecc]", px, pw),
		string.format("box[%f,0.2;%f,0.85;%s]", px, pw, AC.ACCENT.friends),
		string.format("hypertext[%f,0.3;10,0.6;h_head;" ..
			"<global valign=middle size=24 color=#ffffff><b>Friends</b>]", ix),

		string.format("hypertext[%f,2.3;%f,1.0;h_soon;" ..
			"<global valign=middle halign=center size=30 color=#ffd54f><b>Coming soon</b>]", px, pw),

		string.format("hypertext[%f,3.6;%f,1.4;h_info;" ..
			"<global valign=middle halign=center size=16 color=#cfd8dc>" ..
			"A friends list with invites and online status is on the way.\n" ..
			"For now you can still play together right away:]", px, pw),

		-- Two big shortcut buttons, centred.
		string.format("button[%f,5.2;4.6,1.0;friends_host;%s]", cx - 4.9, fgettext("Host a world")),
		string.format("button[%f,5.2;4.6,1.0;friends_servers;%s]", cx + 0.3, fgettext("Join by address")),

		string.format("hypertext[%f,6.6;%f,1.0;h_hint;" ..
			"<global valign=middle halign=center size=13 color=#8a97a5>" ..
			"Host a world and share your IP (or playit.gg address), " ..
			"or open Servers to enter a friend's address.]", ix, iw),
	}
	return table.concat(fs)
end

local function button_handler(frame, fields, name, tabdata)
	if fields.friends_host then
		frame:set_tab("worlds")
		return true
	end
	if fields.friends_servers then
		frame:set_tab("servers")
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
