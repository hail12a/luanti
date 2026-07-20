-- Luanti
-- Copyright (C) 2025 siliconsniffer
-- SPDX-License-Identifier: LGPL-2.1-or-later


local function exit_dialog_formspec()
	local show_dialog = core.settings:get_bool("enable_esc_dialog", true)
	local dir = core.get_texturepath_share() .. DIR_DELIM .. "base" .. DIR_DELIM .. "pack" .. DIR_DELIM
	local btn   = core.formspec_escape(dir .. "akititocraft_btn.png")
	local btn_h = core.formspec_escape(dir .. "akititocraft_btn_hover.png")
	local btn_p = core.formspec_escape(dir .. "akititocraft_btn_press.png")
	local formspec = {
		"formspec_version[6]" ..
		"size[10,3.9]" ..
		"box[0.4,0.4;9.2,3.1;#0e1a2ef2]" ..
		"box[0.4,0.4;9.2,0.12;#e74c3c]" ..
		("style_type[button;border=false;font=bold;textcolor=#ffffff;bgimg=%s;bgimg_hovered=%s;bgimg_pressed=%s;bgimg_middle=8]")
			:format(btn, btn_h, btn_p) ..
		"style_type[label;font=bold]" ..
		"label[0.8,1.1;" .. fgettext("Are you sure you want to quit?") .. "]" ..
		"checkbox[0.8,1.9;cb_show_dialog;" .. fgettext("Always show this dialog.") .. ";" .. tostring(show_dialog) .. "]" ..
		"style[btn_quit_confirm_yes;textcolor=#ff6b6b]" ..
		"button[0.8,2.6;4,0.8;btn_quit_confirm_cancel;" .. fgettext("Cancel") .. "]" ..
		"button[5.2,2.6;4,0.8;btn_quit_confirm_yes;" .. fgettext("Quit") .. "]" ..
		"set_focus[btn_quit_confirm_yes]"
	}
	return table.concat(formspec, "")
end


local function exit_dialog_buttonhandler(this, fields)
	if fields.cb_show_dialog ~= nil then
		core.settings:set_bool("enable_esc_dialog", core.is_yes(fields.cb_show_dialog))
		return false
	elseif fields.btn_quit_confirm_yes then
		this:delete()
		core.close()
		return true
	elseif fields.btn_quit_confirm_cancel then
		this:delete()
		this:show()
		return true
	end
end


local function event_handler(event)
	if event == "DialogShow" then
		mm_game_theme.set_engine(true) -- hide the menu header
		return true
	end
	return false
end


function create_exit_dialog()
	local retval = dialog_create("dlg_exit",
		exit_dialog_formspec,
		exit_dialog_buttonhandler,
		event_handler)
	return retval
end
