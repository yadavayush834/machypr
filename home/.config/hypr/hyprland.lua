-- ARCH LINUX — Lua configuration for Hyprland 0.57
hl.monitor({output="",mode="preferred",position="auto",scale="auto"})
hl.env("XCURSOR_THEME", "Adwaita")
hl.env("XCURSOR_SIZE", "24")
hl.config({
 general={gaps_in=5,gaps_out=10,border_size=2,resize_on_border=true,layout="dwindle",
  col={active_border={colors={"rgba(5ca9dfee)","rgba(3778b7ee)"},angle=45},inactive_border="rgba(293345aa)"}},
 decoration={rounding=10,active_opacity=1.0,inactive_opacity=0.97,
  shadow={enabled=true,range=22,render_power=3,color=0x55000000},
  blur={enabled=true,size=5,passes=2,vibrancy=0.16}},
 animations={enabled=true},dwindle={preserve_split=true},
 input={kb_layout="us",follow_mouse=1,touchpad={natural_scroll=true,tap_to_click=true}},
 misc={disable_hyprland_logo=true,force_default_wallpaper=0}
})
pcall(dofile, os.getenv("HOME") .. "/.config/hypr/wallpaper-colors.lua")
hl.curve("arch", {type="bezier",points={{0.22,1},{0.36,1}}})
hl.animation({leaf="windows",enabled=true,speed=4,bezier="arch",style="popin 94%"})
hl.animation({leaf="workspaces",enabled=true,speed=3,bezier="arch",style="slide"})
hl.animation({leaf="fade",enabled=true,speed=3,bezier="arch"})
hl.animation({leaf="border",enabled=true,speed=5,bezier="arch"})
hl.on("hyprland.start",function() hl.exec_cmd(os.getenv("HOME").."/.local/bin/arch-start") end)
local function run(keys,cmd) hl.bind(keys,hl.dsp.exec_cmd(cmd)) end
run("SUPER + Return","kitty")
run("SUPER + Q","kitty")
run("SUPER + E","dolphin")
run("SUPER + B",os.getenv("HOME").."/.local/bin/brave")
run("SUPER + C",os.getenv("HOME").."/.local/bin/code")
run("SUPER + Space","wofi --show drun")
run("SUPER + R","wofi --show drun")
run("SUPER + L","hyprlock")
run("SUPER + V",os.getenv("HOME").."/.local/bin/arch-clipboard")
run("SUPER + Escape",os.getenv("HOME").."/.local/bin/arch-power")
run("SUPER + F1","kitty --title Shortcuts "..os.getenv("HOME").."/.local/bin/arch-shortcuts")
run("Print",os.getenv("HOME").."/.local/bin/arch-shot")
run("SUPER + SHIFT + R","hyprctl reload")
run("SUPER + ALT + W",os.getenv("HOME").."/.local/bin/arch-wallpaper")
run("SUPER + ALT + B",os.getenv("HOME").."/.local/bin/arch-waybar-style")
hl.bind("SUPER + W",hl.dsp.window.close())
hl.bind("SUPER + SHIFT + Space",hl.dsp.window.float({action="toggle"}))
hl.bind("SUPER + J",hl.dsp.layout("togglesplit"))
hl.bind("SUPER + S",hl.dsp.workspace.toggle_special("scratch"))
hl.bind("SUPER + SHIFT + S",hl.dsp.window.move({workspace="special:scratch"}))
for _,d in ipairs({"left","right","up","down"}) do
 hl.bind("SUPER + "..d,hl.dsp.focus({direction=d}))
end
for i=1,10 do
 hl.bind("SUPER + "..(i%10),hl.dsp.focus({workspace=i}))
 hl.bind("SUPER + SHIFT + "..(i%10),hl.dsp.window.move({workspace=i}))
end
hl.bind("SUPER + mouse:272",hl.dsp.window.drag(),{mouse=true})
hl.bind("SUPER + mouse:273",hl.dsp.window.resize(),{mouse=true})
for key,cmd in pairs({XF86AudioRaiseVolume="wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+",XF86AudioLowerVolume="wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-",XF86AudioMute="wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle",XF86MonBrightnessUp="brightnessctl set +5%",XF86MonBrightnessDown="brightnessctl set 5%-",XF86AudioPlay="playerctl play-pause",XF86AudioNext="playerctl next",XF86AudioPrev="playerctl previous"}) do
 hl.bind(key,hl.dsp.exec_cmd(cmd),{locked=true,repeating=true})
end
hl.gesture({fingers=3,direction="horizontal",action="workspace"})
