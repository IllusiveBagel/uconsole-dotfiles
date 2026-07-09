---------------------------
-- "Tape Deck 01"        --
-- Cassette-futurism     --
-- theme for Awesome WM  --
---------------------------

local theme_assets = require("beautiful.theme_assets")
local xresources = require("beautiful.xresources")
local dpi = xresources.apply_dpi
local gears = require("gears")
local gfs = require("gears.filesystem")

-- NOTE: matches the path used in rc.lua's beautiful.init() call —
-- ~/.config/awesome/themes/cassette/
local themes_path = gfs.get_configuration_dir() .. "themes/cassette/"

local theme = {}

-- ── Palette ─────────────────────────────────────────────
-- bg (near-black warm)      : #1c1712
-- bg alt (deck panel)       : #241a10
-- fg (amber phosphor)       : #ffb45c
-- fg bright (hot amber)     : #ff9d3f
-- accent (VU-meter teal)    : #7ee0c4
-- urgent (tape-warning red) : #e5502f
-- muted (plastic beige)     : #c9bfa8
-- border idle               : #3a2e20

theme.font          = "JetBrains Mono 10"
theme.font_bold     = "JetBrains Mono Bold 10"

theme.bg_normal     = "#1c1712"
theme.bg_focus      = "#2a2018"
theme.bg_urgent     = "#4a1b0c"
theme.bg_minimize   = "#171009"
theme.bg_systray    = theme.bg_normal

theme.fg_normal     = "#ffb45c"
theme.fg_focus      = "#ff9d3f"
theme.fg_urgent     = "#e5502f"
theme.fg_minimize   = "#8a6a2f"

-- Extra named accents (not part of stock beautiful vars, but handy
-- to share between theme.lua and rc.lua so widget colors stay in sync
-- with the palette instead of hardcoding hex in rc.lua).
theme.fg_accent     = "#7ee0c4" -- VU-meter teal (wifi connected, charging)
theme.fg_warn       = "#ef8a2c" -- amber warning (mid battery, etc.)

theme.border_width  = dpi(2)
theme.border_normal = "#3a2e20"
theme.border_focus  = "#ff9d3f"
theme.border_marked = "#7ee0c4"

-- gaps between clients (needs awful.util or lain if you want smart gaps;
-- plain awesome respects useless_gap directly)
theme.useless_gap   = dpi(4)

-- ── Menu ────────────────────────────────────────────────
theme.menu_height        = dpi(24)
theme.menu_width         = dpi(160)
theme.menu_bg_normal     = "#1c1712"
theme.menu_bg_focus      = "#2a2018"
theme.menu_fg_normal     = "#ffb45c"
theme.menu_fg_focus      = "#ff9d3f"
theme.menu_border_color  = "#ff9d3f"
theme.menu_border_width  = dpi(1)

-- ── Titlebars ───────────────────────────────────────────
theme.titlebar_bg_focus  = "#241a10"
theme.titlebar_bg_normal = "#171009"
theme.titlebar_fg_focus  = "#ff9d3f"
theme.titlebar_fg_normal = "#8a6a2f"
theme.titlebar_size      = dpi(24)

-- ── Wibar (top panel — the "deck faceplate") ───────────
theme.wibar_height = dpi(22)
theme.wibar_bg      = "#0d0906"
theme.wibar_fg       = "#e8ddc7"

-- taglist: selected tag reads like a pressed transport button
theme.taglist_bg_focus     = "#ef8a2c"
theme.taglist_fg_focus     = "#0d0906"
theme.taglist_bg_occupied  = "#171009"
theme.taglist_fg_occupied  = "#c98f4f"
theme.taglist_bg_empty     = "#0d0906"
theme.taglist_fg_empty     = "#5a4c33"
theme.taglist_bg_urgent    = "#e5502f"
theme.taglist_fg_urgent    = "#0d0906"
theme.taglist_font         = "JetBrains Mono Bold 10"
theme.taglist_spacing      = dpi(4)

