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
-- Debug helper - Disabled for production
-------------------------------------------------
function Module:Debug(msg)
    -- Debug disabled for cleaner output
    -- if YATP.db and YATP.db.profile and YATP.db.profile.debugMode then
    --     print("|cff00ff00[YATP - QuestTracker]|r " .. tostring(msg))
    -- end
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
    indentObjectives = true, -- Remove dashes and add indentation to objectives
    
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
local isApplyingLevels = false -- Prevent multiple simultaneous level applications
local lastProcessedQuests = {} -- Cache of quest titles to their line numbers

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
    if self.db.indentObjectives == nil then
        self.db.indentObjectives = true
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
        -- Apply visual enhancements immediately
        self:ApplyVisualEnhancements()
        
        -- Hook the update function if we haven't already to maintain our modifications
        if not originalUpdateFunction then
            -- Try to hook WatchFrame_Update if it exists
            if WatchFrame_Update then
                originalUpdateFunction = WatchFrame_Update
                WatchFrame_Update = function(...)
                    -- Call the original update function first
                    -- This will reset the WatchFrame to its clean state
                    originalUpdateFunction(...)
                    
                    -- IMPORTANT: After WatchFrame_Update, the frame is CLEAN (no modifications)
                    -- We can now safely apply our enhancements without worrying about duplicates
                    
                    -- Apply text enhancements (levels and colors) immediately on clean frame
                    if self.db.showQuestLevels or self.db.colorCodeByDifficulty then
                        self:ApplyAllTextEnhancements()
                    end
                    
                    -- Format quest objectives (indent and remove dashes)
                    if self.db.indentObjectives then
                        self:FormatQuestObjectives()
                    end
                    
                    -- Apply visual enhancements (these are independent)
                    if self.db.textOutline then
                        self:ApplyTextOutline()
                    end
                    if self.db.customWidth then
                        self:ApplyCustomWidth()
                    end
                end
            end
        end
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
    
    -- Update tracked quests table
    self:UpdateTrackedQuests()
    
    -- Apply text enhancements (levels and colors) in one pass
    if self.db.showQuestLevels or self.db.colorCodeByDifficulty then
        self:ApplyAllTextEnhancements()
    else
        self:RemoveQuestLevels()
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
    
    -- Clear the cache of processed quests
    wipe(lastProcessedQuests)
    
    -- Search through all WatchFrame lines to find ones with modifications
    for lineNum = 1, 50 do
        local watchLine = _G["WatchFrameLine" .. lineNum]
        if watchLine and watchLine.text then
            local currentText = watchLine.text:GetText()
            if currentText then
                local newText = currentText
                local modified = false
                
                -- Remove difficulty symbols (!! ! ~) at the start
                newText = string.gsub(newText, "^!! ", "")
                newText = string.gsub(newText, "^! ", "")
                newText = string.gsub(newText, "^~ ", "")
                
                -- Remove difficulty symbols after color codes
                newText = string.gsub(newText, "(|c%x%x%x%x%x%x%x%x)!! ", "%1")
                newText = string.gsub(newText, "(|c%x%x%x%x%x%x%x%x)! ", "%1")
                newText = string.gsub(newText, "(|c%x%x%x%x%x%x%x%x)~ ", "%1")
                
                -- Remove ALL level prefixes (including multiple consecutive ones)
                local maxIterations = 10 -- Prevent infinite loops
                local iterations = 0
                while string.find(newText, "%[%d+%]") and iterations < maxIterations do
                    local beforeRemove = newText
                    -- Remove level prefix at the start
                    newText = string.gsub(newText, "^%[%d+%]%s*", "")
                    -- Remove level prefix after color codes
                    newText = string.gsub(newText, "(|c%x%x%x%x%x%x%x%x)%s*%[%d+%]%s*", "%1")
                    
                    -- If nothing changed, break to avoid infinite loop
                    if beforeRemove == newText then
                        break
                    end
                    modified = true
                    iterations = iterations + 1
                end
                
                if newText ~= currentText then
                    watchLine.text:SetText(newText)
                end
            end
        end
    end
end

