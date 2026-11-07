-- Local hardware workaround: discard F11 from every keyboard, with any modifiers.
local options={ignore_mods=true,locked=true,dont_inhibit=true,submap_universal=true,allow_input_capture=true,description="Block faulty F11 key"}
hl.bind("code:95",hl.dsp.no_op(),options)
hl.bind("code:95",hl.dsp.no_op(),{ignore_mods=true,locked=true,dont_inhibit=true,submap_universal=true,allow_input_capture=true,release=true,description="Block faulty F11 release"})
