local L = LibStub("AceLocale-3.0"):NewLocale("YATP", "frFR")
if not L then return end

-- Base fallback (still mostly English until translated)
local base = {
	["A modular collection of interface tweaks and utilities."] = "A modular collection of interface tweaks and utilities.",
	["About"] = "About",
	["Author"] = "Author",
	["Version"] = "Version",
	["Interface"] = "Interface",
	["Quality of Life"] = "Quality of Life",
	["QualityOfLife"] = "Quality of Life",
	["Select a category tab to configure modules."] = "Select a category tab to configure modules.",
	["No modules in this category yet."] = "No modules in this category yet.",
	["XPRepBar"] = "XP & Reputation",
	["XP Bar"] = "XP Bar",
	["Lock bar"] = "Lock bar",
	["Width"] = "Width",
	["Height"] = "Height",
	["Position"] = "Position",
	["Position X"] = "Position X",
	["Position Y"] = "Position Y",
	["Show Ticks"] = "Show Ticks",
	["Bar Texture"] = "Bar Texture",
	["Show text only on mouseover"] = "Show text only on mouseover",
	["If enabled, the XP text will only show when hovering the bar."] = "If enabled, the XP text will only show when hovering the bar.",
}
for k,v in pairs(base) do if not L[k] then L[k] = v end end

-- ChatBubbles fallback additions
local extra = {
	["ChatBubbles"] = "ChatBubbles",
	["Enable"] = "Enable",
	["Font Face"] = "Font Face",
	["Outline"] = "Outline",
	["Utilities"] = "Utilities",
	["Force Refresh"] = "Force Refresh",
	["Advanced"] = "Advanced",
	["Scan Interval"] = "Scan Interval",
	["Post-detection Sweeps"] = "Post-detection Sweeps",
	["Continuously sweep world frames to strip bubble textures ASAP (slightly higher CPU)."] = "Continuously sweep world frames to strip bubble textures ASAP (slightly higher CPU).",
	["Seconds between sweeps in aggressive mode."] = "Seconds between sweeps in aggressive mode.",
	["Extra quick sweeps right after detecting a bubble."] = "Extra quick sweeps right after detecting a bubble.",
}
for k,v in pairs(extra) do if not L[k] then L[k] = v end end
if not L["Toggle the ChatBubbles module. Removes bubble artwork and restyles the text using your chosen font settings."] then L["Toggle the ChatBubbles module. Removes bubble artwork and restyles the text using your chosen font settings."] = "Toggle the ChatBubbles module. Removes bubble artwork and restyles the text using your chosen font settings." end

