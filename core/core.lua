--========================================================--
-- YATP - Core
--========================================================--

local YATP = LibStub("AceAddon-3.0"):NewAddon("YATP", "AceConsole-3.0", "AceEvent-3.0")
local LSM  = LibStub("LibSharedMedia-3.0", true)

_G.YATP = YATP  -- Por si quieres acceder desde otros addons

-------------------------------------------------
-- Default settings
-------------------------------------------------
local defaults = {
    profile = {
        modules = {}, -- Cada módulo guardará sus datos aquí
    }
}

-------------------------------------------------
-- Initialize
-------------------------------------------------
function YATP:OnInitialize()
    self.db = LibStub("AceDB-3.0"):New("YATP_DB", defaults, true)
    self.modules = {}

    -- Sistema de configuración base
    self.options = {
        type = "group",
        name = "YATP - Yet Another Tweaks Pack",
        args = {
            general = {
                type = "group",
                name = "General",
                order = 1,
                args = {
                    description = {
                        type = "description",
                        name = "Colección modular de mejoras y tweaks para WoW.",
                        order = 0,
                    },
                },
            },
        },
    }

    -- Registrar en el panel de opciones
    LibStub("AceConfig-3.0"):RegisterOptionsTable("YATP", self.options)
    self.optionsFrame = LibStub("AceConfigDialog-3.0"):AddToBlizOptions("YATP", "YATP")

    -- Comando de chat
    self:RegisterChatCommand("yatp", "ChatCommand")
end

-------------------------------------------------
-- OnEnable (al cargar el addon)
-------------------------------------------------
function YATP:OnEnable()
    self:Print("YATP cargado. Usa /yatp para configurar.")
end

-------------------------------------------------
-- Módulos
-------------------------------------------------
function YATP:RegisterModule(name, module)
    if not name or not module then
        self:Print("Error: módulo inválido.")
        return
    end

    self.modules[name] = module

    -- Inicializar módulo si tiene función propia
    if type(module.OnModuleInitialize) == "function" then
        module:OnModuleInitialize()
    end

    self:Print("Módulo cargado: " .. name)
end

-------------------------------------------------
-- Opciones de Módulos
-------------------------------------------------
function YATP:AddModuleOptions(name, optionsTable)
    if not name or not optionsTable then return end
    if not self.options.args then return end

    self.options.args[name] = {
        type = "group",
        name = name,
        order = 10 + (#self.options.args),
        args = optionsTable.args or {},
    }

    -- Actualizar el panel
    LibStub("AceConfigRegistry-3.0"):NotifyChange("YATP")
end

-------------------------------------------------
-- Abrir configuración desde código o chat
-------------------------------------------------
function YATP:OpenConfig(target)
    InterfaceOptionsFrame_OpenToCategory(self.optionsFrame)
    InterfaceOptionsFrame_OpenToCategory(self.optionsFrame)

    if target and self.options.args[target] then
        LibStub("AceConfigDialog-3.0"):SelectGroup("YATP", target)
    end
end

-------------------------------------------------
-- Chat command
-------------------------------------------------
function YATP:ChatCommand(input)
    if not input or input:trim() == "" then
        self:OpenConfig()
    else
        local args = { strsplit(" ", input:lower()) }
        local cmd = args[1]

        if cmd == "reload" then
            ReloadUI()
        elseif cmd == "modules" then
            self:Print("Módulos cargados:")
            for name in pairs(self.modules) do
                self:Print(" - " .. name)
            end
        else
            self:Print("Comandos disponibles:")
            self:Print("/yatp → abre la configuración")
            self:Print("/yatp modules → lista los módulos activos")
            self:Print("/yatp reload → recarga la interfaz")
        end
    end
end
