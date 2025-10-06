--========================================================--
-- YATP - XP Bar Module (based on BetterXPBar)
--========================================================--

local YATP = LibStub("AceAddon-3.0"):GetAddon("YATP")
local LSM  = LibStub("LibSharedMedia-3.0", true)

-------------------------------------------------
-- Module definition
-------------------------------------------------
local XPBar = {}
YATP:RegisterModule("XPBar", XPBar)

-------------------------------------------------
-- Defaults
-------------------------------------------------
XPBar.defaults = {
    width = 400,
    height = 15,
    locked = true,
    font = "Friz Quadrata TT",
    fontSize = 10,
    fontOutline = "OUTLINE",
    textMode = "ALWAYS", -- ALWAYS / MOUSEOVER
    texture = "Blizzard",
    bgTexture = "Blizzard",
    bgColor = { r=0, g=0, b=0, a=0.6 },
    showTicks = true,
}

-------------------------------------------------
-- Initialization
-------------------------------------------------
function XPBar:OnModuleInitialize()
    YATP:RegisterChatCommand("xpbar", function() XPBar:OpenConfig() end)

    if not YATP.db.profile.modules then YATP.db.profile.modules = {} end
    if not YATP.db.profile.modules.XPBar then
        YATP.db.profile.modules.XPBar = CopyTable(self.defaults)
    end

    self.db = YATP.db.profile.modules.XPBar
    self:CreateBar()
    self:ApplySettings()

    YATP:RegisterEvent("PLAYER_XP_UPDATE", function() self:UpdateXP() end)
    YATP:RegisterEvent("PLAYER_UPDATE_RESTING", function() self:UpdateXP() end)
    YATP:RegisterEvent("UPDATE_EXHAUSTION", function() self:UpdateXP() end)
    YATP:RegisterEvent("PLAYER_LEVEL_UP", function() self:UpdateXP() end)

    self:UpdateXP()

    -- Integrar opciones dentro del panel YATP
    if YATP.AddModuleOptions then
        YATP:AddModuleOptions("XPBar", self:BuildOptions())
    end
end

-------------------------------------------------
-- Bar Creation
-------------------------------------------------
function XPBar:CreateBar()
    if self.frame then return end

    local f = CreateFrame("Frame", "YATP_XPBarFrame", UIParent)
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", function()
        if not self.db.locked then f:StartMoving() end
    end)
    f:SetScript("OnDragStop", function()
        f:StopMovingOrSizing()
        self:SavePosition()
    end)

    local bar = CreateFrame("StatusBar", nil, f)
    bar:SetPoint("TOPLEFT", f, "TOPLEFT", 2, -2)
    bar:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -2, 2)
    bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    bar:SetStatusBarColor(0.58, 0.0, 0.78)

    local rest = bar:CreateTexture(nil, "BORDER")
    rest:SetAllPoints(bar)
    rest:SetTexture("Interface\\TargetingFrame\\UI-StatusBar")
    rest:SetVertexColor(0.2, 0.6, 1, 0.5)
    bar.rest = rest

    local bg = bar:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(bar)
    bar.bg = bg

    local text = bar:CreateFontString(nil, "OVERLAY")
    text:SetPoint("CENTER")
    f.text = text

    local border = CreateFrame("Frame", nil, f, BackdropTemplateMixin and "BackdropTemplate" or nil)
    border:SetAllPoints(f)
    border:SetFrameLevel(f:GetFrameLevel() + 5)
    border:SetBackdrop({
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 12,
        insets = { left=3, right=3, top=3, bottom=3 }
    })
    border:SetBackdropBorderColor(1, 1, 1, 1)

    local ticks = {}
    for i = 1, 9 do
        local tick = bar:CreateTexture(nil, "OVERLAY")
        tick:SetWidth(1)
        tick:SetPoint("TOP")
        tick:SetPoint("BOTTOM")
        ticks[i] = tick
    end
    f.ticks = ticks

    f.bar = bar
    f.border = border
    self.frame = f

    f:SetScript("OnEnter", function() self:UpdateTextVisibility(true) end)
    f:SetScript("OnLeave", function() self:UpdateTextVisibility(false) end)
end

-------------------------------------------------
-- Settings & Position
-------------------------------------------------
function XPBar:SavePosition()
    local p, _, rp, x, y = self.frame:GetPoint()
    self.db.point, self.db.rel, self.db.x, self.db.y = p, rp, x, y
end

function XPBar:RestorePosition()
    if self.db.point then
        self.frame:ClearAllPoints()
        self.frame:SetPoint(self.db.point, UIParent, self.db.rel, self.db.x, self.db.y)
    else
        self.frame:SetPoint("CENTER", 0, -250)
    end
end