-- tasklist
theme.tasklist_bg_normal   = "#0d0906"
theme.tasklist_fg_normal   = "#7a5a35"
theme.tasklist_bg_focus    = "#241a10"
theme.tasklist_fg_focus    = "#ff9d3f"
theme.tasklist_bg_urgent   = "#4a1b0c"
theme.tasklist_fg_urgent   = "#ff9d3f"
theme.tasklist_disable_icon = false

-- ── Notifications (naughty) ─────────────────────────────
theme.notification_font         = "JetBrains Mono 10"
theme.notification_bg           = "#171009"
theme.notification_fg           = "#ffb45c"
theme.notification_border_color = "#ff9d3f"
theme.notification_border_width = dpi(2)
theme.notification_shape        = function(cr, w, h) gears.shape.rectangle(cr, w, h) end

-- ── Hotkeys popup ────────────────────────────────────────
theme.hotkeys_bg           = "#171009"
theme.hotkeys_fg           = "#ffb45c"
theme.hotkeys_border_color = "#ff9d3f"
theme.hotkeys_border_width = dpi(2)
theme.hotkeys_modifiers_fg = "#7ee0c4"
theme.hotkeys_font         = "JetBrains Mono 10"
theme.hotkeys_description_font = "JetBrains Mono 9"

-- ── Layout icons ─────────────────────────────────────────
-- These paths match the stock awesome default theme's layout of
-- /usr/share/awesome/themes/default/layouts/*.png — copy that folder
-- (not "icons/layouts") into themes_path, see install notes.
theme.layout_fairh      = themes_path .. "layouts/fairhw.png"
theme.layout_fairv      = themes_path .. "layouts/fairvw.png"
theme.layout_floating   = themes_path .. "layouts/floatingw.png"
theme.layout_magnifier  = themes_path .. "layouts/magnifierw.png"
theme.layout_max        = themes_path .. "layouts/maxw.png"
theme.layout_fullscreen = themes_path .. "layouts/fullscreenw.png"
theme.layout_tilebottom = themes_path .. "layouts/tilebottomw.png"
theme.layout_tileleft   = themes_path .. "layouts/tileleftw.png"
theme.layout_tile       = themes_path .. "layouts/tilew.png"
theme.layout_tiletop    = themes_path .. "layouts/tiletopw.png"
theme.layout_spiral     = themes_path .. "layouts/spiralw.png"
theme.layout_dwindle    = themes_path .. "layouts/dwindlew.png"
theme.layout_cornernw   = themes_path .. "layouts/cornernww.png"
theme.layout_cornerne   = themes_path .. "layouts/cornernew.png"
theme.layout_cornersw   = themes_path .. "layouts/cornersww.png"
theme.layout_cornerse   = themes_path .. "layouts/cornersew.png"

-- Generate taglist square icons in the "cassette hub" style (small
-- filled/hollow circles rather than default squares) so tags look like
-- little reels.
theme.taglist_squares_sel   = theme_assets.taglist_squares_sel(
    theme.wibar_height / 4, "#ff9d3f"
)
theme.taglist_squares_unsel = theme_assets.taglist_squares_unsel(
    theme.wibar_height / 4, "#5a4c33"
)

-- ── Icon theme (for rofi/awesome app icons, optional) ────
theme.icon_theme = nil

-- ── Wallpaper ────────────────────────────────────────────
-- Point this at wallpaper.png once you've generated/placed one
-- (see the cassette-tape wallpaper we'll build next).
theme.wallpaper = themes_path .. "wallpaper.jpeg"

-- ── Titlebar ──────────────────────────────────────────────
-- No stock PNG button icons here — rc.lua builds a custom titlebar out
-- of text glyphs styled to match the wibar's bracket buttons, so there
-- are no titlebar/*.png files to install for this theme.

-- ── Recolor stock icons in-palette ───────────────────────
-- Real function, verified against
-- /usr/share/awesome/lib/beautiful/theme_assets.lua — recolors every
-- theme.layout_* icon in place with one color.
theme = theme_assets.recolor_layout(theme, theme.fg_normal)

return theme