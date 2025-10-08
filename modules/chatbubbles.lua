--========================================================--
-- YATP - ChatBubbles Module (integrated from standalone NoBubbles)
-- Removes graphical chat bubble textures and applies custom font styling
--========================================================--

local ADDON = ... -- not strictly needed inside AceAddon context
local YATP = LibStub("AceAddon-3.0"):GetAddon("YATP", true)
if not YATP then return end

local L = LibStub("AceLocale-3.0"):GetLocale("YATP", true)

local ChatBubbles = YATP:NewModule("ChatBubbles", "AceEvent-3.0")

-- Defaults migrated from original addon (renamed)
ChatBubbles.defaults = {
    enabled = true,
    fontSize = 14,
    font = "FRIZQT",       -- FRIZQT, ARIALN, MORPHEUS, SKURRI
    flags = "OUTLINE",      -- "", OUTLINE, THICKOUTLINE
    aggressive = false,      -- continuous sweeping
    scanInterval = 0.08,     -- seconds between sweeps when aggressive
    postSweeps = 2,          -- extra sweeps after a detection
}

local FONTS = {
    FRIZQT   = { name = "Friz Quadrata", path = "Fonts\\FRIZQT__.TTF" },
    ARIALN   = { name = "Arial Narrow",  path = "Fonts\\ARIALN.TTF"  },
    MORPHEUS = { name = "Morpheus",      path = "Fonts\\MORPHEUS.TTF"},
    SKURRI   = { name = "Skurri",        path = "Fonts\\SKURRI.TTF"  },
}

local FLAG_LABELS = {
    [""]             = "None",
    ["OUTLINE"]      = "Outline",
    ["THICKOUTLINE"] = "Thick Outline",
}

-- Forward declarations
local evtFrame
local pendingSweeps = 0       -- sweeps extra post-detección (consumidos por tarea scheduler)
local scheduled = false       -- marca si la tarea ya registrada
local aggressiveTaskName = "ChatBubblesAggressive"
local postTaskName = "ChatBubblesPostSweeps"

-------------------------------------------------
-- Utility helpers
-------------------------------------------------
local function fontValues()
    local t = {}
    for k, v in pairs(FONTS) do t[k] = v.name end
    return t
end

function ChatBubbles:StyleText(fs)
    if not fs then return end
    local db = self.db
    if not (db and db.enabled) then return end
    local fontPath = (FONTS[db.font] and FONTS[db.font].path) or FONTS.FRIZQT.path
    local flags = db.flags ~= "" and db.flags or nil
    fs:SetFont(fontPath, db.fontSize, flags)
    fs:SetJustifyH("LEFT")
end

function ChatBubbles:ApplySettings()
    if not self.db.enabled then return end
    for i = 1, WorldFrame:GetNumChildren() do
        local frame = select(i, WorldFrame:GetChildren())
        if frame and frame.text and frame.inUse then
            self:StyleText(frame.text)
        end
    end
end

-------------------------------------------------
-- Bubble skinning adapted
-------------------------------------------------
local function SkinFrame(frame)
    if frame.__cbStyled then return end
    local hasFont
    for i = 1, select("#", frame:GetRegions()) do
        local region = select(i, frame:GetRegions())
        if region then
            local otype = region:GetObjectType()
            if otype == "Texture" then
                region:SetTexture(nil)
            elseif otype == "FontString" then
                hasFont = true
                frame.text = frame.text or region
            end
        end
    end
    if hasFont and frame.text then
        ChatBubbles:StyleText(frame.text)
        frame.inUse = true
        if not frame.__cb_hooked then
            frame:HookScript("OnHide", function() frame.inUse = false end)
            frame.__cb_hooked = true
        end
        frame.__cbStyled = true
    end
end

local function UpdateFrame(frame)
    if not frame.text then
        SkinFrame(frame)
    else
        ChatBubbles:StyleText(frame.text)
    end
end