function XPBar:ApplySettings()
    local db = self.db
    self.frame:SetSize(db.width, db.height)

    local texPath = (LSM and LSM:Fetch("statusbar", db.texture)) or "Interface\\TargetingFrame\\UI-StatusBar"
    self.frame.bar:SetStatusBarTexture(texPath)
    self.frame.bar.rest:SetTexture(texPath)

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

    self.frame:EnableMouse(not db.locked or db.textMode == "MOUSEOVER")
    self:RestorePosition()
    self:UpdateTextVisibility(false)
end

-------------------------------------------------
-- XP Update
-------------------------------------------------
function XPBar:UpdateXP()
    if not self.frame then return end
    local bar = self.frame.bar
    local rest = bar.rest
    local max = UnitXPMax("player")
    local curr = UnitXP("player")
    local rested = GetXPExhaustion() or 0
    if max == 0 then return end

    bar:SetMinMaxValues(0, max)
    bar:SetValue(curr)

    local width = bar:GetWidth()
    local totalXP = math.min(curr + rested, max)
    local restWidth = (totalXP / max) * width

    rest:SetWidth(restWidth)
    rest:ClearAllPoints()
    rest:SetPoint("LEFT", bar, "LEFT")
    rest:SetHeight(bar:GetHeight())

    if self.db.textMode == "ALWAYS" then
        self:SetXPText(curr, max, rested)
    elseif self.db.textMode == "MOUSEOVER" then
        self.frame.text:SetText("")
    end
end

function XPBar:SetXPText(curr, max, rested)
    local percent = (curr / max) * 100
    local text = string.format("XP: %d / %d (%.1f%%)", curr, max, percent)

    if rested and rested > 0 then
        local restPercent = (rested / max) * 100
        text = text .. string.format(" R: (%.1f%%)", restPercent)
    end

    self.frame.text:SetText(text)
end

function XPBar:UpdateTextVisibility(hovered)
    if self.db.textMode == "ALWAYS" then
        local curr, max = UnitXP("player"), UnitXPMax("player")
        local rested = GetXPExhaustion() or 0
        self:SetXPText(curr, max, rested)
    elseif self.db.textMode == "MOUSEOVER" then
        if hovered then
            local curr, max = UnitXP("player"), UnitXPMax("player")
            local rested = GetXPExhaustion() or 0
            self:SetXPText(curr, max, rested)
        else
            self.frame.text:SetText("")
        end
    end
end

-------------------------------------------------
-- Options integration
-------------------------------------------------
function XPBar:BuildOptions()
    local get = function(info) return self.db[ info[#info] ] end
    local set = function(info, val)
        self.db[ info[#info] ] = val
        self:ApplySettings()
        self:UpdateXP()
    end

    local textureValues = function()
        local t = { ["Blizzard"] = "Blizzard" }
        if LSM then for _, name in ipairs(LSM:List("statusbar")) do t[name] = name end end
        return t
    end

    return {
        type = "group",
        name = "XP Bar",
        args = {
            locked = { type="toggle", name="Lock bar", order=1, get=get, set=set },
            width = { type="range", name="Width", min=100, max=800, step=10, order=2, get=get, set=set },
            height = { type="range", name="Height", min=10, max=50, step=1, order=3, get=get, set=set },
            textMode = {
                type="select", name="Text Mode", order=4,
                values = { ALWAYS="Always Show", MOUSEOVER="Show on Mouseover" },
                get=get, set=set
            },
            fontSize = { type="range", name="Font Size", min=8, max=24, step=1, order=5, get=get, set=set },
            fontOutline = {
                type="select", name="Font Outline", order=6,
                values = { NONE="None", OUTLINE="Outline", THICKOUTLINE="Thick Outline" },
                get=get, set=set
            },
            texture = { type="select", name="Bar Texture", values=textureValues, order=7, get=get, set=set },
            bgHeader = { type="header", name="Background", order=10 },
            bgTexture = { type="select", name="Background Texture", values=textureValues, order=11, get=get, set=set },
            bgColor = { type="color", name="Background Color", hasAlpha=true, order=12,
                get=function() local c=self.db.bgColor return c.r, c.g, c.b, c.a end,
                set=function(_, r, g, b, a)
                    local c = self.db.bgColor
                    c.r, c.g, c.b, c.a = r, g, b, a
                    self:ApplySettings()
                end
            },
            ticks = { type="toggle", name="Show Ticks", order=20,
                get=function() return self.db.showTicks end,
                set=function(_, v) self.db.showTicks = v self:ApplySettings() end },
        }
    }
end

-------------------------------------------------
-- Config
-------------------------------------------------
function XPBar:OpenConfig()
    if YATP.OpenConfig then
        YATP:OpenConfig("XPBar")
    else
        print("YATP config not available.")
    end
end
-------------------------------------------------