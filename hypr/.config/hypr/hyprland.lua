-- Translated from hyprland.conf for Hyprland 0.55+ Lua configs.
-- API reference: https://github.com/hyprwm/Hyprland/blob/main/example/hyprland.lua
-- Wiki:          https://wiki.hypr.land/Configuring/Start/
--
-- The old hyprland.conf is kept on disk as a fallback / reference; Hyprland
-- prefers this file when present. Delete this file to revert.

------------------
---- MONITORS ----
------------------

hl.monitor({ output = "DP-1",     mode = "3440x1440@160", position = "0x0",  scale = 1 })
hl.monitor({ output = "HDMI-A-1", mode = "2560x1080@75",  position = "3440x-560", scale = 1, transform = 1 })

-- TODO(verify): monitor/default/persistent field names on workspace_rule.
-- Hyprlang used `workspace = 1, monitor:DP-1, default:true`; this is my best
-- mapping but the example config doesn't cover this exact case.
for i = 1, 9 do
    hl.workspace_rule({ workspace = i, monitor = "DP-1", default = (i == 1) or nil })
end
hl.workspace_rule({ workspace = 10, monitor = "HDMI-A-1", persistent = true, default = true })


---------------------
---- MY PROGRAMS ----
---------------------

local terminal    = "kitty"
local fileManager = "nemo"
local menu        = "rofi -show drun"
local browser     = "brave"
local calculator  = "kitty --class float-calc -e qalc"


-------------------------------
---- ENVIRONMENT VARIABLES ----
-------------------------------

hl.env("XCURSOR_THEME",    "Bibata-Modern-Ice")
hl.env("XCURSOR_SIZE",     "24")
hl.env("HYPRCURSOR_THEME", "Bibata-Modern-Ice")
hl.env("HYPRCURSOR_SIZE",  "24")


-----------------------
---- LOOK AND FEEL ----
-----------------------

hl.config({
    general = {
        gaps_in     = 5,
        gaps_out    = 5,
        border_size = 1,

        col = {
            active_border   = { colors = {"rgba(89b4faee)", "rgba(a6e3a1ee)"}, angle = 45 },
            inactive_border = "rgba(45475aff)",
        },

        resize_on_border = false,
        allow_tearing    = false,
        layout           = "dwindle",
    },

    decoration = {
        rounding       = 10,
        rounding_power = 2,

        active_opacity   = 1.0,
        inactive_opacity = 0.95,

        blur = {
            enabled  = true,
            size     = 3,
            passes   = 3,
            vibrancy = 0.1696,
        },
    },

    animations = {
        enabled = true,
    },

    master = {
        new_status = "master",
    },

    dwindle = {
        preserve_split = true,
    },

    misc = {
        force_default_wallpaper  = 0,
        disable_hyprland_logo    = true,
        disable_splash_rendering = true,
    },

    cursor = {
        no_hardware_cursors = true,
    },
})

-- Bezier curves
hl.curve("easeOutQuint",   { type = "bezier", points = { {0.23, 1},    {0.32, 1}    } })
hl.curve("easeInOutCubic", { type = "bezier", points = { {0.65, 0.05}, {0.36, 1}    } })
hl.curve("linear",         { type = "bezier", points = { {0, 0},       {1, 1}       } })
hl.curve("almostLinear",   { type = "bezier", points = { {0.5, 0.5},   {0.75, 1.0}  } })
hl.curve("quick",          { type = "bezier", points = { {0.15, 0},    {0.1, 1}     } })

