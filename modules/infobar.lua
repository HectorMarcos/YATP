--========================================================--
-- YATP - InfoBar Module (Quality of Life)
--========================================================--
local L   = LibStub("AceLocale-3.0"):GetLocale("YATP", true) or setmetatable({}, { __index=function(_,k) return k end })
local LSM = LibStub("LibSharedMedia-3.0", true)
local YATP = LibStub("AceAddon-3.0"):GetAddon("YATP", true)
if not YATP then
    print("YATP not found, aborting InfoBar module")
    return
end

local Module = YATP:NewModule("InfoBar", "AceConsole-3.0")

-------------------------------------------------
-- Defaults
-------------------------------------------------
Module.defaults = {
    enabled = true,
    font = "Friz Quadrata TT",
    fontSize = 12,
    fontOutline = "OUTLINE",
    fontColor = { r=1, g=1, b=1 },
    background = true,
    locked = true,
    point = "TOP",
    relPoint = "TOP",
    posX = 0,
    posY = -10,
    showFPS = true,
    showPing = true,
    showDurability = true,
    lowDurThreshold = 25,
    colorizeLowDurability = true,
    updateInterval = 1,
}

-------------------------------------------------
-- Initialization
-------------------------------------------------
function Module:OnInitialize()
    if not YATP.db.profile.modules then YATP.db.profile.modules = {} end
    if not YATP.db.profile.modules.InfoBar then
        YATP.db.profile.modules.InfoBar = CopyTable(self.defaults)
    end
    self.db = YATP.db.profile.modules.InfoBar

    -- Migration for older versions missing point/relPoint
    if not self.db.point then self.db.point = self.defaults.point end
    if not self.db.relPoint then self.db.relPoint = self.defaults.relPoint end

    self:RegisterChatCommand("infobar", function() self:OpenConfig() end)

    if YATP.AddModuleOptions then
        YATP:AddModuleOptions("InfoBar", self:BuildOptions(), "QualityOfLife")
    end
end

function Module:OnEnable()
    if not self.db.enabled then return end
    self:CreateFrame()
    self:ApplySettings()
    self:StartUpdater()
end

function Module:OnDisable()
    if self.ticker then
        self.ticker:Cancel()
        self.ticker = nil
    end
    if self.frame then
        self.frame:Hide()
    end
end

-------------------------------------------------
-- Frame
-------------------------------------------------
function Module:CreateFrame()
    if self.frame then return end

    local f = CreateFrame("Frame", "YATP_InfoBarFrame", UIParent)
    f:SetSize(260, 18)
    f:SetPoint(self.db.point or "TOP", UIParent, self.db.relPoint or (self.db.point or "TOP"), self.db.posX, self.db.posY)

    f.bg = f:CreateTexture(nil, "BACKGROUND")
    f.bg:SetAllPoints(f)
    f.bg:SetColorTexture(0, 0, 0, 0.5)

    f.text = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    f.text:SetPoint("CENTER")

    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", function(frame)
        if not self.db.locked then frame:StartMoving() end
    end)
    f:SetScript("OnDragStop", function(frame)
        if not self.db.locked then
            frame:StopMovingOrSizing()
            self:SavePosition()
        end
    end)

    -- Tooltip for durability slot breakdown
    f:SetScript("OnEnter", function()
        self:ShowTooltip()
    end)
    f:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    self.frame = f
end

-------------------------------------------------
-- Position helpers
-------------------------------------------------
function Module:SavePosition()
    if not self.frame then return end
    local p, parent, rp, x, y = self.frame:GetPoint()
    -- We always reanchor to UIParent for persistence
    if parent and parent ~= UIParent then
        -- translate to UIParent coordinates
        self.frame:ClearAllPoints()
        self.frame:SetPoint(p, UIParent, p, x, y)
        p, parent, rp, x, y = self.frame:GetPoint()
    end
    self.db.point = p or self.db.point or "TOP"
    self.db.relPoint = rp or self.db.relPoint or self.db.point
    self.db.posX = x or 0
    self.db.posY = y or 0
end

function Module:ApplyPosition()
    if not self.frame then return end
    local p  = self.db.point or "TOP"
    local rp = self.db.relPoint or p
    self.frame:ClearAllPoints()
    self.frame:SetPoint(p, UIParent, rp, self.db.posX or 0, self.db.posY or 0)
end

-------------------------------------------------
-- Updater
-------------------------------------------------
function Module:StartUpdater()
    if self.ticker then self.ticker:Cancel() end
    local interval = math.max(0.2, self.db.updateInterval or 1)
    self.ticker = C_Timer.NewTicker(interval, function()
        self:RefreshText()
    end)
    -- Immediate first update
    self:RefreshText()
end

-------------------------------------------------
-- Computations
-------------------------------------------------
local INVENTORY_SLOTS = {1,2,3,5,6,7,8,9,10,11,12,13,14,15,16,17,18}

