-- Refractive glass: guarded plugin loading and per-surface compositor sampling.
local library=os.getenv('HOME')..'/.local/lib/macos-desktop/hyprglass.so'
local renderer=false
if os.getenv('MACOS_DISABLE_PLUGINS')~='1' then
 local file=io.open(library,'rb')
 if file then file:close();hl.plugin.load(library);renderer=true end
end
hl.config({decoration={rounding=16,blur={enabled=true,size=6,passes=2,vibrancy=0.18},shadow={enabled=true,range=30,render_power=3,color=0x66000000}}})
for _,name in ipairs({'macos-dock','macos-menu','macos-menubar','macos-spotlight','macos-launchpad','macos-osd','macos-dashboard'}) do
 hl.layer_rule({match={namespace=name},blur=true,ignore_alpha=0.2})
end
if renderer and hl.plugin.hyprglass then
 local appearance=io.open(os.getenv('HOME')..'/.config/macos-desktop/appearance.json','r')
 local dark=true
 if appearance then local text=appearance:read('*a');appearance:close();dark=not text:match('"applied"%s*:%s*"light"') end
 local hg=hl.plugin.hyprglass
 hg.config({enabled=true,manage_window_blur=true,skip_opaque_windows=true,
  default_theme=dark and 'dark' or 'light',default_preset='default',
  blur_strength=0.65,blur_iterations=2,refraction_strength=0.8,
  chromatic_aberration=0.25,fresnel_strength=0.38,specular_strength=0.45,
  edge_thickness_px=12,edge_height=8,glass_opacity=1.0,
  dark={brightness=0.88,contrast=1.05,saturation=0.95,adaptive_dim=0.45,tint_color=0x14223535},
  light={brightness=1.02,contrast=1.0,saturation=0.95,adaptive_boost=0.2,tint_color=0xf3f7ff24},
  layers={enabled=true}})
 for _,name in ipairs({'macos-dock','macos-menu','macos-menubar','macos-spotlight','macos-launchpad','macos-osd','macos-dashboard'}) do
  hg.layer(name,{mask_threshold=0.2})
 end
 -- Compositor fallback for clients without their own translucent surfaces.
 -- Native foreground text still comes from each unmodified application.
 hl.window_rule({match={class='.*'},opacity=1.0})
 hl.window_rule({match={fullscreen=true},opacity=1.0,tag='+hyprglass_disabled'})
end
if hl.plugin.hyprbars then
 local dark=true
 local f=io.open(os.getenv('HOME')..'/.config/macos-desktop/appearance.json','r')
 if f then local text=f:read('*a');f:close();dark=not text:match('"applied"%s*:%s*"light"') end
 hl.config({plugin={hyprbars={bar_blur=false,bar_color=dark and 'rgb(303034)' or 'rgb(ededf1)'}}})
end
hl.curve('glass',{type='bezier',points={{0.2,0.85},{0.25,1}}})
hl.animation({leaf='windows',enabled=true,speed=4,bezier='glass',style='popin 98%'})
