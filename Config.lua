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
    }
}

-------------------------------------------------
-- OnInitialize
-------------------------------------------------
function YATP:OnInitialize()
    self.db = AceDB:New("YATP_DB", defaults, true)
    self.modules = self.modules or {}

    self:Print("|cff33ff99YATP|r inicializando...")

    -- Tabla de opciones base
    self.options = {
        type = "group",
        name = "YATP - Yet Another Tweaks Pack",
        args = {
            general = {
                type = "group",
                name = L["General"],
                order = 1,
                args = {
                    description = {
                        type = "description",
                        name = L["A modular collection of interface tweaks and utilities."],
                        fontSize = "medium",
                        order = 1,
                    },
                },
            },
        },
    }

    -- Registrar opciones en el panel de interfaz
    AceConfig:RegisterOptionsTable("YATP", self.options)
    self.optionsFrame = AceConfigDialog:AddToBlizOptions("YATP", "YATP")

    -- Comando por chat
    self:RegisterChatCommand("yatp", "ChatCommand")

    self:Print("YATP inicializado correctamente.")
end

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
function YATP:AddModuleOptions(name, optionsTable)
    if not name or not optionsTable then return end
    if not self.options.args then return end

    self.options.args[name] = {
        type = "group",
        name = L[name] or name,
        order = 10 + (#self.options.args),
        args = optionsTable.args or {},
    }

    AceConfigRegistry:NotifyChange("YATP")
    self:Print("Opciones registradas para módulo: " .. name)
end

-------------------------------------------------
-- Abrir configuración
-------------------------------------------------
function YATP:OpenConfig(target)
    InterfaceOptionsFrame_OpenToCategory(self.optionsFrame)
    InterfaceOptionsFrame_OpenToCategory(self.optionsFrame) -- doble llamada por bug clásico de Blizzard

    if target and self.options.args[target] then
        AceConfigDialog:SelectGroup("YATP", target)
    end
end

-------------------------------------------------
-- Chat Command
-------------------------------------------------
function YATP:ChatCommand(input)
    input = input and input:trim():lower() or ""

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
