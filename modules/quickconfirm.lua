--========================================================--
-- YATP - QuickConfirm (Quality of Life)
-- Automatically confirms selected StaticPopup dialogs:
--  * Transmog appearance collection (appearance learn)
--  * Bind-on-pickup loot confirmation
--  * Uses event-driven approach (inspired by Leatrix_Plus)
--========================================================--
local ADDON = "YATP"
local ModuleName = "QuickConfirm"

local L   = LibStub("AceLocale-3.0"):GetLocale(ADDON, true) or setmetatable({}, { __index=function(_,k) return k end })
local YATP = LibStub("AceAddon-3.0"):GetAddon(ADDON, true)
if not YATP then return end

local Module = YATP:NewModule(ModuleName, "AceConsole-3.0", "AceEvent-3.0")

-------------------------------------------------
-- Defaults
-------------------------------------------------
Module.defaults = {
    enabled = true,
    autoTransmog = true,
    autoBopLoot = true, -- auto-confirm bind-on-pickup world loot popups
    adiBagsRefreshDelay = 0.3, -- delay before refreshing AdiBags after transmog (seconds)
    useFallbackMethod = true, -- if event-driven fails, use hook method as fallback
}

-------------------------------------------------
-- Event-driven constants
-------------------------------------------------
-- Events to register for auto-confirm
local EVENTS = {
    LOOT_BIND_CONFIRM = "autoBopLoot",      -- BoP loot confirmation
    -- TRANSMOG_COLLECTION_UPDATE could be used but we'll use StaticPopup hook for transmog
}

-------------------------------------------------
-- Fallback detection patterns (only used if event method fails)
-------------------------------------------------
local TRANSMOG_PATTERNS = {
    "are you sure you want to collect the appearance",
    "collect the appearance of",
}

local BOP_LOOT_PATTERNS = {
    "will bind it to you",
    "bind it to you",
}

-------------------------------------------------
-- Lifecycle
-------------------------------------------------
function Module:OnInitialize()
    if not YATP.db.profile.modules then YATP.db.profile.modules = {} end
    if not YATP.db.profile.modules[ModuleName] then
        YATP.db.profile.modules[ModuleName] = CopyTable(self.defaults)
    end
    self.db = YATP.db.profile.modules[ModuleName]
    
    -- Ensure new defaults are applied to existing configs
    for key, value in pairs(self.defaults) do
        if self.db[key] == nil then
            self.db[key] = value
        end
    end

    if YATP.AddModuleOptions then
        YATP:AddModuleOptions(ModuleName, self:BuildOptions(), "QualityOfLife")
    end
end

function Module:OnEnable()
    if not self.db.enabled then return end
    self:RegisterEvents()
    self:InstallFallbackHook()
end

function Module:OnDisable()
    self:UnregisterAllEvents()
end

-------------------------------------------------
-- Event Registration (Event-Driven Method)
-------------------------------------------------
function Module:RegisterEvents()
    print("[QuickConfirm] RegisterEvents() called")
    print("[QuickConfirm] enabled:", self.db.enabled, "autoBopLoot:", self.db.autoBopLoot)
    
    if not self.db.enabled then 
        print("[QuickConfirm] Module disabled, not registering events")
        return 
    end
    
    -- Register BoP loot event if enabled
    if self.db.autoBopLoot then
        print("[QuickConfirm] Registering LOOT_BIND_CONFIRM event")
        self:RegisterEvent("LOOT_BIND_CONFIRM")
        print("[QuickConfirm] LOOT_BIND_CONFIRM registered successfully")
    else
        print("[QuickConfirm] autoBopLoot is disabled, not registering LOOT_BIND_CONFIRM")
    end
    
    -- Note: Transmog doesn't have a direct event we can use before the popup shows,
    -- so we'll use the StaticPopup hook for that
end

