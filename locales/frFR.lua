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
for k,v in pairs(base) do
	if not L[k] then L[k] = v end
end
--========================================================--
-- YATP - Français (Fallback)
--========================================================--
local L = LibStub("AceLocale-3.0"):NewLocale("YATP", "frFR")
if not L then return end

-- Using English fallback strings (can be translated later)
L["Reset Position"] = "Reset Position"
L["Reset the bar position to its default location"] = "Reset the bar position to its default location"
L["Debug Position"] = "Debug Position"
L["Print coordinates to chat when position changes"] = "Print coordinates to chat when position changes"
