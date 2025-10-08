--========================================================--
-- YATP - XP & Reputation Bar Module
--========================================================--

local L   = LibStub("AceLocale-3.0"):GetLocale("YATP", true) or setmetatable({}, { __index=function(_,k) return k end })
local LSM = LibStub("LibSharedMedia-3.0", true)
local YATP = LibStub("AceAddon-3.0"):GetAddon("YATP", true)
if not YATP then
    print("YATP not found, aborting XPRepBar module")
    return
end

-- Create Ace3 module
local XPRepBar = YATP:NewModule("XPRepBar", "AceEvent-3.0", "AceConsole-3.0")

-- Stable Blizzard-like colors (sourced from classic UI approximations)
local XP_COLOR       = { r = 0.58, g = 0.0,  b = 0.55 }   -- deep purple/pink (Blizzard exp bar tint in some classic builds) fallback to standard blue if preferred
local XP_COLOR_ALT   = { r = 0.0,  g = 0.44, b = 0.87 }   -- original blue we used earlier (kept as alternative)
local RESTED_COLOR   = { r = 0.0,  g = 0.39, b = 0.88, a = 0.55 } -- subdued rested overlay
local REP_NEUTRAL    = { r = 0.8,  g = 0.7,  b = 0.2 }    -- fallback rep color before faction reaction applied

-------------------------------------------------
-- Defaults
-------------------------------------------------
XPRepBar.defaults = {
    enabled = true,
    width = 400,
    height = 15,
    locked = true,
    font = "Friz Quadrata TT",
    fontSize = 10,
    fontOutline = "OUTLINE",
    mouseOver = false, -- false = always visible, true = only on mouseover
    texture = "Blizzard",
    bgTexture = "Blizzard",
    bgColor = { r=0, g=0, b=0, a=0.6 },
    -- default anchor/position so posX/posY work before any manual save
    point = "CENTER",
    rel = "CENTER",
    x = 0,
    y = -250,
    showTicks = true,
}

-------------------------------------------------
-- OnInitialize
-------------------------------------------------
function XPRepBar:OnInitialize()
    if not YATP.db.profile.modules then YATP.db.profile.modules = {} end
    if not YATP.db.profile.modules.XPRepBar then
        YATP.db.profile.modules.XPRepBar = CopyTable(self.defaults)
    end
    self.db = YATP.db.profile.modules.XPRepBar

    -- Migration: ensure positional fields exist for older profiles
    if not self.db.point or not self.db.rel then
        self.db.point = self.db.point or self.defaults.point
        self.db.rel   = self.db.rel   or self.defaults.rel
    end
    if self.db.x == nil then self.db.x = self.defaults.x end
    if self.db.y == nil then self.db.y = self.defaults.y end

    -- Backwards compatible chat command and new alias
    self:RegisterChatCommand("xpbar", function() self:OpenConfig() end)
    self:RegisterChatCommand("xprep", function() self:OpenConfig() end)
    if YATP.AddModuleOptions then
        YATP:AddModuleOptions("XPRepBar", self:BuildOptions(), "Interface")
    end
end

-------------------------------------------------
-- OnEnable
-------------------------------------------------
function XPRepBar:OnEnable()
    if not self.db or not self.db.enabled then return end
    self:CreateBar()
    self:ApplySettings()
    self:UpdateXP()
    self:UpdateReputation()

    self:RegisterEvent("PLAYER_XP_UPDATE", "UpdateXP")
    self:RegisterEvent("PLAYER_UPDATE_RESTING", "UpdateXP")
    self:RegisterEvent("UPDATE_EXHAUSTION", "UpdateXP")
    self:RegisterEvent("PLAYER_LEVEL_UP", "UpdateXP")
    self:RegisterEvent("UPDATE_FACTION", "UpdateReputation")
    self:RegisterEvent("PLAYER_ENTERING_WORLD", "UpdateReputation")
end

function XPRepBar:OnDisable()
    -- Unregister events and hide frames without destroying settings
    self:UnregisterAllEvents()
    if self.frame then self.frame:Hide() end
    if self.repFrame then self.repFrame:Hide() end
end

