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
local function b(k, d, o) hl.bind(k, d, o) end
local exec = hl.dsp.exec_cmd
local function g(name) return hl.dsp.global("orchard:" .. name) end
local CMD = "SUPER"

-- ⌘-letter shortcuts go to the focused app. Terminals use Ctrl+Shift for
-- copy/paste and friends, everything else uses Ctrl.
local TERMS = { footclient = true, foot = true, kitty = true, Alacritty = true, ["com.mitchellh.ghostty"] = true }
local function isTerm()
    local w = hl.get_active_window()
    return w ~= nil and TERMS[w.class] == true
end
local function send(mods, key)
    hl.dispatch(hl.dsp.send_shortcut({ mods = mods, key = key }))
end
local function cmd(key, termShift)
    b(CMD .. " + " .. key, function ()
        if termShift and isTerm() then send("CTRL SHIFT", key) else send("CTRL", key) end
    end)
end
for _, k in ipairs({ "C", "V", "F", "T", "N" }) do cmd(k, true) end
for _, k in ipairs({ "X", "Z", "A", "S", "O", "P", "R", "L", "D", "G", "K", "U", "I", "B", "J", "Y" }) do cmd(k, false) end
b(CMD .. " + SHIFT + Z", function () send("CTRL SHIFT", "Z") end, { desc = "Redo" })
b(CMD .. " + SHIFT + T", function () send("CTRL SHIFT", "T") end, { desc = "Reopen tab" })
b(CMD .. " + SHIFT + N", function () send("CTRL SHIFT", "N") end, { desc = "New private window / folder" })
b(CMD .. " + SHIFT + S", function () send("CTRL SHIFT", "S") end, { desc = "Save As" })
b(CMD .. " + comma",     function () send("CTRL", "comma") end, { desc = "App settings" })
b(CMD .. " + equal",     function () send("CTRL", "equal") end, { desc = "Zoom in" })
b(CMD .. " + minus",     function () send("CTRL", "minus") end, { desc = "Zoom out" })
b(CMD .. " + 0",         function () send("CTRL", "0") end, { desc = "Actual size" })
b(CMD .. " + bracketleft",  function () send("ALT", "left") end,  { desc = "Back" })
b(CMD .. " + bracketright", function () send("ALT", "right") end, { desc = "Forward" })
b(CMD .. " + BackSpace", function () send("CTRL", "BackSpace") end, { desc = "Delete word" })
b(CMD .. " + left",  function () send("", "Home") end, { desc = "Line start" })
b(CMD .. " + right", function () send("", "End") end,  { desc = "Line end" })
b("ALT + left",  function () send("CTRL", "left") end,  { desc = "Word left" })
b("ALT + right", function () send("CTRL", "right") end, { desc = "Word right" })
b("ALT + BackSpace", function () send("CTRL", "BackSpace") end, { desc = "Delete word" })

-- ⌘W closes the tab, or the window when the app has no tabs (terminals)
b(CMD .. " + W", function ()
    if isTerm() then hl.dispatch(hl.dsp.window.close()) else send("CTRL", "W") end
end, { desc = "Close tab / window" })
b(CMD .. " + SHIFT + W", hl.dsp.window.close(), { desc = "Close window" })
b(CMD .. " + Q",          g("quit"),       { desc = "Quit app" })
b(CMD .. " + H",          g("hide"),       { desc = "Hide app" })
b(CMD .. " + ALT + H",    g("hideothers"), { desc = "Hide others" })
b(CMD .. " + M",          g("minimize"),   { desc = "Minimize" })
b(CMD .. " + CTRL + F",   hl.dsp.window.fullscreen({ mode = "fullscreen" }), { desc = "Full screen" })
b("CTRL + ALT + F",       g("fill"),       { desc = "Fill" })
b("CTRL + ALT + C",       g("center"),     { desc = "Center" })
b("CTRL + ALT + left",    g("tileleft"),   { desc = "Tile left" })
b("CTRL + ALT + right",   g("tileright"),  { desc = "Tile right" })
b("CTRL + ALT + Return",  hl.dsp.window.fullscreen({ mode = "maximized" }), { desc = "Zoom" })
b(CMD .. " + CTRL + T",   hl.dsp.window.float({ action = "toggle" }), { desc = "Tile / float window" })

