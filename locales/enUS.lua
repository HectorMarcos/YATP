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
L["Show Spark"] = "Show Spark"
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
L["Show Ammo (Hunter only)"] = true
L["Show Ammo"] = true
L["Low Ammo Threshold"] = true
L["Color ammo below threshold"] = true
L["Show Soul Shards (Warlock only)"] = true
L["Show Soul Shards"] = true
L["Hunter"] = true
L["Warlock"] = true
L["Low Shards Threshold"] = true
L["Color shards below threshold"] = true
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
L["Automatically confirms selected transmog confirmation popups and bind-on-pickup loot popups."] = true
L["Automatically confirms transmog and bind-on-pickup loot popups using efficient event-driven method."] = true
L["Automatically confirms selected confirmation popups (transmog)."] = true
L["Transmog"] = true
L["Auto-confirm transmog appearance popups"] = true
L["Instantly confirms transmog appearance collection popups."] = true
L["AdiBags Refresh Delay"] = true
L["Delay (in seconds) before refreshing AdiBags after confirming a transmog. AdiBags must be installed and enabled for this to work."] = true
L["Delay (in seconds) before refreshing AdiBags after confirming a transmog."] = true
L["Loot"] = true
L["Auto-confirm bind-on-pickup loot popups"] = true
L["Automatically confirm popups that appear when looting bind-on-pickup items from world objects."] = true
L["Instantly confirms bind-on-pickup loot using Blizzard API (event-driven, no delays)."] = true
L["Use Fallback Hook Method"] = true
L["Enable hook-based fallback for popups that don't have direct events (recommended)."] = true
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
L["Customize action button hotkey fonts and ability icon tint. Click behavior is handled by the Pressdown module."] = true
L["Customize action button hotkey fonts and ability icon tint using Bartender4-style range checking system."] = true
L["Hotkey Color"] = true
L["Font"] = true -- already defined earlier, reuse
L["Icon Tint"] = true
L["Enable Tint"] = true
L["Out of Range"] = true
L["Out of Range Indicator"] = true
L["Configure how the Out of Range indicator displays on buttons (Bartender4 style)."] = true
L["No Display"] = true
L["Full Button Mode"] = true
L["Hotkey Mode"] = true
L["Hotkey Mode (Not Yet Implemented)"] = true
L["Not Enough Mana"] = true
L["Unusable"] = true
L["Normal"] = true
L["Behavior"] = true
L["Trigger on Key Down"] = true
L["Keyboard Only"] = true
L["Apply 'key down' only if the button has a keyboard binding; mouse clicks stay default (on release)."] = true
L["Fire actions on key press (may reduce perceived input lag)."] = true

-- Pressdown Module  
L["Pressdown"] = true
L["Configure when action buttons trigger (on key press vs key release)."] = true
L["Click Behavior"] = true
L["Enable Pressdown"] = true
L["Makes actions trigger on key press instead of key release."] = true
L["Makes key-bound actions trigger immediately when you press a key down, instead of waiting for key release. This can reduce input lag and make the game feel more responsive."] = true
L["|cffFFD700Note:|r Requires /reload to fully apply enabling or disabling this feature."] = true
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

-- NamePlates Module
L["NamePlates"] = "Ascension NamePlates"
L["Enable NamePlates Integration"] = true
L["Enable integration with Ascension NamePlates addon through YATP"] = true
L["Configure Ascension NamePlates addon integration"] = true

-- Status Tab
L["Addon Status"] = true
L["Status"] = true
L["Loaded"] = true
L["Available (not loaded)"] = true
L["Not Available"] = true
L["Title"] = true
L["Notes"] = true
L["Actions"] = true
L["Load NamePlates Now"] = true
L["Force load Ascension NamePlates immediately. Use this for the first time setup or if auto-load is disabled."] = true
L["Load NamePlates Addon"] = true
L["Attempt to load the Ascension NamePlates addon"] = true
L["Open Original Configuration"] = true
L["Open the original Ascension NamePlates configuration panel in Blizzard options"] = true
L["Settings"] = true
L["Auto-Load on Startup"] = true
L["Automatically load Ascension_NamePlates addon on every UI reload (recommended if you fixed LoadOnDemand issue)"] = true
L["Auto-open Config"] = true
L["Automatically open NamePlates configuration when clicking the YATP integration"] = true
L["Quick Access"] = true
L["The Ascension NamePlates addon provides comprehensive nameplate customization options including health bars, fonts, colors, cast bars, and more."] = true
L["Available Categories"] = true
L["Overall settings and clickable area"] = true
L["Friendly"] = true
L["Settings for friendly unit nameplates"] = true
L["Enemy"] = true
L["Settings for enemy unit nameplates"] = true
L["Personal"] = true
L["Settings for your own nameplate"] = true
L["Diagnostics"] = true
L["Check for Conflicts"] = true
L["Scan for other nameplate addons that might conflict with Ascension NamePlates (Plater, TidyPlates, etc)"] = true
L["Troubleshooting"] = true

