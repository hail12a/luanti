-- AkititoCraft home screen.
--
-- This replaces the old tab-strip main menu with a proper landing screen:
-- a centered title over a card with big Play / Settings / Shop / Quit
-- buttons, in the style of a modern game menu. "Play" opens the tabbed
-- screen (Worlds / Friends / Servers); the other buttons are wired by the
-- caller via the callbacks table.
--
-- create_home_dlg{ on_play = f(this), on_settings = f(this), on_about = f(this) }

local function esc(t)
	return core.formspec_escape(defaulttexturedir .. t)
end

-- Geometry shared with the tabview so the home screen sits in the exact
-- same on-screen rectangle as the Worlds / Servers screens.
local CONTENT_W = MAIN_TAB_W          -- 15.5
local CONTENT_H = MAIN_TAB_H          -- 7.1
local TOUCH_GUI = false               -- resolved per-build below

local function home_formspec()
	TOUCH_GUI = core.settings:get_bool("touch_gui")

	local total_h = CONTENT_H + TABHEADER_H +
			(TOUCH_GUI and GAMEBAR_OFFSET_TOUCH or GAMEBAR_OFFSET_DESKTOP) + GAMEBAR_H
	local anchor_y = (TABHEADER_H + CONTENT_H / 2) / total_h

	local btn   = esc("akititocraft_btn.png")
	local btn_h = esc("akititocraft_btn_hover.png")
	local btn_p = esc("akititocraft_btn_press.png")
	local grn   = esc("akititocraft_btn_green.png")
	local grn_h = esc("akititocraft_btn_green_hover.png")

	local version = core.get_version and core.get_version().string or ""

	-- Centred button column.
	local bw, bx = 7.0, (CONTENT_W - 7.0) / 2      -- x = 4.25

	local fs = {
		("formspec_version[6]size[%f,%f,false]"):format(CONTENT_W, total_h),
		("anchor[0.5,%f]"):format(anchor_y),
		"bgcolor[;neither]",
		("container[0,%f]"):format(TABHEADER_H),

		-- Backdrop + soft card behind the buttons.
		("box[0,0;%f,%f;#0000008C]"):format(CONTENT_W, CONTENT_H),
		"box[3.85,2.25;7.8,4.6;#101f33cc]",
		"box[3.85,2.25;7.8,0.06;#1e88e5]",

		-- Title + subtitle (styled text; no logo art needed).
		("hypertext[0,0.45;%f,1.25;h_title;"):format(CONTENT_W) ..
			"<global valign=middle halign=center size=44 color=#FFFFFF><b>AkititoCraft</b>]",
		("hypertext[0,1.7;%f,0.5;h_sub;"):format(CONTENT_W) ..
			"<global valign=middle halign=center size=15 color=#9fb3c8>Minecraft-style survival \194\183 hosted worlds \194\183 crossplay]",

		-- Button skin (9-sliced textures).
		("style_type[button;border=false;font=bold;textcolor=#ffffff;bgimg=%s;bgimg_hovered=%s;bgimg_pressed=%s;bgimg_middle=8]")
			:format(btn, btn_h, btn_p),
		("style[btn_play;border=false;font=bold;textcolor=#ffffff;bgimg=%s;bgimg_hovered=%s;bgimg_pressed=%s;bgimg_middle=8]")
			:format(grn, grn_h, grn),
		("style[btn_shop;border=false;font=bold;textcolor=#8a97a5;bgimg=%s;bgimg_hovered=%s;bgimg_pressed=%s;bgimg_middle=8]")
			:format(btn, btn, btn),

		("button[%f,2.55;%f,1.05;btn_play;%s]"):format(bx, bw, fgettext("Play")),
		("button[%f,3.80;%f,0.85;btn_settings;%s]"):format(bx, bw, fgettext("Settings")),
		("button[%f,4.80;%f,0.85;btn_shop;%s]"):format(bx, bw, fgettext("Shop")),
		-- "Coming soon" badge pinned to the right of the Shop button.
		"hypertext[9.55,4.98;1.85,0.5;h_soon;<global valign=middle halign=center size=12 color=#ffd54f><b>COMING SOON</b>]",
		("button[%f,5.95;%f,0.85;btn_quit;%s]"):format(bx, bw, fgettext("Quit")),

		-- Footer: About (left) + version (right).
		"style[btn_about;border=false;bgimg=" .. btn .. ";bgimg_hovered=" .. btn_h ..
			";bgimg_pressed=" .. btn_p .. ";bgimg_middle=8;textcolor=#cfd8dc]",
		("button[0.35,6.25;2.3,0.65;btn_about;%s]"):format(fgettext("About")),
		("hypertext[9.5,6.35;5.65,0.6;h_ver;"):format() ..
			"<global valign=middle halign=right size=12 color=#7f8c99>" ..
			core.formspec_escape(version) .. "]",

		"set_focus[btn_play;true]",
		"container_end[]",
	}
	return table.concat(fs)
