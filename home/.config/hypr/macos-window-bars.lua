-- Desktop-wide window controls. The plugin is compiled against installed Hyprland headers.
local library=os.getenv('HOME')..'/.local/lib/macos-desktop/hyprbars.so'
if not hl.plugin.hyprbars then
 local file=io.open(library,'rb')
 if file then file:close();pcall(hl.plugin.load,library) end
end
if hl.plugin.hyprbars then
 local dark=true
 local file=io.open(os.getenv('HOME')..'/.config/macos-desktop/appearance.json','r')
 if file then
  local value=file:read('*a');file:close()
  dark=not value:match('"applied"%s*:%s*"light"')
 end
 hl.config({plugin={hyprbars={bar_height=30,bar_color=dark and 'rgb(303034)' or 'rgb(ededf1)',col={text=dark and 'rgb(f2f2f7)' or 'rgb(202024)'},bar_text_font='Inter',bar_text_size=11,bar_text_weight='500',bar_text_align='center',bar_buttons_alignment='left',bar_padding=12,bar_button_padding=7,bar_part_of_window=true,bar_precedence_over_border=true,bar_blur=false,icon_on_hover=true,inactive_button_color='rgb(808087)',on_double_click=[[hyprctl dispatch 'hl.dsp.window.fullscreen({mode="maximized"})']]}}})
 hl.plugin.hyprbars.add_button({bg_color='rgb(ff5f57)',fg_color='rgb(620a08)',size=12,icon='×',action=[[hyprctl dispatch 'hl.dsp.window.close()']]})
 hl.plugin.hyprbars.add_button({bg_color='rgb(febc2e)',fg_color='rgb(805600)',size=12,icon='−',action=[[hyprctl dispatch 'hl.dsp.window.move({workspace="special:minimized",follow=false})']]})
 hl.plugin.hyprbars.add_button({bg_color='rgb(28c840)',fg_color='rgb(006500)',size=12,icon='+',action=[[hyprctl dispatch 'hl.dsp.window.fullscreen({mode="maximized"})']]})
 -- Brave already draws native GTK traffic lights inside its tab strip.
 hl.window_rule({match={class='brave-browser'},['hyprbars:no_bar']=true})
end