-- Using English fallback strings (can be translated later)
L["Reset Position"] = "Reset Position"
L["Reset the bar position to its default location"] = "Reset the bar position to its default location"
L["Debug Position"] = "Debug Position"
L["Print coordinates to chat when position changes"] = "Print coordinates to chat when position changes"
L["Hide Chat Bubbles"] = "Masquer les bulles de chat"
-- PlayerAuras
L["PlayerAuras"] = "AurasJoueur"
L["Enable PlayerAuras"] = "Activer PlayerAuras"
L["Manage Buffs"] = "Gérer les Buffs"
L["Manage Debuffs"] = "Gérer les Debuffs"
L["Throttle"] = "Fréquence"
L["Seconds between refresh attempts when changes occur."] = "Secondes entre tentatives de rafraîchissement lors de changements."
L["Layout"] = "Disposition"
L["Debuffs per Row"] = "Debuffs par ligne"
L["Grow Direction"] = "Direction de croissance"
L["Sort Mode"] = "Mode de tri"
L["Alphabetical"] = "Alphabétique"
L["Original"] = "Original"
L["Duration Text"] = "Texte de durée"
L["Font Size"] = "Taille de police"
L["Outline"] = "Contour"
L["Font"] = "Police"
L["Buff Filters"] = "Filtres de Buffs"
L["Hide this buff when active."] = "Masque ce buff lorsqu'il est actif."
L["Reset List"] = "Réinitialiser liste"
L["Restore default known buffs list."] = "Restaure la liste de buffs par défaut."
L["Left"] = "Gauche"
L["Right"] = "Droite"
L["Game Default"] = "Police du jeu"
L["PlayerAuras Filters"] = "PlayerAuras - Filtres"
L["PlayerAurasFilters"] = "PlayerAuras - Filtres"
L["Filters"] = "Filtres"
L["Search"] = "Recherche"
L["Filter the list by substring (case-insensitive)."] = "Filtre la liste par sous-chaîne (insensible à la casse)."
L["Toggles"] = "Commutateurs"
L["BronzeBeard Buffs"] = "Buffs BronzeBeard"
L["Custom Buffs"] = "Buffs Personnalisés"
L["Add Buff"] = "Ajouter Buff"
L["Add"] = "Ajouter"
L["Enter the exact buff name to add it to the list and toggle hide/show."] = "Entrez le nom exact du buff pour l'ajouter et pouvoir le masquer/afficher."
L["Hide"] = "Masquer"
L["Remove"] = "Retirer"
L["Remove this custom buff from the list."] = "Retire ce buff personnalisé de la liste."
L["Custom Added Buffs"] = "Buffs Personnalisés Ajoutés"
-- Interface Hub
L["Interface Hub"] = "Hub d'Interface"
L["Use the dropdown below to select a module."] = "Utilisez la liste déroulante ci-dessous pour sélectionner un module."
L["Select a module from the list on the left."] = "Sélectionnez un module dans la liste à gauche."
L["Select Module"] = "Sélectionner Module"
L["Reload UI"] = "Recharger UI"
L["Module Options"] = "Options du Module"
L["No module selected."] = "Aucun module sélectionné."
L["Modules"] = "Modules"
L["Enable or disable the PlayerAuras module (all features)."] = "Active ou désactive le module PlayerAuras (toutes ses fonctions)."
L["If enabled, PlayerAuras filters and repositions your buffs (hiding those you mark)."] = "Si activé, PlayerAuras filtre et repositionne vos buffs (masque ceux que vous marquez)."
L["If enabled, PlayerAuras repositions your debuffs applying the same scaling and sorting."] = "Si activé, PlayerAuras repositionne vos debuffs en appliquant le même redimensionnement et tri."
-- InfoBar (fallback)
if not L["Info Bar"] then L["Info Bar"] = "Info Bar" end
if not L["Enable Module"] then L["Enable Module"] = "Enable Module" end
if not L["Lock Frame"] then L["Lock Frame"] = "Lock Frame" end
if not L["Update Interval (seconds)"] then L["Update Interval (seconds)"] = "Update Interval (seconds)" end
if not L["Metrics"] then L["Metrics"] = "Metrics" end
if not L["Show FPS"] then L["Show FPS"] = "Show FPS" end
if not L["Show Ping"] then L["Show Ping"] = "Show Ping" end
if not L["Show Durability"] then L["Show Durability"] = "Show Durability" end
if not L["Low Durability Threshold"] then L["Low Durability Threshold"] = "Low Durability Threshold" end
if not L["Only color durability below threshold"] then L["Only color durability below threshold"] = "Only color durability below threshold" end
if not L["Appearance"] then L["Appearance"] = "Appearance" end
if not L["Font Color"] then L["Font Color"] = "Font Color" end
if not L["Show Background"] then L["Show Background"] = "Show Background" end
if not L["Durability"] then L["Durability"] = "Durability" end
if not L["None"] then L["None"] = "None" end
if not L["Thick Outline"] then L["Thick Outline"] = "Thick Outline" end
if not L["InfoBar"] then L["InfoBar"] = "Info Bar" end
-- QuickConfirm (fallbacks)
if not L["QuickConfirm"] then L["QuickConfirm"] = "QuickConfirm" end
if not L["Automatically confirms selected confirmation popups (transmog)."] then L["Automatically confirms selected confirmation popups (transmog)."] = "Automatically confirms selected confirmation popups (transmog)." end
if not L["Transmog"] then L["Transmog"] = "Transmog" end
if not L["Auto-confirm transmog appearance popups"] then L["Auto-confirm transmog appearance popups"] = "Auto-confirm transmog appearance popups" end
if not L["AdiBags Refresh Delay"] then L["AdiBags Refresh Delay"] = "AdiBags Refresh Delay" end
if not L["Delay (in seconds) before refreshing AdiBags after confirming a transmog. AdiBags must be installed and enabled for this to work."] then L["Delay (in seconds) before refreshing AdiBags after confirming a transmog. AdiBags must be installed and enabled for this to work."] = "Delay (in seconds) before refreshing AdiBags after confirming a transmog. AdiBags must be installed and enabled for this to work." end
if not L["Miscellaneous"] then L["Miscellaneous"] = "Miscellaneous" end
if not L["Suppress click sound"] then L["Suppress click sound"] = "Suppress click sound" end
if not L["Scan Interval"] then L["Scan Interval"] = "Scan Interval" end
if not L["Debug"] then L["Debug"] = "Debug" end
if not L["Debug Messages"] then L["Debug Messages"] = "Debug Messages" end
if not L["Hotkey Color"] then L["Hotkey Color"] = "Hotkey Color" end
if not L["Fire actions on key press (may reduce perceived input lag)."] then L["Fire actions on key press (may reduce perceived input lag)."] = "Fire actions on key press (may reduce perceived input lag)." end
-- Removed exit/logout QuickConfirm keys (scope narrowed to transmog)
-- Extras / Fixes (fallback)
if not L["Extras"] then L["Extras"] = "Extras" end
if not L["Miscellaneous small toggles and fixes."] then L["Miscellaneous small toggles and fixes."] = "Miscellaneous small toggles and fixes." end
if not L["Fixes"] then L["Fixes"] = "Fixes" end
if not L["WAAdiFixes"] then L["WAAdiFixes"] = "WA/Adi Fixes" end
if not L["(Migrated from 'Fixes' module name)"] then L["(Migrated from 'Fixes' module name)"] = "(Migrated from 'Fixes' module name)" end
if not L["Enable Resize API Fix"] then L["Enable Resize API Fix"] = "Enable Resize API Fix" end
if not L["Prevents SetResizeBounds/SetMaxResize errors injected by modern addons."] then L["Prevents SetResizeBounds/SetMaxResize errors injected by modern addons."] = "Prevents SetResizeBounds/SetMaxResize errors injected by modern addons." end
if not L["Various small compatibility toggles."] then L["Various small compatibility toggles."] = "Various small compatibility toggles." end
if not L["Compatibility Fixes"] then L["Compatibility Fixes"] = "Compatibility Fixes" end
if not L["WeakAuras / AdiBags"] then L["WeakAuras / AdiBags"] = "WeakAuras / AdiBags" end
if not L["Resize Bounds Patch"] then L["Resize Bounds Patch"] = "Resize Bounds Patch" end
if not L["Prevents errors when modern WeakAuras code calls SetResizeBounds on legacy client frames."] then L["Prevents errors when modern WeakAuras code calls SetResizeBounds on legacy client frames."] = "Prevents errors when modern WeakAuras code calls SetResizeBounds on legacy client frames." end
if not L["You can add more inline groups here for future fixes."] then L["You can add more inline groups here for future fixes."] = "You can add more inline groups here for future fixes." end
-- LootRollInfo (fallback EN for now)
if not L["LootRollInfo"] then L["LootRollInfo"] = "LootRollInfo" end
if not L["Shows who rolled Need/Greed/DE/Pass on loot frames."] then L["Shows who rolled Need/Greed/DE/Pass on loot frames."] = "Shows who rolled Need/Greed/DE/Pass on loot frames." end
if not L["Display"] then L["Display"] = "Display" end
if not L["Show Tooltips"] then L["Show Tooltips"] = "Show Tooltips" end
if not L["Show Counters"] then L["Show Counters"] = "Show Counters" end
if not L["Counter Size Delta"] then L["Counter Size Delta"] = "Counter Size Delta" end
if not L["Class Color Names"] then L["Class Color Names"] = "Class Color Names" end
if not L["Hide Chat Messages"] then L["Hide Chat Messages"] = "Hide Chat Messages" end
if not L["Suppress system loot roll lines from chat."] then L["Suppress system loot roll lines from chat."] = "Suppress system loot roll lines from chat." end
if not L["Clear on Cancel"] then L["Clear on Cancel"] = "Clear on Cancel" end
if not L["Remove stored roll data when a roll is canceled."] then L["Remove stored roll data when a roll is canceled."] = "Remove stored roll data when a roll is canceled." end
if not L["Track Minimum Rarity"] then L["Track Minimum Rarity"] = "Track Minimum Rarity" end
-- Hotkeys (fallback English)
if not L["Hotkeys"] then L["Hotkeys"] = "Hotkeys" end
if not L["Customize action button hotkey fonts and ability icon tint."] then L["Customize action button hotkey fonts and ability icon tint."] = "Customize action button hotkey fonts and ability icon tint." end
if not L["Icon Tint"] then L["Icon Tint"] = "Icon Tint" end
if not L["Enable Tint"] then L["Enable Tint"] = "Enable Tint" end
if not L["Out of Range"] then L["Out of Range"] = "Out of Range" end
if not L["Not Enough Mana"] then L["Not Enough Mana"] = "Not Enough Mana" end
if not L["Unusable"] then L["Unusable"] = "Unusable" end
if not L["Normal"] then L["Normal"] = "Normal" end
if not L["Behavior"] then L["Behavior"] = "Behavior" end
if not L["Trigger on Key Down"] then L["Trigger on Key Down"] = "Trigger on Key Down" end
if not L["Keyboard Only"] then L["Keyboard Only"] = "Keyboard Only" end
if not L["Apply 'key down' only if the button has a keyboard binding; mouse clicks stay default (on release)."] then L["Apply 'key down' only if the button has a keyboard binding; mouse clicks stay default (on release)."] = "Apply 'key down' only if the button has a keyboard binding; mouse clicks stay default (on release)." end

