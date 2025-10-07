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
}

-- Target strings (exact). Using English retail style text; adjust if server differs.
local LINE_INTERFACE_ACTION_FAILED = "interface action failed"   -- lowered fragment; we will lowercase incoming
-- UI error line shows inconsistent formatting and a common misspelling 'occured'.
-- We'll treat it as presence of 'ui' + 'error' + 'interface' + 'error' and final token 'occurred/occured'.
local LINE_UI_ERROR_OCCURRED       = "ui error: an interface error occurred" -- canonical lowered fragment (kept for reference)

-- Internal state counters (simple session stats)
local countInterfaceFailed = 0
local countUIErrorOccurred = 0
local debugUntil = 0

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
                suppressed = true
            else
                -- Fallback: compact pattern to catch variants like 'uierror:ui error: an interface error occured.'
                if compact:find("uierroruierroraninterfaceerroroccur", 1, true) or compact:find("uierroraninterfaceerroroccur", 1, true) then
                    countUIErrorOccurred = countUIErrorOccurred + 1
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

    if suppressed then
        return true
    end

    -- Near-miss diagnostics: if debug + diagnosticLog, record lines containing partial tokens to help refine
    if db.diagnosticLog and YATP and YATP.IsDebug and YATP:IsDebug() then
        -- Only log if it contains partial tokens but was not suppressed
        if lowered:find("interface action", 1, true) or lowered:find("ui error", 1, true) then
            Module:Debug(string.format("(diagnostic) event=%s raw='%s' stripped='%s' lowered='%s'", tostring(event), original, stripped, lowered))
        end
    end
    return false
end

--------------------------------------------------
-- Local helpers
--------------------------------------------------
local function EnsureDB()
    if not YATP.db.profile.modules then YATP.db.profile.modules = {} end
    if not YATP.db.profile.modules.ChatFilters then
        YATP.db.profile.modules.ChatFilters = CopyTable(Module.defaults)
    end
    Module.db = YATP.db.profile.modules.ChatFilters
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
end

function Module:OnEnable()
    if not self.db or not self.db.enabled then return end
    ChatFrame_AddMessageEventFilter("CHAT_MSG_SYSTEM", SystemMessageFilter)
    if self.db.scanExtraSystemEvents then
        -- Safety net: sometimes servers may route these messages oddly
        ChatFrame_AddMessageEventFilter("CHAT_MSG_CHANNEL", SystemMessageFilter)
        ChatFrame_AddMessageEventFilter("CHAT_MSG_SAY", SystemMessageFilter)
    end
    self:Debug("ChatFilters enabled")
end

function Module:OnDisable()
    ChatFrame_RemoveMessageEventFilter("CHAT_MSG_SYSTEM", SystemMessageFilter)
    if self.db and self.db.scanExtraSystemEvents then
        ChatFrame_RemoveMessageEventFilter("CHAT_MSG_CHANNEL", SystemMessageFilter)
        ChatFrame_RemoveMessageEventFilter("CHAT_MSG_SAY", SystemMessageFilter)
    end
    self:Debug("ChatFilters disabled")
end

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
            debugSpacer = { type = "description", order = 50, name = " " },
            -- (Hidden) debugWindow button retained in code but not exposed; you can re-enable by restoring this block.
            -- (Hidden) diagnosticLog toggle similarly omitted.
        }
    }
end

return Module
