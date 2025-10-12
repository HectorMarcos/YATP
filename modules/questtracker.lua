--========================================================--
-- YATP - Quest Tracker Module
--========================================================--
-- This module provides enhancements and customizations for the quest tracker
-- Features:
--  * Enhanced quest objective display
--  * Quest progress tracking improvements
--  * Custom quest sorting options
--  * Quest tracker positioning and sizing
--  * Progress notifications and alerts
--========================================================--

local L   = LibStub("AceLocale-3.0"):GetLocale("YATP", true) or setmetatable({}, { __index=function(_,k) return k end })
local LSM = LibStub("LibSharedMedia-3.0", true)
local YATP = LibStub("AceAddon-3.0"):GetAddon("YATP", true)
if not YATP then
    return
end

-- Create the module
local Module = YATP:NewModule("QuestTracker", "AceEvent-3.0", "AceConsole-3.0", "AceTimer-3.0")

-------------------------------------------------
-- Debug helper
-------------------------------------------------
function Module:Debug(msg)
    if YATP.db and YATP.db.profile and YATP.db.profile.debugMode then
        print("|cff00ff00[YATP - QuestTracker]|r " .. tostring(msg))
    end
end

-------------------------------------------------
-- Defaults
-------------------------------------------------
Module.defaults = {
    enabled = true,
    
    -- Display options
    enhancedDisplay = true,
    showQuestLevels = true,
    showProgressPercent = true,
    compactMode = false,
    
    -- Sorting options
    customSorting = false,
    sortByLevel = false,
    sortByZone = false,
    sortByDistance = false,
    
    -- Position and size
    customPosition = false,
    trackerScale = 1.0,
    trackerAlpha = 1.0,
    lockPosition = false,
    
    -- Notifications
    progressNotifications = true,
    completionSound = true,
    objectiveCompleteAlert = true,
    
    -- Auto-tracking
    autoTrackNew = true,
    autoUntrackComplete = false,
    maxTrackedQuests = 25,
    
    -- Visual enhancements
    colorCodeByDifficulty = true,
    highlightNearbyObjectives = true,
    showQuestIcons = true,
}

-------------------------------------------------
-- Local variables
-------------------------------------------------
local questTrackerFrame
local originalUpdateFunction
local trackedQuests = {}
local nearbyObjectives = {}

-------------------------------------------------
-- Version migrations
-------------------------------------------------
local function RunMigrations(self)
    -- Future version migrations will go here
    -- Example:
    -- if self.db.oldKey ~= nil and self.db.newKey == nil then
    --     self.db.newKey = self.db.oldKey; self.db.oldKey = nil
    -- end
end

-------------------------------------------------
-- Quest Tracker Enhancement Functions
-------------------------------------------------

-- Hook into the quest tracker update function
local function HookQuestTracker(self)
    if not self.db.enabled then return end
    
    -- Get the quest tracker frame for WoW 3.3.5
    questTrackerFrame = WatchFrame
    
    if questTrackerFrame then
        self:Debug("Quest tracker frame found: " .. (questTrackerFrame:GetName() or "unnamed"))
        
        -- Apply visual enhancements immediately
        self:ApplyVisualEnhancements()
        
        -- Hook the update function if we haven't already
        if not originalUpdateFunction and questTrackerFrame.Update then
            originalUpdateFunction = questTrackerFrame.Update
            questTrackerFrame.Update = function(...)
                originalUpdateFunction(...)
                self:EnhanceQuestDisplay()
            end
            self:Debug("Hooked WatchFrame.Update function")
        end
    else
        self:Debug("WatchFrame not found")
    end
end

-- Enhance quest display
function Module:EnhanceQuestDisplay()
    if not self.db.enhancedDisplay then return end
    
    self:Debug("Enhancing quest display")
    
    -- Update tracked quests table
    self:UpdateTrackedQuests()
    
    -- Apply quest level display
    if self.db.showQuestLevels then
        self:ShowQuestLevels()
    else
        self:RemoveQuestLevels()
    end
    
    -- Apply progress percentages
    if self.db.showProgressPercent then
        self:ShowProgressPercentages()
    end
    
    -- Apply color coding
    if self.db.colorCodeByDifficulty then
        self:ApplyDifficultyColors()
    end
end