-- NamePlates Module (fallback English)
if not L["NamePlates"] then L["NamePlates"] = "Ascension NamePlates" end
if not L["Enable NamePlates Integration"] then L["Enable NamePlates Integration"] = "Enable NamePlates Integration" end
if not L["Enable integration with Ascension NamePlates addon through YATP"] then L["Enable integration with Ascension NamePlates addon through YATP"] = "Enable integration with Ascension NamePlates addon through YATP" end
if not L["Addon Status"] then L["Addon Status"] = "Addon Status" end
if not L["Status"] then L["Status"] = "Status" end
if not L["Loaded"] then L["Loaded"] = "Loaded" end
if not L["Available (not loaded)"] then L["Available (not loaded)"] = "Available (not loaded)" end
if not L["Not Available"] then L["Not Available"] = "Not Available" end
if not L["Title"] then L["Title"] = "Title" end
if not L["Notes"] then L["Notes"] = "Notes" end
if not L["Actions"] then L["Actions"] = "Actions" end
if not L["Load NamePlates Addon"] then L["Load NamePlates Addon"] = "Load NamePlates Addon" end
if not L["Attempt to load the Ascension NamePlates addon"] then L["Attempt to load the Ascension NamePlates addon"] = "Attempt to load the Ascension NamePlates addon" end
if not L["Open Original Configuration"] then L["Open Original Configuration"] = "Open Original Configuration" end
if not L["Open the original configuration panel for Ascension NamePlates"] then L["Open the original configuration panel for Ascension NamePlates"] = "Open the original configuration panel for Ascension NamePlates" end
if not L["Information"] then L["Information"] = "Information" end
if not L["The NamePlates addon is loaded and configured. Use the tabs above to access different configuration categories."] then L["The NamePlates addon is loaded and configured. Use the tabs above to access different configuration categories."] = "The NamePlates addon is loaded and configured. Use the tabs above to access different configuration categories." end
if not L["Load the NamePlates addon to unlock configuration tabs with embedded settings for General, Friendly, Enemy, and Personal nameplates."] then L["Load the NamePlates addon to unlock configuration tabs with embedded settings for General, Friendly, Enemy, and Personal nameplates."] = "Load the NamePlates addon to unlock configuration tabs with embedded settings for General, Friendly, Enemy, and Personal nameplates." end
if not L["Addon status and basic controls"] then L["Addon status and basic controls"] = "Addon status and basic controls" end
if not L["General nameplate settings"] then L["General nameplate settings"] = "General nameplate settings" end
if not L["Settings for targeted enemy nameplates"] then L["Settings for targeted enemy nameplates"] = "Settings for targeted enemy nameplates" end

