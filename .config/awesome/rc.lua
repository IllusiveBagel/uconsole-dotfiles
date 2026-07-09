-- If LuaRocks is installed, make sure that packages installed through it are
-- found (e.g. lgi). If LuaRocks is not installed, do nothing.
pcall(require, "luarocks.loader")

-- Standard awesome library
local gears = require("gears")
local awful = require("awful")
require("awful.autofocus")
-- Widget and layout library
local wibox = require("wibox")
-- Theme handling library
local beautiful = require("beautiful")
local dpi = require("beautiful.xresources").apply_dpi
-- Notification library
local naughty = require("naughty")
local menubar = require("menubar")
local hotkeys_popup = require("awful.hotkeys_popup")
-- Enable hotkeys help widget for VIM and other apps
-- when client with a matching name is opened:
require("awful.hotkeys_popup.keys")

-- Load Debian menu entries
local debian = require("debian.menu")
local has_fdo, freedesktop = pcall(require, "freedesktop")

-- {{{ Error handling
-- Check if awesome encountered an error during startup and fell back to
-- another config (This code will only ever execute for the fallback config)
if awesome.startup_errors then
    naughty.notify({ preset = naughty.config.presets.critical,
                     title = "Oops, there were errors during startup!",
                     text = awesome.startup_errors })
end

-- Handle runtime errors after startup
do
    local in_error = false
    awesome.connect_signal("debug::error", function (err)
        -- Make sure we don't go into an endless error loop
        if in_error then return end
        in_error = true

        naughty.notify({ preset = naughty.config.presets.critical,
                         title = "Oops, an error happened!",
                         text = tostring(err) })
        in_error = false
    end)
end
-- }}}

-- {{{ Variable definitions
-- Themes define colours, icons, font and wallpapers.
-- "Tape Deck 01" — cassette-futurism theme (amber/cream on near-black).
beautiful.init(os.getenv("HOME") .. "/.config/awesome/themes/cassette/theme.lua")

-- This is used later as the default terminal and editor to run.
terminal = "alacritty"
editor = os.getenv("EDITOR") or "editor"
editor_cmd = terminal .. " -e " .. editor

-- Default modkey.
-- Usually, Mod4 is the key with a logo between Control and Alt.
-- If you do not like this or do not have such a key,
-- I suggest you to remap Mod4 to another key using xmodmap or other tools.
-- However, you can use another modifier like Mod1, but it may interact with others.
modkey = "Mod1"

-- Table of layouts to cover with awful.layout.inc, order matters.
awful.layout.layouts = {
    awful.layout.suit.tile,
    awful.layout.suit.tile.left,
    awful.layout.suit.tile.bottom,
    awful.layout.suit.tile.top,
    awful.layout.suit.fair,
    awful.layout.suit.fair.horizontal,
    awful.layout.suit.spiral,
    awful.layout.suit.spiral.dwindle,
    awful.layout.suit.max,
    awful.layout.suit.max.fullscreen,
    awful.layout.suit.magnifier,
    awful.layout.suit.corner.nw,
}
-- }}}

-- {{{ Menu
-- Create a launcher widget and a main menu
myawesomemenu = {
   { "hotkeys", function() hotkeys_popup.show_help(nil, awful.screen.focused()) end },
   { "manual", terminal .. " -e man awesome" },
   { "edit config", editor_cmd .. " " .. awesome.conffile },
   { "restart", awesome.restart },
   { "quit", function() awesome.quit() end },
}

local menu_awesome = { "awesome", myawesomemenu, beautiful.awesome_icon }
local menu_terminal = { "open terminal", terminal }

if has_fdo then
    mymainmenu = freedesktop.menu.build({
        before = { menu_awesome },
        after =  { menu_terminal }
    })
else
    mymainmenu = awful.menu({
        items = {
                  menu_awesome,
                  { "Debian", debian.menu.Debian_menu.Debian },
                  menu_terminal,
                }
    })
end


mylauncher = awful.widget.launcher({ image = beautiful.awesome_icon,
                                     menu = mymainmenu })

-- Menubar configuration
menubar.utils.terminal = terminal -- Set the terminal for applications that require it
-- }}}