-------------------------------------------------
-- Create XP + Reputation bar
-------------------------------------------------
function XPRepBar:CreateBar()
    -- Ensure main XP frame exists
    if not self.frame then
        local f = CreateFrame("Frame", "YATP_XPRepBarFrame", UIParent, BackdropTemplateMixin and "BackdropTemplate" or nil)
    f:SetMovable(false)
    f:EnableMouse(true)
        f:SetSize(self.db.width, self.db.height)
        f:SetPoint("CENTER", 0, -250)

    local bar = CreateFrame("StatusBar", nil, f)
        bar:SetPoint("TOPLEFT", f, "TOPLEFT", 2, -2)
        bar:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -2, 2)
    -- create a unique texture instance for this statusbar to avoid shared texture color bleed
    local barTex = bar:CreateTexture(nil, "ARTWORK")
    barTex:SetAllPoints(bar)
    bar:SetStatusBarTexture(barTex)
        f.bar = bar

        local rest = bar:CreateTexture(nil, "ARTWORK")
        rest:SetPoint("TOPLEFT", bar, "TOPLEFT", 0, 0)
        rest:SetPoint("BOTTOMLEFT", bar, "BOTTOMLEFT", 0, 0)
        rest:SetWidth(0)
        rest:SetTexture("Interface\\TargetingFrame\\UI-StatusBar")
        rest:SetVertexColor(0.35, 0.78, 1, 0.75)
        f.bar.rest = rest

        local bg = bar:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints(bar)
        f.bar.bg = bg

        local text = bar:CreateFontString(nil, "OVERLAY")
        text:SetPoint("CENTER")
        f.text = text

        -- Border
        local border = CreateFrame("Frame", nil, f, BackdropTemplateMixin and "BackdropTemplate" or nil)
        border:SetAllPoints(f)
        border:SetFrameLevel(f:GetFrameLevel() + 5)
        border:SetBackdrop({
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 16, edgeSize = 12,
            insets = { left=3, right=3, top=3, bottom=3 }
        })
        border:SetBackdropBorderColor(1, 1, 1, 1)
        f.border = border

        -- ticks
        local ticks = {}
        for i = 1, 9 do
            local tick = bar:CreateTexture(nil, "OVERLAY")
            tick:SetWidth(1)
            tick:SetPoint("TOP")
            tick:SetPoint("BOTTOM")
            ticks[i] = tick
        end
        f.ticks = ticks

    -- Mouse events (XP frame only updates XP text on hover)
    f:SetScript("OnEnter", function() self:UpdateTextVisibility(true) end)
    f:SetScript("OnLeave", function() self:UpdateTextVisibility(false) end)
    -- dragging support: allow moving when unlocked
    f:SetScript("OnMouseDown", function()
        if not self.db.locked then
            f:StartMoving()
        end
    end)
    f:SetScript("OnMouseUp", function()
        if not self.db.locked then
            f:StopMovingOrSizing()
            self:SavePosition()
        end
    end)

        self.frame = f
    end

    -- Create reputation frame (above the XP frame) if missing
    if not self.repFrame then
        local r = CreateFrame("Frame", "YATP_RepBarFrame", UIParent)
    r:SetMovable(false)
    r:EnableMouse(true)
        r:SetSize(self.db.width, self.db.height)
        r:SetPoint("BOTTOM", self.frame, "TOP", 0, 2)

    local bar = CreateFrame("StatusBar", nil, r)
        bar:SetPoint("TOPLEFT", r, "TOPLEFT", 2, -2)
        bar:SetPoint("BOTTOMRIGHT", r, "BOTTOMRIGHT", -2, 2)
    -- create a unique texture instance for the rep statusbar as well
    local repBarTex = bar:CreateTexture(nil, "ARTWORK")
    repBarTex:SetAllPoints(bar)
    bar:SetStatusBarTexture(repBarTex)
        r.bar = bar

        local bg = bar:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints(bar)
        r.bg = bg

        local text = bar:CreateFontString(nil, "OVERLAY")
        text:SetPoint("CENTER")
        r.text = text

        -- Border
        local border = CreateFrame("Frame", nil, r, BackdropTemplateMixin and "BackdropTemplate" or nil)
        border:SetAllPoints(r)
        border:SetFrameLevel(r:GetFrameLevel() + 5)
        border:SetBackdrop({
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 16, edgeSize = 12,
            insets = { left=3, right=3, top=3, bottom=3 }
        })
        border:SetBackdropBorderColor(1, 1, 1, 1)
        r.border = border

        -- ticks
        local ticks = {}
        for i = 1, 9 do
            local tick = bar:CreateTexture(nil, "OVERLAY")
            tick:SetWidth(1)
            tick:SetPoint("TOP")
            tick:SetPoint("BOTTOM")
            ticks[i] = tick
        end
        r.ticks = ticks

        r:SetScript("OnEnter", function() self:UpdateRepTextVisibility(true) end)
        r:SetScript("OnLeave", function() self:UpdateRepTextVisibility(false) end)
        -- allow dragging repFrame when unlocked as well (keeps it in sync)
        r:SetScript("OnMouseDown", function()
            if not self.db.locked and self.frame then
                -- start moving the main frame so we have a single anchor
                self.frame:StartMoving()
            end
        end)
        r:SetScript("OnMouseUp", function()
            if not self.db.locked and self.frame then
                self.frame:StopMovingOrSizing()
                self:SavePosition()
            end
        end)

        self.repFrame = r
    end