-- Global Health Bar Texture
if not L["Global Health Bar Texture"] then L["Global Health Bar Texture"] = "Global Health Bar Texture" end
if not L["Override the health bar texture for ALL nameplates (friendly, enemy, and personal). This ensures consistent texture across all nameplate types, including targets."] then L["Override the health bar texture for ALL nameplates (friendly, enemy, and personal). This ensures consistent texture across all nameplate types, including targets."] = "Override the health bar texture for ALL nameplates (friendly, enemy, and personal). This ensures consistent texture across all nameplate types, including targets." end
if not L["Enable Global Health Bar Texture"] then L["Enable Global Health Bar Texture"] = "Enable Global Health Bar Texture" end
if not L["Apply the same health bar texture to all nameplate types"] then L["Apply the same health bar texture to all nameplate types"] = "Apply the same health bar texture to all nameplate types" end
if not L["Health Bar Texture"] then L["Health Bar Texture"] = "Health Bar Texture" end
if not L["Texture to use for all health bars"] then L["Texture to use for all health bars"] = "Texture to use for all health bars" end

-- Target Border System
if not L["Target Border (YATP Custom)"] then L["Target Border (YATP Custom)"] = "Target Border (YATP Custom)" end
if not L["Enable Target Border"] then L["Enable Target Border"] = "Enable Target Border" end
if not L["Add a colored border around the nameplate of your current target for better visibility"] then L["Add a colored border around the nameplate of your current target for better visibility"] = "Add a colored border around the nameplate of your current target for better visibility" end
if not L["Border Color"] then L["Border Color"] = "Border Color" end
if not L["Color of the target border effect"] then L["Color of the target border effect"] = "Color of the target border effect" end
if not L["Border Thickness"] then L["Border Thickness"] = "Border Thickness" end
if not L["Thickness of the border in pixels. Higher values create a thicker border"] then L["Thickness of the border in pixels. Higher values create a thicker border"] = "Thickness of the border in pixels. Higher values create a thicker border" end

