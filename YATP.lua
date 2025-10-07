--========================================================--
-- YATP - Core (Ace3)
--========================================================--
local ADDON_NAME = "YATP"

local AceAddon        = LibStub("AceAddon-3.0")
local AceConfig       = LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local AceConfigReg    = LibStub("AceConfigRegistry-3.0")
local AceDB           = LibStub("AceDB-3.0")

local L = LibStub("AceLocale-3.0"):GetLocale(ADDON_NAME, true) or setmetatable({}, { __index=function(_,k) return k end })

local YATP = AceAddon:NewAddon(ADDON_NAME, "AceConsole-3.0", "AceEvent-3.0")
_G.YATP = YATP

-- Defaults
local defaults = {
    profile = {
        modules = {},
    }
}

function YATP:OnInitialize()
    self.db = AceDB:New("YATP_DB", defaults, true)

    -- Base options table
    self.options = {
        type = "group",
        name = "YATP - Yet Another Tweaks Pack",
        args = {
            general = {
                type = "group",
                name = L["General"] or "General",
                order = 1,
                args = {
                    desc = {
                        type = "description",
                        name = L["A modular collection of interface tweaks and utilities."] or "A modular collection of interface tweaks and utilities.",
                        order = 1,
                        fontSize = "medium",
                    },
                },
            },
        },
    }

    AceConfig:RegisterOptionsTable(ADDON_NAME, self.options)
    self.optionsFrame = AceConfigDialog:AddToBlizOptions(ADDON_NAME, ADDON_NAME)

    self:RegisterChatCommand("yatp", "ChatCommand")
end

function YATP:OnEnable()
    -- Intentionally quiet (no prints)
end

-- Add module options into main panel
function YATP:AddModuleOptions(name, optionsTable)
    if not name or not optionsTable then return end
    if not self.options.args then return end

    self.options.args[name] = {
        type  = "group",
        name  = L[name] or name,
        order = 10 + (self._optcount or 0),
        args  = optionsTable.args or {},
    }
    self._optcount = (self._optcount or 0) + 1
    AceConfigReg:NotifyChange(ADDON_NAME)
end

-- Open config (and optionally select a group)
function YATP:OpenConfig(target)
    InterfaceOptionsFrame_OpenToCategory(self.optionsFrame)
    InterfaceOptionsFrame_OpenToCategory(self.optionsFrame)
    if target and self.options.args[target] then
        AceConfigDialog:SelectGroup(ADDON_NAME, target)
    end
end

function YATP:ChatCommand(input)
    input = input and input:trim():lower() or ""
    if input == "" then
        self:OpenConfig()
    elseif input == "modules" then
        for name in pairs(self.modules or {}) do
            self:Print(" - "..name)
        end
    elseif input == "reload" then
        ReloadUI()
    else
        self:Print("/yatp  - open config")
        self:Print("/yatp modules - list modules")
        self:Print("/yatp reload  - reload UI")
    end
end

function YATP:L(key) return L[key] or key end
