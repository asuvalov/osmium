--[[

     Licensed under GNU General Public License v2
      * (c) 2020, Andrew Suvalov

--]]

local helpers = require("osmium.helpers")
local shell   = require("awful.util").shell
local wibox   = require("wibox")
local awful   = require("awful")
local string  = string
local type    = type

-- xbacklight
-- osmium.widget.backlight

local function factory(args)
    local backlight = { widget = wibox.widget.textbox() }
    local args      = args or {}
    local timeout   = args.timeout or 5
    local settings  = args.settings or function() end
    backlight.cmd   = args.cmd or "xbacklight -get"

    function backlight.update()
        helpers.async({shell, "-c", type(backlight.cmd) == "string" and backlight.cmd or backlight.cmd()},
        function (s)
            backlight_now = {
                brightness = tonumber(s)
            }
            widget = backlight.widget
            settings()
        end)
    end

    helpers.newtimer("backlight", timeout, backlight.update)

    backlight.widget:buttons(awful.util.table.join(
    awful.button({}, 4, function() -- scroll up
        os.execute("xbacklight -inc 5")
        backlight.update()
    end),
    awful.button({}, 5, function() -- scroll down
        os.execute("xbacklight -dec 5")
        backlight.update()
    end)
    ))

    return backlight
end

return factory
