--========================================================--
-- YATP - Core.lua
-- Yet Another Tweaks Pack
--========================================================--

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
        -- remove hub flags
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

    self:Print("|cff33ff99YATP|r inicializando...")

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

    -- Tabla para mapping de módulos registrados (para open rápido)
    self.interfaceHubModules = self.interfaceHubModules or {}

    -- Comando por chat
    self:RegisterChatCommand("yatp", "ChatCommand")

    self:Print("YATP inicializado correctamente.")
end

-------------------------------------------------
-- Crear / asegurar categoría (panel secundario)
-------------------------------------------------
function YATP:EnsureCategory() return nil end

-------------------------------------------------
-- OnEnable
-------------------------------------------------
function YATP:OnEnable()
    self:Print("YATP cargado. Usa /yatp para configurar.")
end

-------------------------------------------------
-- Registro de módulos
-------------------------------------------------
function YATP:RegisterModule(name, module)
    if not name or not module then
        self:Print("Error: módulo inválido.")
        return
    end

    if self.modules[name] then
        self:Print("Módulo '" .. name .. "' ya está registrado.")
        return
    end

    self.modules[name] = module
    self:Print("Registrando módulo: " .. name)

    if type(module.OnModuleInitialize) == "function" then
        -- Inicializar el módulo
        local success, err = pcall(function() module:OnModuleInitialize() end)
        if not success then
            self:Print("Error inicializando módulo " .. name .. ": " .. tostring(err))
        else
            self:Print("Módulo " .. name .. " inicializado correctamente.")
        end
    end
end

-------------------------------------------------
-- Añadir opciones al panel
-------------------------------------------------
function YATP:AddModuleOptions(name, optionsTable, panel)
    if not name or not optionsTable then return end
    -- panel: "Interface" (default) o "QualityOfLife"
    local target = (panel == "QualityOfLife") and self.qolHubOptions or self.interfaceHubOptions
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
    else
        AceConfigRegistry:NotifyChange("YATP-InterfaceHub")
    end
    self.interfaceHubModules[name] = { panel = (panel == "QualityOfLife") and "qol" or "interface" }
    self:Print(string.format("Módulo '%s' añadido al panel %s", name, (panel == "QualityOfLife" and "Quality of Life" or "Interface Hub")))
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
    end
    -- Intentar abrir módulo en el panel adecuado
    if self.interfaceHubModules and self.interfaceHubModules[target] then
        local meta = self.interfaceHubModules[target]
        if meta.panel == "qol" then
            InterfaceOptionsFrame_OpenToCategory(self.qolHubFrame)
            InterfaceOptionsFrame_OpenToCategory(self.qolHubFrame)
            AceConfigDialog:SelectGroup("YATP-QualityOfLife", target)
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
        self:Print("Módulos registrados:")
        for name in pairs(self.modules) do
            self:Print(" - " .. name)
        end
    elseif input == "reload" then
        ReloadUI()
    else
        self:Print("Comandos disponibles:")
        self:Print("/yatp → abre la configuración")
        self:Print("/yatp modules → lista los módulos activos")
        self:Print("/yatp reload → recarga la interfaz")
    end
end

-------------------------------------------------
-- Helper para localización
-------------------------------------------------
function YATP:L(key)
    return L[key] or key
end