-- Update tracked quests information
function Module:UpdateTrackedQuests()
    wipe(trackedQuests)
    
    -- Get all tracked quests using WoW 3.3.5 API
    local numEntries = GetNumQuestLogEntries()
    for i = 1, numEntries do
        local questTitle, level, questTag, suggestedGroup, isHeader, isCollapsed, isComplete, isDaily, questID = GetQuestLogTitle(i)
        if questTitle and not isHeader and IsQuestWatched(i) then
            -- For 3.3.5, questID might be nil, so we use the index
            local id = questID or i
            trackedQuests[id] = {
                title = questTitle,
                level = level,
                questTag = questTag,
                isComplete = isComplete,
                isDaily = isDaily,
                questIndex = i,
                objectives = {}
            }
            
            -- Get quest objectives
            local numObjectives = GetNumQuestLeaderBoards(i)
            for j = 1, numObjectives do
                local description, objectiveType, finished = GetQuestLogLeaderBoard(j, i)
                if description then
                    table.insert(trackedQuests[id].objectives, {
                        text = description,
                        type = objectiveType,
                        finished = finished
                    })
                end
            end
        end
    end
end

-- Remove quest levels from tracker
function Module:RemoveQuestLevels()
    if not questTrackerFrame then return end
    
    self:Debug("Removing quest levels from WatchFrame")
    
    local numWatched = GetNumQuestWatches()
    for i = 1, numWatched do
        local watchLine = _G["WatchFrameLine" .. i]
        if watchLine and watchLine.text then
            local currentText = watchLine.text:GetText()
            if currentText and string.find(currentText, "^%[%d+%] ") then
                -- Remove the level prefix
                local newText = string.gsub(currentText, "^%[%d+%] ", "")
                watchLine.text:SetText(newText)
                self:Debug("Removed level from: " .. newText)
            end
        end
    end
end

-- Show quest levels in tracker
function Module:ShowQuestLevels()
    if not self.db.showQuestLevels or not questTrackerFrame then return end
    
    self:Debug("Applying quest levels to WatchFrame")
    
    -- Get all quest entries in WatchFrame
    local numWatched = GetNumQuestWatches()
    self:Debug("Number of watched quests: " .. numWatched)
    
    for i = 1, numWatched do
        local questIndex = GetQuestIndexForWatch(i)
        if questIndex then
            local title, level, questTag, suggestedGroup, isHeader, isCollapsed, isComplete, isDaily, questID = GetQuestLogTitle(questIndex)
            
            if title and level and not isHeader then
                -- Find the corresponding watch line in WatchFrame
                local watchLine = _G["WatchFrameLine" .. i]
                if watchLine and watchLine.text then
                    local currentText = watchLine.text:GetText()
                    if currentText then
                        -- Check if level is already added to avoid duplicates
                        local levelPrefix = "[" .. level .. "] "
                        if not string.find(currentText, "^%[%d+%] ") then
                            watchLine.text:SetText(levelPrefix .. currentText)
                            self:Debug("Added level [" .. level .. "] to quest: " .. title)
                        end
                    end
                end
            end
        end
    end
end

-- Show progress percentages
function Module:ShowProgressPercentages()
    -- Implementation for showing progress percentages
    -- This would calculate and display completion percentages for objectives
    self:Debug("Showing progress percentages")
end

-- Apply difficulty-based color coding
function Module:ApplyDifficultyColors()
    -- Implementation for difficulty color coding
    -- This would color quest titles based on difficulty relative to player level
    self:Debug("Applying difficulty colors")
end

-- Apply visual enhancements to the tracker
function Module:ApplyVisualEnhancements()
    if not questTrackerFrame then 
        questTrackerFrame = WatchFrame
    end
    
    if not questTrackerFrame then 
        self:Debug("Cannot apply visual enhancements: WatchFrame not found")
        return 
    end
    
    self:Debug("Applying visual enhancements - Scale: " .. self.db.trackerScale .. ", Alpha: " .. self.db.trackerAlpha)
    
    -- Apply scale
    questTrackerFrame:SetScale(self.db.trackerScale)
    
    -- Apply alpha
    questTrackerFrame:SetAlpha(self.db.trackerAlpha)
    
    -- Handle position locking
    if self.db.lockPosition then
        questTrackerFrame:SetMovable(false)
        questTrackerFrame:EnableMouse(false)
        self:Debug("Position locked")
    else
        questTrackerFrame:SetMovable(true)
        questTrackerFrame:EnableMouse(true)
        self:Debug("Position unlocked")
    end
    
    -- Force a visual update
    if questTrackerFrame:IsVisible() then
        questTrackerFrame:Hide()
        questTrackerFrame:Show()
    end
end

