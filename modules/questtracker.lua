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
    enhancedDisplay = true,        -- Always enabled, not shown in UI
    showQuestLevels = true,
    showProgressPercent = false,   -- Removed from UI, disabled by default
    compactMode = false,           -- Removed from UI, disabled by default
    
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
    
    -- Text appearance
    textOutline = false,
    outlineThickness = 1, -- 1 = normal, 2 = thick
    
    -- Frame dimensions
    customWidth = false,
    frameWidth = 300,
}

-------------------------------------------------
-- Local variables
-------------------------------------------------
local questTrackerFrame
local originalUpdateFunction
local trackedQuests = {}
local nearbyObjectives = {}
local maintenanceTimer
local savedWatchFrameContent = {}
local savedFrameProperties = {}

-------------------------------------------------
-- Version migrations
-------------------------------------------------
local function RunMigrations(self)
    -- Ensure new settings have default values for existing configurations
    if self.db.textOutline == nil then
        self.db.textOutline = false
    end
    if self.db.outlineThickness == nil then
        self.db.outlineThickness = 1
    end
    if self.db.customWidth == nil then
        self.db.customWidth = false
    end
    if self.db.frameWidth == nil then
        self.db.frameWidth = 300
    end
    
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
        
        -- Hook the update function if we haven't already to maintain our modifications
        if not originalUpdateFunction then
            -- Try to hook WatchFrame_Update if it exists
            if WatchFrame_Update then
                originalUpdateFunction = WatchFrame_Update
                WatchFrame_Update = function(...)
                    -- Save our current modifications before the update
                    if self.db.showQuestLevels or self.db.textOutline or self.db.customWidth or self.db.colorCodeByDifficulty then
                        self:SaveWatchFrameContent()
                    end
                    
                    -- Call the original update function
                    originalUpdateFunction(...)
                    
                    -- Try to restore immediately without delay to prevent flash
                    local restored = false
                    if self.db.showQuestLevels or self.db.textOutline or self.db.customWidth or self.db.colorCodeByDifficulty then
                        restored = self:RestoreWatchFrameContent()
                    end
                    
                    if not restored then
                        -- If restoration failed, apply fresh (this will be instant since frame just updated)
                        if self.db.showQuestLevels then
                            self:ShowQuestLevels()
                        end
                        if self.db.textOutline then
                            self:ApplyTextOutline()
                        end
                        if self.db.customWidth then
                            self:ApplyCustomWidth()
                        end
                        if self.db.colorCodeByDifficulty then
                            self:ApplyDifficultyColors()
                        end
                    end
                end
                self:Debug("Hooked WatchFrame_Update function with flash prevention")
            else
                self:Debug("WatchFrame_Update function not found")
            end
        end
    else
        self:Debug("WatchFrame not found")
    end
end

