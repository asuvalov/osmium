--[[
     Licensed under GNU General Public License v2
      * (c) 2013,      Luca CPZ
      * (c) 2010-2012, Peter Hofmann
--]]

local helpers              = require("lain.helpers")
local wibox                = require("wibox")
local naughty              = require("naughty")
local tconcat              = table.concat
local gmatch, lines, floor = string.gmatch, io.lines, math.floor
local fmt = string.format

-- Memory usage (ignoring caches)
-- lain.widget.mem

local function factory(args)
  local mem       = { widget = wibox.widget.textbox() }
  local args      = args or {}
  local timeout   = args.timeout or 2
  local settings  = args.settings or function() end
  local showpopup = args.showpopup or "on"

  mem.followtag           = args.followtag or false
  mem.notification_preset = args.notification_preset

  if not mem.notification_preset then
      mem.notification_preset = {
        font = "Monospace 10",
        fg   = "#FFFFFF",
        bg   = "#000000"
      }
  end

  function mem.hide()
    if not mem.notification then
      return
    end
    naughty.destroy(mem.notification)
    mem.notification = nil
  end

  function mem.show(seconds, scr)
    mem.hide(); mem.update()
    mem.notification_preset.screen = mem.followtag and focused() or scr or 1
    mem.notification = naughty.notify {
      preset  = mem.notification_preset,
      timeout = type(seconds) == "number" and seconds or 5
    }
  end

  function mem.update()
      mem_now = {}
      for line in lines("/proc/meminfo") do
          for k, v in gmatch(line, "([%a]+):[%s]+([%d]+).+") do
              if     k == "MemTotal"     then mem_now.total = floor(v / 1024 + 0.5)
              elseif k == "MemFree"      then mem_now.free  = floor(v / 1024 + 0.5)
              elseif k == "Buffers"      then mem_now.buf   = floor(v / 1024 + 0.5)
              elseif k == "Cached"       then mem_now.cache = floor(v / 1024 + 0.5)
              elseif k == "SwapTotal"    then mem_now.swap  = floor(v / 1024 + 0.5)
              elseif k == "SwapFree"     then mem_now.swapf = floor(v / 1024 + 0.5)
              elseif k == "SReclaimable" then mem_now.srec  = floor(v / 1024 + 0.5)
              end
          end
      end

    mem_now.used     = mem_now.total - mem_now.free - mem_now.buf - mem_now.cache - mem_now.srec
    mem_now.swapused = floor(mem_now.swap - mem_now.swapf)
    mem_now.perc     = floor(mem_now.used / mem_now.total * 100)

    widget = mem.widget
    settings()

    local text = { [1] = fmt("%-5s\t%-5s\t%-5s\t%-5s\t%-4s\n", "type", "total", "used", "free", "unit") }
    text[#text+1]      = fmt("%-5s\t%-5d\t%-5d\t%-5d\t%-4s\n", "ram",  mem_now.total, mem_now.used, mem_now.free,  "MB")
    text[#text+1]      = fmt("%-5s\t%-5d\t%-5d\t%-5d\t%-4s"  , "swap", mem_now.swap, mem_now.swapused, mem_now.swapf, "MB")
    mem.notification_preset.text = table.concat(text)
  end

  if showpopup == "on" then
    mem.widget:connect_signal('mouse::enter', function () mem.show(0) end)
    mem.widget:connect_signal('mouse::leave', function () mem.hide() end)
  end

  helpers.newtimer("mem", timeout, mem.update)

  return mem
end

return factory
