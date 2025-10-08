--========================================================--
-- YATP - ChatFilters Module
--========================================================--
-- Purpose: Suppress noisy system chat lines (e.g. repetitive interface
-- error spam) with user toggles for each predefined message.
-- Scope: Initial minimal implementation with two fixed suppressible
-- messages, each behind its own toggle inside the QoL > Chat Filters panel.
-- Future: Could expand into user-defined pattern list & summary counters.
--========================================================--

local ADDON = "YATP"
local YATP = LibStub("AceAddon-3.0"):GetAddon(ADDON, true)
if not YATP then return end

local Module = YATP:NewModule("ChatFilters", "AceEvent-3.0")

--------------------------------------------------
-- Defaults
--------------------------------------------------
Module.defaults = {
    enabled = true, -- master enable/disable for the module
    suppressInterfaceActionFailed = true, -- filter message 1
    suppressUIErrorOccurred = true,      -- filter message 2
    useSubstringMatching = true,         -- (hidden) always on: substring (case-insensitive)
    debugWindowSeconds = 8,              -- reserved for a future debug passthrough
    diagnosticLog = false,               -- (hidden) when true + debug mode: log near-miss lines to help adjust filters
    scanExtraSystemEvents = true,        -- (hidden) always true for now: hook a few related events (safety net)
    -- Loot money suppression (simple toggle – always hide money lines when enabled)
    suppressLootMoney = false,
    -- Login welcome spam (grouped suppression)
    suppressLoginWelcomeSpam = false,    -- group toggle (welcome, uptime, total time played, level time played)
    -- Advanced: legacy AddMessage hook (disabled by default; can cause crashes on some clients)
    enableAddMessageHook = false,            -- legacy (hidden)
    enableTimePlayedHook = true,             -- hidden, always applied when suppressLoginWelcomeSpam active
    suppressOnlyFirstPlayed = true,          -- hidden: only hide first automatic /played
    enableInterfaceFailedFallback = false,   -- hidden: targeted DEFAULT_CHAT_FRAME AddMessage hook (risky)
}

-- Target strings (exact). Using English retail style text; adjust if server differs.
local LINE_INTERFACE_ACTION_FAILED = "interface action failed"   -- lowered fragment; we will lowercase incoming
-- UI error line shows inconsistent formatting and a common misspelling 'occured'.
-- We'll treat it as presence of 'ui' + 'error' + 'interface' + 'error' and final token 'occurred/occured'.
local LINE_UI_ERROR_OCCURRED       = "ui error: an interface error occurred" -- canonical lowered fragment (kept for reference)

-- Internal state counters (simple session stats)
local countInterfaceFailed = 0
local countUIErrorOccurred = 0
local countLootMoneySuppressed = 0
local countLoginSpamSuppressed = 0
local debugUntil = 0
local pendingStatRefresh = false

local function ThrottledStatsRefresh()
    if pendingStatRefresh then return end
    pendingStatRefresh = true
    local ok, C_Timer = pcall(function() return C_Timer end)
    if ok and C_Timer and C_Timer.After then
        C_Timer.After(0.3, function()
            pendingStatRefresh = false
            if LibStub then
                local reg = LibStub("AceConfigRegistry-3.0", true)
                if reg then reg:NotifyChange("YATP") end
            end
        end)
    else
        -- Fallback immediate refresh if timer not available
        pendingStatRefresh = false
        if LibStub then
            local reg = LibStub("AceConfigRegistry-3.0", true)
            if reg then reg:NotifyChange("YATP") end
        end
    end
end

-- Frame hook storage
local hookedFrames = {}
local hookRequested = false

-- (Removed summary/threshold logic – kept counter only)

--------------------------------------------------
-- Utility: Conditional debug output respecting global debug mode
--------------------------------------------------
function Module:Debug(msg)
    if YATP and YATP.IsDebug and YATP:IsDebug() then
        DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99YATP:ChatFilters|r " .. tostring(msg))
    end
end

--------------------------------------------------
-- Filter Function
-- Return true to suppress, false/nil to allow.
--------------------------------------------------
-- Utility: remove WoW inline color codes |cAARRGGBB ... |r (and any stray |r)
local colorPattern = "|c%x%x%x%x%x%x%x%x"
local function StripColors(s)
    if not s or s == "" then return s end
    -- remove starting |cXXXXXXXX sequences and matching |r resets
    local cleaned = s:gsub(colorPattern, ""):gsub("|r", "")
    return cleaned
