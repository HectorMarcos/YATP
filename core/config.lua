--========================================================--
-- YATP - Core.lua
-- Yet Another Tweaks Pack
--========================================================--
-- NOTE: This is the current configuration implementation.
-- The old root-level 'config.lua' (duplicate) was removed to avoid confusion.
-- Keep all option registration logic consolidated here.

local ADDON_NAME = "YATP"
local AceAddon = LibStub("AceAddon-3.0")
local AceConfig = LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local AceConfigRegistry = LibStub("AceConfigRegistry-3.0")
local AceDB = LibStub("AceDB-3.0")
local LSM = LibStub("LibSharedMedia-3.0", true)
local L = LibStub("AceLocale-3.0"):GetLocale(ADDON_NAME, true)

-------------------------------------------------
-- Core addon object
-------------------------------------------------
local YATP = LibStub("AceAddon-3.0"):GetAddon("YATP", true)
if not YATP then return end

-------------------------------------------------
-- Defaults
-------------------------------------------------
local defaults = {
    profile = {
        modules = {}, -- cada módulo guardará aquí su config
        debug = false, -- legacy flag (will mirror debugMode for backward compatibility)
        debugMode = false, -- nuevo toggle unificado para todos los módulos
    }
}

-------------------------------------------------
-- OnInitialize
-------------------------------------------------
function YATP:OnInitialize()
    self.db = AceDB:New("YATP_DB", defaults, true)
    self.modules = self.modules or {}
    self.categories = self.categories or {}          -- tablas de opciones por categoría
    self.categoryFrames = self.categoryFrames or {}  -- referencias a frames de InterfaceOptions

    local version = GetAddOnMetadata(ADDON_NAME, "Version") or "?"

    -- Panel raíz (solo página "About"). Las categorías se registran como sub-panels
    self.options = {
        type = "group",
        name = "YATP",
        args = {
            desc = { type = "description", name = L["A modular collection of interface tweaks and utilities."], fontSize = "medium", order = 1 },
            author = { type = "description", name = string.format("%s: %s", L["Author"] or "Author", "Zavah"), order = 2 },
            ver = { type = "description", name = string.format("%s: %s", L["Version"] or "Version", version), order = 3 },
            spacer = { type = "description", name = "\n", order = 4 },
            note = { type = "description", name = L["Select a category tab to configure modules."] or "Select a category tab to configure modules.", order = 5 },
        },
    }

    AceConfig:RegisterOptionsTable("YATP", self.options)
    self.optionsFrame = AceConfigDialog:AddToBlizOptions("YATP", "YATP")

    -- Panel padre 'Interface Hub' bajo YATP
    self.interfaceHubOptions = {
        type = "group",
        name = L["Interface Hub"] or "Interface Hub",
        childGroups = "tree",
        args = {
            info = { type = "description", name = L["Select a module from the list on the left."] or "Select a module from the list on the left.", order = 1 },
        }
    }
    AceConfig:RegisterOptionsTable("YATP-InterfaceHub", self.interfaceHubOptions)
    self.interfaceHubFrame = AceConfigDialog:AddToBlizOptions("YATP-InterfaceHub", L["Interface Hub"] or "Interface Hub", "YATP")

    -- Panel padre 'Quality of Life' separado
    self.qolHubOptions = {
        type = "group",
        name = L["Quality of Life"] or "Quality of Life",
        childGroups = "tree",
        args = {
            info = { type = "description", name = L["Select a module from the list on the left."] or "Select a module from the list on the left.", order = 1 },
        }
    }
    AceConfig:RegisterOptionsTable("YATP-QualityOfLife", self.qolHubOptions)
    self.qolHubFrame = AceConfigDialog:AddToBlizOptions("YATP-QualityOfLife", L["Quality of Life"] or "Quality of Life", "YATP")

    -- Panel padre 'Extras' para fixes / utilidades pequeñas
    self.extrasHubOptions = {
        type = "group",
        name = L["Extras"] or "Extras",
        childGroups = "tree",
        args = {
            info = { type = "description", name = L["Miscellaneous small toggles and fixes."] or "Miscellaneous small toggles and fixes.", order = 1 },
            debugHeader = { type="header", name = L["Debug"] or "Debug", order = 5 },
            debugMode = {
                type = "toggle",
                name = L["Debug Mode"] or "Debug Mode",
                desc = L["Enable verbose debug output for all modules that support it."] or "Enable verbose debug output for all modules that support it.",
                order = 6,
                get = function() return self.db and self.db.profile.debugMode end,
                set = function(_, val)
                    if not self.db then return end
                    self.db.profile.debugMode = val
                    -- mirror legacy flag for modules still checking .debug
                    self.db.profile.debug = val
                    if val then
                        self:Print("Debug Mode ON")
                    else
                        self:Print("Debug Mode OFF")
                    end
                end,
            },
        }
    }
    AceConfig:RegisterOptionsTable("YATP-Extras", self.extrasHubOptions)
    self.extrasHubFrame = AceConfigDialog:AddToBlizOptions("YATP-Extras", L["Extras"] or "Extras", "YATP")

    -- Internal lookup table so OpenConfig can quickly determine which hub a module lives in
    self.interfaceHubModules = self.interfaceHubModules or {}

    -- Comando por chat
    self:RegisterChatCommand("yatp", "ChatCommand")
