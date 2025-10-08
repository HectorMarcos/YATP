-- PlayerAuras (formerly BetterBuffs integration)
-- Unifies player buff & debuff filtering and layout under YATP.
-- Provides configurable scaling, per-row counts, duration styling, and hide lists.
-- Future-ready for pattern filters or categorization.

local addonName, ns = ...
local YATP = YATP or LibStub("AceAddon-3.0"):GetAddon("YATP")
local L = ns and ns.L or setmetatable({}, { __index = function(t,k) return k end })

local Module = YATP:NewModule("PlayerAuras", "AceEvent-3.0")

------------------------------------------------------------
-- Defaults
------------------------------------------------------------
-- Filtering (knownBuffs) removed; moved to PlayerAuraFilter module (clean slate)
-- Legacy default buff list intentionally not migrated.

local defaults = {
    profile = {
        enabled = true,
    throttle = 0.12,           -- (antes 0.1) ligero aumento reduce frecuencia de layout
        manageBuffs = true,
        manageDebuffs = true,
        iconScale = 1.0,
        buffsPerRow = 8,
        debuffsPerRow = 8,
        growDirection = "LEFT",   -- LEFT or RIGHT
        sortMode = "original",    -- original / alpha
        durationFontSize = 12,
        durationOutline = "OUTLINE",
        durationFont = "STANDARD_TEXT_FONT",
        -- Filtering data moved to PlayerAuraFilter; no longer stored here.
    }
}

------------------------------------------------------------
-- Local state
------------------------------------------------------------
local dirty = false
local lastUpdate = 0
local hooked = false

------------------------------------------------------------
-- Utility
------------------------------------------------------------
local function SafeCopyTable(src)
    if type(src) ~= "table" then return src end
    local t = {}
    for k,v in pairs(src) do
        if type(v) == "table" then
            t[k] = SafeCopyTable(v)
        else
            t[k] = v
        end
    end
    return t
end

local function FetchFontPath(fontKey)
    if LibStub and LibStub("LibSharedMedia-3.0", true) then
        local LSM = LibStub("LibSharedMedia-3.0")
        return LSM:Fetch("font", fontKey or "Friz Quadrata TT")
    end
    return _G.STANDARD_TEXT_FONT
end

------------------------------------------------------------
-- Migration
------------------------------------------------------------
-- Migration of BetterBuffs filtering intentionally omitted (filtering moved modules)
local function MigrateFromBetterBuffs(moduleDB)
    if YATP.db.profile.migratedBetterBuffs then return end
    if _G.BetterBuffsDB and _G.BetterBuffsDB.profile then
        local src = _G.BetterBuffsDB.profile
        local map = {
            enabled = "enabled",
            iconScale = "iconScale",
            buffsPerRow = "buffsPerRow",
            durationFontSize = "durationFontSize",
            durationOutline = "durationOutline",
            durationFont = "durationFont",
        }
        for old,newKey in pairs(map) do
            if moduleDB[newKey] == nil and src[old] ~= nil then
                moduleDB[newKey] = src[old]
            end
        end
        YATP.db.profile.migratedBetterBuffs = true
    end
end

------------------------------------------------------------
-- Core Refresh Logic
------------------------------------------------------------
function Module:MarkDirty()
    dirty = true
end

local auraButtonsCache = { buffs = {}, debuffs = {} }
local auraButtonsCount = { buffs = 0, debuffs = 0 }