end

-- Parse money loot line (returns true if it's a money-only line)
local function ParseMoneyLine(lowered)
    -- Accept forms:
    --  you loot 13 copper
    --  you loot 2 silver.
    --  you loot 1 gold!
    --  your share of the loot is 5 silver 32 copper.
    -- Allow optional punctuation and mixed multi-denomination sequences.
    -- Strategy: strip trailing punctuation, then tokenize numbers + denom pairs.
    local s = lowered:gsub("[%.,!]+$", "")
    if not (s:find("you loot", 1, true) or s:find("your share of the loot is", 1, true)) then
        -- Fallback: some servers format money without the exact prefix; accept line if it contains at least one denomination token
        if not (s:find("gold", 1, true) or s:find("silver", 1, true) or s:find("copper", 1, true)) then
            return nil
        end
    end
    -- Exclude probable item loot lines if they contain a colon followed immediately by a color code / item link and no denomination tokens
    if s:find("you loot:", 1, true) and not (s:find("gold", 1, true) or s:find("silver", 1, true) or s:find("copper", 1, true)) then return nil end
    for _ in s:gmatch("%d+%s+(gold|silver|copper)") do
        return true
    end
    return false
end

local function SystemMessageFilter(self, event, msg, ...)
    local db = Module.db
    if not db or not db.enabled then return false end
    if debugUntil > 0 and GetTime() < debugUntil then
        -- In debug passthrough window; do not suppress.
        return false
    end
    local original = msg or ""
    local stripped = StripColors(original)
    local lowered = stripped:lower()

    -- Exact vs substring logic; we default to substring fragments to be locale / punctuation tolerant
    local suppressed = false

    if db.suppressInterfaceActionFailed then
        if db.useSubstringMatching then
            if lowered:find(LINE_INTERFACE_ACTION_FAILED, 1, true) then
                countInterfaceFailed = countInterfaceFailed + 1
                ThrottledStatsRefresh()
                suppressed = true
            end
        elseif lowered == LINE_INTERFACE_ACTION_FAILED then
            countInterfaceFailed = countInterfaceFailed + 1
            suppressed = true
        end
    end

    if not suppressed and db.suppressUIErrorOccurred then
        if db.useSubstringMatching then
            -- Token approach: ensure essential parts exist regardless of duplicated prefixes or missing spaces
            -- Normalize by removing spaces and colons for a secondary loose compare too.
            local compact = lowered:gsub("[%s:]", "")
            -- Basic token presence check
            local hasUI = lowered:find("ui", 1, true)
            local hasFirstError = lowered:find("error", 1, true)
            local hasInterface = lowered:find("interface", 1, true)
            -- Accept either 'occurred' or 'occured'
            local hasOccurred = lowered:find("occurred", 1, true) or lowered:find("occured", 1, true)
            if hasUI and hasFirstError and hasInterface and hasOccurred then
                countUIErrorOccurred = countUIErrorOccurred + 1
                ThrottledStatsRefresh()
                suppressed = true
            else
                -- Fallback: compact pattern to catch variants like 'uierror:ui error: an interface error occured.'
                if compact:find("uierroruierroraninterfaceerroroccur", 1, true) or compact:find("uierroraninterfaceerroroccur", 1, true) then
                    countUIErrorOccurred = countUIErrorOccurred + 1
                    ThrottledStatsRefresh()
                    suppressed = true
                end
            end
        else
            -- Strict equality fallback (unlikely to match in variants but kept for completeness)
            if lowered == LINE_UI_ERROR_OCCURRED then
                countUIErrorOccurred = countUIErrorOccurred + 1
                suppressed = true
            end
        end
    end

    if not suppressed and original and original ~= "" then
        if db.suppressLootMoney then
            local isMoney = ParseMoneyLine(lowered)
            if isMoney then
                countLootMoneySuppressed = countLootMoneySuppressed + 1
                ThrottledStatsRefresh()
                suppressed = true
            elseif event == "CHAT_MSG_MONEY" then
                -- Fallback: event explicitly flagged as MONEY; suppress anyway
                countLootMoneySuppressed = countLootMoneySuppressed + 1
                ThrottledStatsRefresh()
                suppressed = true
                Module:Debug("(money-fallback) Suppressed via event only: " .. lowered)
            elseif db.diagnosticLog and YATP and YATP.IsDebug and YATP:IsDebug() and event == "CHAT_MSG_MONEY" then
                Module:Debug("(money-diagnostic) toggle=ON but ParseMoneyLine failed: '" .. lowered .. "'")
            end
        elseif event == "CHAT_MSG_MONEY" and db.diagnosticLog and YATP and YATP.IsDebug and YATP:IsDebug() then
            Module:Debug("(money-diagnostic) toggle=OFF value appeared: '" .. lowered .. "'")
        end
    end

    if not suppressed and db.suppressLoginWelcomeSpam then
        -- Expand variants; allow optional 'on' or 'at' or 'in', tolerate punctuation
        local l = lowered:gsub("[%.!]+$", "")
        if l:find("welcome to ascension", 1, true)
            or l:find("server uptime", 1, true)
            or l:find("total time played", 1, true)
            or l:find("time played this level", 1, true)
            or l:find("time played on this level", 1, true)
            or l:find("time played in this level", 1, true)
            or l:find("time played at this level", 1, true)
        then
            countLoginSpamSuppressed = countLoginSpamSuppressed + 1
            ThrottledStatsRefresh()
            suppressed = true
        end
    end

    if suppressed then
        return true
    end

    -- Near-miss diagnostics: if debug + diagnosticLog, record lines containing partial tokens to help refine
    if db.diagnosticLog and YATP and YATP.IsDebug and YATP:IsDebug() then
        local looksInterface = (event == "CHAT_MSG_SYSTEM") and (lowered:find("interface action", 1, true) or lowered:find("ui error", 1, true)) or false
        local looksTime = (event == "CHAT_MSG_SYSTEM") and lowered:find("time played", 1, true) or false
        local looksMoney = (event == "CHAT_MSG_MONEY") or false
        if not looksMoney and event ~= "CHAT_MSG_MONEY" and db.suppressLootMoney then
            if ParseMoneyLine(lowered) then looksMoney = true end
        end
        if looksInterface or looksTime or looksMoney then
            Module:Debug(string.format("(diagnostic) event=%s raw='%s' stripped='%s' lowered='%s'", tostring(event), original, stripped, lowered))
        end
    end
    return false
end

--------------------------------------------------
-- Generic line checks (used by event filter and frame hook)
--------------------------------------------------
local function ShouldSuppressLoginLine(lowered)
    local l = lowered:gsub("[%.!]+$", "")
    if l:find("welcome to ascension", 1, true)
        or l:find("server uptime", 1, true)
        or l:find("total time played", 1, true)
        or l:find("time played this level", 1, true)
        or l:find("time played on this level", 1, true)
        or l:find("time played in this level", 1, true)
        or l:find("time played at this level", 1, true)
    then
        return true
    end
    return false
end

local function StripAndLower(line)
    if not line then return "" end
    local stripped = StripColors(line)
    return stripped:lower(), stripped
end

local function HookedAddMessage(frame, text, r, g, b, id, holdTime, ...)
    local db = Module.db
    if not db or not db.enabled or not db.enableAddMessageHook then
        if frame.__YATP_OrigAddMessage and frame.__YATP_OrigAddMessage ~= frame.AddMessage then
            return frame.__YATP_OrigAddMessage(frame, text, r, g, b, id, holdTime, ...)
        end
        return
    end
    if db.suppressLoginWelcomeSpam and type(text) == "string" then
        local lowered = StripAndLower(text)
        if ShouldSuppressLoginLine(lowered) then
            if db.diagnosticLog and YATP and YATP.IsDebug and YATP:IsDebug() then
                Module:Debug("(hook) suppressed login line: " .. text)
            end
            countLoginSpamSuppressed = countLoginSpamSuppressed + 1
            ThrottledStatsRefresh()
            return -- swallow
        end
    end
    if frame.__YATP_OrigAddMessage and frame.__YATP_OrigAddMessage ~= frame.AddMessage then
        return frame.__YATP_OrigAddMessage(frame, text, r, g, b, id, holdTime, ...)
    end
end

local function HookChatFrames()
    if type(NUM_CHAT_WINDOWS) ~= "number" or NUM_CHAT_WINDOWS <= 0 then return end
    for i=1, NUM_CHAT_WINDOWS do
        local f = _G["ChatFrame"..i]
        if f and not f.__YATP_OrigAddMessage and type(f.AddMessage) == "function" then
            -- pcall guard in case another addon overwrites unexpectedly
            local ok = pcall(function()
                f.__YATP_OrigAddMessage = f.AddMessage
                f.AddMessage = HookedAddMessage
                hookedFrames[#hookedFrames+1] = f
            end)
            if not ok and YATP and YATP.IsDebug and YATP:IsDebug() then
                Module:Debug("Failed to hook ChatFrame"..i)
            end
        end
    end
end

local function RequestHookLater()
    if hookRequested then return end
    hookRequested = true
    Module:RegisterEvent("PLAYER_LOGIN", function()
        -- Defer a bit more to allow other addons to finish altering chat frames.
        local delayFrame, elapsed = CreateFrame("Frame"), 0
        delayFrame:SetScript("OnUpdate", function(f, e)
            elapsed = elapsed + e
            if elapsed > 0.5 then
                f:SetScript("OnUpdate", nil)
                if Module.db and Module.db.enableAddMessageHook then
                    HookChatFrames()
                end
            end
        end)
        Module:UnregisterEvent("PLAYER_LOGIN")
    end)
end

local function UnhookChatFrames()
    for _, f in ipairs(hookedFrames) do
        if f.__YATP_OrigAddMessage then
            f.AddMessage = f.__YATP_OrigAddMessage
            f.__YATP_OrigAddMessage = nil
        end
    end
    wipe(hookedFrames)
end

-- Targeted fallback hook for direct AddMessage prints of the interface action failed line.
-- Some server builds (or other addons) may bypass CHAT_MSG_SYSTEM and call DEFAULT_CHAT_FRAME:AddMessage directly,
-- which our event filter cannot intercept. We safely wrap ONLY ChatFrame1 (DEFAULT_CHAT_FRAME) instead of all frames
-- to avoid the broader crash risk that motivated hiding the legacy AddMessage hook.
local function InstallInterfaceFailedFallback()
    -- Disabled (crash risk). Left as no-op. Hidden flag retained for future safer implementation.
    if Module.db and Module.db.enableInterfaceFailedFallback then
        if YATP and YATP.IsDebug and YATP:IsDebug() then
            Module:Debug("InterfaceFailedFallback requested but currently disabled (no-op)")
        end
    end
end

local function RemoveInterfaceFailedFallback()
    local f = _G.DEFAULT_CHAT_FRAME
    if f and f.__YATP_IFOrigAddMessage then
        f.AddMessage = f.__YATP_IFOrigAddMessage
        f.__YATP_IFOrigAddMessage = nil
    end
    Module._fallbackIFHookInstalled = nil
end

--------------------------------------------------
-- Local helpers
--------------------------------------------------
local orig_ChatFrame_DisplayTimePlayed -- forward declare for restore

local function EnsureDB()
    if not YATP.db.profile.modules then YATP.db.profile.modules = {} end
    if not YATP.db.profile.modules.ChatFilters then
        -- Fallback CopyTable (some private builds may lack it early)
        local copy
        if type(CopyTable) == "function" then
            copy = CopyTable(Module.defaults)
        else
            copy = {}
            for k,v in pairs(Module.defaults) do copy[k]=v end
        end
        YATP.db.profile.modules.ChatFilters = copy
    end
    Module.db = YATP.db.profile.modules.ChatFilters
    -- Migration: auto-disable legacy AddMessage hook once
    if Module.db.enableAddMessageHook and not Module.db._migratedDisableAddMsg then
        Module.db.enableAddMessageHook = false
        Module.db._migratedDisableAddMsg = true
    end
end

--------------------------------------------------
-- Lifecycle
--------------------------------------------------
function Module:OnInitialize()
    EnsureDB()
    -- Register options into Quality of Life hub
    if YATP.AddModuleOptions then
        YATP:AddModuleOptions("ChatFilters", self:BuildOptions(), "QualityOfLife")
    end
    -- Delay hooking until PLAYER_LOGIN to avoid early frame access crash
    RequestHookLater()
end

function Module:OnEnable()
    if not self.db or not self.db.enabled then return end
    ChatFrame_AddMessageEventFilter("CHAT_MSG_SYSTEM", SystemMessageFilter)
    ChatFrame_AddMessageEventFilter("CHAT_MSG_MONEY", SystemMessageFilter)
    if self.db.scanExtraSystemEvents then
        -- Safety net: sometimes servers may route these messages oddly
        ChatFrame_AddMessageEventFilter("CHAT_MSG_CHANNEL", SystemMessageFilter)
        ChatFrame_AddMessageEventFilter("CHAT_MSG_SAY", SystemMessageFilter)
    end
    self:Debug("ChatFilters enabled")
    -- Legacy AddMessage hook left possible via SavedVariables flag (not exposed)
    if self.db.enableAddMessageHook then
        if _G.ChatFrame1 then HookChatFrames() else RequestHookLater() end
    end
    self:SetupTimePlayedHook()
    -- prepare suppression flag for first automatic /played lines after login/reload
    self._suppressNextTimePlayed = true
    self:RegisterEvent("PLAYER_ENTERING_WORLD", function()
        self._suppressNextTimePlayed = true
    end)
    -- Fallback hook now gated behind hidden flag; not auto-enabled to avoid potential crashes.
    InstallInterfaceFailedFallback()
end

function Module:OnDisable()
    ChatFrame_RemoveMessageEventFilter("CHAT_MSG_SYSTEM", SystemMessageFilter)
    ChatFrame_RemoveMessageEventFilter("CHAT_MSG_MONEY", SystemMessageFilter)
    if self.db and self.db.scanExtraSystemEvents then
        ChatFrame_RemoveMessageEventFilter("CHAT_MSG_CHANNEL", SystemMessageFilter)
        ChatFrame_RemoveMessageEventFilter("CHAT_MSG_SAY", SystemMessageFilter)
    end
    -- (Summary timer removed)
    self:Debug("ChatFilters disabled")
    UnhookChatFrames()
    RemoveInterfaceFailedFallback()
    -- Restore time played if hooked
    if orig_ChatFrame_DisplayTimePlayed and ChatFrame_DisplayTimePlayed == Module._proxyTimePlayed then
        ChatFrame_DisplayTimePlayed = orig_ChatFrame_DisplayTimePlayed
    end
end

--------------------------------------------------
-- Panic helper (manual emergency disable from /run)
--------------------------------------------------
SLASH_YATPCHATFILTERSOFF1 = "/yatpcfoff"
SlashCmdList["YATPCHATFILTERSOFF"] = function()
    if YATP and YATP.db and YATP.db.profile and YATP.db.profile.modules and YATP.db.profile.modules.ChatFilters then
        YATP.db.profile.modules.ChatFilters.enabled = false
        if Module:IsEnabled() then Module:Disable() end
        print("YATP ChatFilters: force disabled.")
    end
end

-- Hidden toggle for interface failed fallback hook (diagnostic use only)
SLASH_YATPIFHOOK1 = "/yatpiffallback"
SlashCmdList["YATPIFHOOK"] = function()
    print("YATP ChatFilters: fallback hook deshabilitado por riesgo de crash. No se activará.")
end

--------------------------------------------------
-- Loot Money Summary Support
--------------------------------------------------
-- (Removed summary-related helper functions)

--------------------------------------------------
-- Options (AceConfig table construction)
--------------------------------------------------
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
        end
    end

    return {
        type = "group",
        name = "Chat Filters",
        args = {
            header = { type = "header", name = "Chat Filters", order = 0 },
            enabled = {
                type = "toggle", order = 1,
                name = "Enable Module",
                desc = "Enable or disable suppression of predefined chat system lines.",
                get = get, set = set,
            },
            description = {
                type = "description", order = 2, fontSize = "small",
                name = "Suppress repetitive system error lines that add noise to chat. Each line has its own toggle.",
            },
            suppressInterfaceActionFailed = {
                type = "toggle", order = 10,
                name = "Suppress 'Interface action failed because of an AddOn'",
                desc = "Hide the system line: 'Interface action failed because of an AddOn'.",
                width = "full",
                get = get, set = set,
                disabled = function() return not self.db.enabled end,
            },
            suppressUIErrorOccurred = {
                type = "toggle", order = 11,
                name = "Suppress 'UI Error: an interface error occurred.'",
                desc = "Hide the system line: 'UI Error: an interface error occurred.'",
                width = "full",
                get = get, set = set,
                disabled = function() return not self.db.enabled end,
            },
            lootHeader = { type = "header", order = 20, name = "Loot Money" },
            suppressLootMoney = {
                type = "toggle", order = 21,
                name = "Enable Loot Money Filtering",
                desc = "Hide repetitive 'You loot X Copper/Silver/Gold' lines.",
                get = get, set = set,
                disabled = function() return not self.db.enabled end,
            },
            -- Removed mode / threshold / interval controls for simplicity
            loginHeader = { type = "header", order = 25, name = "Login Welcome Spam" },
            suppressLoginWelcomeSpam = {
                type = "toggle", order = 26,
                name = "Suppress Login Welcome Lines",
                desc = "Hide Welcome/Uptime and the first automatic 'Total time played' dump after login/reload. Manual /played luego mostrará los tiempos.",
                get = get, set = set,
                disabled = function() return not self.db.enabled end,
            },
            -- Advanced options hidden; behavior applied automatically.
            -- Hidden advanced toggles intentionally removed from UI:
            -- * useSubstringMatching (always true)
            -- * scanExtraSystemEvents (always true for now)
            -- * diagnosticLog (kept internally; toggle not exposed)
            -- * debugWindow (temporary passthrough button hidden by request)
            statsHeader = { type = "header", name = "Session Stats", order = 30 },
            statInterface = {
                type = "description", order = 31,
                name = function() return string.format("Interface action failed suppressed: %d", countInterfaceFailed) end,
            },
            statUIError = {
                type = "description", order = 32,
                name = function() return string.format("UI error occurred suppressed: %d", countUIErrorOccurred) end,
            },
            statLoot = {
                type = "description", order = 33,
                name = function() return string.format("Loot money lines suppressed: %d", countLootMoneySuppressed) end,
            },
            statLogin = {
                type = "description", order = 34,
                name = function() return string.format("Login welcome lines suppressed: %d", countLoginSpamSuppressed) end,
            },
            debugSpacer = { type = "description", order = 50, name = " " },
            -- (Hidden) debugWindow button retained in code but not exposed; you can re-enable by restoring this block.
            -- (Hidden) diagnosticLog toggle similarly omitted.
        }
    }
end

--------------------------------------------------
-- Safer Time Played Hook Implementation
--------------------------------------------------
function Module:SetupTimePlayedHook()
    if not self.db or not self.db.enabled then return end
    if not self.db.suppressLoginWelcomeSpam then return end
    -- enableTimePlayedHook is now implicit (hidden)
    if not orig_ChatFrame_DisplayTimePlayed then
        if type(ChatFrame_DisplayTimePlayed) ~= "function" then return end
        orig_ChatFrame_DisplayTimePlayed = ChatFrame_DisplayTimePlayed
    end
    if ChatFrame_DisplayTimePlayed == Module._proxyTimePlayed then return end
    Module._proxyTimePlayed = function(...)
        local db = Module.db
        if not (db and db.enabled and db.suppressLoginWelcomeSpam and db.enableTimePlayedHook) then
            return orig_ChatFrame_DisplayTimePlayed(...)
        end
        if db.suppressOnlyFirstPlayed then
            if Module._suppressNextTimePlayed then
                Module._suppressNextTimePlayed = false -- consume first automatic dump
                countLoginSpamSuppressed = countLoginSpamSuppressed + 1 -- also treat as login spam suppressed
                ThrottledStatsRefresh()
                return -- suppress this one
            else
                return orig_ChatFrame_DisplayTimePlayed(...)
            end
        else
            return -- always suppress
        end
    end
    ChatFrame_DisplayTimePlayed = Module._proxyTimePlayed
    if YATP and YATP.IsDebug and YATP:IsDebug() then
        Module:Debug("TimePlayed suppression active (proxy installed)")
    end
end

return Module