end

local function home_buttonhandler(this, fields)
	if fields.btn_play then
		if this.callbacks.on_play then this.callbacks.on_play(this) end
		return true
	end
	if fields.btn_settings then
		if this.callbacks.on_settings then this.callbacks.on_settings(this) end
		return true
	end
	if fields.btn_about then
		if this.callbacks.on_about then this.callbacks.on_about(this) end
		return true
	end
	if fields.btn_shop then
		local dlg = messagebox("home_shop_soon", fgettext(
			"The in-game Shop is coming soon.\n\nHere you'll be able to get cosmetics and " ..
			"content packs for AkititoCraft. Stay tuned!"))
		dlg:set_parent(this)
		this:hide()
		dlg:show()
		return true
	end
	if fields.btn_quit then
		local dlg = create_exit_dialog()
		dlg:set_parent(this)
		this:hide()
		dlg:show()
		return true
	end
	return false
end

local function home_eventhandler(event)
	if event == "DialogShow" then
		-- Show the engine/menu header behind the screen.
		mm_game_theme.set_engine()
		return true
	end
	if event == "MenuQuit" then
		local this = ui.find_by_name("home")
		local dlg = create_exit_dialog()
		dlg:set_parent(this)
		this:hide()
		dlg:show()
		ui.update()
		return true
	end
	return false
end

function create_home_dlg(callbacks)
	local dlg = dialog_create("home", home_formspec, home_buttonhandler, home_eventhandler)
	dlg.callbacks = callbacks or {}
	return dlg
end

--------------------------------------------------------------------------------
-- About dialog (also carries the required engine/content attribution).
--------------------------------------------------------------------------------
local function about_formspec()
	local v = core.get_version and core.get_version() or {}
	local version = v.string or ""

	local body =
		"AkititoCraft " .. version .. "\n\n" ..
		"A Minecraft-style voxel game with hosted worlds and mobile/PC crossplay.\n\n" ..
		"Built on the Luanti (formerly Minetest) engine, licensed under the GNU LGPL 2.1+ " ..
		"and GPL 3.0. Game content is based on Mineclonia, licensed under the GNU GPL 3.0. " ..
		"Thanks to the Luanti and Mineclonia communities."

	return table.concat({
		"formspec_version[6]size[10,7.2]",
		"box[0,0;10,1.0;#1e88e5]",
		"hypertext[0.4,0.15;9.2,0.7;h_t;<global valign=middle size=24 color=#ffffff><b>About</b>]",
		"box[0.4,1.3;9.2,4.7;#0b0b0bcc]",
		("textarea[0.6,1.5;8.8,4.3;;;%s]"):format(core.formspec_escape(body)),
		"button[3.5,6.2;3,0.8;btn_about_ok;" .. fgettext("OK") .. "]",
		"set_focus[btn_about_ok;true]",
	})
end

local function about_buttonhandler(this, fields)
	if fields.btn_about_ok then
		this:delete()
		return true
	end
	return false
end

function create_about_dlg()
	return dialog_create("home_about", about_formspec, about_buttonhandler, nil)
end