function Module:Refresh()
    if not self.db.profile.enabled then return end

    -- reset counts (no wipe para evitar realloc)
    auraButtonsCount.buffs = 0
    auraButtonsCount.debuffs = 0

    local p = self.db.profile
    if p.manageBuffs then
        local i = 1
        while true do
            local name = UnitBuff("player", i)
            if not name then break end
            local button = _G["BuffButton"..i]
            if button then
                local filterMod = YATP:GetModule("PlayerAuraFilter", true)
                local hide = false
                if filterMod and filterMod.db and filterMod.db.profile.enabled then
                    hide = filterMod:ShouldHideAura(name, false)
                end
                if hide then
                    button:Hide()
                else
                    button:Show()
                    button.__paName = name
                    auraButtonsCount.buffs = auraButtonsCount.buffs + 1
                    auraButtonsCache.buffs[auraButtonsCount.buffs] = button
                end
            end
            i = i + 1
        end
        -- nil out sobrantes previo layout (si la lista se achicó)
        for j = auraButtonsCount.buffs + 1, #auraButtonsCache.buffs do
            auraButtonsCache.buffs[j] = nil
        end
    end

    if p.manageDebuffs and DebuffButton_UpdateAnchors then
        local i = 1
        while true do
            local name = UnitDebuff("player", i)
            if not name then break end
            local button = _G["DebuffButton"..i]
            if button then
                button.__paName = name
                auraButtonsCount.debuffs = auraButtonsCount.debuffs + 1
                auraButtonsCache.debuffs[auraButtonsCount.debuffs] = button
            end
            i = i + 1
        end
        for j = auraButtonsCount.debuffs + 1, #auraButtonsCache.debuffs do
            auraButtonsCache.debuffs[j] = nil
        end
    end

    if p.sortMode == "alpha" then
        table.sort(auraButtonsCache.buffs, function(a,b) return (a.__paName or "") < (b.__paName or "") end)
        table.sort(auraButtonsCache.debuffs, function(a,b) return (a.__paName or "") < (b.__paName or "") end)
    end

    self:Layout("buffs", auraButtonsCache.buffs, p.buffsPerRow)
    self:Layout("debuffs", auraButtonsCache.debuffs, p.debuffsPerRow, true)
end

function Module:Layout(kind, list, perRow, isDebuff)
    if not perRow or perRow < 1 then perRow = 8 end
    local p = self.db.profile
    local scale = p.iconScale or 1
    local fontSize = p.durationFontSize or 12
    local outline = p.durationOutline or "OUTLINE"
    local fontPath = FetchFontPath(p.durationFont)

    local anchorFrame
    if kind == "buffs" then
        anchorFrame = BuffFrame
    else
        anchorFrame = DebuffFrame or BuffFrame -- fallback
    end
    if not anchorFrame then return end

    local spacingX, spacingY = 5, 5
    local extraRowSpace = (fontSize * scale * 1.4)
    local growLeft = (p.growDirection == "LEFT")

    for index, button in ipairs(list) do
        button:SetScale(scale)
        button:ClearAllPoints()
        local col = (index - 1) % perRow
        local row = math.floor((index - 1) / perRow)

        if not button.__paBaseW then
            button.__paBaseW = button:GetWidth()
            button.__paBaseH = button:GetHeight()
        end
        local baseW = button.__paBaseW * scale
        local baseH = button.__paBaseH * scale

        local xOffset = col * (baseW + spacingX)
        if growLeft then xOffset = -xOffset end
        local yOffset = -row * (baseH + spacingY + extraRowSpace)

        local point, relPoint
        if growLeft then
            point, relPoint = "TOPRIGHT", "TOPRIGHT"
        else
            point, relPoint = "TOPLEFT", "TOPLEFT"
        end

        button:SetPoint(point, anchorFrame, relPoint, xOffset, yOffset)

        -- duration styling
        if button.duration then
            if not button.__paLastFont or button.__paLastFont ~= fontPath or button.__paLastSize ~= fontSize or button.__paLastOutline ~= outline then
                button.duration:SetFont(fontPath, fontSize * scale, outline)
                button.__paLastFont = fontPath
                button.__paLastSize = fontSize
                button.__paLastOutline = outline
            end
            if not button.__paDurationReanchored then
                button.duration:ClearAllPoints()
                button.duration:SetPoint("TOP", button, "BOTTOM", 0, -2)
                button.__paDurationReanchored = true
            end
            local text = button.duration:GetText()
            if text and text ~= button.__paLastDurationText then
                -- Solo aplicar gsub si contiene espacio + unidad probable (simple heuristic)
                if text:find(" ") then
                    local newText = text:gsub("(%d+)%s+([smhdSMHD])", "%1%2")
                    if newText ~= text then
                        button.duration:SetText(newText)
                        text = newText
                    end
                end
                button.__paLastDurationText = text
            end
        end
    end