local function FindFrame(msg)
    for i = 1, WorldFrame:GetNumChildren() do
        local frame = select(i, WorldFrame:GetChildren())
        if frame and not frame:GetName() and not frame.inUse then
            for j = 1, select("#", frame:GetRegions()) do
                local region = select(j, frame:GetRegions())
                if region and region:GetObjectType() == "FontString" and region:GetText() == msg then
                    return frame
                end
            end
        end
    end
end

local function FullSweep()
    local children = { WorldFrame:GetChildren() }
    for _, frame in ipairs(children) do
        if frame and not frame:GetName() and not frame.__cbStyled then
            SkinFrame(frame)
        end
    end
end

local function RunPostSweep()
    if pendingSweeps > 0 then
        pendingSweeps = pendingSweeps - 1
        FullSweep()
    end
end

local function EnsureScheduled()
    if scheduled then return end
    local sched = YATP and YATP.GetScheduler and YATP:GetScheduler()
    if not sched then return end
    -- Aggressive sweep tarea (solo ejecuta si aggressive activo)
    sched:AddTask(aggressiveTaskName, function()
        return ChatBubbles.db and (ChatBubbles.db.scanInterval or 0.12) or 0.12
    end, function()
        local db = ChatBubbles.db
        if db and db.enabled and db.aggressive then
            FullSweep()
        end
    end, { spread = 0.1 })
    -- Post sweeps (rápidas) intervalo fijo pequeño mientras haya pendientes
    sched:AddTask(postTaskName, 0.07, RunPostSweep, { spread = 0.05 })
    scheduled = true
end

local function SchedulePostSweeps(n)
    if n <= 0 then return end
    pendingSweeps = math.min(5, math.max(pendingSweeps, n)) -- cap 5
    EnsureScheduled()
end

local chatEvents = {
    CHAT_MSG_SAY = true,
    CHAT_MSG_YELL = true,
    CHAT_MSG_PARTY = true,
    CHAT_MSG_PARTY_LEADER = true,
    CHAT_MSG_MONSTER_SAY = true,
    CHAT_MSG_MONSTER_YELL = true,
    CHAT_MSG_MONSTER_PARTY = true,
}

-------------------------------------------------
-- Module lifecycle
-------------------------------------------------
function ChatBubbles:OnInitialize()
    -- Migration: pull from legacy global NoBubblesDB if present and not yet migrated
    local store = YATP.db.profile.modules
    if not store.ChatBubbles then
        store.ChatBubbles = CopyTable(self.defaults)
        if _G.NoBubblesDB and type(_G.NoBubblesDB.profile) == "table" then
            local legacy = _G.NoBubblesDB.profile
            for k,v in pairs(self.defaults) do
                if legacy[k] ~= nil then
                    store.ChatBubbles[k] = legacy[k]
                end
            end
        end
    end
    self.db = store.ChatBubbles

    if YATP.AddModuleOptions then
        YATP:AddModuleOptions("ChatBubbles", self:BuildOptions(), "Interface")
    end

    -- Slash commands (mirror original)
    YATP:RegisterChatCommand("cbubbles", function() self:OpenConfig() end)
    YATP:RegisterChatCommand("chatbubbles", function() self:OpenConfig() end)
end

function ChatBubbles:OnEnable()
    if not self.db.enabled then return end
    EnsureScheduled()
    evtFrame = evtFrame or CreateFrame("Frame")
    for ev in pairs(chatEvents) do evtFrame:RegisterEvent(ev) end
    evtFrame:SetScript("OnEvent", function(_, event, msg)
        if GetCVarBool("chatBubbles") or GetCVarBool("chatBubblesParty") then
            -- short polling window to find bubble frame
            evtFrame.elapsed = 0
            evtFrame:SetScript("OnUpdate", function(self, elapsed)
                self.elapsed = self.elapsed + elapsed
                local frame = FindFrame(msg)
                if frame or self.elapsed > 0.3 then
                    self:SetScript("OnUpdate", nil)
                    if frame then UpdateFrame(frame) end
                    -- schedule extra sweeps to catch late texture recycle
                    if frame and ChatBubbles.db.postSweeps and ChatBubbles.db.postSweeps > 0 then
                        SchedulePostSweeps(ChatBubbles.db.postSweeps)
                    end
                end
            end)
        end
    end)
