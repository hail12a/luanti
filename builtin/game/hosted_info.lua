-- AkititoCraft: on join, tell the player where the server is hosted so
-- they can share it with friends and diagnose connection problems.
-- Skips singleplayer worlds (nothing to share, no listener).

core.register_on_joinplayer(function(player)
	if core.is_singleplayer() then
		return
	end

	local name = player:get_player_name()
	local port = core.settings:get("port") or "30000"
	local bind = core.settings:get("bind_address") or ""

	local where
	if bind ~= "" then
		where = bind .. ":" .. port
	else
		where = "port " .. port .. " (all interfaces)"
	end

	core.chat_send_player(name,
		"[AkititoCraft] Server hosted on " .. where)
	core.chat_send_player(name,
		"[AkititoCraft] Friends: connect with your public IP (or playit.gg address)"
		.. " on port " .. port .. ".")
	core.chat_send_player(name,
		"[AkititoCraft] If they can't connect: (1) UDP " .. port ..
		" must be forwarded/allowed in Windows Firewall, (2) playit tunnel must be UDP.")
end)