-------------------------------------------------
-- Event Handlers (Hybrid: API + Button Click Fallback)
-------------------------------------------------
function Module:LOOT_BIND_CONFIRM(event, arg1, arg2, ...)
    print("[QuickConfirm] ✓✓✓ LOOT_BIND_CONFIRM event fired!")
    print("[QuickConfirm] arg1:", tostring(arg1), "arg2:", tostring(arg2))
    
    if not self.db.enabled or not self.db.autoBopLoot then 
        print("[QuickConfirm] Module or autoBopLoot disabled, not confirming")
        return 
    end
    
    -- Check if ConfirmLootSlot exists and try it
    if type(ConfirmLootSlot) == "function" then
        print("[QuickConfirm] ConfirmLootSlot exists, calling it...")
        ConfirmLootSlot(arg1, arg2)
        StaticPopup_Hide("LOOT_BIND", ...)
        print("[QuickConfirm] ConfirmLootSlot called")
    else
        print("[QuickConfirm] ⚠ ConfirmLootSlot does NOT exist!")
    end
    
    -- Also try button click method as fallback
    C_Timer.After(0.05, function()
        print("[QuickConfirm] Fallback: Searching for LOOT_BIND popup...")
        
        for i = 1, STATICPOPUP_NUMDIALOGS do
            local frame = _G["StaticPopup" .. i]
            if frame and frame:IsShown() and frame.which == "LOOT_BIND" then
                print("[QuickConfirm]   Found at StaticPopup" .. i)
                
                local button = _G[frame:GetName() .. "Button1"]
                if button and button:IsShown() and button:IsEnabled() then
                    print("[QuickConfirm]   Clicking button...")
                    button:Click()
                    print("[QuickConfirm]   ✓✓✓ Button clicked successfully!")
                    return
                end
            end
        end
        
        print("[QuickConfirm]   No popup found (already confirmed?)")
    end)
end

-------------------------------------------------
-- Fallback Hook Method (for Transmog and safety)
-------------------------------------------------
function Module:InstallFallbackHook()
    if self._fallbackHookInstalled then return end
    if not self.db.useFallbackMethod then return end
    
    -- Hook StaticPopup_Show to catch transmog popups
    -- We use this for transmog because there's no pre-popup event we can use
    hooksecurefunc("StaticPopup_Show", function(which, ...)
        if not self.db or not self.db.enabled then return end
        
        -- Handle transmog confirmation
        if self.db.autoTransmog and which == "CONFIRM_COLLECT_APPEARANCE" then
            -- Use a small delay to ensure the popup is fully initialized
            C_Timer.After(0.05, function()
                self:ConfirmTransmogPopup()
            end)
        end
    end)
    
    self._fallbackHookInstalled = true
end

-------------------------------------------------
-- Transmog Confirmation Helper
-------------------------------------------------
function Module:ConfirmTransmogPopup()
    -- Find the CONFIRM_COLLECT_APPEARANCE popup
    for i = 1, STATICPOPUP_NUMDIALOGS do
        local frame = _G["StaticPopup" .. i]
        if frame and frame:IsShown() and frame.which == "CONFIRM_COLLECT_APPEARANCE" then
            local button = _G[frame:GetName() .. "Button1"]
            if button and button:IsShown() and button:IsEnabled() then
                button:Click()
                
                -- Schedule AdiBags refresh after confirming transmog
                self:ScheduleAdiBagsRefresh()
                
                if YATP.Debug then
                    YATP:Debug("QuickConfirm", "Auto-confirmed transmog appearance")
                end
                return true
            end
        end
    end
    return false
end



-------------------------------------------------
-- AdiBags Refresh Integration
-------------------------------------------------
function Module:ScheduleAdiBagsRefresh()
    local delay = self.db.adiBagsRefreshDelay or 0.3
    
    C_Timer.After(delay, function()
        -- Verify that AdiBags is loaded
        local AdiBags = LibStub("AceAddon-3.0"):GetAddon("AdiBags", true)
        if AdiBags and AdiBags.SendMessage then
            pcall(function()
                -- SendMessage triggers AdiBags filtering/update system
                AdiBags:SendMessage('AdiBags_FiltersChanged')
                
                if YATP.Debug then
                    YATP:Debug("QuickConfirm", "Refreshed AdiBags after transmog")
                end
            end)
        end
    end)
end

