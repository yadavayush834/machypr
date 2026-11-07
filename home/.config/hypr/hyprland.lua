-- ARCH LINUX — Lua configuration for Hyprland 0.57
hl.monitor({output="",mode="preferred",position="auto",scale="auto"})
hl.env("XCURSOR_THEME", "WhiteSur-cursors")
hl.env("XCURSOR_SIZE", "24")
hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1")
hl.config({
 general={gaps_in=5,gaps_out=10,border_size=1,resize_on_border=false,layout="dwindle",
  col={active_border={colors={"rgba(5ca9dfee)","rgba(3778b7ee)"},angle=45},inactive_border="rgba(293345aa)"}},
 decoration={rounding=12,active_opacity=1.0,inactive_opacity=1.0,
  shadow={enabled=true,range=28,render_power=3,color=0x66000000},
  blur={enabled=true,size=5,passes=2,vibrancy=0.16}},
 animations={enabled=true},dwindle={preserve_split=true},
 input={kb_layout="us",follow_mouse=0,touchpad={natural_scroll=true,tap_to_click=true}},
 misc={disable_hyprland_logo=true,force_default_wallpaper=0}
})
pcall(dofile, os.getenv("HOME") .. "/.config/hypr/wallpaper-colors.lua")
hl.curve("macos", {type="bezier",points={{0.22,1},{0.36,1}}})
hl.animation({leaf="windows",enabled=true,speed=4,bezier="macos",style="popin 97%"})
hl.animation({leaf="workspaces",enabled=true,speed=3,bezier="macos",style="slide"})
hl.animation({leaf="fade",enabled=true,speed=3,bezier="macos"})
hl.animation({leaf="border",enabled=true,speed=5,bezier="macos"})
hl.on("hyprland.start",function() hl.exec_cmd(os.getenv("HOME").."/.local/bin/arch-start") end)
local function run(keys,cmd) hl.bind(keys,hl.dsp.exec_cmd(cmd)) end
run("SUPER + Return","kitty")
run("SUPER + Q","kitty")
run("SUPER + E","dolphin")
run("SUPER + B",os.getenv("HOME").."/.local/bin/brave")
run("SUPER + C",os.getenv("HOME").."/.local/bin/code")
run("SUPER + Space",os.getenv("HOME").."/.local/bin/macos-spotlight")
run("SUPER + R",os.getenv("HOME").."/.local/bin/macos-launchpad")
run("SUPER + L","hyprlock")
run("SUPER + V",os.getenv("HOME").."/.local/bin/arch-clipboard")
run("SUPER + Escape",os.getenv("HOME").."/.local/bin/arch-power")
run("SUPER + F1","kitty --title Shortcuts "..os.getenv("HOME").."/.local/bin/arch-shortcuts")
run("Print",os.getenv("HOME").."/.local/bin/arch-shot")
run("SUPER + SHIFT + R","hyprctl reload")
run("SUPER + ALT + W",os.getenv("HOME").."/.local/bin/arch-wallpaper")
run("SUPER + ALT + B",os.getenv("HOME").."/.local/bin/macos-menu control")
run("SUPER + ALT + N",os.getenv("HOME").."/.local/bin/arch-wifi")
hl.bind("SUPER + W",hl.dsp.window.close())
hl.bind("SUPER + SHIFT + Space",hl.dsp.window.float({action="toggle"}))
hl.bind("SUPER + J",hl.dsp.layout("togglesplit"))
run("SUPER + S",os.getenv("HOME").."/.local/bin/macos-screenshot region --clipboard")
hl.bind("SUPER + SHIFT + S",hl.dsp.window.move({workspace="special:scratch"}))
for _,d in ipairs({"left","right","up","down"}) do
 hl.bind("SUPER + "..d,hl.dsp.focus({direction=d}))
end
for i=1,10 do
 hl.bind("SUPER + "..(i%10),hl.dsp.focus({workspace=i}))
 local move_keys=(i>=3 and i<=5) and "SUPER + ALT + SHIFT + " or "SUPER + SHIFT + "
 hl.bind(move_keys..(i%10),hl.dsp.window.move({workspace=i}))