end

-------------------------------------------------
-- Crear / asegurar categoría (panel secundario)
-------------------------------------------------
function YATP:EnsureCategory() return nil end

-------------------------------------------------
-- OnEnable
-------------------------------------------------
function YATP:OnEnable()
end

-------------------------------------------------
-- Module registration
-------------------------------------------------
function YATP:RegisterModule(name, module)
    if not name or not module then
        return
    end

    if self.modules[name] then
        return
    end

    self.modules[name] = module

    if type(module.OnModuleInitialize) == "function" then
        -- Initialize the module's own state / DB migrations
        pcall(function() module:OnModuleInitialize() end)
    end
end

-------------------------------------------------
-- Añadir opciones al panel
-------------------------------------------------
function YATP:AddModuleOptions(name, optionsTable, panel)
    if not name or not optionsTable then return end
    -- panel: "Interface" (default) | "QualityOfLife" | "Extras"
    local target
    if panel == "QualityOfLife" then
        target = self.qolHubOptions
    elseif panel == "Extras" then
        target = self.extrasHubOptions
    else
        target = self.interfaceHubOptions
    end
    if not target then return end
    local args = target.args
    local order = 10
    for k,v in pairs(args) do
        if type(v)=="table" and v.type=="group" and k ~= "info" then
            order = math.max(order, (v.order or 10)+1)
        end
    end
    args[name] = {
        type = "group",
        name = L[name] or name,
        order = order,
        args = optionsTable.args or optionsTable,
    }
    -- Notify the specific registry id used
    if panel == "QualityOfLife" then
        AceConfigRegistry:NotifyChange("YATP-QualityOfLife")
        self.interfaceHubModules[name] = { panel = "qol" }
    elseif panel == "Extras" then
        AceConfigRegistry:NotifyChange("YATP-Extras")
        self.interfaceHubModules[name] = { panel = "extras" }
    else
        AceConfigRegistry:NotifyChange("YATP-InterfaceHub")
        self.interfaceHubModules[name] = { panel = "interface" }
    end
end

