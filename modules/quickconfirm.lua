--========================================================--
-- YATP - QuickConfirm (Quality of Life)
-- Automatically confirms selected StaticPopup dialogs:
--  * Transmog appearance collection (appearance learn)
--  * Exit game dialogs (QUIT / CONFIRM_EXIT) – does NOT auto-confirm logout (CAMP)
--========================================================--
local ADDON = "YATP"
local ModuleName = "QuickConfirm"

local L   = LibStub("AceLocale-3.0"):GetLocale(ADDON, true) or setmetatable({}, { __index=function(_,k) return k end })
local YATP = LibStub("AceAddon-3.0"):GetAddon(ADDON, true)
if not YATP then return end

local Module = YATP:NewModule(ModuleName, "AceConsole-3.0")

-- Simple debug print helper
function Module:Debug(msg)
    if not YATP or not YATP.IsDebug or not YATP:IsDebug() then return end
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99YATP:QC|r "..tostring(msg))
end

-------------------------------------------------
-- Defaults
-------------------------------------------------
Module.defaults = {
    enabled = true,
    scanInterval = 0.25, -- (legacy) mantenido para compat; ya no se usa como OnUpdate scanner continuo
    autoTransmog = true,
    autoExit = true, -- renamed from autoLogout
    suppressClickSound = false, -- removed feature (kept key for backwards safety, no effect)
    -- debug flag removed (now uses global YATP Extras > Debug Mode)
    minClickGap = 0.3, -- safeguard between automatic clicks
    retryAttempts = 4,  -- número de reintentos escalonados para confirmar un popup si botón tarda en habilitarse
    retryStep = 0.15,   -- separación entre reintentos
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

-- Exit popups rely on StaticPopup dialogs like CONFIRM_EXIT / QUIT.
-- Requested change: only auto‑confirm full game exit, NOT logout (CAMP), so CAMP removed.
local EXIT_POPUP_WHICH = {
    QUIT = true,
    CONFIRM_EXIT = true,
}
-- Direct which value seen in debug for transmog confirmation
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
    -- Migration: if old autoLogout exists and autoExit not yet defined, copy value
    if self.db.autoExit == nil and self.db.autoLogout ~= nil then
        self.db.autoExit = self.db.autoLogout
    end

    if YATP.AddModuleOptions then
        YATP:AddModuleOptions(ModuleName, self:BuildOptions(), "QualityOfLife")
    end
end

function Module:OnEnable()
    if not self.db.enabled then return end
    self:InstallPopupHook()
    self:StartExitWatcher()
end

function Module:OnDisable()
    self:StopExitWatcher()
end

-------------------------------------------------
-- Hook StaticPopup_Show to catch texts immediately
-------------------------------------------------
function Module:InstallPopupHook()
    if self._popupHookInstalled then return end
    local function hookFn(which, text, ...)
        if not self.db or not self.db.enabled then return end
        local safeText = type(text) == "string" and text or ""
        local lowerText = safeText:lower()
        if YATP:IsDebug() then
            DEFAULT_CHAT_FRAME:AddMessage(string.format("|cff33ff99YATP:QuickConfirm|r show which=%s text='%s'", tostring(which), (safeText:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""))))
        end
        local needTransmog = false
        if self.db.autoTransmog then
            if which and TRANSMOG_WHICH[which] then
                needTransmog = true
            else
                -- intentar detección por fragmentos de texto si se recibió alguno
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
        if needTransmog then
            self:SchedulePopupRetries({ mode = "transmog", which = which, text = safeText })
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
    if YATP:IsDebug() then
        DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99YATP:QuickConfirm|r could not find frame for which="..tostring(which))
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
    if YATP:IsDebug() then
        DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99YATP:QuickConfirm|r text match failed")
    end
end

-------------------------------------------------
-- Scanner (throttled) using OnUpdate on a hidden frame
-------------------------------------------------
-- Eliminado: scanner continuo sustituido por reintentos programados.
function Module:StartScanner() end
function Module:StopScanner() end

-------------------------------------------------
-- Core scan logic
-------------------------------------------------
-- Eliminado: lógica de escaneo continuo
function Module:ScanOnce() end

