-- AkititoCraft "Play" screen: a custom framed menu with a left sidebar
-- (Worlds / Friends / Servers) and a content panel on the right. Each page
-- draws its own distinct layout into the shared content region (AC) below;
-- this file only owns the frame, the sidebar navigation and event routing.
--
-- The page objects (tab_local / tab_friends / tab_online) supply
-- cbf_formspec(frame, name, tabdata) and cbf_button_handler(frame, fields,
-- name, tabdata). The frame passes itself as the "tabview" so those pages can
-- open sub-dialogs (world create/delete, register, ...) and call
-- frame:set_tab(name) to navigate.

-- Overall canvas (kept in sync with the header/gamebar spacing so the logo
-- shows above the frame, matching the home screen).
local CANVAS_W = 18.5
local CANVAS_H = 8.8

-- Shared content region used by every page (global so the pages can read it).
AC = {
	PX = 4.35,
	PY = 0.2,
	PW = 13.9,
	PH = CANVAS_H - 0.4,   -- 0.2 top + 0.2 bottom margin
}

-- Page accent colours (used by the pages for their header strips).
AC.ACCENT = {
	worlds  = "#3aa856",
	friends = "#8e44ad",
	servers = "#1e88e5",
}

local function esc(t)
	return core.formspec_escape(defaulttexturedir .. t)
end

local BTN   = function() return esc("akititocraft_btn.png") end
local BTN_H = function() return esc("akititocraft_btn_hover.png") end
local BTN_P = function() return esc("akititocraft_btn_press.png") end
local GRN   = function() return esc("akititocraft_btn_green.png") end
local GRN_H = function() return esc("akititocraft_btn_green_hover.png") end

-- Standard button skin shared by the whole menu.
function ac_button_skin()
	return ("style_type[button;border=false;font=bold;textcolor=#ffffff;bgimg=%s;bgimg_hovered=%s;bgimg_pressed=%s;bgimg_middle=8]")
		:format(BTN(), BTN_H(), BTN_P())
end

local NAV = {
	{ id = "worlds",  label = "Worlds"  },
	{ id = "friends", label = "Friends" },
	{ id = "servers", label = "Servers" },
}

local function sidebar(active)
	local fs = {
		-- Sidebar background.
		"box[0.3,0.2;3.7,8.4;#0b1526f2]",
		"box[0.3,0.2;3.7,0.06;#1e88e5]",
		"hypertext[0.3,0.45;3.7,0.6;h_nav;<global valign=middle halign=center size=15 color=#7f8c99><b>MENU</b>]",
	}

	local y = 1.3
	for _, item in ipairs(NAV) do
		local name = "nav_" .. item.id
		local accent = AC.ACCENT[item.id]
		if item.id == active then
			-- Active tab: solid accent bar with a transparent button on top.
			local blank = esc("blank.png")
			fs[#fs + 1] = ("box[0.5,%f;3.3,1.0;%s]"):format(y, accent)
			fs[#fs + 1] = ("style[%s;border=false;font=bold;textcolor=#ffffff;bgimg=%s;bgimg_hovered=%s;bgimg_pressed=%s]")
				:format(name, blank, blank, blank)
		else
			fs[#fs + 1] = ("style[%s;border=false;font=bold;textcolor=#cfd8dc;bgimg=%s;bgimg_hovered=%s;bgimg_pressed=%s;bgimg_middle=8]")
				:format(name, BTN(), BTN_H(), BTN_P())
		end
		fs[#fs + 1] = ("button[0.5,%f;3.3,1.0;%s;%s]"):format(y, name, fgettext(item.label))
		y = y + 1.2
	end

	-- Back to main menu, pinned to the bottom.
	fs[#fs + 1] = ("style[nav_back;border=false;font=bold;textcolor=#ffd54f;bgimg=%s;bgimg_hovered=%s;bgimg_pressed=%s;bgimg_middle=8]")
		:format(BTN(), BTN_H(), BTN_P())
	fs[#fs + 1] = ("button[0.5,7.7;3.3,0.9;nav_back;%s]"):format(fgettext("Back"))

	return table.concat(fs)
end

local function play_formspec(data)
	local total_h = CANVAS_H + TABHEADER_H +
			(core.settings:get_bool("touch_gui") and GAMEBAR_OFFSET_TOUCH or GAMEBAR_OFFSET_DESKTOP) + GAMEBAR_H
	local anchor_y = (TABHEADER_H + CANVAS_H / 2) / total_h

	local page = data.pages[data.active]
	local content = page.cbf_formspec(data.self, page.name, data.tabdata[data.active]) or ""

	return table.concat({
		("formspec_version[6]size[%f,%f,false]"):format(CANVAS_W, total_h),
		("anchor[0.5,%f]"):format(anchor_y),
		"bgcolor[;neither]",
		("container[0,%f]"):format(TABHEADER_H),
		ac_button_skin(),
		sidebar(data.active),
		content,
		"container_end[]",
	})
end

local function switch_page(self, name)
	if not self.data.pages[name] then
		return
	end
	self.data.active = name
	mm_game_theme.set_engine()
	if name == "servers" then
		serverlistmgr.sync()
	end
end

local function play_buttonhandler(self, fields)
	if fields.nav_back then
		local home = ui.find_by_name("home")
		self:hide()
		if home then home:show() end
		return true
	end
	if fields.nav_worlds  then switch_page(self, "worlds")  return true end
	if fields.nav_friends then switch_page(self, "friends") return true end
	if fields.nav_servers then switch_page(self, "servers") return true end

	local page = self.data.pages[self.data.active]
	if page.cbf_button_handler then
		return page.cbf_button_handler(self, fields, page.name, self.data.tabdata[self.data.active])
	end
	return false
end

local function play_eventhandler(event)
	local self = ui.find_by_name("play")
	if event == "DialogShow" then
		mm_game_theme.set_engine()
		return true
	end
	if event == "MenuQuit" then
		local home = ui.find_by_name("home")
		if self then self:hide() end
		if home then home:show() end
		ui.update()
		return true
	end
	return false
end

-- pages: { worlds = <tab obj>, friends = <tab obj>, servers = <tab obj> }
function create_play_dlg(pages)
	local dlg = dialog_create("play", play_formspec, play_buttonhandler, play_eventhandler)
	dlg.width  = CANVAS_W
	dlg.height = CANVAS_H
	dlg.data.pages  = pages
	dlg.data.active = "worlds"
	dlg.data.self   = dlg
	dlg.data.tabdata = {
		worlds  = {},
		friends = {},
		servers = {},
	}
	-- Navigation shim so pages written for the tabview can call frame:set_tab.
	dlg.set_tab = function(self, name)
		-- Accept both new names and the old tab names.
		local map = { ["local"] = "worlds", online = "servers" }
		switch_page(self, map[name] or name)
	end
	return dlg
end