-------------------------------------------------
-- Abrir configuración
-------------------------------------------------
function YATP:OpenConfig(target)
    -- Abre el panel raíz siempre
    InterfaceOptionsFrame_OpenToCategory(self.optionsFrame)
    InterfaceOptionsFrame_OpenToCategory(self.optionsFrame)
    if not target or target == "" then return end
    if target == "InterfaceHub" or target == "interfacehub" then
        InterfaceOptionsFrame_OpenToCategory(self.interfaceHubFrame)
        InterfaceOptionsFrame_OpenToCategory(self.interfaceHubFrame)
        return
    elseif target == "QualityOfLife" or target == "qualityoflife" or target == "qol" then
        InterfaceOptionsFrame_OpenToCategory(self.qolHubFrame)
        InterfaceOptionsFrame_OpenToCategory(self.qolHubFrame)
        return
    elseif target == "Extras" or target == "extras" then
        InterfaceOptionsFrame_OpenToCategory(self.extrasHubFrame)
        InterfaceOptionsFrame_OpenToCategory(self.extrasHubFrame)
        return
    end
    -- Attempt to open a specific module inside the correct hub
    if self.interfaceHubModules and self.interfaceHubModules[target] then
        local meta = self.interfaceHubModules[target]
        if meta.panel == "qol" then
            InterfaceOptionsFrame_OpenToCategory(self.qolHubFrame)
            InterfaceOptionsFrame_OpenToCategory(self.qolHubFrame)
            AceConfigDialog:SelectGroup("YATP-QualityOfLife", target)
        elseif meta.panel == "extras" then
            InterfaceOptionsFrame_OpenToCategory(self.extrasHubFrame)
            InterfaceOptionsFrame_OpenToCategory(self.extrasHubFrame)
            AceConfigDialog:SelectGroup("YATP-Extras", target)
        else
            InterfaceOptionsFrame_OpenToCategory(self.interfaceHubFrame)
            InterfaceOptionsFrame_OpenToCategory(self.interfaceHubFrame)
            AceConfigDialog:SelectGroup("YATP-InterfaceHub", target)
        end
        return
    end
    -- Fallback: abrir por label directo (por si algo quedó raíz)
    local label = L[target] or target
    InterfaceOptionsFrame_OpenToCategory(label)
    InterfaceOptionsFrame_OpenToCategory(label)
end

-- Hub eliminado

-------------------------------------------------
-- Chat Command
-------------------------------------------------
function YATP:ChatCommand(input)
    input = input and strtrim(input):lower() or ""

    if input == "" then
        self:OpenConfig()
    elseif input == "modules" then
    if self.db and self.db.profile.debug then
        self:Print("Registered modules:")
    end
        for name in pairs(self.modules) do
            if self.db and self.db.profile.debug then
                self:Print(" - " .. name)
            end
        end
    elseif input == "reload" then
        ReloadUI()
    else
    self:Print("/yatp  - abre la configuración")
    self:Print("/yatp modules - lista módulos (requiere debug activado para ver salida)")
    self:Print("/yatp reload  - recarga la interfaz")
    self:Print("/yatp debug   - alterna mensajes de diagnóstico")
    end
end

-------------------------------------------------
-- Toggle debug via command
-------------------------------------------------
-- Añadimos un comando simple: /yatp debug
local origChatCommand = YATP.ChatCommand
function YATP:ChatCommand(input)
    input = input and strtrim(input):lower() or ""
    if input == "debug" then
        self.db.profile.debug = not self.db.profile.debug
        self:Print("Debug " .. (self.db.profile.debug and "activado" or "desactivado"))
        return
    end
    origChatCommand(self, input)
end

-------------------------------------------------
-- Helper para localización
-------------------------------------------------
function YATP:L(key)
    return L[key] or key
end

-------------------------------------------------
-- Global Debug Helper API
-------------------------------------------------
function YATP:IsDebug()
    if not self.db or not self.db.profile then return false end
    return self.db.profile.debugMode or self.db.profile.debug
end

-- Backwards compat: modules calling YATP:Debug(msg)
function YATP:Debug(msg)
    -- Debug messages disabled
end

-------------------------------------------------
-- Reload Prompt Helper (used after toggling modules)
-------------------------------------------------
-- Static popup definition (idempotent)
StaticPopupDialogs["YATP_RELOAD_UI"] = StaticPopupDialogs["YATP_RELOAD_UI"] or {
    text = "A reload (/reload) is recommended to fully apply this change. Reload now?",
    button1 = YES,
    button2 = CANCEL,
    OnAccept = function() ReloadUI() end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

function YATP:ShowReloadPrompt()
    if not StaticPopupDialogs["YATP_RELOAD_UI"] then return end
    if not InCombatLockdown or (InCombatLockdown and not InCombatLockdown()) then
        StaticPopup_Show("YATP_RELOAD_UI")
    else
        -- Combat lockdown: delay prompt until out of combat
        local f = CreateFrame("Frame")
        f:RegisterEvent("PLAYER_REGEN_ENABLED")
        f:SetScript("OnEvent", function(self)
            self:UnregisterEvent("PLAYER_REGEN_ENABLED")
            StaticPopup_Show("YATP_RELOAD_UI")
        end)
    end
end