end

-------------------------------------------------
-- Save and restore position
-------------------------------------------------
function XPRepBar:SavePosition()
    local p, _, rp, x, y = self.frame:GetPoint()
    self.db.point, self.db.rel, self.db.x, self.db.y = p, rp, x, y
end

function XPRepBar:RestorePosition()
    self:ApplyPosition()
end

-- Centralized position logic so sliders & manual edits work immediately, even at max level
function XPRepBar:ApplyPosition()
    if not self.frame then return end
    local db = self.db
    self.frame:ClearAllPoints()
    -- Always use stored offsets; if point missing, treat as CENTER
    local point = db.point or "CENTER"
    local rel   = db.rel   or "CENTER"
    self.frame:SetPoint(point, UIParent, rel, db.x or 0, db.y or 0)

    if self.repFrame then
        self.repFrame:ClearAllPoints()
        local level = UnitLevel("player") or 0
        if level >= 60 then
            -- At max level rep bar takes the XP bar position using same stored offsets
            local rPoint = db.point or "CENTER"
            local rRel   = db.rel   or "CENTER"
            self.repFrame:SetPoint(rPoint, UIParent, rRel, db.x or 0, db.y or 0)
        else
            -- Normal (rep above XP)
            self.repFrame:SetPoint("BOTTOM", self.frame, "TOP", 0, 2)
        end
    end
end

