--      ██╗   ██╗ ██████╗ ██╗     ██╗   ██╗███╗   ███╗███████╗
--      ██║   ██║██╔═══██╗██║     ██║   ██║████╗ ████║██╔════╝
--      ██║   ██║██║   ██║██║     ██║   ██║██╔████╔██║█████╗
--      ╚██╗ ██╔╝██║   ██║██║     ██║   ██║██║╚██╔╝██║██╔══╝
--       ╚████╔╝ ╚██████╔╝███████╗╚██████╔╝██║ ╚═╝ ██║███████╗
--        ╚═══╝   ╚═════╝ ╚══════╝ ╚═════╝ ╚═╝     ╚═╝╚══════╝

-- ===================================================================
-- Initialization
-- ===================================================================

local wibox = require("wibox")
local awful = require("awful")
local gears = require("gears")
local beautiful = require("beautiful")
local dpi = beautiful.xresources.apply_dpi

local offsetx = dpi(56)
local offsety = dpi(300)
local screen = awful.screen.focused()
local icon_dir = gears.filesystem.get_configuration_dir()
   .. "/icons/volume/"
   .. beautiful.name
   .. "/"

-- ===================================================================
-- Appearance & Functionality
-- ===================================================================

local prop_icon = wibox.widget({
   widget = wibox.widget.imagebox,
})

-- create the prop_adjust component
local prop_adjust = wibox({
   screen = awful.screen.focused(),
   x = screen.geometry.width - offsetx,
   y = (screen.geometry.height / 2) - (offsety / 2),
   width = dpi(48),
   height = offsety,
   shape = gears.shape.rounded_rect,
   visible = false,
   ontop = true,
})

local prop_bar = wibox.widget({
   widget = wibox.widget.progressbar,
   shape = gears.shape.rounded_bar,
   color = "#efefef",
   background_color = beautiful.bg_focus,
   max_value = 100,
   value = 0,
})

prop_adjust:setup({
   layout = wibox.layout.align.vertical,
   {
      wibox.container.margin(prop_bar, dpi(14), dpi(20), dpi(20), dpi(20)),
      forced_height = offsety * 0.75,
      direction = "east",
      layout = wibox.container.rotate,
   },
   wibox.container.margin(prop_icon),
})

-- create a 4 second timer to hide the prop adjust
-- component whenever the timer is started
local hide_prop_adjust = gears.timer({
   timeout = 4,
   autostart = true,
   callback = function()
      prop_adjust.visible = false
   end,
})

-- show prop-adjust when "volume_change" signal is emitted
awesome.connect_signal("volume_change", function()
   -- set new volume value
   awful.spawn.easy_async_with_shell(
      "amixer sget Master | grep 'Right:' | awk -F '[][]' '{print ($4 == \"on\") ? $2 : 0}' | sed 's/[^0-9]//g'",
      function(stdout)
         local volume_level = tonumber(stdout)
         prop_bar.value = volume_level
         if volume_level > 40 then
            prop_icon:set_image(icon_dir .. "volume.png")
         elseif volume_level > 0 then
            prop_icon:set_image(icon_dir .. "volume-low.png")
         else
            prop_icon:set_image(icon_dir .. "volume-off.png")
         end
      end,
      false
   )

   -- make prop_adjust component visible
   if prop_adjust.visible then
      hide_prop_adjust:again()
   else
      prop_adjust.visible = true
      hide_prop_adjust:start()
   end
end)

local naughty = require("naughty")
-- show prop-adjust when "brightness_change" signal is emitted
awesome.connect_signal("brightness_change", function()
   -- set new brightness value
   awful.spawn.easy_async_with_shell(
      "echo $(( $(brightnessctl get)*100 / $(brightnessctl max) ))",
      function(stdout)
         local brightness_level = tonumber(stdout)
         prop_bar.value = brightness_level
         prop_icon:set_image(icon_dir .. "brightness.png")
      end,
      false
   )

   -- make prop_adjust component visible
   if prop_adjust.visible then
      hide_prop_adjust:again()
   else
      prop_adjust.visible = true
      hide_prop_adjust:start()
   end
end)