-- Threat System
if not L["Threat System (YATP Custom)"] then L["Threat System (YATP Custom)"] = "Threat System (YATP Custom)" end
if not L["Enable Threat System"] then L["Enable Threat System"] = "Enable Threat System" end
if not L["Color nameplates based on your threat level with that enemy"] then L["Color nameplates based on your threat level with that enemy"] = "Color nameplates based on your threat level with that enemy" end
if not L["Threat Colors"] then L["Threat Colors"] = "Threat Colors" end
if not L["Configure colors for different threat levels"] then L["Configure colors for different threat levels"] = "Configure colors for different threat levels" end
if not L["Low Threat"] then L["Low Threat"] = "Low Threat" end
if not L["Color when you have low threat"] then L["Color when you have low threat"] = "Color when you have low threat" end
if not L["Medium Threat"] then L["Medium Threat"] = "Medium Threat" end
if not L["Color when you have medium threat"] then L["Color when you have medium threat"] = "Color when you have medium threat" end
if not L["High Threat"] then L["High Threat"] = "High Threat" end
if not L["Color when you have high threat"] then L["Color when you have high threat"] = "Color when you have high threat" end
if not L["Tanking"] then L["Tanking"] = "Tanking" end
if not L["Color when you have aggro"] then L["Color when you have aggro"] = "Color when you have aggro" end