-- Save current WatchFrame content and properties
function Module:SaveWatchFrameContent()
    wipe(savedWatchFrameContent)
    wipe(savedFrameProperties)
    
    -- Save frame properties
    if WatchFrame then
        savedFrameProperties.width = WatchFrame:GetWidth()
        savedFrameProperties.scale = WatchFrame:GetScale()
        savedFrameProperties.alpha = WatchFrame:GetAlpha()
    end
    
    -- Save text content and font properties
    for lineNum = 1, 50 do
        local watchLine = _G["WatchFrameLine" .. lineNum]
        if watchLine and watchLine.text and watchLine:IsVisible() then
            local text = watchLine.text:GetText()
            if text and text ~= "" then
                local font, size, flags = watchLine.text:GetFont()
                savedWatchFrameContent[lineNum] = {
                    text = text,
                    font = font,
                    size = size,
                    flags = flags,
                    width = watchLine.text:GetWidth(),
                    hasLevel = string.find(text, "^%[%d+%] ") ~= nil,
                    hasColor = string.find(text, "|c%x%x%x%x%x%x%x%x") ~= nil,
                }
            end
        end
    end
    
    self:Debug("Saved " .. #savedWatchFrameContent .. " WatchFrame lines and properties")
end

-- Restore WatchFrame content and properties seamlessly
function Module:RestoreWatchFrameContent()
    if not savedWatchFrameContent or next(savedWatchFrameContent) == nil then
        return false
    end
    
    -- Restore frame properties
    if savedFrameProperties and WatchFrame then
        if savedFrameProperties.width then
            WatchFrame:SetWidth(savedFrameProperties.width)
        end
        if savedFrameProperties.scale then
            WatchFrame:SetScale(savedFrameProperties.scale)
        end
        if savedFrameProperties.alpha then
            WatchFrame:SetAlpha(savedFrameProperties.alpha)
        end
    end
    
    -- Restore text content and properties
    for lineNum, savedData in pairs(savedWatchFrameContent) do
        local watchLine = _G["WatchFrameLine" .. lineNum]
        if watchLine and watchLine.text and watchLine:IsVisible() then
            local currentText = watchLine.text:GetText()
            -- Only restore if the content differs and our modification exists in saved version
            if currentText ~= savedData.text and (savedData.hasLevel or savedData.hasColor) then
                watchLine.text:SetText(savedData.text)
            end
            
            -- Restore font properties if they were modified
            if savedData.font and savedData.size and savedData.flags then
                local currentFont, currentSize, currentFlags = watchLine.text:GetFont()
                if currentFlags ~= savedData.flags then
                    watchLine.text:SetFont(savedData.font, savedData.size, savedData.flags)
                end
            end
            
            -- Restore text width if it was modified
            if savedData.width and watchLine.text:GetWidth() ~= savedData.width then
                watchLine.text:SetWidth(savedData.width)
            end
        end
    end
    
    self:Debug("Restored WatchFrame content and properties")
    return true
end

-- Apply text outline to WatchFrame text
function Module:ApplyTextOutline()
    if not questTrackerFrame then 
        questTrackerFrame = WatchFrame
    end
    
    if not questTrackerFrame then 
        self:Debug("Cannot apply text outline: WatchFrame not found")
        return 
    end
    
    -- Ensure outlineThickness has a default value
    if not self.db.outlineThickness then
        self.db.outlineThickness = 1
    end
    
    self:Debug("Applying text outline - Enabled: " .. tostring(self.db.textOutline) .. ", Thickness: " .. tostring(self.db.outlineThickness))
    
    -- Apply outline to all visible WatchFrame lines
    for lineNum = 1, 50 do
        local watchLine = _G["WatchFrameLine" .. lineNum]
        if watchLine and watchLine.text then
            if self.db.textOutline then
                -- Apply outline based on thickness setting
                if self.db.outlineThickness == 2 then
                    watchLine.text:SetFont(watchLine.text:GetFont(), select(2, watchLine.text:GetFont()), "THICKOUTLINE")
                else
                    watchLine.text:SetFont(watchLine.text:GetFont(), select(2, watchLine.text:GetFont()), "OUTLINE")
                end
                self:Debug("Applied outline to WatchFrameLine" .. lineNum)
            else
                -- Remove outline
                watchLine.text:SetFont(watchLine.text:GetFont(), select(2, watchLine.text:GetFont()), "")
                self:Debug("Removed outline from WatchFrameLine" .. lineNum)
            end
        end
    end
end

-- Apply custom width to WatchFrame
function Module:ApplyCustomWidth()
    if not questTrackerFrame then 
        questTrackerFrame = WatchFrame
    end
    
    if not questTrackerFrame then 
        self:Debug("Cannot apply custom width: WatchFrame not found")
        return 
    end
    
    -- Ensure frameWidth has a default value
    if not self.db.frameWidth then
        self.db.frameWidth = 300
    end
    
    if self.db.customWidth then
        local newWidth = self.db.frameWidth
        self:Debug("Applying custom width: " .. tostring(newWidth))
        
        questTrackerFrame:SetWidth(newWidth)
        
        -- Also adjust the text regions to fit the new width
        for lineNum = 1, 50 do
            local watchLine = _G["WatchFrameLine" .. lineNum]
            if watchLine and watchLine.text then
                -- Set text width to be slightly less than frame width to prevent overflow
                watchLine.text:SetWidth(newWidth - 20)
                self:Debug("Adjusted text width for WatchFrameLine" .. lineNum)
            end
        end
    else
        self:Debug("Restoring default WatchFrame width")
        -- Restore default width (WatchFrame default is usually around 204)
        questTrackerFrame:SetWidth(204)
        
        -- Restore default text widths
        for lineNum = 1, 50 do
            local watchLine = _G["WatchFrameLine" .. lineNum]
            if watchLine and watchLine.text then
                watchLine.text:SetWidth(184) -- Default WatchFrame text width
            end
        end
    end
end

-- Enhanced quest display with flash prevention
function Module:EnhanceQuestDisplay()
    -- Enhanced display is always enabled now
    if not self.db.enabled then return end
    
    self:Debug("Enhancing quest display")
    
    -- Update tracked quests table
    self:UpdateTrackedQuests()
    
    -- Apply quest level display
    if self.db.showQuestLevels then
        self:ShowQuestLevels()
    else
        self:RemoveQuestLevels()
    end
    
    -- Apply color coding
    if self.db.colorCodeByDifficulty then
        self:ApplyDifficultyColors()
    else
        self:RemoveDifficultyColors()
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
    
    -- Search through all WatchFrame lines to find ones with level prefixes
    for lineNum = 1, 50 do -- Check up to 50 lines
        local watchLine = _G["WatchFrameLine" .. lineNum]
        if watchLine and watchLine.text then
            local currentText = watchLine.text:GetText()
            if currentText and string.find(currentText, "^%[%d+%] ") then
                -- This line has a level prefix, check if it's a quest title (not an objective)
                -- Quest titles typically don't have progress counters
                if not string.find(currentText, "%d+/%d+") then
                    -- Remove the level prefix
                    local newText = string.gsub(currentText, "^%[%d+%] ", "")
                    watchLine.text:SetText(newText)
                    self:Debug("Removed level from quest title: " .. newText)
                end
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
                -- Find the quest title line in WatchFrame (quest titles don't start with bullet points or dashes)
                -- We need to search through WatchFrame lines to find the one that matches this quest title
                for lineNum = 1, 50 do -- Check up to 50 lines
                    local watchLine = _G["WatchFrameLine" .. lineNum]
                    if watchLine and watchLine.text then
                        local currentText = watchLine.text:GetText()
                        if currentText then
                            -- Check if this line contains the quest title and is not an objective
                            -- Quest titles usually don't start with bullet points, dashes, or have progress counters
                            if string.find(currentText, title, 1, true) and 
                               not string.find(currentText, "^[•%-]") and  -- Not starting with bullet or dash
                               not string.find(currentText, "%d+/%d+") and  -- Not containing progress counters like "0/4"
                               not string.find(currentText, "^%[%d+%] ") then -- Not already having level prefix
                                
                                local levelPrefix = "[" .. level .. "] "
                                watchLine.text:SetText(levelPrefix .. currentText)
                                self:Debug("Added level [" .. level .. "] to quest title: " .. title)
                                break -- Found and modified this quest, move to next
                            end
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
    if not self.db.colorCodeByDifficulty or not questTrackerFrame then return end
    
    self:Debug("Applying difficulty colors to quest titles")
    
    local numWatched = GetNumQuestWatches()
    local playerLevel = UnitLevel("player")
    
    for i = 1, numWatched do
        local questIndex = GetQuestIndexForWatch(i)
        if questIndex then
            local title, level, questTag, suggestedGroup, isHeader, isCollapsed, isComplete, isDaily, questID = GetQuestLogTitle(questIndex)
            
            if title and level and not isHeader then
                -- Calculate difficulty color based on level difference
                local levelDiff = level - playerLevel
                local color
                
                if levelDiff >= 5 then
                    color = "|cffff0000" -- Red (very hard)
                elseif levelDiff >= 3 then
                    color = "|cffff8000" -- Orange (hard)
                elseif levelDiff >= -2 then
                    color = "|cffffff00" -- Yellow (normal)
                elseif levelDiff >= -7 then
                    color = "|cff00ff00" -- Green (easy)
                else
                    color = "|cff808080" -- Gray (trivial)
                end
                
                -- Find the quest title line in WatchFrame and apply color
                for lineNum = 1, 50 do
                    local watchLine = _G["WatchFrameLine" .. lineNum]
                    if watchLine and watchLine.text then
                        local currentText = watchLine.text:GetText()
                        if currentText then
                            -- Check if this line contains the quest title and is not an objective
                            if string.find(currentText, title, 1, true) and 
                               not string.find(currentText, "^[•%-]") and
                               not string.find(currentText, "%d+/%d+") then
                                
                                -- Remove existing color codes and apply new color
                                local cleanText = string.gsub(currentText, "|c%x%x%x%x%x%x%x%x", "")
                                cleanText = string.gsub(cleanText, "|r", "")
                                
                                -- Apply new color
                                local coloredText = color .. cleanText .. "|r"
                                watchLine.text:SetText(coloredText)
                                self:Debug("Applied " .. color .. " color to quest: " .. title .. " (level " .. level .. " vs player " .. playerLevel .. ")")
                                break
                            end
                        end
                    end
                end
            end
        end
    end
end

-- Remove difficulty colors from quest titles
function Module:RemoveDifficultyColors()
    if not questTrackerFrame then return end
    
    self:Debug("Removing difficulty colors from quest titles")
    
    for lineNum = 1, 50 do
        local watchLine = _G["WatchFrameLine" .. lineNum]
        if watchLine and watchLine.text then
            local currentText = watchLine.text:GetText()
            if currentText and (string.find(currentText, "|c%x%x%x%x%x%x%x%x") or string.find(currentText, "|r")) then
                -- Remove color codes
                local cleanText = string.gsub(currentText, "|c%x%x%x%x%x%x%x%x", "")
                cleanText = string.gsub(cleanText, "|r", "")
                watchLine.text:SetText(cleanText)
                self:Debug("Removed color from: " .. cleanText)
            end
        end
    end
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
    
    -- Apply custom width
    self:ApplyCustomWidth()
    
    -- Apply text outline
    self:ApplyTextOutline()
    
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
    self:RegisterEvent("ZONE_CHANGED", "OnZoneChanged")
    self:RegisterEvent("ZONE_CHANGED_NEW_AREA", "OnZoneChanged")
    
    self:Debug("Quest Tracker module enabled")
    
    -- Start maintenance timer to periodically check and re-apply enhancements
    if not maintenanceTimer then
        maintenanceTimer = self:ScheduleRepeatingTimer("MaintenanceCheck", 5) -- Check every 5 seconds (less aggressive)
        self:Debug("Started maintenance timer")
    end
    
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
    
    -- Cancel maintenance timer
    if maintenanceTimer then
        self:CancelTimer(maintenanceTimer)
        maintenanceTimer = nil
        self:Debug("Cancelled maintenance timer")
    end
    
    -- Restore original quest tracker functionality
    if questTrackerFrame and originalUpdateFunction then
        if WatchFrame_Update then
            WatchFrame_Update = originalUpdateFunction
        end
    end
    
    -- Clean up any existing modifications
    self:RemoveQuestLevels()
    
    -- Clear saved content
    wipe(savedWatchFrameContent)
    wipe(savedFrameProperties)
    
    self:Debug("Quest Tracker module disabled")
end

-- Maintenance function to check and re-apply enhancements periodically
function Module:MaintenanceCheck()
    -- Enhanced display is always enabled now
    if not self.db.enabled then return end
    
    local needsReapply = false
    
    -- Check if quest levels are missing and re-apply if needed
    if self.db.showQuestLevels then
        local numWatched = GetNumQuestWatches()
        
        for i = 1, numWatched do
            local questIndex = GetQuestIndexForWatch(i)
            if questIndex then
                local title, level = GetQuestLogTitle(questIndex)
                if title and level then
                    -- Check if any WatchFrame line has this quest title without level prefix
                    for lineNum = 1, 50 do
                        local watchLine = _G["WatchFrameLine" .. lineNum]
                        if watchLine and watchLine.text then
                            local currentText = watchLine.text:GetText()
                            if currentText and 
                               string.find(currentText, title, 1, true) and 
                               not string.find(currentText, "^[•%-]") and
                               not string.find(currentText, "%d+/%d+") and
                               not string.find(currentText, "^%[%d+%] ") then
                                needsReapply = true
                                break
                            end
                        end
                    end
                    if needsReapply then break end
                end
            end
        end
    end
    
    -- Check if text outline is missing
    if self.db.textOutline and not needsReapply then
        local watchLine = _G["WatchFrameLine1"]
        if watchLine and watchLine.text then
            local font, size, flags = watchLine.text:GetFont()
            local expectedFlags = self.db.outlineThickness == 2 and "THICKOUTLINE" or "OUTLINE"
            if flags ~= expectedFlags then
                needsReapply = true
                self:Debug("Maintenance: Text outline missing")
            end
        end
    end
    
    -- Check if custom width is missing
    if self.db.customWidth and not needsReapply then
        if WatchFrame and WatchFrame:GetWidth() ~= self.db.frameWidth then
            needsReapply = true
            self:Debug("Maintenance: Custom width missing")
        end
    end
    
    if needsReapply then
        self:Debug("Maintenance: Re-applying quest tracker enhancements")
        self:ReapplyAllEnhancements()
    end
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
    
    -- Re-apply quest enhancements immediately to prevent flash
    self:ReapplyAllEnhancements()
end

function Module:OnQuestLogUpdate()
    self:Debug("Quest log updated")
    self:UpdateTrackedQuests()
    
    -- Re-apply enhancements immediately
    self:ReapplyAllEnhancements()
end

function Module:OnZoneChanged()
    self:Debug("Zone changed, re-applying quest tracker enhancements")
    
    -- Re-apply enhancements after zone change with slight delay for loading
    self:ScheduleTimer(function() 
        self:ReapplyAllEnhancements()
    end, 0.3)
end

-- New function to re-apply all active enhancements
function Module:ReapplyAllEnhancements()
    -- Enhanced display is always enabled now
    if not self.db.enabled then return end
    
    self:Debug("Re-applying all quest tracker enhancements")
    
    if self.db.showQuestLevels then
        self:ShowQuestLevels()
    end
    
    if self.db.colorCodeByDifficulty then
        self:ApplyDifficultyColors()
    end
    
    -- Apply visual enhancements including new features
    if self.db.textOutline then
        self:ApplyTextOutline()
    end
    
    if self.db.customWidth then
        self:ApplyCustomWidth()
    end
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
        elseif key == "textOutline" or key == "outlineThickness" then
            -- Apply text outline immediately
            if self:IsEnabled() then
                self:ApplyTextOutline()
            end
        elseif key == "customWidth" or key == "frameWidth" then
            -- Apply width changes immediately
            if self:IsEnabled() then
                self:ApplyCustomWidth()
            end
        elseif key == "showQuestLevels" then
            -- Apply quest levels immediately
            if self:IsEnabled() then
                if val then
                    self:ShowQuestLevels()
                else
                    self:RemoveQuestLevels()
                end
            end
        elseif key == "colorCodeByDifficulty" then
            -- Apply difficulty colors immediately
            if self:IsEnabled() then
                if val then
                    self:ApplyDifficultyColors()
                else
                    self:RemoveDifficultyColors()
                end
            end
            -- Update quest display immediately
            if self:IsEnabled() then
                self:UpdateTrackedQuests()
                self:EnhanceQuestDisplay()
            end
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
                    showQuestLevels = {
                        type = "toggle", order = 1,
                        name = L["Show Quest Levels"] or "Show Quest Levels",
                        desc = L["Display quest levels in the tracker."] or "Display quest levels in the tracker.",
                        get=get, set=set,
                    },
                    colorCodeByDifficulty = {
                        type = "toggle", order = 2,
                        name = L["Color Code by Difficulty"] or "Color Code by Difficulty",
                        desc = L["Color quest titles based on difficulty level."] or "Color quest titles based on difficulty level.",
                        get=get, set=set,
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
                    textOutline = {
                        type = "toggle", order = 4,
                        name = L["Text Outline"] or "Text Outline",
                        desc = L["Add outline to quest tracker text for better readability."] or "Add outline to quest tracker text for better readability.",
                        get=get, set=set,
                    },
                    outlineThickness = {
                        type = "select", order = 5,
                        name = L["Outline Thickness"] or "Outline Thickness",
                        desc = L["Choose the thickness of the text outline."] or "Choose the thickness of the text outline.",
                        values = {
                            [1] = L["Normal"] or "Normal",
                            [2] = L["Thick"] or "Thick",
                        },
                        get=get, set=set,
                        disabled = function() return not self.db.textOutline end,
                    },
                    customWidth = {
                        type = "toggle", order = 6,
                        name = L["Custom Width"] or "Custom Width",
                        desc = L["Enable custom width for the quest tracker frame."] or "Enable custom width for the quest tracker frame.",
                        get=get, set=set,
                    },
                    frameWidth = {
                        type = "range", order = 7,
                        name = L["Frame Width"] or "Frame Width",
                        desc = L["Set the width of the quest tracker frame in pixels."] or "Set the width of the quest tracker frame in pixels.",
                        min = 200, max = 500, step = 10,
                        get=get, set=set,
                        disabled = function() return not self.db.customWidth end,
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
    self:Debug("Text outline: " .. tostring(self.db.textOutline))
    self:Debug("Outline thickness: " .. tostring(self.db.outlineThickness or "nil"))
    self:Debug("Custom width: " .. tostring(self.db.customWidth))
    self:Debug("Frame width: " .. tostring(self.db.frameWidth or "nil"))
    
    -- Test quest tracking
    local numWatched = GetNumQuestWatches()
    self:Debug("Number of watched quests: " .. numWatched)
    
    for i = 1, numWatched do
        local questIndex = GetQuestIndexForWatch(i)
        if questIndex then
            local title, level = GetQuestLogTitle(questIndex)
            self:Debug("Quest " .. i .. ": [" .. (level or "?") .. "] " .. (title or "Unknown"))
        end
    end
    
    -- Show WatchFrame line structure
    self:Debug("--- WatchFrame Lines Analysis ---")
    for lineNum = 1, 20 do -- Check first 20 lines
        local watchLine = _G["WatchFrameLine" .. lineNum]
        if watchLine and watchLine.text then
            local text = watchLine.text:GetText()
            if text and text ~= "" then
                local hasProgress = string.find(text, "%d+/%d+") and "HAS_PROGRESS" or "NO_PROGRESS"
                local hasLevel = string.find(text, "^%[%d+%] ") and "HAS_LEVEL" or "NO_LEVEL"
                local startsWithBullet = string.find(text, "^[•%-]") and "BULLET/DASH" or "NO_BULLET"
                self:Debug("Line " .. lineNum .. ": " .. hasProgress .. " | " .. hasLevel .. " | " .. startsWithBullet .. " | " .. text)
            end
        end
    end
    self:Debug("--- End Lines Analysis ---")
    
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

-- Register clean command to remove all levels manually
SLASH_YATPQTCLEAN1 = "/qtclean"
SlashCmdList["YATPQTCLEAN"] = function()
    if YATP.modules.QuestTracker then
        YATP.modules.QuestTracker:RemoveQuestLevels()
        print("Removed all quest levels from tracker")
    else
        print("Quest Tracker module not found")
    end
end

return Module