end

------------------------------------------------------------
-- Events / Update
------------------------------------------------------------
function Module:OnInitialize()
    self.db = YATP.db:RegisterNamespace("PlayerAuras", defaults)
    MigrateFromBetterBuffs(self.db.profile)
    self:BuildOptions()
end

function Module:OnEnable()
    if not self.db.profile.enabled then return end
    self:RegisterEvent("UNIT_AURA", function(_,unit) if unit == "player" then self:MarkDirty() end end)
    self:RegisterEvent("PLAYER_ENTERING_WORLD", function() self:MarkDirty() end)

    if not hooked and type(BuffFrame_UpdateAllBuffAnchors) == "function" then
        hooksecurefunc("BuffFrame_UpdateAllBuffAnchors", function() self:MarkDirty() end)
        hooked = true
    end

    if not self.updateFrame then
        self.updateFrame = CreateFrame("Frame")
        self.updateFrame:SetScript("OnUpdate", function(_, elapsed)
            if not dirty then return end
            lastUpdate = lastUpdate + elapsed
            local thr = self.db.profile.throttle or 0.12
            if thr < 0.06 then thr = 0.06 end -- anti micro spam
            if lastUpdate >= thr then
                lastUpdate = 0
                dirty = false
                self:Refresh()
            end
        end)
    end

    self:MarkDirty()
end

function Module:OnDisable()
    -- we still leave layout to Blizzard, no restoration needed
end