end

function ChatBubbles:OnDisable()
    if evtFrame then
        for ev in pairs(chatEvents) do evtFrame:UnregisterEvent(ev) end
        evtFrame:SetScript("OnEvent", nil)
        evtFrame:SetScript("OnUpdate", nil)
    end
    -- Las tareas del scheduler verificarán db.enabled y no harán trabajo.
end

-------------------------------------------------
-- Options
-------------------------------------------------
function ChatBubbles:BuildOptions()
    local get = function(info) return self.db[ info[#info] ] end
    local set = function(info, val)
        self.db[ info[#info] ] = val
        if info[#info] == "enabled" then
            if val then self:OnEnable() else self:OnDisable() end
        else
            self:ApplySettings()
        end
    end

    return {
        type = "group",
        name = L["ChatBubbles"] or "ChatBubbles",
        args = {
            general = {
                type="group", name=L["General"], inline=true, order=1,
                args = {
                    enabled = { type="toggle", name=L["Hide Chat Bubbles"] or L["Enable"] or "Hide Chat Bubbles", order=1, width="full", 
                        desc = L["Toggle the ChatBubbles module. Removes bubble artwork and restyles the text using your chosen font settings."] or "Toggle the ChatBubbles module. Removes bubble artwork and restyles the text using your chosen font settings.",
                        get=get, set=set },
                }
            },
            fontGroup = {
                type="group", name=L["Font"] or "Font", inline=true, order=10,
                args = {
                    font = { type="select", name=L["Font Face"] or "Font Face", values = function() return fontValues() end, order=1, width="full", get=get, set=set },
                    fontSize = { type="range", name=L["Font Size"] or "Font Size", min=8, max=32, step=1, order=2, width="full", get=get, set=set },
                    flags = { type="select", name=L["Outline"] or "Outline", values = FLAG_LABELS, order=3, width="full", get=get, set=set },
                }
            },
            advanced = {
                type="group", name=L["Advanced"] or "Advanced", inline=true, order=20,
                args = {
                    aggressive = { type="toggle", name=L["Aggressive Scan"] or "Aggressive Scan", order=1, width="full",
                        desc = L["Continuously sweep world frames to strip bubble textures ASAP (slightly higher CPU)."] or "Continuously sweep world frames to strip bubble textures ASAP (slightly higher CPU).",
                        get = function() return self.db.aggressive end,
                        set = function(_, v) self.db.aggressive = v end },
                    scanInterval = { type="range", name=L["Scan Interval"] or "Scan Interval", order=2, width="full",
                        min=0.02, max=0.25, step=0.01, bigStep=0.01,
                        desc = L["Seconds between sweeps in aggressive mode."] or "Seconds between sweeps in aggressive mode.",
                        get = function() return self.db.scanInterval end,
                        set = function(_, v) self.db.scanInterval = v end },
                    postSweeps = { type="range", name=L["Post-detection Sweeps"] or "Post-detection Sweeps", order=3, width="full",
                        min=0, max=5, step=1,
                        desc = L["Extra quick sweeps right after detecting a bubble."] or "Extra quick sweeps right after detecting a bubble.",
                        get = function() return self.db.postSweeps end,
                        set = function(_, v) self.db.postSweeps = v end },
                }
            },
        }
    }
end

-------------------------------------------------
-- Config open
-------------------------------------------------
function ChatBubbles:OpenConfig()
    if YATP.OpenConfig then
        YATP:OpenConfig("ChatBubbles")
    end
end

return ChatBubbles