-- Embedded NamePlates Configuration
L["Embedded Configuration"] = true
L["Load the NamePlates addon to access embedded configuration options here."] = true
L["General Settings"] = true
L["Classic Style"] = true
L["Use classic style textures for nameplates"] = true
L["Target Scale"] = true
L["Sets the scale of the NamePlate when it is the target"] = true
L["Clickable Area"] = true
L["Clickable Width"] = true
L["Controls the clickable area width of the NamePlate"] = true
L["Clickable Height"] = true
L["Controls the clickable area height of the NamePlate"] = true
L["Show Clickable Box"] = true
L["Draw a white box over the clickable area on all NamePlates"] = true
L["Friendly Units"] = true
L["Name Only (Friendly)"] = true
L["Only show the name on friendly nameplates (no health bar)"] = true
L["Health Bar Width (Friendly)"] = true
L["Sets the width of friendly nameplate health bars"] = true
L["Health Bar Height (Friendly)"] = true
L["Sets the height of friendly nameplate health bars"] = true
L["Show Health Text (Friendly)"] = true
L["Show health text on friendly nameplates"] = true
L["Enemy Units"] = true
L["Health Bar Width (Enemy)"] = true
L["Sets the width of enemy nameplate health bars"] = true
L["Health Bar Height (Enemy)"] = true
L["Sets the height of enemy nameplate health bars"] = true
L["Show Health Text (Enemy)"] = true
L["Show health text on enemy nameplates"] = true
L["Enemy Cast Bars"] = true
L["Show cast bars on enemy nameplates"] = true
L["Cast Bar Height"] = true
L["Height of enemy cast bars"] = true
L["Personal Nameplate"] = true
L["Health Bar Width (Personal)"] = true
L["Sets the width of your personal nameplate health bar"] = true
L["Health Bar Height (Personal)"] = true
L["Sets the height of your personal nameplate health bar"] = true
L["Show Health Text (Personal)"] = true
L["Show health text on your personal nameplate"] = true
L["Advanced"] = true
L["Open Complete Configuration"] = true
L["Open the original addon configuration for access to all advanced options"] = true
L["The options above cover the most commonly used settings. For advanced features like fonts, colors, quest icons, and level indicators, use the complete configuration panel."] = true

-- NamePlates Tab System
L["Addon status and basic controls"] = true
L["General nameplate settings"] = true
L["Information about NamePlates configuration"] = true
L["Configuration Tabs"] = true
L["Once the Ascension NamePlates addon is loaded, additional configuration tabs will appear here:"] = true
L["Load the addon using the Status tab to unlock these configuration options."] = true
L["Information"] = true
L["The NamePlates addon is loaded and configured. Use the tabs above to access different configuration categories."] = true
L["Load the NamePlates addon to unlock configuration tabs with embedded settings for General, Friendly, Enemy, and Personal nameplates."] = true
L["Configure general nameplate appearance and behavior settings."] = true
L["Style"] = true

-- Global Health Bar Texture
L["Global Health Bar Texture"] = true
L["Override the health bar texture for ALL nameplates (friendly, enemy, and personal). This ensures consistent texture across all nameplate types, including targets."] = true
L["Enable Global Health Bar Texture"] = true
L["Apply the same health bar texture to all nameplate types"] = true
L["Health Bar Texture"] = true
L["Texture to use for all health bars"] = true

-- Mouseover Glow Configuration
L["These settings control the invisible clickable area of nameplates. This does not affect the visual appearance of health bars."] = true
L["Configure nameplate settings for friendly units (party members, guild members, etc.)."] = true
L["Display Options"] = true
L["Name Only"] = true
L["Configure nameplate settings for enemy units and hostile NPCs."] = true
L["Enable Cast Bars"] = true
L["Configure your own personal nameplate that appears above your character."] = true