-- Keyboard map indicator and switcher
mykeyboardlayout = awful.widget.keyboardlayout()

-- {{{ Wibar

-- Small helper: wraps a widget in amber square brackets, so each status
-- readout looks like a labeled transport button on a tape deck's
-- faceplate — e.g. [ NET home-wifi ] [ VOL 62% ] [ BATT 74% ].
local function bracket(widget, fg)
    fg = fg or beautiful.fg_minimize
    return wibox.widget {
        {
            markup = '<span foreground="' .. fg .. '">[</span>',
            widget = wibox.widget.textbox,
        },
        widget,
        {
            markup = '<span foreground="' .. fg .. '">]</span>',
            widget = wibox.widget.textbox,
        },
        spacing = 2,
        layout  = wibox.layout.fixed.horizontal,
    }
end

-- Separator / spacer widgets
local sep = wibox.widget.textbox(" ")

-- Clock widget — bright amber "LED" readout, day/date dimmer
mytextclock = wibox.widget {
    format = '<span foreground="' .. beautiful.fg_minimize .. '"> %a %b %d </span>'
        .. '<span foreground="' .. beautiful.fg_focus .. '" font_weight="bold"'
        .. ' font_desc="JetBrains Mono Bold 11" letter_spacing="1536"> %H:%M </span>',
    widget = wibox.widget.textclock,
    refresh = 30,
}

-- Battery widget
local battery_widget = wibox.widget {
    markup = '<span foreground="' .. beautiful.fg_normal .. '"> BATT -- </span>',
    widget = wibox.widget.textbox,
}

local battery_path = nil

local function find_battery_path(callback)
    awful.spawn.easy_async_with_shell(
        "for p in /sys/class/power_supply/*/capacity; do [ -f \"$p\" ] && echo \"$(dirname \"$p\")\" && break; done",
        function(stdout)
            local path = stdout:gsub("%s+", "")
            if path ~= "" then
                battery_path = path
            end
            if callback then callback() end
        end
    )
end

local function update_battery()
    if not battery_path then return end
    awful.spawn.easy_async_with_shell(
        "cat " .. battery_path .. "/capacity 2>/dev/null; cat " .. battery_path .. "/status 2>/dev/null",
        function(stdout)
            local lines = {}
            for line in stdout:gmatch("[^\r\n]+") do
                table.insert(lines, line)
            end
            local capacity = lines[1] or "?"
            local status = lines[2] or "Unknown"
            local label = "BATT"
            local color = beautiful.fg_normal
            local pct = tonumber(capacity) or 0
            if status:match("Charging") then
                label = "CHG"
                color = beautiful.fg_accent
            elseif pct <= 15 then
                color = beautiful.fg_urgent
            elseif pct <= 30 then
                color = beautiful.fg_warn
            end
            battery_widget:set_markup(
                '<span foreground="' .. color .. '"> ' .. label .. ' ' .. capacity .. '% </span>'
            )
        end
    )
end

-- Find battery on startup, then start polling
find_battery_path(update_battery)

gears.timer {
    timeout = 15,
    autostart = true,
    callback = function()
        if battery_path then
            update_battery()
        else
            find_battery_path(update_battery)
        end
    end,
}

-- WiFi widget
local wifi_widget = wibox.widget {
    markup = '<span foreground="' .. beautiful.fg_minimize .. '"> NET -- </span>',
    widget = wibox.widget.textbox,
}

gears.timer {
    timeout = 10,
    call_now = true,
    autostart = true,
    callback = function()
        awful.spawn.easy_async_with_shell(
            "iwgetid -r 2>/dev/null || echo 'N/A'",
            function(stdout)
                local ssid = stdout:gsub("%s+$", "")
                if ssid == "" then ssid = "N/A" end
                local color = ssid == "N/A" and beautiful.fg_urgent or beautiful.fg_accent
                wifi_widget:set_markup(
                    '<span foreground="' .. color .. '"> NET ' .. ssid .. ' </span>'
                )
            end
        )
    end,
}

-- Volume widget
local volume_widget = wibox.widget {
    markup = '<span foreground="' .. beautiful.fg_normal .. '"> VOL --% </span>',
    widget = wibox.widget.textbox,
}

local function update_volume()
    awful.spawn.easy_async_with_shell(
        "amixer sget Master 2>/dev/null | grep -oP '\\[\\K[0-9]+(?=%)' | head -1",
        function(stdout)
            local vol = stdout:gsub("%s+", "")
            if vol == "" then vol = "?" end
            awful.spawn.easy_async_with_shell(
                "amixer sget Master 2>/dev/null | grep -oP '\\[\\K(on|off)(?=\\])' | head -1",
                function(mute_out)
                    local muted = mute_out:gsub("%s+", "") == "off"
                    local label = muted and "MUT" or "VOL"
                    local color = muted and beautiful.fg_urgent or beautiful.fg_normal
                    volume_widget:set_markup(
                        '<span foreground="' .. color .. '"> ' .. label .. ' ' .. vol .. '% </span>'
                    )
                end
            )
        end
    )
end

gears.timer {
    timeout = 5,
    call_now = true,
    autostart = true,
    callback = update_volume,
}

-- Create a wibox for each screen and add it
local taglist_buttons = gears.table.join(
                    awful.button({ }, 1, function(t) t:view_only() end),
                    awful.button({ modkey }, 1, function(t)
                                              if client.focus then
                                                  client.focus:move_to_tag(t)
                                              end
                                          end),
                    awful.button({ }, 3, awful.tag.viewtoggle),
                    awful.button({ modkey }, 3, function(t)
                                              if client.focus then
                                                  client.focus:toggle_tag(t)
                                              end
                                          end),
                    awful.button({ }, 4, function(t) awful.tag.viewnext(t.screen) end),
                    awful.button({ }, 5, function(t) awful.tag.viewprev(t.screen) end)
                )

local tasklist_buttons = gears.table.join(
                     awful.button({ }, 1, function (c)
                                              if c == client.focus then
                                                  c.minimized = true
                                              else
                                                  c:emit_signal(
                                                      "request::activate",
                                                      "tasklist",
                                                      {raise = true}
                                                  )
                                              end
                                          end),
                     awful.button({ }, 3, function()
                                              awful.menu.client_list({ theme = { width = 250 } })
                                          end),
                     awful.button({ }, 4, function ()
                                              awful.client.focus.byidx(1)
                                          end),
                     awful.button({ }, 5, function ()
                                              awful.client.focus.byidx(-1)
                                          end))

local function set_wallpaper(s)
    -- Wallpaper
    if beautiful.wallpaper then
        local wallpaper = beautiful.wallpaper
        -- If wallpaper is a function, call it with the screen
        if type(wallpaper) == "function" then
            wallpaper = wallpaper(s)
        end
        gears.wallpaper.maximized(wallpaper, s, true)
    end
end

-- Re-set wallpaper when a screen's geometry changes (e.g. different resolution)
screen.connect_signal("property::geometry", set_wallpaper)

-- Fix screen rotation (must happen before screen setup)
awful.spawn.with_shell("xrandr --output DSI-2 --rotate right")

awful.screen.connect_for_each_screen(function(s)
    -- Wallpaper
    set_wallpaper(s)

    -- Each screen has its own tag table.
    awful.tag({ "1", "2", "3", "4", "5", "6", "7", "8", "9" }, s, awful.layout.layouts[1])

    -- Create a promptbox for each screen
    s.mypromptbox = awful.widget.prompt()
    -- Create an imagebox widget which will contain an icon indicating which layout we're using.
    -- We need one layoutbox per screen.
    s.mylayoutbox = awful.widget.layoutbox(s)
    s.mylayoutbox:buttons(gears.table.join(
                           awful.button({ }, 1, function () awful.layout.inc( 1) end),
                           awful.button({ }, 3, function () awful.layout.inc(-1) end),
                           awful.button({ }, 4, function () awful.layout.inc( 1) end),
                           awful.button({ }, 5, function () awful.layout.inc(-1) end)))
    -- Create a taglist widget
    s.mytaglist = awful.widget.taglist {
        screen  = s,
        filter  = awful.widget.taglist.filter.all,
        buttons = taglist_buttons
    }

    -- Create a tasklist widget
    s.mytasklist = awful.widget.tasklist {
        screen  = s,
        filter  = awful.widget.tasklist.filter.currenttags,
        buttons = tasklist_buttons
    }

    -- Create the wibox — the deck's faceplate. Height/colors come from theme.lua.
    s.mywibox = awful.wibar({
        position = "top",
        screen   = s,
        height   = beautiful.wibar_height,
        bg       = beautiful.wibar_bg,
        fg       = beautiful.wibar_fg,
    })

    -- Add widgets to the wibox
    s.mywibox:setup {
        layout = wibox.layout.align.horizontal,
        { -- Left widgets
            layout = wibox.layout.fixed.horizontal,
            s.mytaglist,
            sep,
            s.mypromptbox,
        },
        s.mytasklist, -- Middle widget
        { -- Right widgets: each status readout bracketed like a transport button
            layout = wibox.layout.fixed.horizontal,
            spacing = 6,
            bracket(wifi_widget, beautiful.fg_minimize),
            bracket(volume_widget, beautiful.fg_minimize),
            bracket(battery_widget, beautiful.fg_minimize),
            s == screen.primary and wibox.widget.systray() or nil,
            bracket(mytextclock, beautiful.fg_focus),
            sep,
            s.mylayoutbox,
        },
    }
end)
-- }}}

