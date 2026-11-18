-- ╭──────────────────────────────────────────────────────────────────╮
-- │  orchard — macOS 26 (Tahoe) on Hyprland 0.57                      │
-- │  ⌘ = Super. Windows float like on a Mac; ⌘-shortcuts are routed   │
-- │  to each app as the Ctrl / Ctrl+Shift chord it understands.        │
-- ╰──────────────────────────────────────────────────────────────────╯
local HOME = os.getenv("HOME")
local O    = HOME .. "/.config/orchard"
local BIN  = O .. "/bin/"

hl.monitor({ output = "", mode = "preferred", position = "auto", scale = "auto" })

hl.env("XCURSOR_THEME", "MacTahoe-cursors")
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1")
hl.env("GDK_BACKEND", "wayland,x11,*")
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")
hl.env("GTK_CSD", "1")                 -- GTK apps draw their own traffic lights
hl.env("NO_AT_BRIDGE", "1")
hl.env("GTK_A11Y", "none")

hl.config({
    general = {
        gaps_in = 6, gaps_out = 8,
        border_size = 1,
        col = { active_border = "rgba(ffffff22)", inactive_border = "rgba(ffffff12)" },
        resize_on_border = true,
        extend_border_grab_area = 12,
        hover_icon_on_border = true,
        layout = "dwindle",
    },
    decoration = {
        rounding = 14,
        rounding_power = 4.0,           -- continuous (squircle) corners like Apple's
        active_opacity = 1.0, inactive_opacity = 1.0, fullscreen_opacity = 1.0,
        dim_inactive = false,
        shadow = {
            enabled = true, range = 38, render_power = 3, sharp = false,
            color = "rgba(00000070)", color_inactive = "rgba(00000040)",
            offset = "0 12", scale = 1.0,
        },
        blur = {
            enabled = true, size = 9, passes = 3,
            new_optimizations = true, xray = false,
            noise = 0.012, contrast = 1.0, brightness = 1.0,
            vibrancy = 0.22, vibrancy_darkness = 0.1,
            popups = true, special = false,
        },
        glow = { enabled = false },
        motion_blur = { enabled = false },
        wobble = { enabled = false },
    },
    animations = { enabled = true },
    dwindle = { preserve_split = true },
    misc = {
        disable_hyprland_logo = true,
        disable_splash_rendering = true,
        force_default_wallpaper = 0,
        background_color = "rgba(000000ff)",
        render_unfocused_fps = 15,
        enable_swallow = false,
        focus_on_activate = true,
        key_press_enables_dpms = true,
        mouse_move_enables_dpms = true,
        middle_click_paste = false,
        animate_manual_resizes = false,
        animate_mouse_windowdragging = false,
        on_focus_under_fullscreen = 2,
    },
    xwayland = { force_zero_scaling = true },
    render = { direct_scanout = 2, cm_enabled = false },
    input = {
        kb_layout = "us",
        repeat_rate = 35, repeat_delay = 280,       -- macOS default key repeat feel
        follow_mouse = 2,                            -- click to focus, scroll under pointer
        float_switch_override_focus = 0,
        accel_profile = "adaptive",
        touchpad = {
            natural_scroll = true, tap_to_click = true, disable_while_typing = true,
            clickfinger_behavior = true,             -- two-finger click = right click
            scroll_factor = 0.55, drag_lock = 0,
        },
    },
    binds = { workspace_back_and_forth = false, allow_workspace_cycles = true },
    cursor = { hide_on_key_press = true, inactive_timeout = 0, no_warps = true },
    gestures = { workspace_swipe_distance = 520, workspace_swipe_cancel_ratio = 0.25, workspace_swipe_forever = false },
})