-- Programar reintentos escalonados sobre popups detectados
function Module:SchedulePopupRetries(meta)
    local sched = YATP and YATP.GetScheduler and YATP:GetScheduler()
    if not sched then return end
    local baseName = "QuickConfirmPopup:"..(meta.mode or "?")..":"..(meta.which or "-")
    local attempts = 0
    local maxAttempts = self.db.retryAttempts or 4
    local step = self.db.retryStep or 0.15
    if YATP:IsDebug() then
        self:Debug(string.format("schedule transmog retries name=%s max=%d step=%.2f", baseName, maxAttempts, step))
    end
    sched:AddTask(baseName, step, function()
        attempts = attempts + 1
        if not self.db or not self.db.enabled or not self.db.autoTransmog then
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
                    for _, pat in ipairs(TRANSMOG_SUBSTRINGS) do
                        if lower:find(pat, 1, true) then targetFrame = frame; break end
                    end
                    if targetFrame then break end
                end
            end
        end
        if targetFrame then
            self:ClickPrimary(targetFrame, "transmog-auto")
            sched:RemoveTask(baseName)
            return
        end
        if attempts >= maxAttempts then
            if YATP:IsDebug() then
                self:Debug("transmog retries exhausted")
            end
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
        if YATP:IsDebug() then
            DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99YATP:QuickConfirm|r button not ready ("..(reason or "?")..")")
        end
        return
    end

    local now = GetTime()
    if self.lastClick and (now - self.lastClick) < (self.db.minClickGap or 0.3) then return end
    self.lastClick = now

    local ok = pcall(function() button:Click() end)
    self:Debug(string.format("%s auto-confirm (%s)", ok and "performed" or "failed", reason or "?"))
end

-------------------------------------------------
-- Exit countdown watcher (non-StaticPopup frames)
-------------------------------------------------
local function FrameHasExitText(frame)
    if not frame or not frame:IsShown() then return false end
    if frame.GetObjectType and frame:GetObjectType() == "Button" then return false end
    local regions = { frame:GetRegions() }
    for _, r in ipairs(regions) do
        if r and r.GetObjectType and r:GetObjectType()=="FontString" then
            local txt = r:GetText()
            if txt then
                local l = txt:lower()
                if l:find("seconds until exit", 1, true)
                   -- Removed: "seconds until logout" to avoid auto-confirming logout.
                   or l:find("segundos hasta salir",1,true) or l:find("segundos hasta la salida",1,true) then
                    return true
                end
            end
        end
    end
    return false
end

function Module:StartExitWatcher()
    if self._exitSched or not self.db.autoExit then return end
    local sched = YATP and YATP.GetScheduler and YATP:GetScheduler()
    if not sched then return end
    local name = "QuickConfirmExitWatcher"
    sched:AddTask(name, 0.8, function() return 0.8 end, function()
        if not self.db.enabled or not self.db.autoExit then return end
        local f = EnumerateFrames()
        local found
        local scans = 0
        while f and scans < 300 do -- límite para no recorrer demasiados frames
            if FrameHasExitText(f) then found = f; break end
            f = EnumerateFrames(f)
            scans = scans + 1
        end
        if found then
            self:Debug("exit countdown frame detected")
            local clicked
            for i=1, found:GetNumChildren() do
                local child = select(i, found:GetChildren())
                if child and child.GetObjectType and child:GetObjectType()=="Button" and child:IsEnabled() and child:IsShown() then
                    local ok = pcall(function() child:Click() end)
                    self:Debug("attempt child button click: "..tostring(ok))
                    clicked = true
                    break
                end
            end
            if not clicked then
                self:ForceImmediateExit()
            end
        end
    end, { spread = 0.4 })
    self._exitSched = name
end

function Module:StopExitWatcher()
    if self._exitSched then
        local sched = YATP and YATP.GetScheduler and YATP:GetScheduler()
        if sched then sched:RemoveTask(self._exitSched) end
        self._exitSched = nil
    end
end

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
                get = function() return self.db.enabled end,
                set = function(_, v) self.db.enabled = v; if v then self:Enable() else self:Disable() end end,
            },
            desc = { type="description", order=2, fontSize="medium", name = L["Automatically confirms selected confirmation popups (transmog, exit)."] or "Automatically confirms selected confirmation popups (transmog, exit)." },
            headerTransmog = { type="header", name = L["Transmog"] or "Transmog", order = 5 },
            autoTransmog = { type="toggle", order = 6, name = L["Auto-confirm transmog appearance popups"] or "Auto-confirm transmog appearance popups", get=get, set=set },
            headerExit = { type="header", name = L["Exit"] or "Exit", order = 10 },
            autoExit = { type="toggle", order = 11, name = L["Auto-confirm exit popups"] or "Auto-confirm exit popups", get=get, set=set },
            headerOther = { type="header", name = L["Miscellaneous"] or "Miscellaneous", order = 20 },
            -- suppressClickSound removed; placeholder intentionally omitted
            scanInterval = { type="range", hidden=true, order=30, name=L["(Legacy) Scan Interval"] or "(Legacy) Scan Interval", min=0.05, max=0.5, step=0.01, get=get, set=function(i,v) set(i,v) end },
            retryAttempts = { type="range", order=40, name=L["Retry Attempts"] or "Retry Attempts", desc=L["Number of scheduled retry attempts when a popup appears and the confirm button may not yet be ready."] or "Number of scheduled retry attempts when a popup appears and the confirm button may not yet be ready.", min=1, max=10, step=1, get=get, set=set },
            retryStep = { type="range", order=41, name=L["Retry Interval"] or "Retry Interval", desc=L["Seconds between retry attempts."] or "Seconds between retry attempts.", min=0.05, max=0.5, step=0.01, get=get, set=set },
            -- per-module debug toggle removed (uses global Extras > Debug Mode)
        }
    }
end

function Module:OnSettingChanged(key)
    if key == "scanInterval" then
        if self.scanner then self.scanner.accum = 0 end
    elseif key == "autoExit" then
        if self.db.autoExit then
            self:StartExitWatcher()
        else
            self:StopExitWatcher()
        end
    end
end

-------------------------------------------------
-- Open config helper
-------------------------------------------------
function Module:OpenConfig()
    if YATP.OpenConfig then YATP:OpenConfig(ModuleName) end
end
