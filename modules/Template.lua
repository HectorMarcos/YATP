--========================================================--
-- YATP - Module Template (Comprehensive Guide)
--========================================================--
-- How to use this template:
-- 1. Copy this file and rename it (e.g. MyFeature.lua) inside Modules/.
-- 2. Replace EVERY occurrence of "Template" with the real module name.
-- 3. Add localization keys you need in locales/*.lua (enUS acts as fallback).
-- 4. Adjust defaults and BuildOptions for your needs.
-- 5. Keep automatic registration (YATP:AddModuleOptions) so it appears in the Interface Hub.
--
-- YATP conventions:
--  * self.db                   -> per-profile config table (AceDB) at YATP.db.profile.modules[Name]
--  * Module.defaults           -> cloned via CopyTable() first initialization
--  * AddModuleOptions(name)    -> inserts the group into the Interface Hub panel
--  * Debug()                   -> conditional debug output (avoid chat spam)
--  * camelCase for DB keys; user-facing names provided via locales
--
-- Quality suggestions:
--  * Avoid allocating tables every frame in OnUpdate (reuse / cache references)
--  * Prefer events over periodic polling where viable
--  * Rate‑limit potentially expensive actions (timestamps or C_Timer)
--  * Isolate migration helpers for future versions
--========================================================--

local L   = LibStub("AceLocale-3.0"):GetLocale("YATP", true) or setmetatable({}, { __index=function(_,k) return k end })
local LSM = LibStub("LibSharedMedia-3.0", true)
local YATP = LibStub("AceAddon-3.0"):GetAddon("YATP", true)
if not YATP then
    print("YATP not found, aborting Template.lua module")
    return
end

-- Create the module (adjust the quoted name)
local Module = YATP:NewModule("Template", "AceEvent-3.0", "AceConsole-3.0")

-------------------------------------------------
-- Debug helper (activate by enabling the 'debug' toggle if you add one)
-------------------------------------------------
function Module:Debug(msg)
    if not YATP or not YATP.IsDebug or not YATP:IsDebug() then return end
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99YATP:Template|r "..tostring(msg))
end

-------------------------------------------------
-- Defaults
-------------------------------------------------
Module.defaults = {
    enabled = true,            -- enable/disable the module
    exampleOption = true,      -- sample toggle
    -- debug flag removed (uses global Extras > Debug Mode)
    -- Add more persistent keys below
}

-------------------------------------------------
-- (Optional) Version migrations
-- Call this function inside OnInitialize if you need to adapt older saved data
-------------------------------------------------
local function RunMigrations(self)
    -- Example:
    -- if self.db.oldKey ~= nil and self.db.newKey == nil then
    --     self.db.newKey = self.db.oldKey; self.db.oldKey = nil
    -- end
end

-------------------------------------------------
-- OnInitialize
-------------------------------------------------
function Module:OnInitialize()
    -- Ensure per-module subtable exists
    if not YATP.db.profile.modules then YATP.db.profile.modules = {} end
    if not YATP.db.profile.modules.Template then
        YATP.db.profile.modules.Template = CopyTable(self.defaults)
    end
    self.db = YATP.db.profile.modules.Template

    -- Ejecutar migraciones si procede
    RunMigrations(self)

    -- Optional quick slash command (rename 'template')
    self:RegisterChatCommand("template", function() self:OpenConfig() end)

    -- Register options inside the Interface Hub
    if YATP.AddModuleOptions then
        YATP:AddModuleOptions("Template", self:BuildOptions())
    end
end

-------------------------------------------------
-- OnEnable
-------------------------------------------------
function Module:OnEnable()
    if not self.db.enabled then return end
    -- Register events here (example):
    -- self:RegisterEvent("PLAYER_ENTERING_WORLD", "OnEnterWorld")
    -- self:RegisterEvent("PLAYER_REGEN_DISABLED", "OnCombatStart")
    self:Debug("Template enabled")
end

-------------------------------------------------
-- OnDisable
-------------------------------------------------
function Module:OnDisable()
    -- Cancel timers, unregister events if you used broad registrations
    -- Clean up custom frames if created (frame:Hide(); frame:SetScript(nil))
    self:Debug("Template disabled")
end

-------------------------------------------------
-- Example event handler
-------------------------------------------------
function Module:OnEnterWorld()
    -- Example event response
    self:Debug("PLAYER_ENTERING_WORLD")
end

-- Additional event example
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
                desc = (L["Enable or disable this module."] or "Enable or disable this module.") .. "\n" .. (L["Requires /reload to fully apply enabling or disabling."] or "Requires /reload to fully apply enabling or disabling."),
                get=get, set=function(info,val) set(info,val); if YATP and YATP.ShowReloadPrompt then YATP:ShowReloadPrompt() end end,
            },
            -- per-module debug toggle removed (global debug controls output)
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
-- Open configuration from the module
-------------------------------------------------
function Module:OpenConfig()
    if YATP.OpenConfig then
        YATP:OpenConfig("Template")
    else
        print("YATP config no disponible.")
    end
end

-------------------------------------------------
-- Quick author notes:
--  * Add timers: local t = C_Timer.NewTicker(seconds, function() ... end)
--  * Cancel timers in OnDisable.
--  * Use EnumerateFrames only if events are insufficient; limit frequency.
--  * For cross-module checks: YATP.modules["Name"] if you need to inspect state.
-------------------------------------------------

return Module