-- Clean up any duplicate level prefixes
function Module:CleanupDuplicateLevels()
    if not questTrackerFrame then return end
    
    for lineNum = 1, 50 do
        local watchLine = _G["WatchFrameLine" .. lineNum]
        if watchLine and watchLine.text then
            local currentText = watchLine.text:GetText()
            if currentText then
                -- Check for multiple level prefixes like "[11] [11] Quest Title"
                local cleanedText = currentText
                local changesMade = false
                
                -- Remove multiple consecutive level prefixes (more aggressive pattern)
                while string.find(cleanedText, "%[%d+%]%s*%[%d+%]") do
                    cleanedText = string.gsub(cleanedText, "(%[%d+%]%s*)%[%d+%]%s*", "%1")
                    changesMade = true
                end
                
                -- Also remove any extra level prefixes at the beginning
                local levelCount = 0
                for level in string.gmatch(cleanedText, "^%[%d+%]") do
                    levelCount = levelCount + 1
                end
                
                if levelCount > 1 then
                    -- Extract the first level and the rest of the text
                    local firstLevel = string.match(cleanedText, "^%[%d+%]")
                    local restOfText = string.gsub(cleanedText, "^%[%d+%]%s*", "", 1)
                    restOfText = string.gsub(restOfText, "^%[%d+%]%s*", "")
                    cleanedText = firstLevel .. " " .. restOfText
                    changesMade = true
                end
                
                if changesMade then
                    watchLine.text:SetText(cleanedText)
                end
            end
        end
    end
end

-- Helper function to find the exact title line for a quest in WatchFrame
-- Uses WoW 3.3.5 API to map quest watch index to WatchFrame line
local function FindQuestTitleLine(questWatchIndex, questTitle)
    if not questWatchIndex or not questTitle then return nil end
    
    -- In WoW 3.3.5, quest titles in WatchFrame follow a predictable pattern
    -- Each watched quest has its title on a specific line
    -- We can use GetQuestIndexForWatch in reverse to find which line corresponds to this quest
    
    -- Build a map of all visible WatchFrame lines
    local visibleLines = {}
    for lineNum = 1, 50 do
        local watchLine = _G["WatchFrameLine" .. lineNum]
        if watchLine and watchLine.text and watchLine:IsVisible() then
            local text = watchLine.text:GetText()
            if text and text ~= "" then
                -- Clean the text for comparison
                local cleanText = string.gsub(text, "|c%x%x%x%x%x%x%x%x", "")
                cleanText = string.gsub(cleanText, "|r", "")
                cleanText = string.gsub(cleanText, "^%s+", "")
                cleanText = string.gsub(cleanText, "%s+$", "")
                
                -- Remove difficulty symbols for comparison
                cleanText = string.gsub(cleanText, "^!! ", "")
                cleanText = string.gsub(cleanText, "^! ", "")
                cleanText = string.gsub(cleanText, "^~ ", "")
                
                -- CRITICAL: Title must be an EXACT match (not substring)
                -- and must NOT have any objective markers
                local hasProgress = string.find(cleanText, "%d+/%d+")
                local hasDash = string.find(cleanText, "^%-")
                local hasBullet = string.find(cleanText, "^•")
                local hasLevel = string.find(cleanText, "^%[%d+%]")
                local hasColon = string.find(cleanText, ":")
                
                -- If text exactly matches the quest title (case insensitive) and has no markers
                if string.lower(cleanText) == string.lower(questTitle) and 
                   not hasProgress and not hasDash and not hasBullet and not hasLevel and not hasColon then
                    return lineNum, watchLine
                end
            end
        end
    end
    
    return nil
end

