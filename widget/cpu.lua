--[[

     Licensed under GNU General Public License v2
      * (c) 2013,      Luca CPZ
      * (c) 2010-2012, Peter Hofmann

--]]

local helpers  = require("lain.helpers")
local wibox    = require("wibox")
local naughty              = require("naughty")
local fmt = string.format
-- CPU usage
-- lain.widget.cpu

local function factory(args)
    local cpu      = { core = {}, widget = wibox.widget.textbox() }
    local args     = args or {}
    local timeout  = args.timeout or 2
    local settings = args.settings or function() end
    local showpopup = args.showpopup or "on"

  cpu.followtag           = args.followtag or false
  cpu.notification_preset = args.notification_preset

  if not cpu.notification_preset then
      cpu.notification_preset = {
        font = "Monospace 10",
        fg   = "#FFFFFF",
        bg   = "#000000"
      }
  end

  function cpu.hide()
    if not cpu.notification then
      return
    end
    naughty.destroy(cpu.notification)
    cpu.notification = nil
  end

  function cpu.show(seconds, scr)
    cpu.hide(); cpu.update()
    cpu.notification_preset.screen = cpu.followtag and focused() or scr or 1
    cpu.notification = naughty.notify {
      preset  = cpu.notification_preset,
      timeout = type(seconds) == "number" and seconds or 5
    }
  end

    function cpu.update()
        -- Read the amount of time the CPUs have spent performing
        -- different kinds of work. Read the first line of /proc/stat
        -- which is the sum of all CPUs.
        for index,time in pairs(helpers.lines_match("cpu","/proc/stat")) do
            local coreid = index - 1
            local core   = cpu.core[coreid] or
                           { last_active = 0 , last_total = 0, usage = 0 }
            local at     = 1
            local idle   = 0
            local total  = 0

            for field in string.gmatch(time, "[%s]+([^%s]+)") do
                -- 4 = idle, 5 = ioWait. Essentially, the CPUs have done
                -- nothing during these times.
                if at == 4 or at == 5 then
                    idle = idle + field
                end
                total = total + field
                at = at + 1
            end

            local active = total - idle

            if core.last_active ~= active or core.last_total ~= total then
                -- Read current data and calculate relative values.
                local dactive = active - core.last_active
                local dtotal  = total - core.last_total
                local usage   = math.ceil((dactive / dtotal) * 100)

                core.last_active = active
                core.last_total  = total
                core.usage       = usage

                -- Save current data for the next run.
                cpu.core[coreid] = core
            end
        end

        cpu_now = cpu.core
        cpu_now.usage = cpu_now[0].usage
        widget = cpu.widget

        settings()
        
        local text = { [1] = fmt("%s %s %s %s %s %s\n", "cpu0", "cpu1", "cpu2", "cpu3", "cpu4", "cpu5") }
        text[#text+1]      = fmt("%4d %4d %4d %4d %4d %4d", cpu_now[1].usage, cpu_now[2].usage, cpu_now[3].usage, cpu_now[4].usage,
                                                     cpu_now[5].usage, cpu_now[6].usage)
        cpu.notification_preset.text = table.concat(text)

    end
    if showpopup == "on" then
      cpu.widget:connect_signal('mouse::enter', function () cpu.show(0) end)
      cpu.widget:connect_signal('mouse::leave', function () cpu.hide() end)
    end


    helpers.newtimer("cpu", timeout, cpu.update)

    return cpu
end

return factory
