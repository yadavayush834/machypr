-- Optional glass chrome. Application content remains opaque.
hl.config({decoration={rounding=16,blur={enabled=true,size=6,passes=2,vibrancy=0.18},shadow={enabled=true,range=30,render_power=3,color=0x66000000}}})
for _,name in ipairs({'macos-dock','macos-menu','macos-menubar','macos-spotlight','macos-launchpad','macos-osd','macos-dashboard'}) do
 hl.layer_rule({match={namespace=name},blur=true,ignore_alpha=0.2})
end
if hl.plugin.hyprbars then
 local dark=true
 local f=io.open(os.getenv('HOME')..'/.config/macos-desktop/appearance.json','r')
 if f then local s=f:read('*a');f:close();dark=not s:match('"applied"%s*:%s*"light"') end
 hl.config({plugin={hyprbars={bar_blur=true,bar_color=dark and 'rgba(303038b8)' or 'rgba(f1f5ffca)'}}})
end
hl.curve('glass',{type='bezier',points={{0.2,0.85},{0.25,1}}})
hl.animation({leaf='windows',enabled=true,speed=4,bezier='glass',style='popin 98%'})