-------------------------------------------------
-- Apply visual settings
-------------------------------------------------
function XPRepBar:ApplySettings()
    local db = self.db
    self.frame:SetSize(db.width, db.height)

    local texPath = (LSM and LSM:Fetch("statusbar", db.texture)) or "Interface\\TargetingFrame\\UI-StatusBar"
    -- Apply texture path to the unique texture instances created earlier (if present)
    local xpTex = (self.frame.bar and self.frame.bar:GetStatusBarTexture())
    if xpTex and xpTex.SetTexture then
        xpTex:SetTexture(texPath)
    else
        self.frame.bar:SetStatusBarTexture(texPath)
    end
    self.frame.bar.rest:SetTexture(texPath)
    -- Ensure XP bar has its own default color so reputation changes don't tint it
    -- Use a color close to Blizzard's default XP/experience blue
    -- Apply stable XP and rested colors exactly once here
    do
        local xpTex = self.frame.bar:GetStatusBarTexture()
        local c = XP_COLOR_ALT -- choose between XP_COLOR / XP_COLOR_ALT; using blue alt for authenticity
        if xpTex and xpTex.SetVertexColor then
            xpTex:SetVertexColor(c.r, c.g, c.b)
        else
            self.frame.bar:SetStatusBarColor(c.r, c.g, c.b)
        end
        local rc = RESTED_COLOR
        self.frame.bar.rest:SetVertexColor(rc.r, rc.g, rc.b, rc.a or 0.6)
    end

    local bgTex = (LSM and LSM:Fetch("statusbar", db.bgTexture)) or "Interface\\TargetingFrame\\UI-StatusBar"
    local c = db.bgColor
    self.frame.bar.bg:SetTexture(bgTex)
    self.frame.bar.bg:SetVertexColor(c.r, c.g, c.b, c.a)

    local fontPath = (LSM and LSM:Fetch("font", db.font)) or STANDARD_TEXT_FONT
    self.frame.text:SetFont(fontPath, db.fontSize, db.fontOutline)

    local tickR, tickG, tickB = 161/255, 145/255, 158/255
    for i,tick in ipairs(self.frame.ticks) do
        if db.showTicks then
            local sectionWidth = db.width / 10
            tick:ClearAllPoints()
            tick:SetPoint("TOPLEFT", self.frame.bar, "TOPLEFT", sectionWidth * i, 0)
            tick:SetPoint("BOTTOMLEFT", self.frame.bar, "BOTTOMLEFT", sectionWidth * i, 0)
            tick:SetColorTexture(tickR, tickG, tickB, 1)
            tick:Show()
        else
            tick:Hide()
        end
    end

    self.frame:EnableMouse(not db.locked or db.mouseOver)
    -- Movable only when unlocked
    self.frame:SetMovable(not db.locked)
    if self.repFrame then
        self.repFrame:EnableMouse(not db.locked or db.mouseOver)
        self.repFrame:SetMovable(not db.locked)
    end
    self:ApplyPosition()
    self:UpdateTextVisibility(false)

    -- Reputation sync
    if self.repFrame then
        self.repFrame:SetSize(db.width, db.height)
        local repTex = (self.repFrame.bar and self.repFrame.bar:GetStatusBarTexture())
        if repTex and repTex.SetTexture then
            repTex:SetTexture(texPath)
        else
            self.repFrame.bar:SetStatusBarTexture(texPath)
        end
        -- Default rep bar color (will be overridden by UpdateReputation when a faction is watched)
        local repTexDefault = self.repFrame.bar:GetStatusBarTexture()
        local rc = REP_NEUTRAL
        if repTexDefault and repTexDefault.SetVertexColor then
            repTexDefault:SetVertexColor(rc.r, rc.g, rc.b)
        else
            self.repFrame.bar:SetStatusBarColor(rc.r, rc.g, rc.b)
        end
        self.repFrame.bg:SetTexture(bgTex)
        self.repFrame.bg:SetVertexColor(c.r, c.g, c.b, c.a)
        self.repFrame.text:SetFont(fontPath, db.fontSize, db.fontOutline)
    self.repFrame:ClearAllPoints()
    self.repFrame:SetPoint("BOTTOM", self.frame, "TOP", 0, 2)

        local tickR, tickG, tickB = 161/255, 145/255, 158/255
        for i,tick in ipairs(self.repFrame.ticks) do
            if db.showTicks then
                local sectionWidth = db.width / 10
                tick:ClearAllPoints()
                tick:SetPoint("TOPLEFT", self.repFrame.bar, "TOPLEFT", sectionWidth * i, 0)
                tick:SetPoint("BOTTOMLEFT", self.repFrame.bar, "BOTTOMLEFT", sectionWidth * i, 0)
                tick:SetColorTexture(tickR, tickG, tickB, 1)
                tick:Show()
            else
                tick:Hide()
            end
        end
    end
end

-------------------------------------------------
-- Update experience
-------------------------------------------------
function XPRepBar:UpdateXP()
    if not self.frame then return end
    -- Hide XP bar and move reputation into its place when player is max level
    local level = UnitLevel("player") or 0
    if level >= 60 then
        -- hide XP bar
        self.frame:Hide()
        -- move reputation bar to XP frame position if exists
        if self.repFrame then
            self.repFrame:ClearAllPoints()
            -- place repFrame where XP frame sits
            local p, rel, rp, x, y = self.frame:GetPoint()
            -- If we have a stored custom anchor, use the saved db point instead
            local rPoint = self.db.point or "CENTER"
            local rRel   = self.db.rel   or "CENTER"
            self.repFrame:SetPoint(rPoint, UIParent, rRel, self.db.x or 0, self.db.y or 0)
            self.repFrame:Show()
        end
        -- ensure any recent slider change is applied coherently
        self:ApplyPosition()
        return
    else
        -- ensure XP frame is visible when below max level
        self.frame:Show()
        if self.repFrame then
            -- restore repFrame position above XP
            self.repFrame:ClearAllPoints()
            self.repFrame:SetPoint("BOTTOM", self.frame, "TOP", 0, 2)
        end
    end
    -- re-apply position in case user changed sliders while max level then de-leveled (future-proof)
    self:ApplyPosition()
    local bar = self.frame.bar
    local rest = bar.rest
    local max = UnitXPMax("player")
    local curr = UnitXP("player")
    -- NOTE: GetXPExhaustion() returns nil when no rested bonus is available.
    -- We intentionally do NOT coerce it to 0 here so downstream checks can
    -- distinguish between nil (no rested) and 0 (edge case / server variant).
    local rested = GetXPExhaustion()
    if max == 0 then return end

    bar:SetMinMaxValues(0, max)
    bar:SetValue(curr)

    local width = bar:GetWidth()
    -- Rested overlay handling:
    -- Classic behavior: a lighter segment indicates bonus XP up to either
    -- (curr + rested) clamped to next level. Previous implementation never
    -- updated width, causing stale or misleading rested visuals.
    rest:SetHeight(bar:GetHeight())
    if rested and rested > 0 then
        local remainingToLevel = max - curr
        if remainingToLevel < 0 then remainingToLevel = 0 end
        local shownRested = math.min(rested, remainingToLevel)
        local restWidth = (shownRested / max) * width
        -- Guard against tiny floating point artifacts
        if restWidth < 0.25 then
            restWidth = 0 -- visually hide insignificant sliver
        end
        rest:SetWidth(restWidth)
        rest:Show()
    else
        -- Explicitly collapse & hide when no rested bonus is present.
        rest:SetWidth(0)
        rest:Hide()
    end

    if not self.db.mouseOver then
        self:SetXPText(curr, max, rested)
    else
        self.frame.text:SetText("")
    end