hl.animation({ leaf = "global",        enabled = true, speed = 10,   bezier = "default" })
hl.animation({ leaf = "border",        enabled = true, speed = 5.39, bezier = "easeOutQuint" })
hl.animation({ leaf = "windows",       enabled = true, speed = 4.79, bezier = "easeOutQuint" })
hl.animation({ leaf = "windowsIn",     enabled = true, speed = 4.1,  bezier = "easeOutQuint", style = "popin 87%" })
hl.animation({ leaf = "windowsOut",    enabled = true, speed = 1.49, bezier = "linear",       style = "popin 87%" })
hl.animation({ leaf = "fadeIn",        enabled = true, speed = 1.73, bezier = "almostLinear" })
hl.animation({ leaf = "fadeOut",       enabled = true, speed = 1.46, bezier = "almostLinear" })
hl.animation({ leaf = "fade",          enabled = true, speed = 3.03, bezier = "quick" })
hl.animation({ leaf = "layers",        enabled = true, speed = 3.81, bezier = "easeOutQuint" })
hl.animation({ leaf = "layersIn",      enabled = true, speed = 4,    bezier = "easeOutQuint", style = "fade" })
hl.animation({ leaf = "layersOut",     enabled = true, speed = 1.5,  bezier = "linear",       style = "fade" })
hl.animation({ leaf = "fadeLayersIn",  enabled = true, speed = 1.79, bezier = "almostLinear" })
hl.animation({ leaf = "fadeLayersOut", enabled = true, speed = 1.39, bezier = "almostLinear" })
hl.animation({ leaf = "workspaces",    enabled = true, speed = 1.94, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "workspacesIn",  enabled = true, speed = 1.21, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "workspacesOut", enabled = true, speed = 1.94, bezier = "almostLinear", style = "fade" })


---------------
---- INPUT ----
---------------

hl.config({
    input = {
        kb_layout          = "us,us",
        kb_variant         = "basic,intl",
        kb_options         = "grp:win_space_toggle",
        numlock_by_default = true,
        mouse_refocus      = false,
        follow_mouse       = 1,
        sensitivity        = 0,

        touchpad = {
            natural_scroll = false,
            scroll_factor  = 1.0,
        },
    },
})

hl.device({
    name        = "epic-mouse-v1",
    sensitivity = -0.5,
})


---------------------
---- KEYBINDINGS ----
---------------------

local mainMod = "SUPER"

