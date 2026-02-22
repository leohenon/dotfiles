#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Split Discord + Teams
# @raycast.mode silent

# Optional parameters:
# @raycast.packageName App Focus

# Documentation:
# @raycast.description Open Discord and Teams in macOS Split View

open -a "Discord"
open -a "Microsoft Teams"

osascript <<'APPLESCRIPT'
on activate_app(app_name)
  tell application app_name to activate
end activate_app

on click_window_menu_item(process_name, item_names)
  tell application "System Events"
    tell process process_name
      tell menu "Window" of menu bar 1
        repeat with item_name in item_names
          if exists menu item (contents of item_name) then
            click menu item (contents of item_name)
            return true
          end if
        end repeat

        if exists menu item "Move & Resize" then
          tell menu 1 of menu item "Move & Resize"
            repeat with item_name in item_names
              if exists menu item (contents of item_name) then
                click menu item (contents of item_name)
                return true
              end if
            end repeat
          end tell
        end if
      end tell
    end tell
  end tell
  return false
end click_window_menu_item

on click_when_available(process_name, item_names, timeout_seconds)
  set deadline to (current date) + timeout_seconds
  repeat while (current date) < deadline
    if click_window_menu_item(process_name, item_names) then
      return true
    end if
    delay 0.05
  end repeat
  return false
end click_when_available

set left_items to {"Tile Window to Left of Screen", "Tile Window to Left Side of Screen"}
set right_items to {"Tile Window to Right of Screen", "Tile Window to Right Side of Screen"}

activate_app("Discord")
if click_when_available("Discord", left_items, 2.5) is false then
  error "Could not tile Discord to the left."
end if

activate_app("Microsoft Teams")
if click_when_available("Microsoft Teams", right_items, 2.5) is false then
  error "Could not tile Microsoft Teams to the right."
end if
APPLESCRIPT