-- Apply all text enhancements (levels and colors) in one pass to avoid duplicates
-- Color System Example (player level 40):
--   RED:    Quest level 45+ (5+ above player)
--   ORANGE: Quest level 43-44 (3-4 above player)
--   YELLOW: Quest level 38-42 (-2 to +2 from player)
--   GREEN:  Quest level 30-37 (3-10 below player)
--   GRAY:   Quest level 29- (11+ below player, no XP)
function Module:ApplyAllTextEnhancements()
    if not questTrackerFrame then return end
    
    -- Prevent multiple simultaneous applications
    if isApplyingLevels then 
        return 
    end
    isApplyingLevels = true
    
    -- Clean ALL existing modifications first (levels, symbols, colors)
    -- This ensures we start fresh even if WatchFrame_Update didn't fully clean
    self:RemoveQuestLevels()
    self:RemoveDifficultyColors()
    
    -- Clear the cache since we're starting fresh
    wipe(lastProcessedQuests)
    
    local numWatched = GetNumQuestWatches()
    local playerLevel = UnitLevel("player")
    local processedLines = {}
    
    for i = 1, numWatched do
        local questIndex = GetQuestIndexForWatch(i)
        if questIndex then
            local title, level, questTag, suggestedGroup, isHeader, isCollapsed, isComplete, isDaily, questID = GetQuestLogTitle(questIndex)
            
            if title and level and not isHeader then
                -- Calculate color if needed using WoW standard system
                local color = ""
                local closeColor = ""
                local difficultySymbol = "" -- Symbol for colorblind accessibility
                
                if self.db.colorCodeByDifficulty then
                    local levelDiff = level - playerLevel
                    
                    -- WoW Color System (ejemplo: jugador nivel 40)
                    -- Rojo: misión 45+ (5+ niveles arriba)
                    -- Naranja: misión 43-44 (3-4 niveles arriba)
                    -- Amarillo: misión 38-42 (-2 a +2 niveles)
                    -- Verde: misión 30-37 (-10 a -3 niveles)
                    -- Gris: misión 29 o menos (más de -10 niveles)
                    
                    -- Using more distinct colors for colorblind accessibility
                    if levelDiff >= 5 then
                        color = "|cffff0000" -- Bright Red (5+ niveles arriba)
                        difficultySymbol = "!! " -- Very difficult indicator
                    elseif levelDiff >= 3 then
                        color = "|cffff6600" -- Bright Orange (3-4 niveles arriba)
                        difficultySymbol = "! " -- Difficult indicator
                    elseif levelDiff >= -2 then
                        color = "|cffffff00" -- Bright Yellow (-2 a +2 niveles)
                        difficultySymbol = "" -- Normal, no symbol
                    elseif levelDiff >= -10 then
                        color = "|cff00ff00" -- Bright Green (-10 a -3 niveles)
                        difficultySymbol = "" -- Easy, no symbol needed
                    else
                        color = "|cff999999" -- Light Gray (más de -10 niveles)
                        difficultySymbol = "~ " -- Trivial indicator
                    end
                    closeColor = "|r"
                end
                
                -- Find the EXACT title line for this quest using the helper function
                local lineNum, watchLine = FindQuestTitleLine(i, title)
                
                if lineNum and watchLine and not processedLines[lineNum] then
                    local currentText = watchLine.text:GetText()
                    
                    if currentText then
                        -- Apply level AND color in one operation
                        local finalText = currentText
                        
                        -- Add difficulty symbol first (for colorblind accessibility)
                        if self.db.colorCodeByDifficulty and difficultySymbol ~= "" then
                            finalText = difficultySymbol .. finalText
                        end
                        
                        if self.db.showQuestLevels then
                            finalText = "[" .. level .. "] " .. finalText
                        end
                        
                        if self.db.colorCodeByDifficulty then
                            finalText = color .. finalText .. closeColor
                        end
                        
                        watchLine.text:SetText(finalText)
                        processedLines[lineNum] = true
                        lastProcessedQuests[title] = lineNum -- Remember this quest's line
                    end
                end
            end
        end
    end
    
    -- Format quest objectives (remove dash, add indentation)
    if self.db.indentObjectives then
        self:FormatQuestObjectives()
    end
    
    isApplyingLevels = false
end