hl.bind(mainMod .. " + RETURN",        hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + Q",             hl.dsp.window.close())
hl.bind(mainMod .. " + E",             hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + V",             hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + CTRL + RETURN", hl.dsp.exec_cmd(menu))
hl.bind(mainMod .. " + C",             hl.dsp.exec_cmd(calculator))
hl.bind(mainMod .. " + P",             hl.dsp.window.pseudo())
hl.bind(mainMod .. " + CTRL + J",      hl.dsp.layout("togglesplit"))
hl.bind(mainMod .. " + CTRL + K",      hl.dsp.layout("swapsplit"))    -- TODO(verify): swapsplit not in example
-- Fake fullscreen (Hyprland renders fullscreen, client thinks it isn't).
hl.bind(mainMod .. " + F",             hl.dsp.window.fullscreen_state({ internal = 2, client = 0, action = "toggle" }))

-- Browser
hl.bind(mainMod .. " + B",             hl.dsp.exec_cmd(browser))

-- Toggle fcitx5 layout
hl.bind(mainMod .. " + CTRL + L",      hl.dsp.exec_cmd("fcitx5-remote -t"))

-- Move focus
hl.bind(mainMod .. " + left",          hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + right",         hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + up",            hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + down",          hl.dsp.focus({ direction = "down" }))
hl.bind(mainMod .. " + H",             hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + L",             hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + K",             hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + J",             hl.dsp.focus({ direction = "down" }))

-- Lock
hl.bind(mainMod .. " + Escape",        hl.dsp.exec_cmd("hyprlock"))

-- Logout / power menu
hl.bind(mainMod .. " + CTRL + Q",      hl.dsp.exec_cmd(os.getenv("HOME") .. "/.config/rofi/scripts/powermenu.sh"))

-- Workspaces 1–9 and move-to-workspace SHIFT + 1–9
for i = 1, 9 do
    hl.bind(mainMod .. " + " .. i,         hl.dsp.focus({ workspace = i }))
    hl.bind(mainMod .. " + SHIFT + " .. i, hl.dsp.window.move({ workspace = i }))
end

-- Move active window between monitors
-- TODO(verify): monitor target syntax for window.move
hl.bind(mainMod .. " + 0",             hl.dsp.window.move({ monitor = "+1" }))

-- Special workspace (scratchpad)
hl.bind(mainMod .. " + S",             hl.dsp.workspace.toggle_special("magic"))
hl.bind(mainMod .. " + SHIFT + S",     hl.dsp.window.move({ workspace = "special:magic" }))

-- Scroll-through workspaces
hl.bind(mainMod .. " + mouse_down",    hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up",      hl.dsp.focus({ workspace = "e-1" }))

-- Wallpaper
hl.bind(mainMod .. " + W",             hl.dsp.exec_cmd(os.getenv("HOME") .. "/.config/hypr/hyprpaper.bash"))

-- Drag/resize with mouse
hl.bind(mainMod .. " + mouse:272",     hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273",     hl.dsp.window.resize(), { mouse = true })

-- Screenshot
hl.bind("Print",                       hl.dsp.exec_cmd("hyprshot -m region --raw | satty --filename - --copy-command wl-copy"))

-- Audio / brightness (locked + repeating)
hl.bind("XF86AudioRaiseVolume",  hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume",  hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),      { locked = true, repeating = true })
hl.bind("XF86AudioMute",         hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),     { locked = true, repeating = true })
hl.bind("XF86AudioMicMute",      hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),   { locked = true, repeating = true })
hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd("brightnessctl s 10%+"),                           { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl s 10%-"),                           { locked = true, repeating = true })

-- Media keys (locked, no repeat)
hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("playerctl next"),       { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("playerctl previous"),   { locked = true })


--------------------------------
---- WINDOWS AND WORKSPACES ----
--------------------------------

-- Ignore maximize requests
hl.window_rule({
    name           = "suppress-maximize",
    match          = { class = ".*" },
    suppress_event = "maximize",
})

-- Fix XWayland drag issues
hl.window_rule({
    name  = "fix-xwayland-drags",
    match = {
        class      = "^$",
        title      = "^$",
        xwayland   = true,
        float      = true,
        fullscreen = false,
        pin        = false,
    },
    no_focus = true,
})

-- General floating helper (kitty --class float-general etc.)
-- TODO(verify): exact field names for size/center on window_rule
hl.window_rule({
    name   = "float-general",
    match  = { class = "float-general" },
    float  = true,
    size   = "1050 800",
    center = true,
})

-- Floating calculator
hl.window_rule({
    name   = "float-calc",
    match  = { class = "float-calc" },
    float  = true,
    size   = "500 550",
    center = true,
})

-- Satty screenshot: float, pin to monitor 1
-- TODO(verify): submap API not in example config. Hyprlang had:
--   submap = satty / bind = , escape, killactive / bind = , escape, submap, reset / submap = reset
-- Skipping submap for now; the float rules below still apply.
hl.window_rule({
    name    = "satty-float",
    match   = { title = "satty" },
    float   = true,
    size    = "1000 700",
    monitor = 1,
})

-- TODO(verify): blur field on layer_rule
hl.layer_rule({
    name  = "rofi-blur",
    match = { namespace = "rofi" },
    blur  = true,
})


-------------------
---- AUTOSTART ----
-------------------

hl.on("hyprland.start", function()
    hl.exec_cmd("fcitx5 -d --replace")
    hl.exec_cmd("waybar")
    hl.exec_cmd("hyprctl setcursor Bibata-Modern-Ice 24")
    hl.exec_cmd("hyprpaper")
    hl.exec_cmd(os.getenv("HOME") .. "/.config/hypr/hyprpaper.bash")
    hl.exec_cmd("mako")
    hl.exec_cmd(os.getenv("HOME") .. "/.config/waybar/scripts/mako-tracker.sh")
    hl.exec_cmd("hyprctl dispatch workspace 1")
end)
