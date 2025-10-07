--========================================================--
-- YATP - XP Bar Module (final fix)
--========================================================--

print(">>> Cargando módulo XPBar.lua")

-- ⚠️ No usar local ADDON_NAME, YATP = ... aquí
local L   = LibStub("AceLocale-3.0"):GetLocale("YATP", true) or setmetatable({}, { __index=function(_,k) return k end })
local LSM = LibStub("LibSharedMedia-3.0", true)
local YATP = LibStub("AceAddon-3.0"):GetAddon("YATP", true)
if not YATP then
    print("YATP no encontrado, abortando XPBar.lua")
    return
end

-- Crear módulo correctamente
local XPBar = YATP:NewModule("XPBar", "AceEvent-3.0", "AceConsole-3.0")

-- Defaults
XPBar.defaults = {
    width = 400,
    height = 15,
    locked = true,
    font = "Friz Quadrata TT",
    fontSize = 10,
    fontOutline = "OUTLINE",
    mouseOver = false, 
    texture = "Blizzard",
    bgTexture = "Blizzard",
    bgColor = { r=0, g=0, b=0, a=0.6 },
    showTicks = true,
}

function XPBar:OnInitialize()
    if not YATP.db.profile.modules then YATP.db.profile.modules = {} end
    if not YATP.db.profile.modules.XPBar then
        YATP.db.profile.modules.XPBar = CopyTable(self.defaults)
    end
    self.db = YATP.db.profile.modules.XPBar

    self:RegisterChatCommand("xpbar", function() self:OpenConfig() end)
    if YATP.AddModuleOptions then
        YATP:AddModuleOptions("XPBar", self:BuildOptions())
    end
end

function XPBar:OnEnable()
    self:CreateBar()
    self:ApplySettings()
    self:UpdateXP()

    self:RegisterEvent("PLAYER_XP_UPDATE", "UpdateXP")
    self:RegisterEvent("PLAYER_UPDATE_RESTING", "UpdateXP")
    self:RegisterEvent("UPDATE_EXHAUSTION", "UpdateXP")
    self:RegisterEvent("PLAYER_LEVEL_UP", "UpdateXP")
end

-- Bar creation
function XPBar:CreateBar()
    if self.frame then return end
    local f = CreateFrame("Frame", "YATP_XPBarFrame", UIParent)
    f:SetMovable(true); f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", function() if not self.db.locked then f:StartMoving() end end)
    f:SetScript("OnDragStop",  function() f:StopMovingOrSizing(); self:SavePosition() end)

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
    bg:SetAllPoints(bar); bar.bg = bg

    local text = bar:CreateFontString(nil, "OVERLAY")
    text:SetPoint("CENTER"); f.text = text

    local border = CreateFrame("Frame", nil, f, BackdropTemplateMixin and "BackdropTemplate" or nil)
    border:SetAllPoints(f); border:SetFrameLevel(f:GetFrameLevel() + 5)
    border:SetBackdrop({ edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", tile = true, tileSize = 16, edgeSize = 12,
                         insets = { left=3, right=3, top=3, bottom=3 } })
    border:SetBackdropBorderColor(1,1,1,1)

    local ticks = {}
    for i=1,9 do
        local t = bar:CreateTexture(nil, "OVERLAY")
        t:SetWidth(1); t:SetPoint("TOP"); t:SetPoint("BOTTOM")
        ticks[i] = t
    end
    f.ticks = ticks

    f.bar = bar; f.border = border; self.frame = f
    f:SetScript("OnEnter", function() self:UpdateTextVisibility(true) end)
    f:SetScript("OnLeave", function() self:UpdateTextVisibility(false) end)
end

-- Settings & Position
function XPBar:SavePosition()
    local p, _, rp, x, y = self.frame:GetPoint()
    self.db.point, self.db.rel, self.db.x, self.db.y = p, rp, x, y
end

function XPBar:RestorePosition()
    self.frame:ClearAllPoints()
    if self.db.point then
        self.frame:SetPoint(self.db.point, UIParent, self.db.rel, self.db.x, self.db.y)
    else
        self.frame:SetPoint("CENTER", 0, -250)
        self:SavePosition()
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

    self.frame:EnableMouse(not db.locked or db.mouseOver)
    self:RestorePosition()
    self:UpdateTextVisibility(false)
    self.frame:Show()