-- {{{ Mouse bindings
root.buttons(gears.table.join(
    awful.button({ }, 3, function () mymainmenu:toggle() end),
    awful.button({ }, 4, awful.tag.viewnext),
    awful.button({ }, 5, awful.tag.viewprev)
))
-- }}}

-- {{{ Key bindings
globalkeys = gears.table.join(
    awful.key({ modkey,           }, "s",      hotkeys_popup.show_help,
              {description="show help", group="awesome"}),
    awful.key({ modkey,           }, "Left",   awful.tag.viewprev,
              {description = "view previous", group = "tag"}),
    awful.key({ modkey,           }, "Right",  awful.tag.viewnext,
              {description = "view next", group = "tag"}),
    awful.key({ modkey,           }, "Escape", awful.tag.history.restore,
              {description = "go back", group = "tag"}),

    awful.key({ modkey,           }, "j",
        function ()
            awful.client.focus.byidx( 1)
        end,
        {description = "focus next by index", group = "client"}
    ),
    awful.key({ modkey,           }, "k",
        function ()
            awful.client.focus.byidx(-1)
        end,
        {description = "focus previous by index", group = "client"}
    ),
    awful.key({ modkey,           }, "w", function () mymainmenu:show() end,
              {description = "show main menu", group = "awesome"}),

    -- Layout manipulation
    awful.key({ modkey, "Shift"   }, "j", function () awful.client.swap.byidx(  1)    end,
              {description = "swap with next client by index", group = "client"}),
    awful.key({ modkey, "Shift"   }, "k", function () awful.client.swap.byidx( -1)    end,
              {description = "swap with previous client by index", group = "client"}),
    awful.key({ modkey, "Control" }, "j", function () awful.screen.focus_relative( 1) end,
              {description = "focus the next screen", group = "screen"}),
    awful.key({ modkey, "Control" }, "k", function () awful.screen.focus_relative(-1) end,
              {description = "focus the previous screen", group = "screen"}),
    awful.key({ modkey,           }, "u", awful.client.urgent.jumpto,
              {description = "jump to urgent client", group = "client"}),
    awful.key({ modkey,           }, "Tab",
        function ()
            awful.client.focus.history.previous()
            if client.focus then
                client.focus:raise()
            end
        end,
        {description = "go back", group = "client"}),

    -- Standard program
    awful.key({ modkey,           }, "Return", function () awful.spawn(terminal) end,
              {description = "open a terminal", group = "launcher"}),
    awful.key({ modkey, "Control" }, "r", awesome.restart,
              {description = "reload awesome", group = "awesome"}),
    awful.key({ modkey, "Shift"   }, "q", awesome.quit,
              {description = "quit awesome", group = "awesome"}),

    awful.key({ modkey,           }, "l",     function () awful.tag.incmwfact( 0.05)          end,
              {description = "increase master width factor", group = "layout"}),
    awful.key({ modkey,           }, "h",     function () awful.tag.incmwfact(-0.05)          end,
              {description = "decrease master width factor", group = "layout"}),
    awful.key({ modkey, "Shift"   }, "h",     function () awful.tag.incnmaster( 1, nil, true) end,
              {description = "increase the number of master clients", group = "layout"}),
    awful.key({ modkey, "Shift"   }, "l",     function () awful.tag.incnmaster(-1, nil, true) end,
              {description = "decrease the number of master clients", group = "layout"}),
    awful.key({ modkey, "Control" }, "h",     function () awful.tag.incncol( 1, nil, true)    end,
              {description = "increase the number of columns", group = "layout"}),
    awful.key({ modkey, "Control" }, "l",     function () awful.tag.incncol(-1, nil, true)    end,
              {description = "decrease the number of columns", group = "layout"}),
    awful.key({ modkey,           }, "space", function () awful.layout.inc( 1)                end,
              {description = "select next", group = "layout"}),
    awful.key({ modkey, "Shift"   }, "space", function () awful.layout.inc(-1)                end,
              {description = "select previous", group = "layout"}),

    awful.key({ modkey, "Control" }, "n",
              function ()
                  local c = awful.client.restore()
                  -- Focus restored client
                  if c then
                    c:emit_signal(
                        "request::activate", "key.unminimize", {raise = true}
                    )
                  end
              end,
              {description = "restore minimized", group = "client"}),

    -- Rofi launchers
    awful.key({ modkey },            "r",     function () awful.spawn("rofi -show drun") end,
              {description = "rofi app launcher", group = "launcher"}),
    awful.key({ modkey },            "p",     function () awful.spawn("rofi -show run") end,
              {description = "rofi run prompt", group = "launcher"}),
    awful.key({ modkey, "Shift" },   "w",     function () awful.spawn("rofi -show window") end,
              {description = "rofi window switcher", group = "launcher"}),

    awful.key({ modkey }, "x",
              function ()
                  awful.prompt.run {
                    prompt       = "Run Lua code: ",
                    textbox      = awful.screen.focused().mypromptbox.widget,
                    exe_callback = awful.util.eval,
                    history_path = awful.util.get_cache_dir() .. "/history_eval"
                  }
              end,
              {description = "lua execute prompt", group = "awesome"})
)

clientkeys = gears.table.join(
    awful.key({ modkey,           }, "f",
        function (c)
            c.fullscreen = not c.fullscreen
            c:raise()
        end,
        {description = "toggle fullscreen", group = "client"}),
    awful.key({ modkey, "Shift"   }, "c",      function (c) c:kill()                         end,
              {description = "close", group = "client"}),
    awful.key({ modkey, "Control" }, "space",  awful.client.floating.toggle                     ,
              {description = "toggle floating", group = "client"}),
    awful.key({ modkey, "Control" }, "Return", function (c) c:swap(awful.client.getmaster()) end,
              {description = "move to master", group = "client"}),
    awful.key({ modkey,           }, "o",      function (c) c:move_to_screen()               end,
              {description = "move to screen", group = "client"}),
    awful.key({ modkey,           }, "t",      function (c) c.ontop = not c.ontop            end,
              {description = "toggle keep on top", group = "client"}),
    awful.key({ modkey,           }, "n",
        function (c)
            -- The client currently has the input focus, so it cannot be
            -- minimized, since minimized clients can't have the focus.
            c.minimized = true
        end ,
        {description = "minimize", group = "client"}),
    awful.key({ modkey,           }, "m",
        function (c)
            c.maximized = not c.maximized
            c:raise()
        end ,
        {description = "(un)maximize", group = "client"}),
    awful.key({ modkey, "Control" }, "m",
        function (c)
            c.maximized_vertical = not c.maximized_vertical
            c:raise()
        end ,
        {description = "(un)maximize vertically", group = "client"}),
    awful.key({ modkey, "Shift"   }, "m",
        function (c)
            c.maximized_horizontal = not c.maximized_horizontal
            c:raise()
        end ,
        {description = "(un)maximize horizontally", group = "client"})
)

-- Bind all key numbers to tags.
-- Be careful: we use keycodes to make it work on any keyboard layout.
-- This should map on the top row of your keyboard, usually 1 to 9.
for i = 1, 9 do
    globalkeys = gears.table.join(globalkeys,
        -- View tag only.
        awful.key({ modkey }, "#" .. i + 9,
                  function ()
                        local screen = awful.screen.focused()
                        local tag = screen.tags[i]
                        if tag then
                           tag:view_only()
                        end
                  end,
                  {description = "view tag #"..i, group = "tag"}),
        -- Toggle tag display.
        awful.key({ modkey, "Control" }, "#" .. i + 9,
                  function ()
                      local screen = awful.screen.focused()
                      local tag = screen.tags[i]
                      if tag then
                         awful.tag.viewtoggle(tag)
                      end
                  end,
                  {description = "toggle tag #" .. i, group = "tag"}),
        -- Move client to tag.
        awful.key({ modkey, "Shift" }, "#" .. i + 9,
                  function ()
                      if client.focus then
                          local tag = client.focus.screen.tags[i]
                          if tag then
                              client.focus:move_to_tag(tag)
                          end
                     end
                  end,
                  {description = "move focused client to tag #"..i, group = "tag"}),
        -- Toggle tag on focused client.
        awful.key({ modkey, "Control", "Shift" }, "#" .. i + 9,
                  function ()
                      if client.focus then
                          local tag = client.focus.screen.tags[i]
                          if tag then
                              client.focus:toggle_tag(tag)
                          end
                      end
                  end,
                  {description = "toggle focused client on tag #" .. i, group = "tag"})
    )
end

clientbuttons = gears.table.join(
    awful.button({ }, 1, function (c)
        c:emit_signal("request::activate", "mouse_click", {raise = true})
    end),
    awful.button({ modkey }, 1, function (c)
        c:emit_signal("request::activate", "mouse_click", {raise = true})
        awful.mouse.client.move(c)
    end),
    awful.button({ modkey }, 3, function (c)
        c:emit_signal("request::activate", "mouse_click", {raise = true})
        awful.mouse.client.resize(c)
    end)
)

-- Set keys
root.keys(globalkeys)
-- }}}

