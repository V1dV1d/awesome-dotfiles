--      ████████╗ ██████╗ ██████╗     ██████╗  █████╗ ███╗   ██╗███████╗██╗
--      ╚══██╔══╝██╔═══██╗██╔══██╗    ██╔══██╗██╔══██╗████╗  ██║██╔════╝██║
--         ██║   ██║   ██║██████╔╝    ██████╔╝███████║██╔██╗ ██║█████╗  ██║
--         ██║   ██║   ██║██╔═══╝     ██╔═══╝ ██╔══██║██║╚██╗██║██╔══╝  ██║
--         ██║   ╚██████╔╝██║         ██║     ██║  ██║██║ ╚████║███████╗███████╗
--         ╚═╝    ╚═════╝ ╚═╝         ╚═╝     ╚═╝  ╚═╝╚═╝  ╚═══╝╚══════╝╚══════╝

-- ===================================================================
-- Initialization
-- ===================================================================

local awful = require("awful")
local beautiful = require("beautiful")
local wibox = require("wibox")
local gears = require("gears")

local dpi = beautiful.xresources.apply_dpi

-- define module table
local top_panel = {}

-- ===================================================================
-- Bar Creation
-- ===================================================================

top_panel.create = function(s)
   local panel = wibox({
      screen = s,
      ontop = true,
      visible = true,
      height = beautiful.top_panel_height,
      width = s.geometry.width,
      bg = "#00000000",
      type = "dock",
   })

   panel:struts({
      top = beautiful.top_panel_height,
   })

   panel:setup({
      expand = "none",
      layout = wibox.layout.align.horizontal,
      -- left side of top panel
      {
         layout = wibox.layout.fixed.horizontal,
         -- padding so top and left panel (should it exist) do not overlap
         s.index == 1
               and wibox.widget({
                  forced_width = beautiful.left_panel_width,
               })
            or nil,
         require("awesome-wm-widgets.todo-widget.todo")(),
      },
      -- middle of top panel
      require("widgets.calendar").create(s),
      -- right side of top panel
      {
         spacing = 5,
         layout = wibox.layout.fixed.horizontal,
         -- systray can only be created once, so primary screen it is
         s.index == 1
               and wibox.widget({
                  {
                     wibox.widget.systray(),
                     left = dpi(14),
                     top = dpi(2),
                     bottom = dpi(2),
                     right = dpi(14),
                     widget = wibox.container.margin,
                  },
                  bg = beautiful.bg_systray,
                  shape = gears.shape.rounded_bar,
                  shape_clip = true,
                  widget = wibox.container.background,
               })
            or nil,
         require("awesome-wm-widgets.volume-widget.volume")({
            bg_color = "#ffffff33",
            widget_type = "arc",
         }),
         -- only display battery widget whe acpi can find a battery
         io.popen("acpi -b 2>&1"):read(10) ~= "No support"
               and require("awesome-wm-widgets.batteryarc-widget.batteryarc")({
                  bg_color = "#ffffff33",
                  charging_color = "#ffffff",
               })
            or nil,
      },
   })

   local panel_bg = wibox({
      screen = s,
      position = "top",
      ontop = false,
      height = beautiful.top_panel_height,
      width = s.geometry.width,
      bg = beautiful.bg_dark,
      visible = false,
   })

   -- ===================================================================
   -- Functionality
   -- ===================================================================

   -- hide panel when client is fullscreen
   local function change_panel_visibility(client)
      if client.screen == s then
         panel.ontop = not client.fullscreen
      end
   end

   -- connect panel visibility function to relevant signals
   client.connect_signal("property::fullscreen", change_panel_visibility)
   client.connect_signal("focus", change_panel_visibility)

   -- maximize panel if client is maximized
   local function toggle_maximize_top_panel(is_maximized)
      if s == awful.screen.focused() then
         if is_maximized then
            panel_bg.visible = true
         else
            panel_bg.visible = false
         end
      end
   end

   -- maximize if a client is maximized
   client.connect_signal("property::maximized", function(c)
      toggle_maximize_top_panel(c.maximized)
   end)

   client.connect_signal("manage", function(c)
      if
         awful.tag.getproperty(c.first_tag, "layout") == awful.layout.suit.max
      then
         toggle_maximize_top_panel(true)
      end
   end)

   -- unmaximize if a client is removed and there are no maximized clients left
   client.connect_signal("unmanage", function(c)
      local t = awful.screen.focused().selected_tag
      -- if client was maximized
      if c.maximized then
         -- check if any clients that are open are maximized
         for _, c in pairs(t:clients()) do
            if c.maximized then
               return
            end
         end
         toggle_maximize_top_panel(false)

         -- if tag was maximized
      elseif awful.tag.getproperty(t, "layout") == awful.layout.suit.max then
         -- check if any clients are open (and therefore maximized)
         for _ in pairs(t:clients()) do
            return
         end
         toggle_maximize_top_panel(false)
      end
   end)

   -- maximize if layout is maximized and a client is in the layout
   tag.connect_signal("property::layout", function(t)
      -- check if layout is maximized
      if awful.tag.getproperty(t, "layout") == awful.layout.suit.max then
         -- check if clients are open
         for _ in pairs(t:clients()) do
            toggle_maximize_top_panel(true)
            return
         end
         toggle_maximize_top_panel(false)
      else
         toggle_maximize_top_panel(false)
      end
   end)

   -- maximize if a tag is swapped to with a maximized client
   tag.connect_signal("property::selected", function(t)
      -- check if layout is maximized
      if awful.tag.getproperty(t, "layout") == awful.layout.suit.max then
         -- check if clients are open
         for _ in pairs(t:clients()) do
            toggle_maximize_top_panel(true)
            return
         end
         toggle_maximize_top_panel(false)
      else
         -- check if any clients that are open are maximized
         for _, c in pairs(t:clients()) do
            if c.maximized then
               toggle_maximize_top_panel(true)
               return
            end
         end
         toggle_maximize_top_panel(false)
      end
   end)
end

return top_panel