if not L["Additional Enemy Options"] then L["Additional Enemy Options"] = "Additional Enemy Options" end
if not L["For more enemy nameplate customization options, visit the"] then L["For more enemy nameplate customization options, visit the"] = "For more enemy nameplate customization options, visit the" end
if not L["Enemy"] then L["Enemy"] = "Enemy" end
if not L["tab. There you can configure:"] then L["tab. There you can configure:"] = "tab. There you can configure:" end
if not L["Health bar appearance and size"] then L["Health bar appearance and size"] = "Health bar appearance and size" end
if not L["Name display and fonts"] then L["Name display and fonts"] = "Name display and fonts" end
if not L["Cast bar settings"] then L["Cast bar settings"] = "Cast bar settings" end
if not L["Level indicators"] then L["Level indicators"] = "Level indicators" end
if not L["Quest objective icons"] then L["Quest objective icons"] = "Quest objective icons" end
if not L["All these settings apply to enemy nameplates, including when they are targeted."] then L["All these settings apply to enemy nameplates, including when they are targeted."] = "All these settings apply to enemy nameplates, including when they are targeted." end

-- Health Text Positioning
if not L["Health Text Positioning"] then L["Health Text Positioning"] = "Health Text Positioning" end
if not L["Customize the position of the health text displayed on nameplates. The default position is centered with a 1 pixel offset upward."] then L["Customize the position of the health text displayed on nameplates. The default position is centered with a 1 pixel offset upward."] = "Customize the position of the health text displayed on nameplates. The default position is centered with a 1 pixel offset upward." end
if not L["Enable Custom Health Text Position"] then L["Enable Custom Health Text Position"] = "Enable Custom Health Text Position" end
if not L["Enable custom positioning for health text on all nameplates"] then L["Enable custom positioning for health text on all nameplates"] = "Enable custom positioning for health text on all nameplates" end
if not L["Horizontal Offset (X)"] then L["Horizontal Offset (X)"] = "Horizontal Offset (X)" end
if not L["Horizontal offset from center. Negative values move left, positive values move right. Default: 0"] then L["Horizontal offset from center. Negative values move left, positive values move right. Default: 0"] = "Horizontal offset from center. Negative values move left, positive values move right. Default: 0" end
if not L["Vertical Offset (Y)"] then L["Vertical Offset (Y)"] = "Vertical Offset (Y)" end
if not L["Vertical offset from center. Negative values move down, positive values move up. Default: 1"] then L["Vertical offset from center. Negative values move down, positive values move up. Default: 1"] = "Vertical offset from center. Negative values move down, positive values move up. Default: 1" end
if not L["Reset to Default"] then L["Reset to Default"] = "Reset to Default" end
if not L["Reset health text position to default values (X: 0, Y: 1)"] then L["Reset health text position to default values (X: 0, Y: 1)"] = "Reset health text position to default values (X: 0, Y: 1)" end

-- Additional missing keys
if not L["General"] then L["General"] = "General" end
if not L["Enemy Target"] then L["Enemy Target"] = "Enemy Target" end
if not L["Configure general nameplate appearance and behavior settings."] then L["Configure general nameplate appearance and behavior settings."] = "Configure general nameplate appearance and behavior settings." end
if not L["Configure custom Target Border enhancements for enemy units that you have targeted."] then L["Configure custom Target Border enhancements for enemy units that you have targeted."] = "Configure custom Target Border enhancements for enemy units that you have targeted." end

-- Error messages
if not L["Cannot enable NamePlates Integration:"] then L["Cannot enable NamePlates Integration:"] = "Cannot enable NamePlates Integration:" end
if not L["Ascension NamePlates addon is not loaded. Please load it first using the button below."] then L["Ascension NamePlates addon is not loaded. Please load it first using the button below."] = "Ascension NamePlates addon is not loaded. Please load it first using the button below." end