end

-------------------------------------------------
-- Update reputation
-------------------------------------------------
function XPRepBar:UpdateReputation()
    if not self.repFrame then return end

    local name, reaction, min, max, value, factionID = GetWatchedFactionInfo()

    -- No watched faction -> hide bar
    if not name then
        self.repFrame:Hide()
        return
    end

    -- Ensure the reputation frame is visible when a faction is being watched
    self.repFrame:Show()

    -- Show and update color + values
    local color = FACTION_BAR_COLORS[reaction]
    if not color then
        color = { r = 0, g = 0.6, b = 0 }
    end

    -- Use exact FACTION_BAR_COLORS value for authenticity
    local repR = color.r or 0
    local repG = color.g or 0
    local repB = color.b or 0
    -- Do NOT recolor the XP bar here; keep stable
    local repTex = self.repFrame.bar:GetStatusBarTexture()
    if repTex and repTex.SetVertexColor then
        repTex:SetVertexColor(repR, repG, repB)
    else
        self.repFrame.bar:SetStatusBarColor(repR, repG, repB)
    end
    self.repFrame.bar:SetMinMaxValues(min, max)
    self.repFrame.bar:SetValue(value)

    -- Show or hide the text depending on the mouseOver mode
    if not self.db.mouseOver then
        local percent = ((value - min) / (max - min)) * 100
        self.repFrame.text:SetText(string.format("%s: %d / %d (%.1f%%)", name, value - min, max - min, percent))
    else
    self.repFrame.text:SetText("") -- Hide text by default when mouseover mode active
    end

    -- Update text visibility on mouseover
    self:UpdateRepTextVisibility(false)
end


-------------------------------------------------
-- XP text
-------------------------------------------------
function XPRepBar:SetXPText(curr, max, rested)
    local percent = (curr / max) * 100
    local text = string.format("XP: %d / %d (%.1f%%)", curr, max, percent)
    if rested and rested > 0 then
        local restPercent = (rested / max) * 100
        text = text .. string.format(" R: (%.1f%%)", restPercent)
    end
    self.frame.text:SetText(text)
end

function XPRepBar:UpdateTextVisibility(hovered)
    if not self.db.mouseOver then
    local curr, max = UnitXP("player"), UnitXPMax("player")
    local rested = GetXPExhaustion()
    self:SetXPText(curr, max, rested)
    else
        if hovered then
            local curr, max = UnitXP("player"), UnitXPMax("player")
            local rested = GetXPExhaustion()
            self:SetXPText(curr, max, rested)
        else
            self.frame.text:SetText("")
        end
    end
end

function XPRepBar:UpdateRepTextVisibility(hovered)
    local name, reaction, min, max, value = GetWatchedFactionInfo()
    if not name then
        self.repFrame.text:SetText("")
        return
    end

    if not self.db.mouseOver then
        local percent = ((value - min) / (max - min)) * 100
        self.repFrame.text:SetText(string.format("%s: %d / %d (%.1f%%)", name, value - min, max - min, percent))
    else
        if hovered then
            local percent = ((value - min) / (max - min)) * 100
            self.repFrame.text:SetText(string.format("%s: %d / %d (%.1f%%)", name, value - min, max - min, percent))
        else
            self.repFrame.text:SetText("")
        end
    end