-- {{{ Rules
-- Rules to apply to new clients (through the "manage" signal).
awful.rules.rules = {
    -- All clients will match this rule.
    { rule = { },
      properties = { border_width = beautiful.border_width,
                     border_color = beautiful.border_normal,
                     focus = awful.client.focus.filter,
                     raise = true,
                     keys = clientkeys,
                     buttons = clientbuttons,
                     screen = awful.screen.preferred,
                     placement = awful.placement.no_overlap+awful.placement.no_offscreen
     }
    },

    -- Floating clients.
    { rule_any = {
        instance = {
          "DTA",  -- Firefox addon DownThemAll.
          "copyq",  -- Includes session name in class.
          "pinentry",
        },
        class = {
          "Arandr",
          "Blueman-manager",
          "Gpick",
          "Kruler",
          "MessageWin",  -- kalarm.
          "Sxiv",
          "Tor Browser", -- Needs a fixed window size to avoid fingerprinting by screen size.
          "Wpa_gui",
          "veromix",
          "xtightvncviewer"},

        -- Note that the name property shown in xprop might be set slightly after creation of the client
        -- and the name shown there might not match defined rules here.
        name = {
          "Event Tester",  -- xev.
        },
        role = {
          "AlarmWindow",  -- Thunderbird's calendar.
          "ConfigManager",  -- Thunderbird's about:config.
          "pop-up",       -- e.g. Google Chrome's (detached) Developer Tools.
        }
      }, properties = { floating = true }},

    -- Add titlebars to normal clients and dialogs
    { rule_any = {type = { "normal", "dialog" }
      }, properties = { titlebars_enabled = true }
    },

    -- Set Firefox to always map on the tag named "2" on screen 1.
    -- { rule = { class = "Firefox" },
    --   properties = { screen = 1, tag = "2" } },
}
-- }}}

