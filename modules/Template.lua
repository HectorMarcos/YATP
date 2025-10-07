--========================================================--
-- YATP - Module Template
--========================================================--

-- ⚙️ Sustituye "Template" por el nombre de tu módulo
--    Ejemplo: local Module = YATP:NewModule("Bags", "AceEvent-3.0")
--========================================================--

local L   = LibStub("AceLocale-3.0"):GetLocale("YATP", true) or setmetatable({}, { __index=function(_,k) return k end })
local LSM = LibStub("LibSharedMedia-3.0", true)
local YATP = LibStub("AceAddon-3.0"):GetAddon("YATP", true)
if not YATP then
    print("YATP no encontrado, abortando módulo Template.lua")
    return
end

-- Crea el módulo (ajusta el nombre entre comillas)
local Module = YATP:NewModule("Template", "AceEvent-3.0", "AceConsole-3.0")

-------------------------------------------------
-- Defaults
-------------------------------------------------
Module.defaults = {
    enabled = true,
    exampleOption = true,
}

-------------------------------------------------
-- OnInitialize
-------------------------------------------------
function Module:OnInitialize()
    -- Inicializa datos del perfil
    if not YATP.db.profile.modules then YATP.db.profile.modules = {} end
    if not YATP.db.profile.modules.Template then
        YATP.db.profile.modules.Template = CopyTable(self.defaults)
    end
    self.db = YATP.db.profile.modules.Template

    -- Registro de comando (opcional)
    self:RegisterChatCommand("template", function() self:OpenConfig() end)

    -- Añadir pestaña de configuración
    if YATP.AddModuleOptions then
        YATP:AddModuleOptions("Template", self:BuildOptions())
    end
end

-------------------------------------------------
-- OnEnable
-------------------------------------------------
function Module:OnEnable()
    -- Aquí pones lo que debe activarse al habilitar el módulo
    if self.db.enabled then
        self:Print("Módulo Template habilitado.")
        -- Ejemplo: self:RegisterEvent("PLAYER_ENTERING_WORLD", "OnEnterWorld")
    end
end

-------------------------------------------------
-- OnDisable
-------------------------------------------------
function Module:OnDisable()
    -- Aquí limpias lo que hiciera falta al desactivar el módulo
end

-------------------------------------------------
-- Ejemplo de evento
-------------------------------------------------
function Module:OnEnterWorld()
    self:Print("Has entrado en el mundo.")
end

-------------------------------------------------
-- Opciones para AceConfig
-------------------------------------------------
function Module:BuildOptions()
    local get = function(info) return self.db[ info[#info] ] end
    local set = function(info, val) self.db[ info[#info] ] = val end

    return {
        type = "group",
        name = L["Template"],
        args = {
            enabled = {
                type = "toggle",
                name = L["Enable Module"] or "Enable Module",
                desc = L["Enable or disable this module."] or "Enable or disable this module.",
                order = 1,
                get = get,
                set = function(info, val)
                    self.db[ info[#info] ] = val
                    if val then self:Enable() else self:Disable() end
                end,
            },
            exampleOption = {
                type = "toggle",
                name = L["Example Option"] or "Example Option",
                desc = L["This is just an example toggle."] or "This is just an example toggle.",
                order = 2,
                get = get,
                set = set,
            },
        },
    }
end

-------------------------------------------------
-- Abrir configuración desde el módulo
-------------------------------------------------
function Module:OpenConfig()
    if YATP.OpenConfig then
        YATP:OpenConfig("Template")
    else
        print("YATP config no disponible.")
    end
end
