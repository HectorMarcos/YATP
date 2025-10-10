--========================================================--
-- YATP - QuickConfirm (Quality of Life)
-- Automatically confirms selected StaticPopup dialogs:
--  * Transmog appearance collection (appearance learn)
--  * Bind-on-pickup loot confirmation
--  * (Exit auto-confirm feature removed)
--========================================================--
local ADDON = "YATP"
local ModuleName = "QuickConfirm"

local L   = LibStub("AceLocale-3.0"):GetLocale(ADDON, true) or setmetatable({}, { __index=function(_,k) return k end })
local YATP = LibStub("AceAddon-3.0"):GetAddon(ADDON, true)
if not YATP then return end

local Module = YATP:NewModule(ModuleName, "AceConsole-3.0")

-------------------------------------------------
-- Defaults
-------------------------------------------------
Module.defaults = {
    enabled = true,
    scanInterval = 0.25, -- (legacy) kept for compatibility; no longer used as continuous OnUpdate scanner
    autoTransmog = true,
    autoBopLoot = true, -- auto-confirm bind-on-pickup world loot popups
    -- autoExit removed
    suppressClickSound = false, -- removed feature (kept key for backwards safety, no effect)
    -- debug flag removed (now uses global YATP Extras > Debug Mode)
    minClickGap = 0.3, -- safeguard between automatic clicks
    retryAttempts = 3,  -- number of scheduled retry attempts to confirm a popup if button is not yet ready
    retryStep = 0.2,   -- time between retry attempts
    adiBagsRefreshDelay = 0.3, -- delay before refreshing AdiBags after transmog (seconds)
}

-- Hardcoded (lowercase) substrings for detection
local TRANSMOG_SUBSTRINGS = {
    -- Original pattern provided
    "are you sure you want to collect the appearance",
    -- Room for future variations if needed
    -- Add any future lowercase variants here
    -- Extended variants
    "are you sure you want to collect the appearance of", -- user confirmed stable part
    "collect the appearance of", -- shorter core
    "collect the appearance", -- fallback shorter
}

-- BOP loot popup detection patterns (using literal text search like transmog)
local BOP_LOOT_SUBSTRINGS = {
    "will bind it to you", -- main pattern - should match "Looting [item] will bind it to you."
    "bind it to you", -- fallback shorter pattern
    "looting", -- additional fallback
}

-- BOP loot which values
local BOP_LOOT_WHICH = {
    LOOT_BIND = true, -- Confirmed: this is the actual which value for BOP loot confirmations
}

-- Exit popups rely on StaticPopup dialogs like CONFIRM_EXIT / QUIT.
-- Requested change: only auto‑confirm full game exit, NOT logout (CAMP), so CAMP removed.
local EXIT_POPUP_WHICH = {
    QUIT = true,
    CONFIRM_EXIT = true,
}
-- Direct which value for transmog confirmation
local TRANSMOG_WHICH = {
    CONFIRM_COLLECT_APPEARANCE = true,
}

-- Additional lowercase textual cues (extended with Spanish variants)
local EXIT_TEXT_CUES = {
    -- Restricted to explicit exit/quit only (no logout / camp wording)
    "exit", "quit",
    -- NOTE: If you need Spanish exit support ("salir"), re-add it here, but it may
    -- collide with logout contexts on some cores.
}

-- Utility: lowercase contains any of patterns
local function ContainsAny(haystack, list)
    for _, pat in ipairs(list) do
        if haystack:find(pat, 1, true) then return true end
    end
end

-------------------------------------------------
-- Lifecycle
-------------------------------------------------
function Module:OnInitialize()
    if not YATP.db.profile.modules then YATP.db.profile.modules = {} end
    if not YATP.db.profile.modules[ModuleName] then
        YATP.db.profile.modules[ModuleName] = CopyTable(self.defaults)
    end
    self.db = YATP.db.profile.modules[ModuleName]

    if YATP.AddModuleOptions then
        YATP:AddModuleOptions(ModuleName, self:BuildOptions(), "QualityOfLife")
    end
end

function Module:OnEnable()
    if not self.db.enabled then return end
    self:InstallPopupHook()
end

function Module:OnDisable() end