end
hl.bind("SUPER + mouse:272",hl.dsp.window.drag(),{mouse=true})
hl.bind("SUPER + mouse:273",hl.dsp.window.resize(),{mouse=true})
for key,cmd in pairs({XF86AudioRaiseVolume=os.getenv("HOME").."/.local/bin/macos-volume up",XF86AudioLowerVolume=os.getenv("HOME").."/.local/bin/macos-volume down",XF86AudioMute=os.getenv("HOME").."/.local/bin/macos-volume mute",XF86MonBrightnessUp=os.getenv("HOME").."/.local/bin/macos-brightness up",XF86MonBrightnessDown=os.getenv("HOME").."/.local/bin/macos-brightness down",XF86AudioPlay="playerctl play-pause",XF86AudioNext="playerctl next",XF86AudioPrev="playerctl previous"}) do
 hl.bind(key,hl.dsp.exec_cmd(cmd),{locked=true,repeating=true})
end
hl.gesture({fingers=3,direction="horizontal",action="workspace"})

-- macOS desktop: freely positioned windows and translucent desktop surfaces.
hl.window_rule({match={class=".*"},float=true,size={1040,590},center=true})
hl.layer_rule({match={namespace="waybar"},blur=true})
hl.layer_rule({match={namespace="macos-dock"},blur=false})
hl.bind("SUPER + Tab",hl.dsp.exec_cmd(os.getenv("HOME").."/.local/bin/macos-menu window"))
-- Cycle application windows on the current desktop.
run("ALT + Tab",os.getenv("HOME").."/.local/bin/macos-cycle-window")
run("ALT + SHIFT + Tab",os.getenv("HOME").."/.local/bin/macos-cycle-window --previous")

-- Request native GTK title bars with WhiteSur traffic-light buttons.
hl.env("GTK_CSD", "1")

-- Toggle the auto-hiding dock with Super+Alt+D.
run("SUPER + ALT + D","pkill -USR1 -u $(id -u) -f ^/usr/bin/python.*/macos-dock$")

hl.layer_rule({match={namespace="macos-menubar"},blur=true})

-- macOS screenshot shortcuts; Super is the keyboard logo key.
run("SUPER + SHIFT + 3",os.getenv("HOME").."/.local/bin/macos-screenshot screen")
run("SUPER + SHIFT + 4",os.getenv("HOME").."/.local/bin/macos-screenshot region")
run("SUPER + SHIFT + 5",os.getenv("HOME").."/.local/bin/macos-screenshot menu")
run("SUPER + CTRL + SHIFT + 3",os.getenv("HOME").."/.local/bin/macos-screenshot screen --clipboard")
run("SUPER + CTRL + SHIFT + 4",os.getenv("HOME").."/.local/bin/macos-screenshot region --clipboard")

pcall(dofile,os.getenv('HOME')..'/.config/hypr/macos-window-bars.lua')


-- Frosted transient surfaces and familiar desktop window actions.
hl.layer_rule({match={namespace="macos-menu"},blur=true})
hl.layer_rule({match={namespace="macos-spotlight"},blur=true})
hl.bind("SUPER + M",hl.dsp.window.move({workspace="special:minimized",follow=false}))
hl.bind("SUPER + CTRL + F",hl.dsp.window.fullscreen({mode="fullscreen"}))
hl.layer_rule({match={namespace="macos-osd"},blur=true})

pcall(dofile,os.getenv('HOME')..'/.config/hypr/macos-glass.lua')


-- On-demand native dashboard; no background service.
hl.bind("SUPER + D",hl.dsp.exec_cmd(os.getenv("HOME").."/.local/bin/macos-dashboard"))

-- Finish the Alt+Tab cycle when either Alt key is released; pass release to apps.
for _,key in ipairs({"Alt_L","Alt_R"}) do
 hl.bind(key,hl.dsp.exec_cmd(os.getenv("HOME").."/.local/bin/macos-cycle-window --end"),{release=true,ignore_mods=true,non_consuming=true})
end

-- Restore the display immediately on lid open, including at the lock screen.
hl.bind("switch:off:Lid Switch", hl.dsp.exec_cmd('hyprctl dispatch \'hl.dsp.dpms({ action = "enable" })\''), {locked=true})