-- Enemy Target Tab
L["Enemy Target"] = true
L["Settings for targeted enemy nameplates"] = true
L["Configure nameplate settings for enemy units that you have targeted. This includes the official Target Scale option and custom Target Border enhancements."] = true
L["Target Scaling"] = true
L["Sets the scale of the NamePlate when it is the target. This affects ALL targeted nameplates (friendly and enemy)."] = true
L["Information"] = true
L["This is the official setting for targeted nameplates from the NamePlates addon. It makes the nameplate larger when you target an enemy."] = true

-- Target Border System
L["Target Border (YATP Custom)"] = true
L["Enable Target Border"] = true
L["Add a colored border around the nameplate of your current target for better visibility"] = true
L["Border Color"] = true
L["Color of the target border effect"] = true
L["Border Thickness"] = true
L["Thickness of the border in pixels. Higher values create a thicker border"] = true
L["Static (No Animation)"] = true
L["Pulse (Fade In/Out)"] = true
L["Breathe (Scale In/Out)"] = true

-- Threat System
L["Threat System (YATP Custom)"] = true
L["Enable Threat System"] = true
L["Color nameplates based on your threat level with that enemy"] = true
L["Threat Display Method"] = true
L["How threat levels are displayed on nameplates"] = true
L["Name Color"] = true
L["Health Bar Color"] = true
L["Border Color"] = true
L["Threat Colors"] = true
L["Configure colors for different threat levels"] = true
L["No Threat"] = true
L["Color when you have no threat"] = true
L["Low Threat"] = true
L["Color when you have low threat"] = true
L["Medium Threat"] = true
L["Color when you have medium threat"] = true
L["High Threat"] = true
L["Color when you have high threat"] = true
L["Tanking"] = true
L["Color when you have aggro"] = true

L["Additional Enemy Options"] = true
L["For more enemy nameplate customization options, visit the"] = true
L["Enemy"] = true
L["tab. There you can configure:"] = true
L["Health bar appearance and size"] = true
L["Name display and fonts"] = true
L["Cast bar settings"] = true
L["Level indicators"] = true
L["Quest objective icons"] = true
L["All these settings apply to enemy nameplates, including when they are targeted."] = true

-- Missing localizations for nameplate tabs
L["Health Bar"] = true
L["Show Health Text"] = true
L["Cast Bar"] = true

-- Health Text Positioning
L["Health Text Positioning"] = true
L["Customize the position of the health text displayed on nameplates. The default position is centered with a 1 pixel offset upward."] = true
L["Enable Custom Health Text Position"] = true
L["Enable custom positioning for health text on all nameplates"] = true
L["Horizontal Offset (X)"] = true
L["Horizontal offset from center. Negative values move left, positive values move right. Default: 0"] = true
L["Vertical Offset (Y)"] = true
L["Vertical offset from center. Negative values move down, positive values move up. Default: 1"] = true
L["Reset to Default"] = true
L["Reset health text position to default values (X: 0, Y: 1)"] = true

-- Non-Target Alpha Fade System
L["Non-Target Alpha Fade (YATP Custom)"] = true
L["Fade out nameplates that are not your current target. This helps you focus on your target by dimming other enemy nameplates. Only active when you have a target selected - when no target exists, all nameplates remain at full opacity."] = true
L["Enable Non-Target Alpha Fade"] = true
L["Reduce the opacity of enemy nameplates that are not your current target. Only applies when you have a target selected."] = true
L["Non-Target Alpha"] = true
L["Transparency level for non-target nameplates. 0.0 = fully transparent (invisible), 1.0 = fully opaque (no fade). Only applies when you have a target selected."] = true

-- Error messages
L["Cannot enable NamePlates Integration:"] = true
L["Ascension NamePlates addon is not loaded. Please load it first using the button below."] = true