-------------------------------------------------
-- Hook StaticPopup_Show to catch texts immediately
-------------------------------------------------
function Module:InstallPopupHook()
    if self._popupHookInstalled then return end
    local function hookFn(which, text, ...)
        if not self.db or not self.db.enabled then return end
        local safeText = type(text) == "string" and text or ""
        local lowerText = safeText:lower()
        
        local needTransmog = false
        if self.db.autoTransmog then
            if which and TRANSMOG_WHICH[which] then
                needTransmog = true
            else
                -- Try text fragment detection if any text was received
                if safeText ~= "" then
                    for _, pat in ipairs(TRANSMOG_SUBSTRINGS) do
                        if lowerText:find(pat, 1, true) then
                            needTransmog = true
                            break
                        end
                    end
                end
            end
        end
        
        local needBopLoot = false
        if self.db.autoBopLoot then
            if which and BOP_LOOT_WHICH[which] then
                needBopLoot = true
            else
                -- Try text fragment detection if any text was received (fallback)
                if safeText ~= "" then
                    for i, pat in ipairs(BOP_LOOT_SUBSTRINGS) do
                        if lowerText:find(pat, 1, true) then -- using literal search like transmog
                            needBopLoot = true
                            break
                        end
                    end
                end
            end
        end
        
        if needTransmog then
            self:SchedulePopupRetries({ mode = "transmog", which = which, text = safeText })
        end
        if needBopLoot then
            self:SchedulePopupRetries({ mode = "boploot", which = which, text = safeText })
        end
    end
    hooksecurefunc("StaticPopup_Show", hookFn)
    self._popupHookInstalled = true
end

-- Attempt confirmation by which value
function Module:ConfirmByWhich(which, originalText)
    for i=1,4 do
        local frame = _G["StaticPopup"..i]
        if frame and frame:IsShown() and frame.which == which then
            self:ClickPrimary(frame, "which-"..tostring(which))
            return true
        end
    end
end

-- Attempt confirmation by matching displayed text exactly
function Module:ConfirmByText(text, reason)
    for i=1,4 do
        local frame = _G["StaticPopup"..i]
        if frame and frame:IsShown() then
            local tr = _G[frame:GetName().."Text"]
            local t = tr and tr:GetText() or ""
            if t == text then
                self:ClickPrimary(frame, reason or "text-match")
                return true
            end
        end
    end
end

-------------------------------------------------
-- Scanner (throttled) using OnUpdate on a hidden frame
-------------------------------------------------
-- Removed: continuous scanner replaced by scheduled retries.
function Module:StartScanner() end
function Module:StopScanner() end

-------------------------------------------------
-- Core scan logic
-------------------------------------------------
-- Removed: continuous scanning logic
function Module:ScanOnce() end

-- Schedule staggered retries for detected popups
function Module:SchedulePopupRetries(meta)
    local sched = YATP and YATP.GetScheduler and YATP:GetScheduler()
    if not sched then return end
    local baseName = "QuickConfirmPopup:"..(meta.mode or "?")..":"..(meta.which or "-")
    local attempts = 0
    local maxAttempts = self.db.retryAttempts or 3
    local step = self.db.retryStep or 0.2
    
    sched:AddTask(baseName, step, function()
        attempts = attempts + 1
        local modeEnabled = false
        if meta.mode == "transmog" then
            modeEnabled = self.db and self.db.enabled and self.db.autoTransmog
        elseif meta.mode == "boploot" then
            modeEnabled = self.db and self.db.enabled and self.db.autoBopLoot
        end
        
        if not modeEnabled then
            sched:RemoveTask(baseName)
            return
        end
        
        local targetFrame
        for i=1,4 do
            local frame = _G["StaticPopup"..i]
            if frame and frame:IsShown() then
                local which = frame.which
                local tr = _G[frame:GetName().."Text"]
                local txt = (tr and tr:GetText()) or ""
                local lower = txt:lower()
                
                if (meta.which and which == meta.which) then
                    targetFrame = frame; break
                else
                    -- Check text patterns based on mode
                    if meta.mode == "transmog" then
                        for _, pat in ipairs(TRANSMOG_SUBSTRINGS) do
                            if lower:find(pat, 1, true) then targetFrame = frame; break end
                        end
                    elseif meta.mode == "boploot" then
                        -- First check if we have a specific which value
                        if which and BOP_LOOT_WHICH[which] then
                            targetFrame = frame; break
                        else
                            -- Then check text patterns
                            for _, pat in ipairs(BOP_LOOT_SUBSTRINGS) do
                                if lower:find(pat, 1, true) then targetFrame = frame; break end
                            end
                        end
                    end
                    if targetFrame then break end
                end
            end
        end
        
        if targetFrame then
            self:ClickPrimary(targetFrame, (meta.mode or "unknown").."-auto")
            sched:RemoveTask(baseName)
            return
        end
        
        if attempts >= maxAttempts then
            sched:RemoveTask(baseName)
        end
    end, { spread = 0 })
end

-------------------------------------------------
-- Force exit fallback when no clickable button exists
-------------------------------------------------
function Module:ForceImmediateExit()
    local now = GetTime()
    if self._lastForceExit and (now - self._lastForceExit) < 1 then return end
    self._lastForceExit = now
    local ok
    if ForceQuit then ok = pcall(ForceQuit) end
    if (not ok or ok == false) and Quit then pcall(Quit) end
    self:Debug("force exit fallback invoked")
end

-------------------------------------------------
-- Silent click helper
-------------------------------------------------
-- Sound suppression removed per user request (stub kept for minimal diff)
local function TemporarilySuppressSound()
    return nil
