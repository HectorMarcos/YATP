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
            print("[QuickConfirm] Applied missing default:", key, "=", tostring(value))
        end
    end

    if YATP.AddModuleOptions then
        YATP:AddModuleOptions(ModuleName, self:BuildOptions(), "QualityOfLife")
    end
end

function Module:OnEnable()
    print("[QuickConfirm] OnEnable() called")
    if not self.db.enabled then 
        print("[QuickConfirm] Module is disabled in settings")
        return 
    end
    
    print("[QuickConfirm] Config: autoTransmog=" .. tostring(self.db.autoTransmog) .. 
          ", autoBopLoot=" .. tostring(self.db.autoBopLoot) ..
          ", useFallbackMethod=" .. tostring(self.db.useFallbackMethod))
    
    self:RegisterEvents()
    self:InstallFallbackHook()
    
    print("[QuickConfirm] Module enabled successfully!")
end

function Module:OnDisable()
    self:UnregisterAllEvents()
end

-------------------------------------------------
-- Event Registration (Event-Driven Method)
-------------------------------------------------
function Module:RegisterEvents()
    if not self.db.enabled then return end
    
    -- Register BoP loot event if enabled
    if self.db.autoBopLoot then
        self:RegisterEvent("LOOT_BIND_CONFIRM")
    end
    
    -- Note: Transmog doesn't have a direct event we can use before the popup shows,
    -- so we'll use the StaticPopup hook for that
end

-------------------------------------------------
-- Event Handlers (Leatrix Method)
-------------------------------------------------
function Module:LOOT_BIND_CONFIRM(event, slot)
    if not self.db.enabled or not self.db.autoBopLoot then return end
    
    -- Use Blizzard's official API to confirm the loot
    -- This is instant and doesn't require clicking buttons
    ConfirmLootSlot(slot)
    StaticPopup_Hide("LOOT_BIND")
    
    if YATP.Debug then
        YATP:Debug("QuickConfirm", "Auto-confirmed BoP loot (slot: " .. tostring(slot) .. ")")
    end
end

-------------------------------------------------
-- Fallback Hook Method (for Transmog and safety)
-------------------------------------------------
function Module:InstallFallbackHook()
    if self._fallbackHookInstalled then 
        print("[QuickConfirm] Hook already installed")
        return 
    end
    if not self.db.useFallbackMethod then 
        print("[QuickConfirm] useFallbackMethod is disabled")
        return 
    end
    
    print("[QuickConfirm] Installing StaticPopup_Show hook...")
    
    -- Hook StaticPopup_Show to catch transmog popups
    -- We use this for transmog because there's no pre-popup event we can use
    hooksecurefunc("StaticPopup_Show", function(which, ...)
        print("[QuickConfirm] StaticPopup_Show fired - which:", tostring(which))
        
        if not self.db or not self.db.enabled then 
            print("[QuickConfirm] Module disabled or no db")
            return 
        end
        
        -- Handle transmog confirmation
        if self.db.autoTransmog and which == "CONFIRM_COLLECT_APPEARANCE" then
            print("[QuickConfirm] ✓ Transmog popup detected! Scheduling confirm in 0.05s")
            -- Use a small delay to ensure the popup is fully initialized
            C_Timer.After(0.05, function()
                print("[QuickConfirm] Timer fired, calling ConfirmTransmogPopup()")
                self:ConfirmTransmogPopup()
            end)
        else
            if not self.db.autoTransmog then
                print("[QuickConfirm] autoTransmog is OFF")
            end
        end
    end)
    
    self._fallbackHookInstalled = true
    print("[QuickConfirm] Hook installed successfully!")
end

-------------------------------------------------
-- Transmog Confirmation Helper
-------------------------------------------------
function Module:ConfirmTransmogPopup()
    print("[QuickConfirm] ConfirmTransmogPopup() called - scanning popups...")
    
    -- Find the CONFIRM_COLLECT_APPEARANCE popup
    for i = 1, STATICPOPUP_NUMDIALOGS do
        local frame = _G["StaticPopup" .. i]
        if frame then
            local isShown = frame:IsShown()
            local which = frame.which
            print(string.format("[QuickConfirm] StaticPopup%d: shown=%s, which=%s", 
                i, tostring(isShown), tostring(which or "nil")))
            
            if isShown and which == "CONFIRM_COLLECT_APPEARANCE" then
                print("[QuickConfirm] ✓ Found CONFIRM_COLLECT_APPEARANCE popup!")
                
                local button = _G[frame:GetName() .. "Button1"]
                if button then
                    local btnShown = button:IsShown()
                    local btnEnabled = button:IsEnabled()
                    print(string.format("[QuickConfirm] Button1: shown=%s, enabled=%s", 
                        tostring(btnShown), tostring(btnEnabled)))
                    
                    if btnShown and btnEnabled then
                        print("[QuickConfirm] ✓✓ Clicking button!")
                        button:Click()
                        
                        -- Schedule AdiBags refresh after confirming transmog
                        self:ScheduleAdiBagsRefresh()
                        
                        print("[QuickConfirm] ✓✓✓ Transmog confirmed!")
                        
                        if YATP.Debug then
                            YATP:Debug("QuickConfirm", "Auto-confirmed transmog appearance")
                        end
                        return true
                    else
                        print("[QuickConfirm] ✗ Button not ready (shown or enabled = false)")
                    end
                else
                    print("[QuickConfirm] ✗ Button1 not found")
                end
            end
        end
    end
    
    print("[QuickConfirm] ✗ No CONFIRM_COLLECT_APPEARANCE popup found")
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
