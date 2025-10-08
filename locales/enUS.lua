--========================================================--
-- YATP - English (Default)
--========================================================--
local L = LibStub("AceLocale-3.0"):NewLocale("YATP", "enUS", true)
if not L then return end

L["General"] = "General"
L["A modular collection of interface tweaks and utilities."] = "A modular collection of interface tweaks and utilities."

-- XP & Reputation Module
L["XP Bar"] = "XP Bar"
L["XP & Reputation"] = "XP & Reputation"
L["Lock bar"] = "Lock bar"
L["Width"] = "Width"
L["Height"] = "Height"
L["Text Mode"] = "Text Mode"
L["Always Show"] = "Always Show"
L["Show on Mouseover"] = "Show on Mouseover"
L["Font Size"] = "Font Size"
L["Font Outline"] = "Font Outline"
L["Bar Texture"] = "Bar Texture"
L["Background"] = "Background"
L["Background Texture"] = "Background Texture"
L["Background Color"] = "Background Color"
L["Show Ticks"] = "Show Ticks"
L["Visuals"] = "Visuals"
L["Feeling and Position"] = "Feeling and Position"
L["Position X"] = "Position X"
L["Position Y"] = "Position Y"
L["Horizontal offset of the XP bar"] = "Horizontal offset of the XP bar"
L["Vertical offset of the XP bar"] = "Vertical offset of the XP bar"
L["XPBar"] = "XP Bar"
L["XPRepBar"] = "XP & Reputation"
L["Font"] = "Font"
L["Show text only on mouseover"] = "Show text only on mouseover"
L["If enabled, the XP text will only show when hovering the bar."] = "If enabled, the XP text will only show when hovering the bar."
L["Position"] = "Position"