end

function Module:ClickPrimary(popup, reason)
    if not popup then return end
    -- Find primary button for that popup frame
    local name = popup:GetName()
    local button = _G[name.."Button1"] or _G[name.."Button2"] -- try Button2 if Button1 absent/disabled
    if not (button and button:IsShown() and button:IsEnabled()) then
        return
    end

    local now = GetTime()
    if self.lastClick and (now - self.lastClick) < (self.db.minClickGap or 0.3) then return end
    self.lastClick = now

    local ok = pcall(function() button:Click() end)
    
    -- Refresh AdiBags after confirming transmog
    if ok and reason and reason:find("transmog") then
        self:ScheduleAdiBagsRefresh()
    end
end

-------------------------------------------------
-- AdiBags Refresh Integration
-------------------------------------------------
function Module:ScheduleAdiBagsRefresh()
    local sched = YATP and YATP.GetScheduler and YATP:GetScheduler()
    if not sched then return end
    
    local delay = self.db.adiBagsRefreshDelay or 0.3
    
    sched:AddTask("QuickConfirm:AdiBagsRefresh", delay, function()
        -- Verify that AdiBags is loaded
        local AdiBags = LibStub("AceAddon-3.0"):GetAddon("AdiBags", true)
        if AdiBags and AdiBags.SendMessage then
            pcall(function()
                -- SendMessage triggers AdiBags filtering/update system
                AdiBags:SendMessage('AdiBags_FiltersChanged')
            end)
        end
        sched:RemoveTask("QuickConfirm:AdiBagsRefresh")
    end, { spread = 0 })
end

-------------------------------------------------
-- Exit countdown watcher (non-StaticPopup frames)
-------------------------------------------------
-- Exit watcher removed

-------------------------------------------------
-- Options (minimal per requirements)
-------------------------------------------------
function Module:BuildOptions()
    local get = function(info) return self.db[ info[#info] ] end
    local set = function(info, val) self.db[ info[#info] ] = val; self:OnSettingChanged(info[#info]) end

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
            desc = { type="description", order=2, fontSize="medium", name = L["Automatically confirms selected transmog confirmation popups and bind-on-pickup loot popups."] or "Automatically confirms selected transmog confirmation popups and bind-on-pickup loot popups." },
            headerTransmog = { type="header", name = L["Transmog"] or "Transmog", order = 5 },
            autoTransmog = { type="toggle", order = 6, name = L["Auto-confirm transmog appearance popups"] or "Auto-confirm transmog appearance popups", get=get, set=set },
            headerLoot = { type="header", name = L["Loot"] or "Loot", order = 7 },
            autoBopLoot = { type="toggle", order = 8, name = L["Auto-confirm bind-on-pickup loot popups"] or "Auto-confirm bind-on-pickup loot popups", 
                desc = L["Automatically confirm popups that appear when looting bind-on-pickup items from world objects."] or "Automatically confirm popups that appear when looting bind-on-pickup items from world objects.", 
                get=get, set=set },
            -- exit section removed
            -- Advanced options hidden (internal default values only)
            scanInterval = { type="range", hidden=true, order=30, name=L["(Legacy) Scan Interval"] or "(Legacy) Scan Interval", min=0.05, max=0.5, step=0.01, get=get, set=function(i,v) set(i,v) end },
            retryAttempts = { type="range", hidden=true, order=40, name=L["Retry Attempts"] or "Retry Attempts", desc=L["Number of scheduled retry attempts when a popup appears and the confirm button may not yet be ready."] or "Number of scheduled retry attempts when a popup appears and the confirm button may not yet be ready.", min=1, max=10, step=1, get=get, set=set },
            retryStep = { type="range", hidden=true, order=41, name=L["Retry Interval"] or "Retry Interval", desc=L["Seconds between retry attempts."] or "Seconds between retry attempts.", min=0.05, max=0.5, step=0.01, get=get, set=set },
            adiBagsRefreshDelay = { type="range", hidden=true, order=42, name=L["AdiBags Refresh Delay"] or "AdiBags Refresh Delay", desc=L["Delay (in seconds) before refreshing AdiBags after confirming a transmog. AdiBags must be installed and enabled for this to work."] or "Delay (in seconds) before refreshing AdiBags after confirming a transmog. AdiBags must be installed and enabled for this to work.", min=0.1, max=1.0, step=0.05, get=get, set=set },
            -- per-module debug toggle removed (uses global Extras > Debug Mode)
        }
    }
end

function Module:OnSettingChanged(key)
    if key == "scanInterval" then
        if self.scanner then self.scanner.accum = 0 end
    end
end

-------------------------------------------------
-- Open config helper
-------------------------------------------------
function Module:OpenConfig()
    if YATP.OpenConfig then YATP:OpenConfig(ModuleName) end
end