---------------------------------------------------------------- motion
-- Apple's UI springs settle without overshoot; these curves match them.
hl.curve("mac",     { type = "bezier", points = { { 0.25, 1.0 }, { 0.5, 1.0 } } })      -- ease-out quart
hl.curve("macIn",   { type = "bezier", points = { { 0.5, 0.0 }, { 0.75, 0.0 } } })
hl.curve("spaces",  { type = "bezier", points = { { 0.32, 0.72 }, { 0.0, 1.0 } } })     -- Spaces slide
hl.curve("linear",  { type = "bezier", points = { { 0, 0 }, { 1, 1 } } })
hl.animation({ leaf = "windowsIn",   enabled = true, speed = 2.6, bezier = "mac",   style = "popin 90%" })
hl.animation({ leaf = "windowsOut",  enabled = true, speed = 1.8, bezier = "macIn", style = "popin 94%" })
hl.animation({ leaf = "windowsMove", enabled = true, speed = 3.0, bezier = "mac" })
hl.animation({ leaf = "fadeIn",      enabled = true, speed = 2.2, bezier = "mac" })
hl.animation({ leaf = "fadeOut",     enabled = true, speed = 1.6, bezier = "linear" })
hl.animation({ leaf = "fadeSwitch",  enabled = true, speed = 2.5, bezier = "mac" })
hl.animation({ leaf = "fadeShadow",  enabled = true, speed = 2.5, bezier = "mac" })
hl.animation({ leaf = "border",      enabled = true, speed = 2.5, bezier = "mac" })
hl.animation({ leaf = "layers",      enabled = true, speed = 1.8, bezier = "mac",   style = "fade" })
hl.animation({ leaf = "fadeLayers",  enabled = true, speed = 1.8, bezier = "mac" })
hl.animation({ leaf = "workspaces",  enabled = true, speed = 4.2, bezier = "spaces", style = "slide" })
hl.animation({ leaf = "specialWorkspace", enabled = true, speed = 2.4, bezier = "mac", style = "fade" })

---------------------------------------------------------------- glass
-- Orchard surfaces get the frosted blur; pixels under ~40% alpha (shadows,
-- empty space) stay sharp. The menu bar text sits straight on the picture.
for _, ns in ipairs({ "orchard-popup", "orchard-dock", "orchard-spotlight", "orchard-banner",
                      "orchard-hud", "orchard-switcher", "orchard-dialog", "orchard-launchpad" }) do
    hl.layer_rule({ name = "glass-" .. ns, match = { namespace = "^" .. ns .. "$" }, blur = true, ignore_alpha = 0.4 })
end
hl.layer_rule({ name = "launchpad-blur", match = { namespace = "^orchard-launchpad$" }, ignore_alpha = 0.1 })
-- the shell animates its own surfaces
for _, ns in ipairs({ "orchard-bar", "orchard-wallpaper", "orchard-popup", "orchard-dock", "orchard-spotlight",
                      "orchard-mission", "orchard-switcher", "orchard-corner", "orchard-banner", "orchard-launchpad", "orchard-thumb" }) do
    hl.layer_rule({ name = "noanim-" .. ns, match = { namespace = "^" .. ns .. "$" }, no_anim = true })
end
hl.layer_rule({ name = "selection", match = { namespace = "^(selection|hyprpicker)$" }, no_anim = true })

---------------------------------------------------------------- windows
-- Everything floats and opens centred, like a Mac. Big apps open at a
-- comfortable size; dialogs keep their own size.
hl.window_rule({ name = "float-all", match = { class = ".*" }, float = true, center = true })
hl.window_rule({ name = "big-apps",
    match = { class = "^(brave-browser|google-chrome|firefox|code|Code|code-oss|antigravity|Antigravity|org.kde.dolphin|discord|org.telegram.desktop|libreoffice.*|obsidian|org.godotengine.Editor|Godot)$" },
    size = { "monitor_w*0.80", "monitor_h*0.80" } })
hl.window_rule({ name = "terminal-size", match = { class = "^(footclient|foot|kitty)$" }, size = { "760", "470" } })
hl.window_rule({ name = "small-utils",
    match = { class = "^(pavucontrol|org.pulseaudio.pavucontrol|blueman-manager|nm-connection-editor|qt6ct|nwg-look|swappy)$" },
    size = { "760", "520" } })
hl.window_rule({ name = "settings", match = { title = "^System Settings$" }, size = { "760", "540" } })
hl.window_rule({ name = "pip", match = { title = "^Picture.in.[Pp]icture$" }, pin = true, size = { "480", "270" }, move = { "monitor_w-500", "monitor_h-360" } })
hl.window_rule({ name = "suppress-maximize", match = { class = ".*" }, suppress_event = "maximize" })
hl.window_rule({ name = "idle-fullscreen", match = { fullscreen = true }, idle_inhibit = "fullscreen" })

---------------------------------------------------------------- traffic lights
-- Desktop-wide red/yellow/green title bars need the hyprbars plugin built
-- for this Hyprland (bin/build-hyprbars). Without it, GTK apps still draw
-- their own Mac buttons through the MacTahoe theme.
pcall(dofile, O .. "/hypr/titlebars.lua")