-- Quest Tracker Module
L["QuestTracker"] = "Quest Tracker"
L["Quest Tracker"] = true
L["Enable or disable the Quest Tracker module."] = true
L["Display Options"] = true
L["Enhanced Display"] = true
L["Enable enhanced quest tracker display features."] = true
L["Show Quest Levels"] = true
L["Display quest levels in the tracker."] = true
L["Show Progress Percentage"] = true
L["Display completion percentages for quest objectives."] = true
L["Compact Mode"] = true
L["Use a more compact display for quest information."] = true
L["Color Code by Difficulty"] = true
L["Color quest titles based on difficulty level."] = true
L["Indent Objectives"] = true
L["Remove dash from objectives and add indentation for cleaner look."] = true
L["Quest Difficulty Colors"] = true
L["!! RED: 5+ above (Very Hard) | ! ORANGE: 3-4 above (Hard) | YELLOW: ±2 levels (Appropriate) | GREEN: 3-10 below (Easy) | ~ GRAY: 11+ below (No XP)"] = true
L["Symbols (!! ! ~) added for colorblind accessibility"] = true
L["Visual Settings"] = true
L["Tracker Scale"] = true
L["Adjust the size of the quest tracker."] = true
L["Tracker Transparency"] = true
L["Adjust the transparency of the quest tracker."] = true
L["Lock Position"] = true
L["Prevent the quest tracker from being moved."] = true
L["Text Outline"] = true
L["Add outline to quest tracker text for better readability."] = true
L["Clean Quest Tracker"] = true
L["Use /qtclean to remove all quest levels"] = true
L["Fix Quest Tracker"] = true
L["Use /qtfix to clean duplicates and reapply settings"] = true
L["Debug Quest Tracker"] = true
L["Use /qtdebug to see quest tracker debug information"] = true
L["Outline Thickness"] = true
L["Choose the thickness of the text outline."] = true
L["Normal"] = true
L["Thick"] = true
L["Custom Width"] = true
L["Enable custom width for the quest tracker frame."] = true
L["Frame Width"] = true
L["Set the width of the quest tracker frame in pixels."] = true
L["Notifications"] = true
L["Progress Notifications"] = true
L["Show notifications for quest progress updates."] = true
L["Completion Sound"] = true
L["Play a sound when quests are completed."] = true
L["Objective Complete Alert"] = true
L["Show alerts when individual objectives are completed."] = true
L["Auto-tracking"] = true
L["Auto-track New Quests"] = true
L["Automatically track newly accepted quests."] = true
L["Auto-untrack Complete"] = true
L["Automatically untrack completed quests. Works with both 'Force Track All' and 'Auto-track by Zone' modes."] = true
L["Max Tracked Quests"] = true
L["Maximum number of quests to track simultaneously."] = true
L["Force Track All Quests"] = true
L["Automatically track all quests in your quest log. Disables zone-based tracking."] = true
L["Auto-track by Zone"] = true
L["Automatically track quests for your current zone only. Always tracks Ascension Main Quest and Path to Ascension categories. Disables force tracking."] = true
L["Filter by Zone"] = true
L["Only show quests for the current zone."] = true
L["Quest Sorting"] = true
L["Custom Quest Sorting"] = true
L["Enable custom sorting of tracked quests."] = true
L["Sort by Level"] = true
L["Sort quests by their level."] = true
L["Sort by Zone"] = true
L["Sort quests by their zone."] = true
L["Sort by Distance"] = true
L["Sort quests by distance to objectives."] = true
L["Sort quests by level with completed quests at the bottom."] = true
L["Only show quests for the current zone."] = true
L["Visual Settings"] = true
L["Tracker Scale"] = true
L["Adjust the size of the quest tracker."] = true
L["Tracker Transparency"] = true
L["Adjust the transparency of the quest tracker."] = true
L["Lock Position"] = true
L["Prevent the quest tracker from being moved."] = true
L["Text Outline"] = true
L["Add outline to quest tracker text for better readability."] = true
L["Outline Thickness"] = true
L["Choose the thickness of the text outline."] = true
L["Thick"] = true
L["Custom Width"] = true
L["Enable custom width for the quest tracker frame."] = true
L["Frame Width"] = true
L["Set the width of the quest tracker frame in pixels."] = true
L["Notifications"] = true
L["Progress Notifications"] = true
L["Show notifications for quest progress updates."] = true
L["Completion Sound"] = true
L["Play a sound when quests are completed."] = true
L["Objective Complete Alert"] = true
L["Show alerts when individual objectives are completed."] = true
L["Display quest levels in the tracker."] = true
L["Color quest titles based on difficulty level."] = true
L["Indent Objectives"] = true
L["Remove dash from objectives and add indentation for cleaner look."] = true
L["Custom Height"] = true
L["Enable custom height for the quest tracker frame."] = true
L["Frame Height"] = true
L["Set the height of the quest tracker frame in pixels."] = true
L["Hide Background"] = true
L["Hide the quest tracker background and border artwork."] = true

L["Lock the quest tracker in place. When disabled, you can drag the tracker to move it around."] = true
L["This module enhances the quest tracker with additional features and customization options."] = true

-- New simplified quest tracker texts
L["Tracking"] = true
L["All Quests"] = true
L["By Zone"] = true
