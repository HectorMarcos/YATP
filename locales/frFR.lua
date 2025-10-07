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
	["Aggressive Scan"] = "Aggressive Scan",
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