---------------------------------------------------------------- gestures
hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })
hl.gesture({ fingers = 4, direction = "horizontal", action = "workspace" })
hl.gesture({ fingers = 4, direction = "up",   action = function () hl.dispatch(hl.dsp.global("orchard:mission")) end })
hl.gesture({ fingers = 4, direction = "down", action = function () hl.dispatch(hl.dsp.global("orchard:showdesktop")) end })
hl.gesture({ fingers = 3, direction = "up",   action = function () hl.dispatch(hl.dsp.global("orchard:mission")) end })

---------------------------------------------------------------- keys
-- Your zero keybindings, exactly as before, plus the Mac extras on keys
-- zero never used. Copy/paste stay on Ctrl like any Linux desktop.
local function b(k, d, o) hl.bind(k, d, o) end
local exec = hl.dsp.exec_cmd
local function g(name) return hl.dsp.global("orchard:" .. name) end
local M = "SUPER"
local Z = HOME .. "/.config/zero/bin/"
local osd = "qs -c orchard ipc call osd "

-- apps & launchers (zero)
b(M .. " + Return",    exec(BIN .. "term"),  { desc = "Terminal" })
b(M .. " + Q",         exec(BIN .. "term"),  { desc = "Terminal" })
b(M .. " + E",         exec("dolphin"),      { desc = "Files" })
b(M .. " + B",         exec("brave"),        { desc = "Browser" })
b(M .. " + SHIFT + C", exec("code"),         { desc = "VS Code" })
b(M .. " + Space",     g("spotlight"),       { desc = "Spotlight" })
b(M .. " + D",         exec("fuzzel"),       { desc = "Launcher" })
b(M .. " + R",         exec("fuzzel"),       { desc = "Launcher" })
b(M .. " + SHIFT + V", exec(Z .. "clip"),    { desc = "Clipboard" })
b(M .. " + SHIFT + E", exec(Z .. "power"),   { desc = "Power menu" })
b(M .. " + Escape",    exec(Z .. "power"),   { desc = "Power menu" })
b(M .. " + I",         g("control"),         { desc = "Control Center" })
b(M .. " + slash",     g("shortcuts"),       { desc = "Keybinds" })
b(M .. " + SHIFT + equal", exec(BIN .. "textsize up"),   { desc = "Bigger text" })
b(M .. " + SHIFT + minus", exec(BIN .. "textsize down"), { desc = "Smaller text" })
b(M .. " + SHIFT + N", g("nightshift"),      { desc = "Night light" })
b(M .. " + SHIFT + B", g("dock"),            { desc = "Toggle dock auto-hide" })
b(M .. " + S",         exec(Z .. "shot screen-clipboard"), { desc = "Copy full-screen screenshot" })
b(M .. " + CTRL + S",  exec(Z .. "shot screen-clipboard"), { desc = "Copy full-screen screenshot" })
b(M .. " + ALT + S",   exec(Z .. "shot region-clipboard"), { desc = "Copy selected screenshot area" })
b("Print",             exec(Z .. "shot screen-clipboard"), { desc = "Copy full-screen screenshot" })
b("SHIFT + Print",     exec(Z .. "shot screen"))
b(M .. " + SHIFT + S", exec(Z .. "shot edit"))
b(M .. " + SHIFT + P", exec("hyprpicker -a -f hex"))
b(M .. " + L",         exec("loginctl lock-session"), { desc = "Lock" })
b(M .. " + M",         exec("hyprctl dispatch 'hl.dsp.exit()'"), { desc = "Exit Hyprland" })

-- windows (zero)
b(M .. " + C", hl.dsp.window.close())
b(M .. " + V", hl.dsp.window.float({ action = "toggle" }))
b(M .. " + F", hl.dsp.window.fullscreen())
b(M .. " + P", hl.dsp.window.pseudo())
b(M .. " + J", hl.dsp.layout("togglesplit"))
b(M .. " + T", hl.dsp.window.pin())
for dir, key in pairs({ left = "left", right = "right", up = "up", down = "down" }) do
    b(M .. " + " .. key,         hl.dsp.focus({ direction = dir }))
    b(M .. " + SHIFT + " .. key, hl.dsp.window.swap({ direction = dir }))
