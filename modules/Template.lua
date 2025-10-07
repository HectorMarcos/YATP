--========================================================--
-- YATP - Module Template (Guía completa)
--========================================================--
-- Cómo usar esta plantilla:
-- 1. Copia este archivo y renómbralo (ej: MyFeature.lua) dentro de Modules/.
-- 2. Sustituye TODAS las apariciones de "Template" por el nombre real del módulo.
-- 3. Añade claves de localización necesarias en locales/*.lua (enUS siempre fallback).
-- 4. Ajusta defaults y BuildOptions según tus necesidades.
-- 5. Mantén el módulo registrado automáticamente (YATP:AddModuleOptions) para mostrarlo en Interface Hub.
--
-- Convenciones YATP:
--  * self.db                   -> tabla de configuración por perfil (AceDB) en YATP.db.profile.modules[Nombre]
--  * Module.defaults           -> semilla clonada con CopyTable() la primera vez
--  * AddModuleOptions(nombre)  -> inserta el grupo en el panel 'Interface Hub'
--  * Debug()                   -> usar método de debug condicional para no saturar el chat
--  * Notación camelCase para claves DB; nombres legibles en UI mediante locales
--
-- Sugerencias de calidad:
--  * Evita crear tablas por frame en OnUpdate (reutiliza / cachea referencias)
--  * Usa eventos en lugar de escaneos periódicos siempre que sea viable
--  * Rate‑limit acciones potencialmente costosas (usa timestamps o C_Timer)
--  * Aísla funciones de migración para facilitar futuras versiones
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
-- Debug helper (activar con /yatp y toggle en opciones si añades 'debug')
-------------------------------------------------
function Module:Debug(msg)
    if not self.db or not self.db.debug then return end
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99YATP:Template|r "..tostring(msg))
end

-------------------------------------------------
-- Defaults
-------------------------------------------------
Module.defaults = {
    enabled = true,            -- activar/desactivar módulo
    exampleOption = true,      -- ejemplo de toggle
    debug = false,             -- activar mensajes de debug (si se usa)
    -- Añade aquí más claves persistentes
}

-------------------------------------------------
-- (Opcional) Migraciones de versión
-- Llama a esta función en OnInitialize si necesitas adaptar datos antiguos
-------------------------------------------------
local function RunMigrations(self)
    -- Ejemplo:
    -- if self.db.oldKey ~= nil and self.db.newKey == nil then
    --     self.db.newKey = self.db.oldKey; self.db.oldKey = nil
    -- end
end

-------------------------------------------------
-- OnInitialize
-------------------------------------------------
function Module:OnInitialize()
    -- Asegura subtabla de módulos
    if not YATP.db.profile.modules then YATP.db.profile.modules = {} end
    if not YATP.db.profile.modules.Template then
        YATP.db.profile.modules.Template = CopyTable(self.defaults)
    end
    self.db = YATP.db.profile.modules.Template

    -- Ejecutar migraciones si procede
    RunMigrations(self)

    -- Registro de comando rápido (opcional; renombra 'template')
    self:RegisterChatCommand("template", function() self:OpenConfig() end)

    -- Registrar opciones en Interface Hub
    if YATP.AddModuleOptions then
        YATP:AddModuleOptions("Template", self:BuildOptions())
    end
end

-------------------------------------------------
-- OnEnable
-------------------------------------------------
function Module:OnEnable()
    if not self.db.enabled then return end
    -- Registra eventos aquí (ejemplo):
    -- self:RegisterEvent("PLAYER_ENTERING_WORLD", "OnEnterWorld")
    -- self:RegisterEvent("PLAYER_REGEN_DISABLED", "OnCombatStart")
    self:Debug("Template habilitado")
end

-------------------------------------------------
-- OnDisable
-------------------------------------------------
function Module:OnDisable()
    -- Cancela timers, unregister events si usaste RegisterAllEvents (no habitual)
    -- Limpia referencias si creaste frames propios (frame:Hide(); frame:SetScript(nil))
    self:Debug("Template deshabilitado")
end

-------------------------------------------------
-- Ejemplo de evento
-------------------------------------------------
function Module:OnEnterWorld()
    -- Ejemplo de respuesta a evento
    self:Debug("PLAYER_ENTERING_WORLD")
end

-- Ejemplo adicional de eventos
-- function Module:OnCombatStart()
--     self:Debug("Entrando en combate")
-- end

-------------------------------------------------
-- Opciones para AceConfig
-------------------------------------------------
function Module:BuildOptions()
    local get = function(info)
        local key = info[#info]
        return self.db[key]
    end
    local set = function(info, val)
        local key = info[#info]
        self.db[key] = val
        if key == "enabled" then
            if val then self:Enable() else self:Disable() end
        elseif key == "debug" then
            self:Debug("Debug "..(val and "ON" or "OFF"))
        else
            -- Otros ajustes reactivos opcionalmente
        end
    end

    return {
        type = "group",
        name = L["Template"],
        args = {
            headerMain = { type="header", name = L["Template"] or "Template", order=0 },
            enabled = {
                type = "toggle", order = 1,
                name = L["Enable Module"] or "Enable Module",
                desc = L["Enable or disable this module."] or "Enable or disable this module.",
                get=get, set=set,
            },
            debug = {
                type = "toggle", order = 2,
                name = L["Debug Messages"] or "Debug Messages",
                desc = L["Toggle verbose debug output in chat."] or "Toggle verbose debug output in chat.",
                get=get, set=set,
            },
            exampleGroup = {
                type = "group", inline = true, order = 10,
                name = L["Example Settings"] or "Example Settings",
                args = {
                    exampleOption = {
                        type = "toggle", order=1,
                        name = L["Example Option"] or "Example Option",
                        desc = L["This is just an example toggle."] or "This is just an example toggle.",
                        get=get, set=set,
                    },
                }
            },
            help = { type="description", order=90, fontSize="small", name = L["You can duplicate this module as a starting point for new functionality."] or "You can duplicate this module as a starting point for new functionality." },
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

-------------------------------------------------
-- Notas rápidas para autores:
--  * Añade timers: local t = C_Timer.NewTicker(segundos, function() ... end)
--  * Cancela timers en OnDisable.
--  * Usa EnumerateFrames sólo si no hay eventos; limita frecuencia.
--  * Para interacción con otros módulos: YATP.modules["Nombre"] si deseas comprobar estado.
-------------------------------------------------

return Module