-- Format quest objectives by adding indentation
function Module:FormatQuestObjectives()
    if not questTrackerFrame then return end
    
    -- Track which lines are quest titles (so we can indent everything else)
    local titleLines = {}
    
    -- First pass: identify all quest title lines
    for lineNum = 1, 50 do
        local watchLine = _G["WatchFrameLine" .. lineNum]
        if watchLine and watchLine.text and watchLine:IsVisible() then
            local text = watchLine.text:GetText()
            if text and text ~= "" then
                local cleanText = string.gsub(text, "|c%x%x%x%x%x%x%x%x", "")
                cleanText = string.gsub(cleanText, "|r", "")
                cleanText = string.gsub(cleanText, "^%s+", "")
                cleanText = string.gsub(cleanText, "%s+$", "")
                
                -- Remove difficulty symbols and level prefixes for checking
                cleanText = string.gsub(cleanText, "^!! ", "")
                cleanText = string.gsub(cleanText, "^! ", "")
                cleanText = string.gsub(cleanText, "^~ ", "")
                cleanText = string.gsub(cleanText, "^%[%d+%]%s*", "")
                
                -- Check if this matches any tracked quest title
                for i = 1, GetNumQuestWatches() do
                    local questIndex = GetQuestIndexForWatch(i)
                    if questIndex then
                        local title, level, questTag, suggestedGroup, isHeader, isCollapsed, isComplete, isDaily = GetQuestLogTitle(questIndex)
                        if title and string.lower(cleanText) == string.lower(title) then
                            titleLines[lineNum] = true
                            break
                        end
                    end
                end
            end
        end
    end
    
    -- Second pass: indent all non-title lines and remove dashes
    for lineNum = 1, 50 do
        if not titleLines[lineNum] then
            local watchLine = _G["WatchFrameLine" .. lineNum]
            if watchLine and watchLine.text and watchLine:IsVisible() then
                local text = watchLine.text:GetText()
                if text and text ~= "" then
                    local newText = text
                    
                    -- FIRST: Remove any existing indentation to start clean
                    newText = string.gsub(newText, "^%s+", "")
                    
                    -- SECOND: Remove leading dashes and bullets (multiple patterns for safety)
                    newText = string.gsub(newText, "^%-+%s*", "")  -- Remove - at start
                    newText = string.gsub(newText, "^•%s*", "")    -- Remove bullet at start
                    newText = string.gsub(newText, "^–%s*", "")    -- Remove en-dash
                    newText = string.gsub(newText, "^—%s*", "")    -- Remove em-dash
                    
                    -- THIRD: Remove dashes after color codes
                    newText = string.gsub(newText, "(|c%x%x%x%x%x%x%x%x)%s*%-+%s*", "%1")
                    newText = string.gsub(newText, "(|c%x%x%x%x%x%x%x%x)%s*•%s*", "%1")
                    newText = string.gsub(newText, "(|c%x%x%x%x%x%x%x%x)%s*–%s*", "%1")
                    newText = string.gsub(newText, "(|c%x%x%x%x%x%x%x%x)%s*—%s*", "%1")
                    
                    -- Remove dashes in the middle after whitespace (WoW might add them there)
                    newText = string.gsub(newText, "^(%s*)%-+%s*", "%1")
                    
                    -- FINALLY: Add clean indentation
                    newText = "  " .. newText
                    
                    if newText ~= text then
                        watchLine.text:SetText(newText)
                    end
                    
                    -- Hide the dash texture/element if it exists
                    -- In WoW, WatchFrameLines have a .dash element that renders the visual dash
                    -- We hide it to create a cleaner, indented look
                    if watchLine.dash then
                        watchLine.dash:Hide()
                    end
                end
            end
        end
    end
end

-- Show quest levels in tracker (legacy function, now uses unified approach)
function Module:ShowQuestLevels()
    -- Just call the unified function that handles both levels and colors
    self:ApplyAllTextEnhancements()
end

-- Show progress percentages
function Module:ShowProgressPercentages()
    -- Implementation for showing progress percentages
    -- This would calculate and display completion percentages for objectives
end

-- Apply difficulty-based color coding (legacy function, now uses unified approach)
function Module:ApplyDifficultyColors()
    -- Just call the unified function that handles both levels and colors
    self:ApplyAllTextEnhancements()
end