-- Newly added position utilities
L["Reset Position"] = "Reset Position"
L["Reset the bar position to its default location"] = "Reset the bar position to its default location"
L["Debug Position"] = "Debug Position"
L["Print coordinates to chat when position changes"] = "Print coordinates to chat when position changes"
L["About"] = "About"
L["Author"] = "Author"
L["Version"] = "Version"
L["Interface"] = "Interface"
L["Quality of Life"] = "Quality of Life"
L["QualityOfLife"] = "Quality of Life"
L["Select a category tab to configure modules."] = "Select a category tab to configure modules."
L["No modules in this category yet."] = "No modules in this category yet."
L["Debug Mode"] = true
L["Enable verbose debug output for all modules that support it."] = true
L["ChatFilters"] = "Chat Filters"
L["Chat Filters"] = true
-- ChatBubbles / Advanced
L["ChatBubbles"] = "ChatBubbles"
L["Enable"] = "Enable"
L["Font Face"] = "Font Face"
L["Outline"] = "Outline"
L["Utilities"] = "Utilities"
L["Force Refresh"] = "Force Refresh"
L["Advanced"] = "Advanced"
L["Scan Interval"] = "Scan Interval"
L["Post-detection Sweeps"] = "Post-detection Sweeps"
L["Hide Chat Bubbles"] = true
-- PlayerAuras
L["PlayerAuras"] = true
L["Enable PlayerAuras"] = true
L["Manage Buffs"] = true
L["Manage Debuffs"] = true
L["Throttle"] = true
L["Seconds between refresh attempts when changes occur."] = true
L["Layout"] = true
L["Debuffs per Row"] = true
L["Grow Direction"] = true
L["Sort Mode"] = true
L["Alphabetical"] = true
L["Original"] = true
L["Duration Text"] = true
L["Font Size"] = true
L["Outline"] = true
L["Font"] = true
L["Buff Filters"] = true
L["Hide this buff when active."] = true
L["Reset List"] = true
L["Restore default known buffs list."] = true
L["Left"] = true
L["Right"] = true
L["Game Default"] = true
L["PlayerAuras Filters"] = true
L["PlayerAurasFilters"] = true
L["Filters"] = true
L["Search"] = true
L["Filter the list by substring (case-insensitive)."] = true
L["Toggles"] = true
L["BronzeBeard Buffs"] = true
L["Custom Buffs"] = true
L["Add Buff"] = true
L["Add"] = true
L["Enter the exact buff name to add it to the list and toggle hide/show."] = true
L["Hide"] = true
L["Remove"] = true
L["Remove this custom buff from the list."] = true
L["Custom Added Buffs"] = true
-- Interface Hub
L["Interface Hub"] = true
L["Use the dropdown below to select a module."] = true
L["Select a module from the list on the left."] = true
L["Select Module"] = true
L["Reload UI"] = true
L["Module Options"] = true
L["No module selected."] = true
L["Modules"] = true
L["Enable or disable the PlayerAuras module (all features)."] = true
L["If enabled, PlayerAuras filters and repositions your buffs (hiding those you mark)."] = true
L["If enabled, PlayerAuras repositions your debuffs applying the same scaling and sorting."] = true
L["Continuously sweep world frames to strip bubble textures ASAP (slightly higher CPU)."] = "Continuously sweep world frames to strip bubble textures ASAP (slightly higher CPU)."
L["Seconds between sweeps in aggressive mode."] = "Seconds between sweeps in aggressive mode."
L["Extra quick sweeps right after detecting a bubble."] = "Extra quick sweeps right after detecting a bubble."
L["Toggle the ChatBubbles module. Removes bubble artwork and restyles the text using your chosen font settings."] = "Toggle the ChatBubbles module. Removes bubble artwork and restyles the text using your chosen font settings."
-- InfoBar / Quality of Life
L["Info Bar"] = true
L["Enable Module"] = true
L["Lock Frame"] = true
L["Update Interval (seconds)"] = true
L["Metrics"] = true
L["Show FPS"] = true
L["Show Ping"] = true
L["Show Durability"] = true
L["Low Durability Threshold"] = true
L["Only color durability below threshold"] = true
L["Appearance"] = true
L["Font Color"] = true
L["Show Background"] = true
L["Durability"] = true
-- Common formatting terms
L["None"] = "None"
L["Outline"] = "Outline"
L["Thick Outline"] = "Thick Outline"
-- Ensure InfoBar canonical key (module internally may request 'InfoBar')
L["InfoBar"] = "Info Bar"
-- QuickConfirm
L["QuickConfirm"] = true
L["Automatically confirms selected confirmation popups (transmog)."] = true
L["Transmog"] = true
L["Auto-confirm transmog appearance popups"] = true
L["Miscellaneous"] = true
L["Suppress click sound"] = true
L["Scan Interval"] = true
L["(Legacy) Scan Interval"] = true
L["Retry Attempts"] = true
L["Number of scheduled retry attempts when a popup appears and the confirm button may not yet be ready."] = true
L["Retry Interval"] = true
L["Seconds between retry attempts."] = true
L["Debug"] = true
L["Debug Messages"] = true
-- Hotkeys Module
L["Hotkeys"] = true
L["Customize action button hotkey fonts and ability icon tint."] = true
L["Hotkey Color"] = true
L["Font"] = true -- already defined earlier, reuse
L["Icon Tint"] = true
L["Enable Tint"] = true
L["Out of Range"] = true
L["Not Enough Mana"] = true
L["Unusable"] = true
L["Normal"] = true
L["Behavior"] = true
L["Trigger on Key Down"] = true
L["Keyboard Only"] = true
L["Apply 'key down' only if the button has a keyboard binding; mouse clicks stay default (on release)."] = true
L["Fire actions on key press (may reduce perceived input lag)."] = true
-- Legacy QuickConfirm exit-related keys removed (scope now only transmog)
-- Extras / Fixes
L["Extras"] = true
L["Miscellaneous small toggles and fixes."] = true
L["Fixes"] = true
L["WAAdiFixes"] = "WA/Adi Fixes"
L["(Migrated from 'Fixes' module name)"] = true
L["Enable Resize API Fix"] = true
L["Prevents SetResizeBounds/SetMaxResize errors injected by modern addons."] = true
L["Various small compatibility toggles."] = true
L["Compatibility Fixes"] = true
L["WeakAuras / AdiBags"] = true
L["Resize Bounds Patch"] = true
L["Prevents errors when modern WeakAuras code calls SetResizeBounds on legacy client frames."] = true
L["You can add more inline groups here for future fixes."] = true
-- Background FPS Management
L["Performance"] = true
L["Background FPS"] = true
L["Manage Background FPS Cap"] = true
L["When enabled, sets /console maxfpsbk to the value below and restores the previous value when disabled."] = true
L["Background FPS Value"] = true
L["Target FPS while the game is unfocused (0 disables override logic)."] = true
L["Current: %s (Prev: %s) State: %s"] = true
L["Active"] = true
L["Inactive"] = true
L["Hint: Shift-Right-Click the InfoBar to quick toggle."] = true
L["Shift-Right-Click to toggle management."] = true
L["State"] = true
L["Target"] = true
L["Original"] = true
L["Managed"] = true
L["Unmanaged"] = true
-- Background FPS Fix (separate module variant without slider)
L["Tweaks"] = true
L["Enable Background FPS Fix"] = true
L["When enabled, forces a background FPS cap and restores the previous value when disabled."] = true
L["State: %s  Current: %s  Previous: %s"] = true
L["This tweak uses an internal default (60 FPS) for now."] = true
L["Background FPS Cap"] = true
L["Set the background framerate cap. 0 = do not override. This slider removes the old 60 FPS ceiling."] = true
L["Note: Previous UI limited this to 60 FPS; this module lets you set higher values."] = true
-- LootRollInfo
L["LootRollInfo"] = true
L["Shows who rolled Need/Greed/DE/Pass on loot frames."] = true
L["Display"] = true
L["Show Tooltips"] = true
L["Show Counters"] = true
L["Counter Size Delta"] = true
L["Class Color Names"] = true
L["Hide Chat Messages"] = true
L["Suppress system loot roll lines from chat."] = true
L["Clear on Cancel"] = true
L["Remove stored roll data when a roll is canceled."] = true
L["Track Minimum Rarity"] = true
-- Missing keys added after runtime warnings
L["Requires /reload to fully apply enabling or disabling."] = true
L["Enable or disable chat bubble texture removal and font styling."] = true
L["PlayerAuraFilter"] = true
L["Enable or disable this module."] = true
L["Automatically confirms selected transmog confirmation popups."] = true
L["Update Interval"] = true
L["Base seconds between tint update batches (lower = more responsive, higher = cheaper)."] = true