-- Handle quest completion notifications
function Module:OnQuestComplete(questID)
    if not self.db.progressNotifications then return end
    
    local questInfo = trackedQuests[questID]
    if questInfo then
        -- Play completion sound
        if self.db.completionSound then
            PlaySound("QuestCompleted")
        end
        
        -- Show completion message
        self:Debug("Quest completed: " .. (questInfo.title or "Unknown"))
        
        -- Auto-untrack if enabled (for 3.3.5, we need to find the quest index)
        if self.db.autoUntrackComplete and questInfo.questIndex then
            RemoveQuestWatch(questInfo.questIndex)
        end
    end
end

-- Handle objective updates
function Module:OnObjectiveUpdate()
    if self.db.objectiveCompleteAlert then
        -- Implementation for objective completion alerts
        self:Debug("Objective updated")
    end
end

-------------------------------------------------
-- OnInitialize
-------------------------------------------------
function Module:OnInitialize()
    -- Ensure per-module subtable exists
    if not YATP.db.profile.modules then YATP.db.profile.modules = {} end
    if not YATP.db.profile.modules.QuestTracker then
        YATP.db.profile.modules.QuestTracker = CopyTable(self.defaults)
    end
    self.db = YATP.db.profile.modules.QuestTracker

    -- Run migrations if needed
    RunMigrations(self)

    -- Register slash command
    self:RegisterChatCommand("questtracker", function() self:OpenConfig() end)
    self:RegisterChatCommand("qt", function() self:OpenConfig() end)

    -- Register options in Interface Hub
    if YATP.AddModuleOptions then
        YATP:AddModuleOptions("QuestTracker", self:BuildOptions())
    end
end

-------------------------------------------------
-- OnEnable
-------------------------------------------------
function Module:OnEnable()
    if not self.db.enabled then return end
    
    -- Register quest-related events for WoW 3.3.5
    self:RegisterEvent("QUEST_WATCH_UPDATE", "OnQuestWatchUpdate")
    self:RegisterEvent("QUEST_LOG_UPDATE", "OnQuestLogUpdate")
    self:RegisterEvent("UI_INFO_MESSAGE", "OnUIInfoMessage")
    self:RegisterEvent("QUEST_COMPLETE", "OnQuestComplete")
    self:RegisterEvent("PLAYER_ENTERING_WORLD", "OnPlayerEnteringWorld")
    self:RegisterEvent("QUEST_ABANDONED", "OnQuestAbandoned")
    
    self:Debug("Quest Tracker module enabled")
    
    -- Try to hook immediately if WatchFrame exists
    if WatchFrame then
        HookQuestTracker(self)
    else
        -- Hook quest tracker after a short delay to ensure UI is loaded
        self:ScheduleTimer(function() HookQuestTracker(self) end, 1)
    end
end

-------------------------------------------------
-- OnDisable
-------------------------------------------------
function Module:OnDisable()
    -- Unregister events
    self:UnregisterAllEvents()
    
    -- Restore original quest tracker functionality
    if questTrackerFrame and originalUpdateFunction then
        questTrackerFrame.Update = originalUpdateFunction
    end
    
    self:Debug("Quest Tracker module disabled")
end

-------------------------------------------------
-- Event Handlers
-------------------------------------------------
function Module:OnPlayerEnteringWorld()
    -- Initialize quest tracker hooks
    self:ScheduleTimer(function() HookQuestTracker(self) end, 2)
end

function Module:OnQuestWatchUpdate(event, questID)
    self:Debug("Quest watch updated: " .. tostring(questID))
    self:UpdateTrackedQuests()
    
    -- Re-apply quest levels after a brief delay to ensure WatchFrame is updated
    if self.db.showQuestLevels then
        self:ScheduleTimer(function() 
            self:ShowQuestLevels() 
        end, 0.1)
    end
end

function Module:OnQuestLogUpdate()
    self:Debug("Quest log updated")
    self:UpdateTrackedQuests()
end

function Module:OnUIInfoMessage(event, messageType, message)
    -- Handle quest completion messages and other UI info
    if self.db.progressNotifications then
        self:Debug("UI Info message: " .. tostring(message))
    end
end

function Module:OnQuestAbandoned()
    self:Debug("Quest abandoned, updating tracker")
    self:UpdateTrackedQuests()
end