------------------------------------------------------------
-- Options
------------------------------------------------------------
function Module:BuildOptions()
    local p = self.db.profile
    local function get(info) return p[info[#info]] end
    local function set(info, val) p[info[#info]] = val; self:MarkDirty() end

    -- Build buff toggle list (separate panel) with optional search filtering
    local defaultToggles = {}
    local customToggles = {}
    local defaultNames, customNames = {}, {}
    for n, data in pairs(p.knownBuffs) do
        if data._default then table.insert(defaultNames, n) else table.insert(customNames, n) end
    end
    table.sort(defaultNames)
    table.sort(customNames)

    local orderCounter = 1
    for _, name in ipairs(defaultNames) do
        defaultToggles[name] = {
            type = "toggle",
            name = name,
            desc = L["Hide this buff when active."] or "Hide this buff when active.",
            order = orderCounter,
            get = function() return p.knownBuffs[name].hide end,
            set = function(_, v) p.knownBuffs[name].hide = v; self:MarkDirty() end,
        }
        orderCounter = orderCounter + 1
    end

    local customOrder = 1
    for _, name in ipairs(customNames) do
        customToggles[name] = {
            type = "group",
            name = name,
            inline = true,
            order = customOrder,
            args = {
                toggle = {
                    type = "toggle",
                    name = L["Hide"] or "Hide",
                    desc = L["Hide this buff when active."] or "Hide this buff when active.",
                    order = 1,
                    get = function() return p.knownBuffs[name].hide end,
                    set = function(_, v) p.knownBuffs[name].hide = v; self:MarkDirty() end,
                    width = "half",
                },
                remove = {
                    type = "execute",
                    name = L["Remove"] or "Remove",
                    desc = L["Remove this custom buff from the list."] or "Remove this custom buff from the list.",
                    order = 2,
                    func = function()
                        p.knownBuffs[name] = nil
                        self:BuildOptions()
                        self:MarkDirty()
                    end,
                },
            }
        }
        customOrder = customOrder + 1
    end

    self.options = {
        type = "group",
        name = L["PlayerAuras"] or "PlayerAuras",
        args = {
            general = {
                type = "group", inline = true, order = 1,
                name = L["General"] or "General",
                args = {
                    enabled = { type="toggle", name=L["Enable PlayerAuras"] or "Enable PlayerAuras", order=1, width="full",
                        desc = (L["Enable or disable the PlayerAuras module (all features)."] or "Enable or disable the PlayerAuras module (all features).") .. "\n" .. (L["Requires /reload to fully apply enabling or disabling."] or "Requires /reload to fully apply enabling or disabling."),
                        get=function() return p.enabled end,
                        set=function(_,v) p.enabled=v; if v then self:OnEnable() end self:MarkDirty(); if YATP and YATP.ShowReloadPrompt then YATP:ShowReloadPrompt() end end },
                    manageBuffs = { type="toggle", name=L["Manage Buffs"] or "Manage Buffs", order=2, width="full",
                        desc = L["If enabled, PlayerAuras repositions your buffs (visual layout)."] or "If enabled, PlayerAuras repositions your buffs (visual layout).",
                        get=get, set=set },
                    manageDebuffs = { type="toggle", name=L["Manage Debuffs"] or "Manage Debuffs", order=3, width="full",
                        desc = L["If enabled, PlayerAuras repositions your debuffs applying the same scaling and sorting."] or "If enabled, PlayerAuras repositions your debuffs applying the same scaling and sorting.",
                        get=get, set=set },
                }
            },
            layout = {
                type = "group", inline = true, order = 2,
                name = L["Layout"] or "Layout",
                args = {
                    iconScale = { type="range", name=L["Icon Scale"] or "Icon Scale", min=0.5, max=2.0, step=0.05, order=1, get=get, set=set },
                    buffsPerRow = { type="range", name=L["Buffs per Row"] or "Buffs per Row", min=1, max=16, step=1, order=2, get=get, set=set },
                    debuffsPerRow = { type="range", name=L["Debuffs per Row"] or "Debuffs per Row", min=1, max=16, step=1, order=3, get=get, set=set },
                    growDirection = { type="select", name=L["Grow Direction"] or "Grow Direction", order=4, values={ LEFT=L["Left"] or "Left", RIGHT=L["Right"] or "Right" }, get=get, set=set },
                    sortMode = { type="select", name=L["Sort Mode"] or "Sort Mode", order=5, values={ original=L["Original"] or "Original", alpha=L["Alphabetical"] or "Alphabetical" }, get=get, set=set },
                }
            },
            duration = {
                type = "group", inline = true, order = 3,
                name = L["Duration Text"] or "Duration Text",
                args = {
                    durationFontSize = { type="range", name=L["Font Size"] or "Font Size", min=8, max=24, step=1, order=1, get=get, set=set },
                    durationOutline = { type="select", name=L["Outline"] or "Outline", order=2, values={ NONE=L["None"] or "None", OUTLINE=L["Thin"] or "Thin", THICKOUTLINE=L["Thick"] or "Thick" }, get=get, set=set },
                    durationFont = { type="select", name=L["Font"] or "Font", order=3,
                        values = function()
                            local fonts = {}
                            if LibStub and LibStub("LibSharedMedia-3.0", true) then
                                local LSM = LibStub("LibSharedMedia-3.0")
                                for _, fname in ipairs(LSM:List("font")) do fonts[fname] = fname end
                            end
                            if next(fonts) == nil then fonts["STANDARD_TEXT_FONT"] = L["Game Default"] or "Game Default" end
                            return fonts
                        end,
                        get=function() return p.durationFont end,
                        set=function(_,v) p.durationFont=v; self:MarkDirty() end
                    },
                }
            },
        },
    }

    if YATP.AddModuleOptions then
        YATP:AddModuleOptions("PlayerAuras", self.options, "Interface")
    end
end

------------------------------------------------------------
-- Public API (future)
------------------------------------------------------------
-- function Module:AddKnownBuff(name)
-- end

return Module
