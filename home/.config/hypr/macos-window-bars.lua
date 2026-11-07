-- Declare the plugin on EVERY config evaluation. Hyprland reconciles this list
-- after parsing; checking hl.plugin.hyprbars here causes load/unload recursion.
-- The guarded login disables optional plugins after a compositor/plugin update.
if os.getenv('MACOS_DISABLE_PLUGINS') == '1' then return end
local library=os.getenv('HOME')..'/.local/lib/macos-desktop/hyprbars.so'
local file=io.open(library,'rb')
if file then file:close();hl.plugin.load(library) end
if hl.plugin.hyprbars then
 local dark=true
 local file=io.open(os.getenv('HOME')..'/.config/macos-desktop/appearance.json','r')
 if file then
  local value=file:read('*a');file:close()
  dark=not value:match('"applied"%s*:%s*"light"')
 end
 hl.config({plugin={hyprbars={bar_height=36,bar_color=dark and 'rgb(303034)' or 'rgb(ededf1)',col={text=dark and 'rgb(f2f2f7)' or 'rgb(202024)'},bar_text_font='Inter',bar_text_size=11,bar_text_weight='500',bar_text_align='center',bar_buttons_alignment='left',bar_padding=12,bar_button_padding=7,bar_part_of_window=true,bar_precedence_over_border=true,bar_blur=false,icon_on_hover=true,inactive_button_color='rgb(808087)',on_double_click=""}}})
 hl.plugin.hyprbars.add_button({bg_color='rgb(ff5f57)',fg_color='rgb(620a08)',size=12,icon='×',action=[[hyprctl dispatch 'hl.dsp.window.close()']]})
 hl.plugin.hyprbars.add_button({bg_color='rgb(febc2e)',fg_color='rgb(805600)',size=12,icon='−',action=[[hyprctl dispatch 'hl.dsp.window.move({workspace="special:minimized",follow=false})']]})
 hl.plugin.hyprbars.add_button({bg_color='rgb(28c840)',fg_color='rgb(006500)',size=12,icon='+',action=[[hyprctl dispatch 'hl.dsp.window.fullscreen({mode="maximized"})']]})
end

-- These applications draw their own minimize/maximize/close controls.
-- Keep one title bar instead of stacking compositor controls above theirs.
hl.window_rule({
 match={class="^(chatgpt|Chatgpt|ChatGPT|codex|Codex|docker-desktop|Docker Desktop|spotify|Spotify|org.telegram.desktop|telegram-desktop|Telegram)$"},
 ["hyprbars:no_bar"]=true
})
