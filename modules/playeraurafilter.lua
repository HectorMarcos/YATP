-- PlayerAuraFilter
-- Separa la logica de filtrado de auras del modulo PlayerAuras.
-- Empieza limpio (no reutiliza configuraciones previas de PlayerAuras).

local addonName, ns = ...
local YATP = YATP or LibStub("AceAddon-3.0"):GetAddon("YATP")
local L = ns and ns.L or setmetatable({}, { __index = function(t,k) return k end })

local Module = YATP:NewModule("PlayerAuraFilter")

------------------------------------------------------------
-- Defaults (limpios)
------------------------------------------------------------
local defaults = {
    profile = {
        enabled = true,
        knownBuffs = {}, -- formato: [name] = { hide = bool }
        -- Futuro: whitelist/blacklist modes, categorías, sources, etc.
    }
}

------------------------------------------------------------
-- Helpers
------------------------------------------------------------
local function NormalizeName(name)
    if type(name) == "string" then
        return name:gsub("^%s+",""):gsub("%s+$","")
    end
    return name
end

------------------------------------------------------------
-- Core API
------------------------------------------------------------
function Module:ShouldHideAura(name, isDebuff)
    -- Forzado: módulo temporalmente deshabilitado, nunca ocultar.
    return false
end

function Module:AddCustomBuff(name)
    local n = NormalizeName(name)
    if not n or n == "" then return end
    if not self.db.profile.knownBuffs[n] then
        self.db.profile.knownBuffs[n] = { hide = false }
        self:RebuildOptions()
    end
end

function Module:RemoveCustomBuff(name)
    local n = NormalizeName(name)
    if self.db.profile.knownBuffs[n] and not self.db.profile.knownBuffs[n]._default then
        self.db.profile.knownBuffs[n] = nil
        self:RebuildOptions()
    end
end

------------------------------------------------------------
-- Options
------------------------------------------------------------
function Module:RebuildOptions()
    if not self.options then return end
    self:BuildOptions(true)
end

function Module:BuildOptions(refreshOnly)
    local p = self.db.profile

    -- Forzar estado disabled siempre
    p.enabled = false

    local disabledMsg = (L["Temporarily disabled: the game's buff system changed and filtering will return in a future update."] or "Temporarily disabled: the game's buff system changed and filtering will return in a future update.") .. "\n\n" .. (L["Reason"] or "Reason") .. ": " .. (L["Recent aura frame/API changes require a safe reimplementation."] or "Recent aura frame/API changes require a safe reimplementation.") .. "\n" .. (L["Status"] or "Status") .. ": " .. (L["Any names you add are retained but no hiding is applied."] or "Any names you add are retained but no hiding is applied.") .. "\n" .. (L["Next Step"] or "Next Step") .. ": " .. (L["Module will be re-enabled once the new filtering system is finalized."] or "Module will be re-enabled once the new filtering system is finalized.")

    local defaultToggles = {}
    local customGroups = {}
    local defaultsList, customList = {}, {}
    for n,data in pairs(p.knownBuffs) do
        if data._default then table.insert(defaultsList, n) else table.insert(customList, n) end
    end
    table.sort(defaultsList)
    table.sort(customList)

    local orderCounter = 1
    for _, name in ipairs(defaultsList) do
        defaultToggles[name] = {
            type = "toggle",
            name = name,
            desc = L["Hide this buff when active."] or "Hide this buff when active.",
            order = orderCounter,
            get = function() return p.knownBuffs[name].hide end,
            set = function(_, v) p.knownBuffs[name].hide = v end,
        }
        orderCounter = orderCounter + 1
    end

    local customOrder = 1
    for _, name in ipairs(customList) do
        customGroups[name] = {
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
                    set = function(_, v) p.knownBuffs[name].hide = v end,
                    width = "half",
                },
                remove = {
                    type = "execute",
                    name = L["Remove"] or "Remove",
                    desc = L["Remove this custom buff from the list."] or "Remove this custom buff from the list.",
                    order = 2,
                    func = function() self:RemoveCustomBuff(name) end,
                },
            }
        }
        customOrder = customOrder + 1
    end

    self.options = {
        type = "group",
        name = L["Player Aura Filter"] or "Player Aura Filter",
        args = {
            general = {
                type = "group", inline = true, order = 1,
                name = L["General"] or "General",
                args = {
                    enabled = {
                        type = "toggle", order = 1, width = "full",
                        name = (L["Enable Filter"] or "Enable Filter") .. " (" .. (L["Disabled"] or "Disabled") .. ")",
                        desc = disabledMsg,
                        get = function() return false end,
                        set = function() end,
                        disabled = true,
                    },
                }
            },
            add = {
                type = "group", inline = true, order = 2,
                name = L["Custom Buffs"] or "Custom Buffs",
                args = {
                    newBuff = {
                        type = "input",
                        name = L["Add Buff"] or "Add Buff",
                        order = 1,
                        get = function() return p._pendingNewBuff or "" end,
                        set = function(_, val) p._pendingNewBuff = val end,
                    },
                    addBtn = {
                        type = "execute",
                        name = L["Add"] or "Add",
                        order = 2,
                        func = function()
                            local name = (p._pendingNewBuff or ""):gsub("^%s+",""):gsub("%s+$","")
                            if name ~= "" and not p.knownBuffs[name] then
                                p.knownBuffs[name] = { hide = false }
                                p._pendingNewBuff = ""
                                self:RebuildOptions()
                            end
                        end,
                    },
                }
            },
            defaults = {
                type = "group", inline = true, order = 3,
                name = L["Default Buffs"] or "Default Buffs",
                args = defaultToggles,
            },
            custom = {
                type = "group", inline = true, order = 4,
                name = L["Custom Added Buffs"] or "Custom Added Buffs",
                args = customGroups,
            },
        }
    }

    if YATP.AddModuleOptions then
        YATP:AddModuleOptions("PlayerAuraFilter", self.options, "Interface")
    end
end

------------------------------------------------------------
-- Lifecycle
------------------------------------------------------------
function Module:OnInitialize()
    self.db = YATP.db:RegisterNamespace("PlayerAuraFilter", defaults)
    -- Fuerza disabled ignorando valor previo.
    self.db.profile.enabled = false
    self:BuildOptions()
end

function Module:OnEnable()
    -- nada especial por ahora
end

function Module:OnDisable()
end

return Module