function Module:GetAverageDurability()
    local total, current = 0, 0
    for _, slot in ipairs(INVENTORY_SLOTS) do
        local cur, max = GetInventoryItemDurability(slot)
        if cur and max and max > 0 then
            current = current + cur
            total = total + max
        end
    end
    if total > 0 then
        return (current / total) * 100
    end
    return 100
end

-- Build slot detail lines (only those below 100 or maybe all?)
local SLOT_NAMES = {
    [1] = HEADSLOT,
    [2] = NECKSLOT,
    [3] = SHOULDERSLOT,
    [5] = CHESTSLOT,
    [6] = WAISTSLOT,
    [7] = LEGSSLOT,
    [8] = FEETSLOT,
    [9] = WRISTSLOT,
    [10] = HANDSSLOT,
    [11] = FINGER0SLOT_UNIQUE, -- finger1
    [12] = FINGER1SLOT_UNIQUE, -- finger2
    [13] = TRINKET0SLOT_UNIQUE,
    [14] = TRINKET1SLOT_UNIQUE,
    [15] = BACKSLOT,
    [16] = MAINHANDSLOT,
    [17] = SECONDARYHANDSLOT,
    [18] = RANGEDSLOT,
}

function Module:GetDurabilityBreakdown()
    local lines = {}
    for _, slot in ipairs(INVENTORY_SLOTS) do
        local cur, max = GetInventoryItemDurability(slot)
        if cur and max and max > 0 then
            local pct = (cur / max) * 100
            table.insert(lines, { slot = slot, pct = pct })
        end
    end
    table.sort(lines, function(a,b) return a.pct < b.pct end)
    return lines
end

-------------------------------------------------
-- Tooltip
-------------------------------------------------
function Module:ShowTooltip()
    if not self.db.showDurability then return end
    if not self.frame then return end
    GameTooltip:SetOwner(self.frame, "ANCHOR_BOTTOM")
    GameTooltip:ClearLines()
    GameTooltip:AddLine(L["Durability"] or "Durability")
    local breakdown = self:GetDurabilityBreakdown()
    for _, entry in ipairs(breakdown) do
        local name = SLOT_NAMES[entry.slot] or ("Slot "..entry.slot)
        local color = "ffffff"
        if entry.pct <= self.db.lowDurThreshold then
            color = "ff0000"
        elseif entry.pct < 50 then
            color = "ffff00"
        end
        GameTooltip:AddDoubleLine(name, string.format("|cffffffff%.0f%%|r", entry.pct))
    end
    GameTooltip:Show()
end

-------------------------------------------------
-- Text refresh
-------------------------------------------------
function Module:RefreshText()
    if not self.frame or not self.db.enabled then return end

    local parts = {}
    if self.db.showFPS then
        local fps = floor(GetFramerate())
        table.insert(parts, string.format("FPS: %d", fps))
    end
    if self.db.showPing then
        local _, _, home = GetNetStats()
        table.insert(parts, string.format("Ping: %d ms", home or 0))
    end
    if self.db.showDurability then
        local dur = self:GetAverageDurability()
        if self.db.colorizeLowDurability and dur <= self.db.lowDurThreshold then
            table.insert(parts, string.format("|cffff0000Dur: %.0f%%|r", dur))
        else
            table.insert(parts, string.format("Dur: %.0f%%", dur))
        end
    end

    local text = table.concat(parts, "  |  ")
    if text ~= self._lastText then
        self.frame.text:SetTextColor(self.db.fontColor.r, self.db.fontColor.g, self.db.fontColor.b)
        self.frame.text:SetText(text)
        self._lastText = text
    end
end

-------------------------------------------------
-- Apply visual settings
-------------------------------------------------
function Module:ApplySettings()
    if not self.frame then return end
    local db = self.db
    local fontPath = (LSM and LSM:Fetch("font", db.font)) or STANDARD_TEXT_FONT
    self.frame.text:SetFont(fontPath, db.fontSize, db.fontOutline)
    self.frame.text:SetTextColor(db.fontColor.r, db.fontColor.g, db.fontColor.b)
    if db.background then
        self.frame.bg:Show()
    else
        self.frame.bg:Hide()
    end
    self.frame:EnableMouse(not db.locked)
    self:ApplyPosition()
end