-------------------------------------------------
-- Configuration Options
-------------------------------------------------
function Module:BuildOptions()
    local get = function(info)
        local key = info[#info]
        return self.db[key]
    end
    local set = function(info, val)
        local key = info[#info]
        self.db[key] = val
        self:Debug("Setting " .. key .. " to " .. tostring(val))
        
        if key == "enabled" then
            if val then 
                self:Enable() 
            else 
                self:Disable() 
            end
        elseif key == "trackerScale" or key == "trackerAlpha" or key == "lockPosition" then
            -- Apply visual changes immediately
            self:ApplyVisualEnhancements()
        elseif key == "showQuestLevels" then
            -- Apply quest levels immediately
            if self:IsEnabled() then
                if val then
                    self:ShowQuestLevels()
                else
                    self:RemoveQuestLevels()
                end
            end
        elseif key == "enhancedDisplay" or key == "showProgressPercent" or key == "colorCodeByDifficulty" then
            -- Update quest display immediately
            if self:IsEnabled() then
                self:UpdateTrackedQuests()
                self:EnhanceQuestDisplay()
            end
        else
            -- Apply other reactive settings
            if self:IsEnabled() then
                HookQuestTracker(self)
            end
        end
    end

    return {
        type = "group",
        name = L["Quest Tracker"] or "Quest Tracker",
        args = {
            headerMain = { type="header", name = L["Quest Tracker"] or "Quest Tracker", order=0 },
            enabled = {
                type = "toggle", order = 1,
                name = L["Enable Module"] or "Enable Module",
                desc = (L["Enable or disable the Quest Tracker module."] or "Enable or disable the Quest Tracker module.") .. "\n" .. (L["Requires /reload to fully apply enabling or disabling."] or "Requires /reload to fully apply enabling or disabling."),
                get=get, set=function(info,val) set(info,val); if YATP and YATP.ShowReloadPrompt then YATP:ShowReloadPrompt() end end,
            },
            
            displayGroup = {
                type = "group", inline = true, order = 10,
                name = L["Display Options"] or "Display Options",
                args = {
                    enhancedDisplay = {
                        type = "toggle", order = 1,
                        name = L["Enhanced Display"] or "Enhanced Display",
                        desc = L["Enable enhanced quest tracker display features."] or "Enable enhanced quest tracker display features.",
                        get=get, set=set,
                    },
                    showQuestLevels = {
                        type = "toggle", order = 2,
                        name = L["Show Quest Levels"] or "Show Quest Levels",
                        desc = L["Display quest levels in the tracker."] or "Display quest levels in the tracker.",
                        get=get, set=set,
                        disabled = function() return not self.db.enhancedDisplay end,
                    },
                    showProgressPercent = {
                        type = "toggle", order = 3,
                        name = L["Show Progress Percentage"] or "Show Progress Percentage",
                        desc = L["Display completion percentages for quest objectives."] or "Display completion percentages for quest objectives.",
                        get=get, set=set,
                        disabled = function() return not self.db.enhancedDisplay end,
                    },
                    compactMode = {
                        type = "toggle", order = 4,
                        name = L["Compact Mode"] or "Compact Mode",
                        desc = L["Use a more compact display for quest information."] or "Use a more compact display for quest information.",
                        get=get, set=set,
                        disabled = function() return not self.db.enhancedDisplay end,
                    },
                    colorCodeByDifficulty = {
                        type = "toggle", order = 5,
                        name = L["Color Code by Difficulty"] or "Color Code by Difficulty",
                        desc = L["Color quest titles based on difficulty level."] or "Color quest titles based on difficulty level.",
                        get=get, set=set,
                        disabled = function() return not self.db.enhancedDisplay end,
                    },
                }
            },
            
            visualGroup = {
                type = "group", inline = true, order = 20,
                name = L["Visual Settings"] or "Visual Settings",
                args = {
                    trackerScale = {
                        type = "range", order = 1,
                        name = L["Tracker Scale"] or "Tracker Scale",
                        desc = L["Adjust the size of the quest tracker."] or "Adjust the size of the quest tracker.",
                        min = 0.5, max = 2.0, step = 0.05,
                        get=get, set=set,
                    },
                    trackerAlpha = {
                        type = "range", order = 2,
                        name = L["Tracker Transparency"] or "Tracker Transparency",
                        desc = L["Adjust the transparency of the quest tracker."] or "Adjust the transparency of the quest tracker.",
                        min = 0.1, max = 1.0, step = 0.05,
                        get=get, set=set,
                    },
                    lockPosition = {
                        type = "toggle", order = 3,
                        name = L["Lock Position"] or "Lock Position",
                        desc = L["Prevent the quest tracker from being moved."] or "Prevent the quest tracker from being moved.",
                        get=get, set=set,
                    },
                }
            },
            
            notificationGroup = {
                type = "group", inline = true, order = 30,
                name = L["Notifications"] or "Notifications",
                args = {
                    progressNotifications = {
                        type = "toggle", order = 1,
                        name = L["Progress Notifications"] or "Progress Notifications",
                        desc = L["Show notifications for quest progress updates."] or "Show notifications for quest progress updates.",
                        get=get, set=set,
                    },
                    completionSound = {
                        type = "toggle", order = 2,
                        name = L["Completion Sound"] or "Completion Sound",
                        desc = L["Play a sound when quests are completed."] or "Play a sound when quests are completed.",
                        get=get, set=set,
                        disabled = function() return not self.db.progressNotifications end,
                    },
                    objectiveCompleteAlert = {
                        type = "toggle", order = 3,
                        name = L["Objective Complete Alert"] or "Objective Complete Alert",
                        desc = L["Show alerts when individual objectives are completed."] or "Show alerts when individual objectives are completed.",
                        get=get, set=set,
                        disabled = function() return not self.db.progressNotifications end,
                    },
                }
            },
            
            autoGroup = {
                type = "group", inline = true, order = 40,
                name = L["Auto-tracking"] or "Auto-tracking",
                args = {
                    autoTrackNew = {
                        type = "toggle", order = 1,
                        name = L["Auto-track New Quests"] or "Auto-track New Quests",
                        desc = L["Automatically track newly accepted quests."] or "Automatically track newly accepted quests.",
                        get=get, set=set,
                    },
                    autoUntrackComplete = {
                        type = "toggle", order = 2,
                        name = L["Auto-untrack Complete"] or "Auto-untrack Complete",
                        desc = L["Automatically untrack completed quests."] or "Automatically untrack completed quests.",
                        get=get, set=set,
                    },
                    maxTrackedQuests = {
                        type = "range", order = 3,
                        name = L["Max Tracked Quests"] or "Max Tracked Quests",
                        desc = L["Maximum number of quests to track simultaneously."] or "Maximum number of quests to track simultaneously.",
                        min = 5, max = 50, step = 1,
                        get=get, set=set,
                    },
                }
            },
            
            help = { 
                type="description", order=90, fontSize="small", 
                name = L["This module enhances the quest tracker with additional features and customization options."] or "This module enhances the quest tracker with additional features and customization options."
            },
        },
    }
end

-------------------------------------------------
-- Open configuration
-------------------------------------------------
function Module:OpenConfig()
    if YATP.OpenConfig then
        YATP:OpenConfig("QuestTracker")
    end
end

-------------------------------------------------
-- Test function for debugging
-------------------------------------------------
function Module:TestFunction()
    self:Debug("=== Quest Tracker Test Function ===")
    self:Debug("Module enabled: " .. tostring(self:IsEnabled()))
    self:Debug("WatchFrame exists: " .. tostring(WatchFrame ~= nil))
    if WatchFrame then
        self:Debug("WatchFrame name: " .. (WatchFrame:GetName() or "unnamed"))
        self:Debug("WatchFrame visible: " .. tostring(WatchFrame:IsVisible()))
        self:Debug("Current scale: " .. tostring(WatchFrame:GetScale()))
        self:Debug("Current alpha: " .. tostring(WatchFrame:GetAlpha()))
    end
    self:Debug("Config scale: " .. tostring(self.db.trackerScale))
    self:Debug("Config alpha: " .. tostring(self.db.trackerAlpha))
    self:Debug("Enhanced display: " .. tostring(self.db.enhancedDisplay))
    self:Debug("Show quest levels: " .. tostring(self.db.showQuestLevels))
    
    -- Test quest tracking
    local numWatched = GetNumQuestWatches()
    self:Debug("Number of watched quests: " .. numWatched)
    
    for i = 1, numWatched do
        local questIndex = GetQuestIndexForWatch(i)
        if questIndex then
            local title, level = GetQuestLogTitle(questIndex)
            self:Debug("Quest " .. i .. ": [" .. (level or "?") .. "] " .. (title or "Unknown"))
            
            local watchLine = _G["WatchFrameLine" .. i]
            if watchLine and watchLine.text then
                self:Debug("  WatchLine text: " .. (watchLine.text:GetText() or "nil"))
            else
                self:Debug("  WatchLine not found: WatchFrameLine" .. i)
            end
        end
    end
    
    -- Apply settings manually
    self:ApplyVisualEnhancements()
    if self.db.showQuestLevels then
        self:ShowQuestLevels()
    end
    self:Debug("=== Test Complete ===")
end

-- Register test command
SLASH_YATPQTTEST1 = "/qttest"
SlashCmdList["YATPQTTEST"] = function()
    if YATP.modules.QuestTracker then
        YATP.modules.QuestTracker:TestFunction()
    else
        print("Quest Tracker module not found")
    end
end

return Module