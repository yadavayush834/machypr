-- Traffic-light title bars on every window (needs bin/build-hyprbars).
-- Close / minimise / zoom, centred title, double-click to zoom like macOS.
local lib = os.getenv("HOME") .. "/.local/lib/orchard/hyprbars.so"
local f = io.open(lib, "rb")
if not f then return end
f:close()
hl.plugin.load(lib)
if not hl.plugin.hyprbars then return end

local dark = true
local s = io.open(os.getenv("HOME") .. "/.local/state/orchard/settings.json", "r")
if s then
    local v = s:read("*a"); s:close()
    local h = tonumber(os.date("%H"))
    if v:match('"appearance"%s*:%s*"light"') then dark = false
    elseif v:match('"appearance"%s*:%s*"auto"') or not v:match('"appearance"') then dark = (h < 7 or h >= 19) end
end

hl.config({ plugin = { hyprbars = {
    bar_height = 30,
    bar_color = dark and "rgb(2c2c2e)" or "rgb(ececee)",
    col = { text = dark and "rgba(ffffffcc)" or "rgba(000000cc)" },
    bar_text_font = "Inter", bar_text_size = 10, bar_text_align = "center",
    bar_buttons_alignment = "left",
    bar_padding = 12, bar_button_padding = 8,
    bar_part_of_window = true, bar_precedence_over_border = true,
    icon_on_hover = true,
    inactive_button_color = dark and "rgb(4a4a4d)" or "rgb(cfcfd3)",
    on_double_click = "hyprctl dispatch 'hl.dsp.window.fullscreen({ mode = \"maximized\" })'",
} } })
hl.plugin.hyprbars.add_button({ bg_color = "rgb(ff5f57)", fg_color = "rgb(4d0000)", size = 12, icon = "×",
    action = "hyprctl dispatch 'hl.dsp.window.close()'" })
hl.plugin.hyprbars.add_button({ bg_color = "rgb(febc2e)", fg_color = "rgb(5a3d00)", size = 12, icon = "−",
    action = "hyprctl dispatch 'hl.dsp.global(\"orchard:minimize\")'" })
hl.plugin.hyprbars.add_button({ bg_color = "rgb(28c840)", fg_color = "rgb(004d00)", size = 12, icon = "+",
    action = "hyprctl dispatch 'hl.dsp.window.fullscreen({ mode = \"maximized\" })'" })

-- apps that already draw Mac-style buttons (GTK with MacTahoe, Brave, Electron)
hl.window_rule({ name = "no-bar-csd",
    match = { class = "^(brave-browser|google-chrome|discord|org.telegram.desktop|org.gnome.*|swappy|org.quickshell)$" },
    ["hyprbars:no_bar"] = true })
