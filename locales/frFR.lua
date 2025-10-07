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
if not L["Toggle the ChatBubbles module. Removes bubble artwork and restyles the text using your chosen font settings."] then
	L["Toggle the ChatBubbles module. Removes bubble artwork and restyles the text using your chosen font settings."] = "Toggle the ChatBubbles module. Removes bubble artwork and restyles the text using your chosen font settings."
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
L["Hide Chat Bubbles"] = "Masquer les bulles de chat"
