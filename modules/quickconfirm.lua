--========================================================--
-- YATP - QuickConfirm (Quality of Life)
-- Automatically confirms selected StaticPopup dialogs:
--  * Transmog appearance collection (appearance learn)
--  * Logout / Exit dialogs
--========================================================--
local ADDON = "YATP"
local ModuleName = "QuickConfirm"

local L   = LibStub("AceLocale-3.0"):GetLocale(ADDON, true) or setmetatable({}, { __index=function(_,k) return k end })
local YATP = LibStub("AceAddon-3.0"):GetAddon(ADDON, true)
if not YATP then return end

local Module = YATP:NewModule(ModuleName, "AceConsole-3.0")

-- Simple debug print helper
function Module:Debug(msg)
    if not self.db or not self.db.debug then return end
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99YATP:QC|r "..tostring(msg))
end

-------------------------------------------------
-- Defaults
-------------------------------------------------
Module.defaults = {
    enabled = true,
    scanInterval = 0.15, -- seconds between popup scans (throttled)
    autoTransmog = true,
    autoExit = true, -- renamed from autoLogout
    suppressClickSound = false, -- removed feature (kept key for backwards safety, no effect)
    debug = false,
    minClickGap = 0.3, -- safeguard between automatic clicks
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

-- Exit popups rely on StaticPopup dialogs like CONFIRM_EXIT / QUIT (sometimes CAMP on some cores).
local EXIT_POPUP_WHICH = {
    QUIT = true, CONFIRM_EXIT = true, CAMP = true,
}
-- Direct which value seen in debug for transmog confirmation
local TRANSMOG_WHICH = {
    CONFIRM_COLLECT_APPEARANCE = true,
}

-- Additional lowercase textual cues (extended with Spanish variants)
local EXIT_TEXT_CUES = {
    "exit", "quit", "camp", "leave world", -- English
    "salir", "abandonar", -- Spanish core verbs
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
    self:StartScanner()
    self:InstallPopupHook()
    self:RegisterChatCommand("qcdebug", function()
        self.db.debug = not self.db.debug
        self:Debug("debug="..tostring(self.db.debug))
    end)
    self:StartExitWatcher()
end

function Module:OnDisable()
    self:StopScanner()
    self:StopExitWatcher()
end

-------------------------------------------------
-- Hook StaticPopup_Show to catch texts immediately
-------------------------------------------------
function Module:InstallPopupHook()
    if self._popupHookInstalled then return end
    local function hookFn(which, text, ...)
        if not self.db or not self.db.enabled then return end
        if not text or text == "" then return end
        local lowerText = text:lower()
        if self.db.debug then
            DEFAULT_CHAT_FRAME:AddMessage(string.format("|cff33ff99YATP:QuickConfirm|r show '%s' which=%s", (text:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")), tostring(which)))
        end
        -- Direct which detection (fast path) for transmog
        if which and TRANSMOG_WHICH[which] and self.db.autoTransmog then
            C_Timer.After(0, function() self:ConfirmByWhich(which, text) end)
            return
        end
        -- Fallback text pattern detection
        if self.db.autoTransmog then
            for _, pat in ipairs(TRANSMOG_SUBSTRINGS) do
                if lowerText:find(pat, 1, true) then
                    C_Timer.After(0.01, function() self:ConfirmByText(text, "transmog-hook-text") end)
                    break
                end
            end
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
    if self.db.debug then
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
    if self.db.debug then
        DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99YATP:QuickConfirm|r text match failed")
    end
end

-------------------------------------------------
-- Scanner (throttled) using OnUpdate on a hidden frame
-------------------------------------------------
function Module:StartScanner()
    if self.scanner then return end
    local f = CreateFrame("Frame", "YATP_"..ModuleName.."Scanner", UIParent)
    f:Hide() -- remain hidden; no flicker
    f.accum = 0
    f:SetScript("OnUpdate", function(frame, elapsed)
        frame.accum = frame.accum + elapsed
        if frame.accum < (self.db.scanInterval or 0.15) then return end
        frame.accum = 0
        self:ScanOnce()
    end)
    self.scanner = f
end

function Module:StopScanner()
    if self.scanner then
        self.scanner:SetScript("OnUpdate", nil)
        self.scanner:Hide()
        self.scanner = nil
    end
end

-------------------------------------------------
-- Core scan logic
-------------------------------------------------
function Module:ScanOnce()
    if self.db.debug then self._scanTick = (self._scanTick or 0) + 1; if self._scanTick % 20 == 0 then self:Debug("scan running") end end
    -- Iterate all possible StaticPopup frames (Blizzard creates up to 4)
    for i = 1, 4 do
        local frame = _G["StaticPopup"..i]
        if frame and frame:IsShown() then
            local which = frame.which
            local textRegion = _G[frame:GetName().."Text"]
            local text = (textRegion and textRegion:GetText()) or ""
            local lowerText = text:lower()

            if self.db.debug and text ~= "" then
                DEFAULT_CHAT_FRAME:AddMessage(string.format("|cff33ff99YATP:QC Debug|r popup%d which=%s text='%s'", i, tostring(which), lowerText:sub(1,80)))
            end

            -- Transmog detection (prefer which ID)
            if self.db.autoTransmog then
                if which and TRANSMOG_WHICH[which] then
                    self:ClickPrimary(frame, "transmog-which")
                    return
                end
                if text ~= "" then
                    for _, pat in ipairs(TRANSMOG_SUBSTRINGS) do
                        if lowerText:find(pat, 1, true) then
                            self:ClickPrimary(frame, "transmog-text")
                            return
                        end
                    end
                end
            end

            -- Exit detection (covers quit / exit / camp) - excludes generic logout text now
            if self.db.autoExit then
                local isExitCountdown = lowerText:find("seconds until exit", 1, true) or lowerText:find("seconds until logout", 1, true)
                if (which and EXIT_POPUP_WHICH[which]) or ContainsAny(lowerText, EXIT_TEXT_CUES) or isExitCountdown then
                    self:ClickPrimary(frame, isExitCountdown and "exit-countdown" or "exit")
                    if isExitCountdown then
                        self:ForceImmediateExit()
                    end
                    return
                end
            end
        end
    end
    -- Legacy fallback (original logic) if nothing matched yet
    if self.db.autoTransmog then
        for i = 1, 4 do
            local frame = _G["StaticPopup"..i]
            if frame and frame:IsShown() then
                local tr = _G[frame:GetName().."Text"]
                local txt = tr and tr:GetText() or ""
                if txt ~= "" then
                    local lower = txt:lower()
                    if lower:find("are you sure you want to collect the appearance", 1, true) then
                        if self.db.debug then
                            DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99YATP:QC Debug|r legacy pattern matched")
                        end
                        self:ClickPrimary(frame, "transmog-legacy") -- fallback
                        return
                    end
                end
            end
        end
    end
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
        if self.db.debug then
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
                if l:find("seconds until exit", 1, true) or l:find("seconds until logout",1,true)
                   or l:find("segundos hasta salir",1,true) or l:find("segundos hasta la salida",1,true) then
                    return true
                end
            end
        end
    end
    return false
end

function Module:StartExitWatcher()
    if self.exitWatcher or not self.db.autoExit then return end
    local ticker = C_Timer.NewTicker(0.5, function()
        if not self.db.enabled or not self.db.autoExit then return end
        local found
        local f = EnumerateFrames()
        while f do
            if FrameHasExitText(f) then
                found = f
                break
            end
            f = EnumerateFrames(f)
        end
        if found then
            self:Debug("exit countdown frame detected")
            -- Try to click any Button child first
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
    end)
    self.exitWatcher = ticker
end

function Module:StopExitWatcher()
    if self.exitWatcher then
        self.exitWatcher:Cancel()
        self.exitWatcher = nil
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
            desc = { type="description", order=2, fontSize="medium", name = L["Automatically confirms selected confirmation popups (transmog, logout)."] or "Automatically confirms selected confirmation popups (transmog, logout)." },
            headerTransmog = { type="header", name = L["Transmog"] or "Transmog", order = 5 },
            autoTransmog = { type="toggle", order = 6, name = L["Auto-confirm transmog appearance popups"] or "Auto-confirm transmog appearance popups", get=get, set=set },
            headerExit = { type="header", name = L["Exit"] or "Exit", order = 10 },
            autoExit = { type="toggle", order = 11, name = L["Auto-confirm exit popups"] or "Auto-confirm exit popups", get=get, set=set },
            headerOther = { type="header", name = L["Miscellaneous"] or "Miscellaneous", order = 20 },
            -- suppressClickSound removed; placeholder intentionally omitted
            scanInterval = { type="range", order=30, name=L["Scan Interval"] or "Scan Interval", min=0.05, max=0.5, step=0.01, get=get, set=function(i,v) set(i,v) end },
            debug = { type="toggle", order=40, name = L["Debug Messages"] or "Debug Messages", get=get, set=set },
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