-- {{{ Signals
-- Signal function to execute when a new client appears.
client.connect_signal("manage", function (c)
    -- Set the windows at the slave,
    -- i.e. put it at the end of others instead of setting it master.
    -- if not awesome.startup then awful.client.setslave(c) end

    if awesome.startup
      and not c.size_hints.user_position
      and not c.size_hints.program_position then
        -- Prevent clients from being unreachable after screen count changes.
        awful.placement.no_offscreen(c)
    end
end)

-- Add a titlebar if titlebars_enabled is set to true in the rules.
--
-- Custom "tape deck" titlebar: no stock PNG buttons. Controls are text
-- glyphs that light up amber/red on hover, echoing the [ bracketed ]
-- readouts on the wibar. A small LED dot sits left of the title and
-- glows when the client has focus.
client.connect_signal("request::titlebars", function(c)
    local move_resize_buttons = gears.table.join(
        awful.button({ }, 1, function()
            c:emit_signal("request::activate", "titlebar", {raise = true})
            awful.mouse.client.move(c)
        end),
        awful.button({ }, 3, function()
            c:emit_signal("request::activate", "titlebar", {raise = true})
            awful.mouse.client.resize(c)
        end)
    )

    -- One glyph button: dim by default, brightens to `hover_fg` on
    -- mouse-over, runs `fn` on left-click.
    local function control_button(glyph, hover_fg, fn)
        local label = wibox.widget.textbox()
        local idle_fg = beautiful.fg_minimize

        local function paint(fg)
            label:set_markup('<span font_desc="JetBrains Mono 10" foreground="'
                .. fg .. '">' .. glyph .. '</span>')
        end
        paint(idle_fg)

        local btn = wibox.widget {
            {
                label,
                left = 7, right = 7,
                widget = wibox.container.margin,
            },
            widget = wibox.container.background,
        }

        btn:connect_signal("mouse::enter", function() paint(hover_fg) end)
        btn:connect_signal("mouse::leave", function() paint(idle_fg) end)
        btn:buttons(gears.table.join(awful.button({ }, 1, fn)))
        return btn
    end

    local close_btn = control_button("×", beautiful.fg_urgent, function() c:kill() end)
    local max_btn   = control_button("▢", beautiful.fg_accent, function()
        c.maximized = not c.maximized
        c:raise()
    end)
    local min_btn   = control_button("–", beautiful.fg_focus, function()
        c.minimized = true
    end)

    -- Focus LED: lit amber when this client has focus, dim otherwise.
    -- Uses the same focus/unfocus client signals already relied on below
    -- for border_color, rather than an unverified client property.
    local led = wibox.widget {
        {
            id     = "dot",
            shape  = gears.shape.circle,
            bg     = (client.focus == c) and beautiful.fg_focus or beautiful.fg_minimize,
            widget = wibox.container.background,
        },
        forced_width  = dpi(7),
        forced_height = dpi(7),
        left = dpi(9), right = dpi(6), top = dpi(9), bottom = dpi(9),
        widget = wibox.container.margin,
    }
    local function refresh_led()
        led:get_children_by_id("dot")[1].bg =
            (client.focus == c) and beautiful.fg_focus or beautiful.fg_minimize
    end
    c:connect_signal("focus", refresh_led)
    c:connect_signal("unfocus", refresh_led)

    awful.titlebar(c, { size = beautiful.titlebar_size }) : setup {
        { -- Left: focus LED
            led,
            buttons = move_resize_buttons,
            layout  = wibox.layout.fixed.horizontal,
        },
        { -- Middle: title, drag-to-move/resize like before
            {
                align  = "center",
                widget = awful.titlebar.widget.titlewidget(c),
            },
            buttons = move_resize_buttons,
            layout  = wibox.layout.flex.horizontal,
        },
        { -- Right: minimize / maximize / close glyphs
            min_btn,
            max_btn,
            close_btn,
            layout = wibox.layout.fixed.horizontal,
        },
        layout = wibox.layout.align.horizontal,
    }
end)

-- Enable sloppy focus, so that focus follows mouse.
client.connect_signal("mouse::enter", function(c)
    c:emit_signal("request::activate", "mouse_enter", {raise = false})
end)

client.connect_signal("focus", function(c) c.border_color = beautiful.border_focus end)
client.connect_signal("unfocus", function(c) c.border_color = beautiful.border_normal end)
-- }}}