-- Standalone recovery configuration: no third-party plugins or custom includes.
hl.monitor({output="",mode="preferred",position="auto",scale="auto"})
hl.env("XCURSOR_THEME","WhiteSur-cursors")
hl.env("XCURSOR_SIZE","24")
hl.config({general={layout="dwindle",gaps_in=5,gaps_out=10,border_size=2},
 decoration={rounding=10,blur={enabled=false},shadow={enabled=false}},
 animations={enabled=false},input={kb_layout="us"},
 misc={disable_hyprland_logo=true,force_default_wallpaper=0}})
hl.bind("SUPER + Return",hl.dsp.exec_cmd("kitty"))
hl.bind("SUPER + Q",hl.dsp.exec_cmd("kitty"))
hl.bind("SUPER + E",hl.dsp.exec_cmd("dolphin"))
hl.bind("SUPER + Space",hl.dsp.exec_cmd("wofi --show drun"))
hl.bind("SUPER + W",hl.dsp.window.close())
hl.bind("SUPER + L",hl.dsp.exec_cmd("hyprlock"))
hl.bind("SUPER + SHIFT + E",hl.dsp.exit())
for i=1,10 do
 hl.bind("SUPER + "..(i%10),hl.dsp.focus({workspace=i}))
end
hl.on("hyprland.start",function()
 hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE HYPRLAND_INSTANCE_SIGNATURE")
 hl.exec_cmd("hyprpaper")
 hl.exec_cmd("hypridle")
 hl.exec_cmd("kitty --title 'mac-os Recovery'")
end)