end

-- XP Update
function XPBar:UpdateXP()
    if not self.frame then return end
    local bar   = self.frame.bar
    local rest  = bar.rest
    local max   = UnitXPMax("player")
    local curr  = UnitXP("player")
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

    if not self.db.mouseOver then
        self:SetXPText(curr, max, rested)
    else
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
    if not self.db.mouseOver then
        local curr, max = UnitXP("player"), UnitXPMax("player")
        local rested = GetXPExhaustion() or 0
        self:SetXPText(curr, max, rested)
    else
        if hovered then
            local curr, max = UnitXP("player"), UnitXPMax("player")
            local rested = GetXPExhaustion() or 0
            self:SetXPText(curr, max, rested)
        else
            self.frame.text:SetText("")
        end
    end
end

-- Options
function XPBar:BuildOptions()
    local get = function(info) return self.db[ info[#info] ] end
    local set = function(info, val) self.db[ info[#info] ] = val; self:ApplySettings(); self:UpdateXP() end

    local textureValues = function()
        local t = { ["Blizzard"] = "Blizzard" }
        if LSM then for _, name in ipairs(LSM:List("statusbar")) do t[name] = name end end
        return t
    end

    return {
        type = "group",
        name = L["XP Bar"],
        args = {
            locked = { type="toggle", name=L["Lock bar"], order=1, get=get, set=set },

            dimHeader = { type="header", name=L["Font"], order=2 },

            mouseOver = {
                type = "toggle",
                name = L["Show text only on mouseover"],
                desc = L["If enabled, the XP text will only show when hovering the bar."],
                order = 3,
                get = function() return self.db.mouseOver end,
                set = function(_, val)
                    self.db.mouseOver = val
                    self:ApplySettings()
                    self:UpdateXP()
                end,
            },

            fontSize = { type="range", name=L["Font Size"], min=8, max=24, step=1, order=5, get=get, set=set },
            fontOutline = {
                type="select", name=L["Font Outline"], order=6,
                values = { NONE="None", OUTLINE="Outline", THICKOUTLINE="Thick Outline" },
                get=get, set=set
            },
            
            posHeader = { type="header", name=L["Feeling and Position"], order=8 },

            posX = {
                type = "range",
                name = L["Position X"],
                desc = L["Horizontal offset of the XP bar"],
                order = 9,
                min = -1000, max = 1000, step = 1, bigStep = 5,
                get = function() return self.db.x or 0 end,
                set = function(_, val)
                    self.db.x = val
                    self:RestorePosition()
                end,
            },
            posY = {
                type = "range",
                name = L["Position Y"],
                desc = L["Vertical offset of the XP bar"],
                order = 10,
                min = -1000, max = 1000, step = 1, bigStep = 5,
                get = function() return self.db.y or 0 end,
                set = function(_, val)
                    self.db.y = val
                    self:RestorePosition()
                end,
            },            
            width  = { type="range",  name=L["Width"], min=100, max=800, step=10, order=11, get=get, set=set },
            height = { type="range",  name=L["Height"], min=10,  max=50,  step=1,  order=12, get=get, set=set },
            texture =   { type="select", name=L["Bar Texture"], values=textureValues, order=13,  get=get, set=set },
            -- bgHeader =  { type="header", name=L["Background"], order=10 },
            -- bgTexture = { type="select", name=L["Background Texture"], values=textureValues, order=11, get=get, set=set },
            -- bgColor =   { type="color", name=L["Background Color"], hasAlpha=true, order=12,
            --     get=function() local c=self.db.bgColor return c.r, c.g, c.b, c.a end,
            --     set=function(_, r,g,b,a) local c=self.db.bgColor c.r,c.g,c.b,c.a=r,g,b,a; self:ApplySettings() end
            -- },
            ticks = { type="toggle", name=L["Show Ticks"], order=14,
                get=function() return self.db.showTicks end,
                set=function(_, v) self.db.showTicks = v; self:ApplySettings() end },
        }
    }
end

function XPBar:OpenConfig()
    if YATP.OpenConfig then YATP:OpenConfig("XPBar") end
end