-------------------------------------------------
-- Options
-------------------------------------------------
function Module:BuildOptions()
    local get = function(info) return self.db[ info[#info] ] end
    local set = function(info, val) 
        self.db[ info[#info] ] = val
        self:OnSettingChanged(info[#info]) 
    end

    return {
        type = "group",
        name = L["QuickConfirm"] or "QuickConfirm",
        args = {
            enabled = {
                type = "toggle", order = 1,
                name = L["Enable Module"] or "Enable Module",
                desc = L["Requires /reload to fully apply enabling or disabling."] or "Requires /reload to fully apply enabling or disabling.",
                get = function() return self.db.enabled end,
                set = function(_, v)
                    self.db.enabled = v
                    if v then self:Enable() else self:Disable() end
                    if YATP and YATP.ShowReloadPrompt then YATP:ShowReloadPrompt() end
                end,
            },
            desc = { 
                type = "description", 
                order = 2, 
                fontSize = "medium", 
                name = L["Automatically confirms transmog and bind-on-pickup loot popups using efficient event-driven method."] or 
                       "Automatically confirms transmog and bind-on-pickup loot popups using efficient event-driven method." 
            },
            headerTransmog = { type = "header", name = L["Transmog"] or "Transmog", order = 5 },
            autoTransmog = { 
                type = "toggle", 
                order = 6, 
                name = L["Auto-confirm transmog appearance popups"] or "Auto-confirm transmog appearance popups",
                desc = L["Instantly confirms transmog appearance collection popups."] or "Instantly confirms transmog appearance collection popups.",
                get = get, 
                set = set 
            },
            headerLoot = { type = "header", name = L["Loot"] or "Loot", order = 7 },
            autoBopLoot = { 
                type = "toggle", 
                order = 8, 
                name = L["Auto-confirm bind-on-pickup loot popups"] or "Auto-confirm bind-on-pickup loot popups", 
                desc = L["Instantly confirms bind-on-pickup loot using Blizzard API (event-driven, no delays)."] or 
                       "Instantly confirms bind-on-pickup loot using Blizzard API (event-driven, no delays).",
                get = get, 
                set = function(info, val)
                    self.db.autoBopLoot = val
                    if val then
                        self:RegisterEvent("LOOT_BIND_CONFIRM")
                    else
                        self:UnregisterEvent("LOOT_BIND_CONFIRM")
                    end
                end
            },
            headerAdvanced = { type = "header", name = L["Advanced"] or "Advanced", order = 10 },
            useFallbackMethod = {
                type = "toggle",
                order = 11,
                name = L["Use Fallback Hook Method"] or "Use Fallback Hook Method",
                desc = L["Enable hook-based fallback for popups that don't have direct events (recommended)."] or 
                       "Enable hook-based fallback for popups that don't have direct events (recommended).",
                get = get,
                set = set,
            },
            adiBagsRefreshDelay = { 
                type = "range", 
                order = 12, 
                name = L["AdiBags Refresh Delay"] or "AdiBags Refresh Delay", 
                desc = L["Delay (in seconds) before refreshing AdiBags after confirming a transmog."] or 
                       "Delay (in seconds) before refreshing AdiBags after confirming a transmog.", 
                min = 0.1, 
                max = 1.0, 
                step = 0.05, 
                get = get, 
                set = set 
            },
        }
    }
end

function Module:OnSettingChanged(key)
    -- Handle settings that need immediate effect
    if key == "autoBopLoot" then
        if self.db.autoBopLoot then
            self:RegisterEvent("LOOT_BIND_CONFIRM")
        else
            self:UnregisterEvent("LOOT_BIND_CONFIRM")
        end
    end
end

-------------------------------------------------
-- Open config helper
-------------------------------------------------
function Module:OpenConfig()
    if YATP.OpenConfig then YATP:OpenConfig(ModuleName) end
end

-------------------------------------------------
-- Debug command
-------------------------------------------------
function Module:DebugStatus()
    print("============ QuickConfirm Debug Status ============")
    print("Module enabled:", tostring(self.db.enabled))
    print("autoTransmog:", tostring(self.db.autoTransmog))
    print("autoBopLoot:", tostring(self.db.autoBopLoot))
    print("useFallbackMethod:", tostring(self.db.useFallbackMethod))
    print("Hook installed:", tostring(self._fallbackHookInstalled))
    
    print("\nRegistered Events:")
    local hasEvents = false
    if self.events then
        for event in pairs(self.events) do
            print("  -", event)
            hasEvents = true
        end
    end
    if not hasEvents then
        print("  (none)")
    end
    print("===================================================")
end

-- Register slash command for debug
SLASH_QUICKCONFIRMDEBUG1 = "/qcdebug"
SlashCmdList["QUICKCONFIRMDEBUG"] = function()
    local mod = YATP:GetModule("QuickConfirm", true)
    if mod then
        mod:DebugStatus()
    else
        print("[QuickConfirm] Module not found!")
    end
end