end

-------------------------------------------------
-- Options
-------------------------------------------------
function XPRepBar:BuildOptions()
    local get = function(info) return self.db[ info[#info] ] end
    local set = function(info, val)
        local key = info[#info]
        self.db[key] = val
        if key == "enabled" then
            if val then self:Enable() else self:Disable() end
            return
        end
        self:ApplySettings()
        self:UpdateXP()
        self:UpdateReputation()
    end
    -- Safe localization fallback to avoid AceLocale missing entry warnings for dynamic/new keys
    local _L = function(key) return L[key] or key end

    local textureValues = function()
        local t = { ["Blizzard"] = "Blizzard" }
        if LSM then for _, name in ipairs(LSM:List("statusbar")) do t[name] = name end end
        return t
    end

    return {
        type = "group",
        name = L["XP Bar"],
        args = {
            enabled = { type="toggle", name=L["Enable Module"] or "Enable Module", order=0, width="full",
                desc = L["Requires /reload to fully apply enabling or disabling."] or "Requires /reload to fully apply enabling or disabling.",
                get=function() return self.db.enabled end,
                set=function(_, v)
                    self.db.enabled = v
                    if v then self:Enable() else self:Disable() end
                    if YATP and YATP.ShowReloadPrompt then YATP:ShowReloadPrompt() end
                end },
            generalGroup = {
                type = "group",
                name = L["General"],
                inline = true,
                order = 1,
                args = {
                    locked = { type="toggle", name=L["Lock bar"], order=1, width="full", get=get, set=set },
                    mouseOver = {
                        type = "toggle",
                        name = L["Show text only on mouseover"],
                        desc = L["If enabled, the XP text will only show when hovering the bar."],
                        order = 2,
                        width = "full",
                        get = function() return self.db.mouseOver end,
                        set = function(_, val)
                            self.db.mouseOver = val
                            self:ApplySettings(); self:UpdateXP(); self:UpdateReputation()
                            self:UpdateTextVisibility(false); self:UpdateRepTextVisibility(false)
                        end,
                    },
                },
            },
            sizeGroup = {
                type = "group",
                name = L["Width"] .. " / " .. L["Height"],
                inline = true,
                order = 10,
                args = {
                    width  = { type="range",  name=L["Width"],  min=100, max=800, step=10, order=1, width="full", get=get, set=set },
                    height = { type="range",  name=L["Height"], min=10,  max=50,  step=1,  order=2, width="full", get=get, set=set },
                },
            },
            positionGroup = {
                type = "group",
                name = L["Position"],
                inline = true,
                order = 20,
                args = {
                    posX = {
                        type = "range",
                        name = L["Position X"],
                        desc = L["Horizontal offset of the XP bar"],
                        order = 1,
                        width = "full",
                        min = -1000, max = 1000, step = 1, bigStep = 5,
                        get = function() return self.db.x or 0 end,
                        set = function(_, val) self.db.x = val; self:ApplyPosition(); self:UpdateReputation() end,
                    },
                    posY = {
                        type = "range",
                        name = L["Position Y"],
                        desc = L["Vertical offset of the XP bar"],
                        order = 2,
                        width = "full",
                        min = -1000, max = 1000, step = 1, bigStep = 5,
                        get = function() return self.db.y or 0 end,
                        set = function(_, val) self.db.y = val; self:ApplyPosition(); self:UpdateReputation() end,
                    },
                },
            },
            appearanceGroup = {
                type = "group",
                name = L["Bar Texture"],
                inline = true,
                order = 30,
                args = {
                    texture = { type="select", name=L["Bar Texture"], values=textureValues, order=1, width="full", get=get, set=set },
                    ticks = { type="toggle", name=L["Show Ticks"], order=2, width="full",
                        get=function() return self.db.showTicks end,
                        set=function(_, v) self.db.showTicks = v; self:ApplySettings() end },
                },
            },
        }
    }
end

-------------------------------------------------
-- Configuration
-------------------------------------------------
function XPRepBar:OpenConfig()
    if YATP.OpenConfig then YATP:OpenConfig("XPRepBar") end
end