-------------------------------------------------
-- Options
-------------------------------------------------
function Module:BuildOptions()
    local get = function(info) return self.db[ info[#info] ] end
    local set = function(info, val) self.db[ info[#info] ] = val; self:OnSettingChanged(info[#info]) end

    local function colorGet(info)
        local c = self.db[ info[#info] ]
        return c.r, c.g, c.b
    end
    local function colorSet(info, r, g, b)
        local c = self.db[ info[#info] ]
        c.r, c.g, c.b = r, g, b
        self:ApplySettings(); self:RefreshText()
    end

    local function fontValues()
        local t = { ["Friz Quadrata TT"] = "Friz Quadrata TT" }
        if LSM then for _, name in ipairs(LSM:List("font")) do t[name] = name end end
        return t
    end

    return {
        type = "group",
        name = L["Info Bar"] or "Info Bar",
        args = {
            enabled = {
                type = "toggle",
                name = L["Enable Module"] or "Enable Module",
                order = 1,
                get = function() return self.db.enabled end,
                set = function(_, v)
                    self.db.enabled = v
                    if v then self:Enable() else self:Disable() end
                end,
            },
            general = {
                type = "group", inline = true,
                name = L["General"] or "General",
                order = 5,
                args = {
                    locked = { type="toggle", name=L["Lock Frame"] or "Lock Frame", order=1, get=get, set=function(i,v) set(i,v); self:ApplySettings() end },
                    updateInterval = { type="range", name=L["Update Interval (seconds)"] or "Update Interval (seconds)", min=0.2, max=5, step=0.1, order=2,
                        get=get, set=function(i,v) set(i,v); self:StartUpdater() end },
                }
            },
            metrics = {
                type = "group", inline = true,
                name = L["Metrics"] or "Metrics",
                order = 10,
                args = {
                    showFPS = { type="toggle", name=L["Show FPS"] or "Show FPS", order=1, get=get, set=function(i,v) set(i,v); self:RefreshText() end },
                    showPing = { type="toggle", name=L["Show Ping"] or "Show Ping", order=2, get=get, set=function(i,v) set(i,v); self:RefreshText() end },
                    showDurability = { type="toggle", name=L["Show Durability"] or "Show Durability", order=3, get=get, set=function(i,v) set(i,v); self:RefreshText() end },
                    lowDurThreshold = { type="range", name=L["Low Durability Threshold"] or "Low Durability Threshold", min=5, max=75, step=1, order=4, get=get, set=function(i,v) set(i,v); self:RefreshText() end },
                    colorizeLowDurability = { type="toggle", name=L["Only color durability below threshold"] or "Only color durability below threshold", order=5, get=get, set=function(i,v) set(i,v); self:RefreshText() end },
                }
            },
            appearance = {
                type = "group", inline = true,
                name = L["Appearance"] or "Appearance",
                order = 20,
                args = {
                    font = { type="select", name=L["Font"] or "Font", values=fontValues, order=1, get=get, set=function(i,v) set(i,v); self:ApplySettings() end },
                    fontSize = { type="range", name=L["Font Size"] or "Font Size", min=8, max=32, step=1, order=2, get=get, set=function(i,v) set(i,v); self:ApplySettings() end },
                    fontOutline = { type="select", name=L["Font Outline"] or "Font Outline", order=3,
                        values = { NONE=L["None"] or "None", OUTLINE=L["Outline"] or "Outline", THICKOUTLINE=L["Thick Outline"] or "Thick Outline" },
                        get=get, set=function(i,v) set(i,v); self:ApplySettings() end },
                    fontColor = { type="color", name=L["Font Color"] or "Font Color", order=4, get=colorGet, set=colorSet },
                    background = { type="toggle", name=L["Show Background"] or "Show Background", order=5, get=get, set=function(i,v) set(i,v); self:ApplySettings() end },
                }
            },
            position = {
                type = "group", inline = true,
                name = L["Position"] or "Position",
                order = 30,
                args = {
                    posX = { type="range", name=L["Position X"] or "Position X", min=-2000, max=2000, step=1, bigStep=10, order=1,
                        get=function() return self.db.posX end,
                        set=function(_,v) self.db.posX = v; self:ApplyPosition() end },
                    posY = { type="range", name=L["Position Y"] or "Position Y", min=-2000, max=2000, step=1, bigStep=10, order=2,
                        get=function() return self.db.posY end,
                        set=function(_,v) self.db.posY = v; self:ApplyPosition() end },
                    resetPosition = { type="execute", name=L["Reset Position"] or "Reset Position", order=3,
                        func=function()
                            self.db.point = self.defaults.point
                            self.db.relPoint = self.defaults.relPoint
                            self.db.posX = self.defaults.posX
                            self.db.posY = self.defaults.posY
                            self:ApplyPosition()
                        end },
                }
            },
        },
    }
end

function Module:OnSettingChanged(key)
    if key == "font" or key == "fontSize" or key == "fontOutline" or key == "fontColor" or key == "background" or key == "locked" then
        self:ApplySettings()
    elseif key == "showFPS" or key == "showPing" or key == "showDurability" or key == "lowDurThreshold" or key == "colorizeLowDurability" then
        self:RefreshText()
    elseif key == "updateInterval" then
        self:StartUpdater()
    end
end

-------------------------------------------------
-- Open Config through YATP
-------------------------------------------------
function Module:OpenConfig()
    if YATP.OpenConfig then YATP:OpenConfig("InfoBar") end
end