end
b(M .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
b(M .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })
for i = 1, 10 do
    local key = i % 10
    b(M .. " + " .. key,         hl.dsp.focus({ workspace = i }))
    b(M .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end
b(M .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
b(M .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))
b(M .. " + grave",         hl.dsp.workspace.toggle_special("magic"))
b(M .. " + SHIFT + grave", hl.dsp.window.move({ workspace = "special:magic" }))

-- volume / brightness / media (zero keys, orchard HUD)
b("XF86AudioRaiseVolume",  exec(osd .. "volume 0.05"),  { locked = true, repeating = true })
b("XF86AudioLowerVolume",  exec(osd .. "volume -0.05"), { locked = true, repeating = true })
b("XF86AudioMute",         exec(osd .. "volume mute"),  { locked = true })
b("XF86AudioMicMute",      exec("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"), { locked = true })
b("XF86MonBrightnessUp",   exec(osd .. "brightness 0.05"),  { locked = true, repeating = true })
b("XF86MonBrightnessDown", exec(osd .. "brightness -0.05"), { locked = true, repeating = true })
b(M .. " + CTRL + up",     exec(osd .. "brightness 0.05"),  { repeating = true })
b(M .. " + CTRL + down",   exec(osd .. "brightness -0.05"), { repeating = true })
-- laptop F11/F12 (brightness keys) are blocked — faulty hardware
b(M .. " + equal",         exec(osd .. "brightness 0.05"),  { repeating = true, desc = "Brightness up" })
b(M .. " + minus",         exec(osd .. "brightness -0.05"), { repeating = true, desc = "Brightness down" })
b("XF86AudioNext",  exec("playerctl next"),       { locked = true })
b("XF86AudioPrev",  exec("playerctl previous"),   { locked = true })
b("XF86AudioPlay",  exec("playerctl play-pause"), { locked = true })
b("XF86AudioPause", exec("playerctl play-pause"), { locked = true })

-- Mac extras (keys zero never used)
b(M .. " + Tab",           g("switch-next"),   { desc = "Switch apps" })
b(M .. " + SHIFT + Tab",   g("switch-prev"),   { desc = "Switch apps back" })
b("ALT + Tab",             g("winswitch-next"), { desc = "Switch windows" })
b("ALT + SHIFT + Tab",     g("winswitch-prev"), { desc = "Switch windows back" })
b("Super_L", g("switch-commit"),    { release = true, ignore_mods = true, non_consuming = true })
b("Super_R", g("switch-commit"),    { release = true, ignore_mods = true, non_consuming = true })
b("Alt_L",   g("winswitch-commit"), { release = true, ignore_mods = true, non_consuming = true })
b("Alt_R",   g("winswitch-commit"), { release = true, ignore_mods = true, non_consuming = true })
b(M .. " + W",             g("window-next"),   { desc = "Next window of this app" })
b("F3",                    g("mission"),       { desc = "Mission Control" })
b("CTRL + up",             g("mission"),       { desc = "Mission Control" })
b("F4",                    g("launchpad"),     { desc = "Launchpad" })
b(M .. " + A",             g("launchpad"),     { desc = "Launchpad" })
b(M .. " + H",             g("hide"),          { desc = "Hide app" })
b(M .. " + ALT + H",       g("hideothers"),    { desc = "Hide others" })
b(M .. " + N",             g("minimize"),      { desc = "Minimize window" })
b(M .. " + ALT + Q",       g("quit"),          { desc = "Quit app" })
b(M .. " + ALT + Escape",  g("forcequit"),     { desc = "Force Quit" })
b(M .. " + ALT + D",       g("dock"),          { desc = "Toggle dock auto-hide" })
b(M .. " + ALT + N",       g("notifications"), { desc = "Notification Center" })
b(M .. " + ALT + C",       g("control"),       { desc = "Control Center" })
b(M .. " + ALT + comma",   g("settings"),      { desc = "System Settings" })
b(M .. " + SHIFT + 3",     exec(BIN .. "shot screen 0 file"))
b(M .. " + SHIFT + 4",     exec(BIN .. "shot region 0 file"))
b(M .. " + SHIFT + 5",     g("screenshot"))
b("CTRL + ALT + F",        g("fill"),          { desc = "Fill screen" })
b("CTRL + ALT + C",        g("center"),        { desc = "Center window" })
b("CTRL + ALT + left",     g("tileleft"),      { desc = "Tile left" })
b("CTRL + ALT + right",    g("tileright"),     { desc = "Tile right" })
b(M .. " + CTRL + left",   hl.dsp.focus({ workspace = "e-1" }), { desc = "Previous desktop" })
b(M .. " + CTRL + right",  hl.dsp.focus({ workspace = "e+1" }), { desc = "Next desktop" })

b("SUPER + CTRL + ALT + R", exec("hyprctl reload"), { desc = "Reload Hyprland" })

hl.on("hyprland.start", function () hl.exec_cmd(BIN .. "start") end)