-- system
b(CMD .. " + Space",       g("spotlight"),     { desc = "Spotlight" })
b(CMD .. " + SHIFT + V",   g("clipboard"),     { desc = "Clipboard history" })
b(CMD .. " + Tab",         g("switch-next"),   { desc = "App switcher" })
b(CMD .. " + SHIFT + Tab", g("switch-prev"),   { desc = "App switcher back" })
b("Super_L", g("switch-commit"), { release = true, ignore_mods = true, non_consuming = true })
b(CMD .. " + up",          g("mission"),       { desc = "Mission Control" })
b("CTRL + up",             g("mission"),       { desc = "Mission Control" })
b("F3",                    g("mission"))
b("F4",                    g("launchpad"))
b(CMD .. " + SHIFT + A",   g("launchpad"),     { desc = "Apps" })
b(CMD .. " + ALT + Escape", g("forcequit"),    { desc = "Force Quit" })
b(CMD .. " + CTRL + Q",    exec("loginctl lock-session"), { desc = "Lock Screen" })
b(CMD .. " + SHIFT + Q",   exec("qs -c orchard ipc call shell confirm logout"), { desc = "Log Out" })
b(CMD .. " + ALT + D",     g("dock"),          { desc = "Hide / show Dock" })
b(CMD .. " + ALT + N",     g("notifications"), { desc = "Notification Center" })
b(CMD .. " + ALT + C",     g("control"),       { desc = "Control Center" })
b(CMD .. " + ALT + comma", g("settings"),      { desc = "System Settings" })
b(CMD .. " + ALT + slash", g("shortcuts"),     { desc = "Keyboard shortcuts" })
b(CMD .. " + Return",      exec(BIN .. "term"), { desc = "Terminal" })
b(CMD .. " + ALT + space", exec("dolphin"),    { desc = "Finder" })

-- screenshots (⇧⌘3 screen, ⇧⌘4 area, ⇧⌘5 toolbar; add ⌃ for clipboard)
b(CMD .. " + SHIFT + 3",        exec(BIN .. "shot screen 0 file"))
b(CMD .. " + SHIFT + 4",        exec(BIN .. "shot region 0 file"))
b(CMD .. " + SHIFT + 5",        g("screenshot"))
b(CMD .. " + CTRL + SHIFT + 3", exec(BIN .. "shot screen 0 clip"))
b(CMD .. " + CTRL + SHIFT + 4", exec(BIN .. "shot region 0 clip"))
b("Print",                      exec(BIN .. "shot screen 0 file"))
b(CMD .. " + SHIFT + C",        exec("hyprpicker -a -f hex"), { desc = "Colour picker" })

-- Spaces (desktops)
for i = 1, 9 do
    b(CMD .. " + " .. i,             hl.dsp.focus({ workspace = i }))
    b(CMD .. " + SHIFT + " .. i,     hl.dsp.window.move({ workspace = i }))
end
b("CTRL + left",  hl.dsp.focus({ workspace = "e-1" }), { desc = "Previous desktop" })
b("CTRL + right", hl.dsp.focus({ workspace = "e+1" }), { desc = "Next desktop" })
b(CMD .. " + CTRL + left",  hl.dsp.focus({ workspace = "r-1" }))
b(CMD .. " + CTRL + right", hl.dsp.focus({ workspace = "r+1" }))
b(CMD .. " + grave", hl.dsp.window.cycle_next(), { desc = "Next window of app" })

b(CMD .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
b(CMD .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })
b("CTRL + SUPER + mouse:272", hl.dsp.window.drag(), { mouse = true })

-- media keys → the shell's HUD
local osd = "qs -c orchard ipc call osd "
b("XF86AudioRaiseVolume",  exec(osd .. "volume 0.0625"),  { locked = true, repeating = true })
b("XF86AudioLowerVolume",  exec(osd .. "volume -0.0625"), { locked = true, repeating = true })
b("XF86AudioMute",         exec(osd .. "volume mute"),    { locked = true })
b("XF86AudioMicMute",      exec("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"), { locked = true })
b("XF86MonBrightnessUp",   exec(osd .. "brightness 0.0625"),  { locked = true, repeating = true })
b("XF86MonBrightnessDown", exec(osd .. "brightness -0.0625"), { locked = true, repeating = true })
-- this laptop's F11/F12 are disabled (keyboard fault): ⌥⌘= / ⌥⌘- for brightness
b(CMD .. " + ALT + equal", exec(osd .. "brightness 0.0625"),  { repeating = true, desc = "Brightness up" })
b(CMD .. " + ALT + minus", exec(osd .. "brightness -0.0625"), { repeating = true, desc = "Brightness down" })
b("XF86AudioNext",  exec("playerctl next"),       { locked = true })
b("XF86AudioPrev",  exec("playerctl previous"),   { locked = true })
b("XF86AudioPlay",  exec("playerctl play-pause"), { locked = true })
b("XF86AudioPause", exec("playerctl play-pause"), { locked = true })

b("SUPER + CTRL + ALT + R", exec("hyprctl reload"), { desc = "Reload Hyprland" })

hl.on("hyprland.start", function () hl.exec_cmd(BIN .. "start") end)