-- Remove difficulty colors from quest titles
function Module:RemoveDifficultyColors()
    if not questTrackerFrame then return end
    
    for lineNum = 1, 50 do
        local watchLine = _G["WatchFrameLine" .. lineNum]
        if watchLine and watchLine.text then
            local currentText = watchLine.text:GetText()
            if currentText and (string.find(currentText, "|c%x%x%x%x%x%x%x%x") or string.find(currentText, "|r")) then
                -- Remove color codes
                local cleanText = string.gsub(currentText, "|c%x%x%x%x%x%x%x%x", "")
                cleanText = string.gsub(cleanText, "|r", "")
                watchLine.text:SetText(cleanText)
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
        maintenanceTimer = self:ScheduleRepeatingTimer("MaintenanceCheck", 10) -- Check every 10 seconds (less frequent to avoid duplicates)
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
-- Maintenance function to check and re-apply enhancements periodically
function Module:MaintenanceCheck()
    -- Enhanced display is always enabled now
    if not self.db.enabled then return end
    
    -- Only do very light maintenance checks to avoid constant reapplication
    local numWatched = GetNumQuestWatches()
    
    -- Very light check - only verify basic frame properties
    if numWatched > 0 and questTrackerFrame and questTrackerFrame:IsVisible() then
        -- Simple scale/alpha check only (these don't interfere with text content)
        if questTrackerFrame:GetScale() ~= self.db.trackerScale then
            questTrackerFrame:SetScale(self.db.trackerScale)
        end
        
        if questTrackerFrame:GetAlpha() ~= self.db.trackerAlpha then
            questTrackerFrame:SetAlpha(self.db.trackerAlpha)
        end
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
    
    -- Apply text enhancements (levels and colors) in one unified pass
    if self.db.showQuestLevels or self.db.colorCodeByDifficulty then
        self:ApplyAllTextEnhancements()
    end
    
    -- Apply visual enhancements (these don't conflict with text)
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
        -- Process quest notifications here
    end
end

function Module:OnQuestAbandoned()
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
        elseif key == "indentObjectives" then
            -- Apply or remove objective formatting immediately
            if self:IsEnabled() then
                if val then
                    self:FormatQuestObjectives()
                else
                    -- Refresh the display to restore original formatting
                    self:UpdateTrackedQuests()
                    self:EnhanceQuestDisplay()
                end
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
                    indentObjectives = {
                        type = "toggle", order = 3,
                        name = L["Indent Objectives"] or "Indent Objectives",
                        desc = L["Remove dash from objectives and add indentation for cleaner look."] or "Remove dash from objectives and add indentation for cleaner look.",
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
        YATP.modules.QuestTracker:CleanupDuplicateLevels()
        print("Removed all quest levels from tracker and cleaned duplicates")
    else
        print("Quest Tracker module not found")
    end
end

-- Register fix command to clean duplicates and reapply
SLASH_YATPQTFIX1 = "/qtfix"
SlashCmdList["YATPQTFIX"] = function()
    if YATP.modules.QuestTracker then
        local module = YATP.modules.QuestTracker
        module:RemoveQuestLevels()
        module:CleanupDuplicateLevels()
        if module.db.showQuestLevels then
            module:ShowQuestLevels()
        end
        if module.db.colorCodeByDifficulty then
            module:ApplyDifficultyColors()
        end
        print("Fixed quest tracker duplicates and reapplied settings")
    else
        print("Quest Tracker module not found")
    end
end

-- Register debug command to see quest info
SLASH_YATPQTDEBUG1 = "/qtdebug"
SlashCmdList["YATPQTDEBUG"] = function()
    if YATP.modules.QuestTracker then
        local module = YATP.modules.QuestTracker
        print("=== Quest Tracker Debug Info ===")
        print("Show Levels: " .. tostring(module.db.showQuestLevels))
        print("Color by Difficulty: " .. tostring(module.db.colorCodeByDifficulty))
        
        local numWatched = GetNumQuestWatches()
        print("Watched Quests: " .. numWatched)
        
        for i = 1, numWatched do
            local questIndex = GetQuestIndexForWatch(i)
            if questIndex then
                local title, level = GetQuestLogTitle(questIndex)
                if title then
                    print(string.format("Quest %d: Level %s - %s", i, level or "nil", title))
                end
            end
        end
        
        print("\n=== WatchFrame Lines ===")
        for lineNum = 1, 20 do
            local watchLine = _G["WatchFrameLine" .. lineNum]
            if watchLine and watchLine.text and watchLine:IsVisible() then
                local text = watchLine.text:GetText()
                if text and text ~= "" then
                    local cleanText = string.gsub(text, "|c%x%x%x%x%x%x%x%x", "")
                    cleanText = string.gsub(cleanText, "|r", "")
                    local indent = string.match(text, "^(%s+)") or ""
                    print(string.format("Line %d [%d spaces]: %s", lineNum, string.len(indent), cleanText))
                end
            end
        end
        print("=== End Debug Info ===")
    else
        print("Quest Tracker module not found")
    end
end

return Module