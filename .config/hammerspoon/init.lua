-- Hammerspoon config

local videoApps = {
	"IINA",
	"VLC",
	"QuickTime Player",
	"TV",
	"Safari",
	"Google Chrome",
	"Arc",
	"Firefox",
}

local function windowUnderMouse()
	local point = hs.geometry.new(hs.mouse.getAbsolutePosition())
	local screen = hs.mouse.getCurrentScreen()

	return hs.fnutils.find(hs.window.orderedWindows(), function(win)
		return win:screen():id() == screen:id()
			and win:isVisible()
			and not win:isMinimized()
			and point:inside(win:frame())
	end)
end

local function topWindowOnScreen(screen)
	return hs.fnutils.find(hs.window.orderedWindows(), function(win)
		return win:screen():id() == screen:id()
			and win:isVisible()
			and not win:isMinimized()
			and win:isStandard()
	end)
end

local function focusWindowOnScreen(screen)
	local win = windowUnderMouse()
	if win and win:screen():id() == screen:id() then
		win:raise()
		win:focus()
		return true
	end

	local windows = hs.fnutils.filter(hs.window.orderedWindows(), function(candidate)
		return candidate:screen():id() == screen:id() and candidate:isVisible() and not candidate:isMinimized()
	end)

	if #windows == 0 then
		return false
	end
	windows[1]:raise()
	windows[1]:focus()
	return true
end

local function postMouse(type, point)
	hs.eventtap.event.newMouseEvent(type, point):post()
end

-- Alt+Shift+M: switch monitor focus.
hs.hotkey.bind({ "alt", "shift" }, "M", function()
	local targetScreen = hs.mouse.getCurrentScreen():next()
	local frame = targetScreen:fullFrame()
	local point = { x = frame.x + frame.w / 2, y = frame.y + frame.h / 2 }

	hs.mouse.absolutePosition(point)

	hs.timer.doAfter(0.08, function()
		postMouse(hs.eventtap.event.types.leftMouseDown, point)
		hs.timer.doAfter(0.03, function()
			postMouse(hs.eventtap.event.types.leftMouseUp, point)

			hs.timer.doAfter(0.08, function()
				if focusWindowOnScreen(targetScreen) then
					return
				end

				if not targetScreen:name():lower():find("retina") then
					return
				end

				for _, appName in ipairs(videoApps) do
					local app = hs.application.get(appName)
					if app and app:isRunning() then
						app:activate(false)
						return
					end
				end
			end)
		end)
	end)
end)

-- Alt+Shift+N: send the focused window to the next monitor without switching focus.
hs.hotkey.bind({ "alt", "shift" }, "N", function()
	local win = hs.window.focusedWindow()
	if not win then
		hs.alert.show("No focused window")
		return
	end

	win:moveToScreen(win:screen():next(), false, true, 0)
end)

-- Alt+Shift+O: swap the frontmost normal window on each monitor.
hs.hotkey.bind({ "alt", "shift" }, "O", function()
	if #hs.screen.allScreens() ~= 2 then
		hs.alert.show("Window swap expects exactly 2 monitors")
		return
	end

	local screenA = hs.mouse.getCurrentScreen()
	local screenB = screenA:next()
	local windowA = topWindowOnScreen(screenA)
	local windowB = topWindowOnScreen(screenB)

	if not windowA or not windowB then
		hs.alert.show("Need one normal window on each monitor")
		return
	end

	windowA:moveToScreen(screenB, false, true, 0)
	windowB:moveToScreen(screenA, false, true, 0)
	windowA:raise()
	windowA:focus()
end)
