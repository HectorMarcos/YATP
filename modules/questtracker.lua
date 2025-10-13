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
    -- All debug disabled
end

-- Debug function specifically for dash analysis
function Module:DebugDashAnalysis()
    local watchFrame = _G["WatchFrame"]
    if not watchFrame then 
        print("|cffff0000[YATP - Dash Debug]|r WatchFrame not found")
        return 
    end
    
    print("|cff00ff00[YATP - Dash Debug]|r === Analyzing .dash elements ===")
    
    for lineNum = 1, 50 do
        local watchLine = _G["WatchFrameLine" .. lineNum]
        if watchLine and watchLine.text and watchLine:IsVisible() then
            local text = watchLine.text:GetText()
            if text and text ~= "" then
                -- Clean text for display
                local cleanText = string.gsub(text, "|c%x%x%x%x%x%x%x%x", "")
                cleanText = string.gsub(cleanText, "|r", "")
                
                -- Check dash status
                local hasDash = watchLine.dash and true or false
                local dashVisible = hasDash and watchLine.dash:IsVisible() or false
                local dashExists = hasDash and "YES" or "NO"
                local dashVisibleText = dashVisible and "VISIBLE" or "HIDDEN"
                
                print(string.format("|cff00ff00[YATP - Dash Debug]|r Line %d: '%s' | Dash: %s (%s)", 
                    lineNum, cleanText, dashExists, dashVisibleText))
            end
        end
    end
    
    print("|cff00ff00[YATP - Dash Debug]|r === Analysis Complete ===")
end

function Module:Print(msg)
    print("|cff00ff00[YATP - QuestTracker]|r " .. tostring(msg))
end

function Module:ForceQuestTrackerUpdate()
    -- Force update the quest tracker display
    if WatchFrame and WatchFrame:IsVisible() then
        WatchFrame_Update()
        if WatchFrameHeader then
            WatchFrameHeader:Hide()
            WatchFrameHeader:Show()
        end
    end
    
    -- Force POI (Point of Interest) icon updates
    if QuestMapUpdateAllQuests then
        QuestMapUpdateAllQuests()
    end
    
    -- Force quest POI frame updates (the arrow icons)
    if QuestPOIUpdateIcons then
        QuestPOIUpdateIcons()
    end
    
    -- Alternative POI update methods for different client versions
    if QuestMapFrame and QuestMapFrame.DetailsFrame and QuestMapFrame.DetailsFrame.BackButton then
        -- Force a quest map refresh which also updates POIs
        C_Timer.After(0.05, function()
            if GetNumQuestWatches() > 0 then
                local questID = GetQuestIDFromLogIndex(GetQuestIndexForWatch(1))
                if questID then
                    QuestMapFrame_ShowQuestDetails(questID)
                    QuestMapFrame_CloseQuestDetails()
                end
            end
        end)
    end
    
    -- Update world map quest POIs if visible
    if WorldMapFrame and WorldMapFrame:IsVisible() then
        if WorldMapQuestFrame_Update then
            WorldMapQuestFrame_Update()
        end
    end
    
    -- Also trigger our own enhancement update
    self:ScheduleTimer(function()
        self:ReapplyAllEnhancements()
        
        -- Final POI refresh after enhancements are applied
        if WatchFrame_Update then
            WatchFrame_Update()
        end
        
        -- Trigger quest log update event to refresh POIs
        if QuestLog_Update then
            QuestLog_Update()
        end
        
    end, 0.1)
    
    -- Additional delayed POI update for stubborn icons
    self:ScheduleTimer(function()
        if QuestPOIUpdateIcons then
            QuestPOIUpdateIcons()
        end
        -- Simulate quest watch update to refresh POIs
        if WatchFrame_Update then
            WatchFrame_Update()
        end
        -- Call our comprehensive POI update function
        self:UpdateQuestPOIIcons()
    end, 0.2)
end

function Module:UpdateQuestPOIIcons()
    -- Method 1: Direct POI function calls
    if QuestPOIUpdateIcons then
        QuestPOIUpdateIcons()
        self:Debug("Called QuestPOIUpdateIcons()")
    end
    
    -- Method 2: Update quest map POIs
    if QuestMapUpdateAllQuests then
        QuestMapUpdateAllQuests()
        self:Debug("Called QuestMapUpdateAllQuests()")
    end
    
    -- Method 3: Force WatchFrame children update (POI icons are often children)
    if WatchFrame then
        local children = {WatchFrame:GetChildren()}
        self:Debug("Found " .. #children .. " WatchFrame children")
        for i, child in ipairs(children) do
            if child and child.Update then
                child:Update()
                self:Debug("Updated child " .. i .. " with Update method")
            elseif child and child.IsVisible and child:IsVisible() then
                child:Hide()
                child:Show()
                self:Debug("Refreshed child " .. i .. " with hide/show")
            end
        end
    end
    
    -- Method 4: Update individual quest POI frames
    local watchCount = GetNumQuestWatches()
    self:Debug("Updating POI for " .. watchCount .. " watched quests")
    for i = 1, watchCount do
        local questIndex = GetQuestIndexForWatch(i)
        if questIndex then
            local questID = GetQuestIDFromLogIndex and GetQuestIDFromLogIndex(questIndex)
            if questID and QuestPOI_UpdateIcon then
                QuestPOI_UpdateIcon(questID)
                self:Debug("Updated POI for quest ID " .. questID)
            end
        end
    end
    
    self:Debug("Completed quest POI icons update")
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
    
    -- Position and size
    positionX = 0,
    positionY = 0,
    lockPosition = true,
    
    -- Auto-tracking (simplified - only two options)
    forceTrackAll = false,     -- Force tracking of all quests
    autoTrackByZone = true,    -- Auto-track quests by current zone (default enabled)
    
    -- Visual enhancements
    colorCodeByDifficulty = true,
    indentObjectives = true,           -- Indent quest objectives for better readability
    highlightNearbyObjectives = true,
    showQuestIcons = true,

    
    -- Text appearance
    textOutline = false,
    
    -- Frame dimensions
    customHeight = true,      -- Always enabled - no UI option
    frameHeight = 600,
    
    -- Frame appearance
    hideBackground = false,    -- Hide quest tracker background art
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
    if self.db.customHeight == nil then
        self.db.customHeight = true  -- Always enabled
    end
    if self.db.frameHeight == nil then
        self.db.frameHeight = 600
    end
    if self.db.hideBackground == nil then
        self.db.hideBackground = false
    end
    if self.db.positionX == nil then
        self.db.positionX = 0
    end
    if self.db.positionY == nil then
        self.db.positionY = 0
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
        
        -- Make frame always movable to prevent SexyMap errors, but hook all positioning functions
        questTrackerFrame:SetMovable(true)
        
        -- Hook SetUserPlaced to prevent errors but ignore the call
        if not questTrackerFrame.originalSetUserPlaced then
            questTrackerFrame.originalSetUserPlaced = questTrackerFrame.SetUserPlaced
            questTrackerFrame.SetUserPlaced = function(frame, userPlaced)
                -- Always return success to prevent SexyMap errors, but don't actually set user placed
                -- This makes SexyMap think it succeeded without giving it control
                self:Debug("SetUserPlaced intercepted (SexyMap compatibility): " .. tostring(userPlaced))
                return true
            end
        end
        
        -- Hook GetUserPlaced to always return false (we're managing position)
        if not questTrackerFrame.originalGetUserPlaced then
            questTrackerFrame.originalGetUserPlaced = questTrackerFrame.GetUserPlaced
            questTrackerFrame.GetUserPlaced = function(frame)
                -- Always return false so other addons know we're managing position
                return false
            end
        end
        
        -- Hook SetPoint to intercept ALL positioning attempts (including SexyMap)
        if not questTrackerFrame.originalSetPoint then
            questTrackerFrame.originalSetPoint = questTrackerFrame.SetPoint
            questTrackerFrame.SetPoint = function(frame, point, relativeTo, relativePoint, x, y, ...)
                -- If we have custom position, always use ours instead of any external positioning
                if self.db.positionX and self.db.positionY then
                    self:Debug("Position change intercepted, using custom position instead")
                    frame.originalSetPoint(frame, "TOPLEFT", UIParent, "TOPLEFT", self.db.positionX, self.db.positionY)
                else
                    -- No custom position, allow normal positioning
                    frame.originalSetPoint(frame, point, relativeTo, relativePoint, x, y, ...)
                end
            end
        end
        
        -- Hook the update function if we haven't already to maintain our modifications
        if not originalUpdateFunction then
            -- Try to hook WatchFrame_Update if it exists
            if WatchFrame_Update then
                originalUpdateFunction = WatchFrame_Update
                WatchFrame_Update = function(...)
                    -- Store our custom position before calling original function
                    local savedCustomX, savedCustomY = self.db.positionX, self.db.positionY
                    
                    -- Pre-apply position before original function (SetPoint hook will enforce it)
                    if savedCustomX and savedCustomY then
                        questTrackerFrame:ClearAllPoints()
                        questTrackerFrame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", savedCustomX, savedCustomY)
                    end
                    
                    -- Call the original update function
                    -- This will reset the WatchFrame to its clean state but position is hooked
                    originalUpdateFunction(...)
                    
                    -- Position is automatically maintained by SetPoint hook, no need for double-check
                    
                    -- IMPORTANT: After WatchFrame_Update, the frame is CLEAN (no modifications)
                    -- We can now safely apply our enhancements without worrying about duplicates
                    
                    -- Apply text enhancements (levels and colors) immediately on clean frame
                    if self.db.showQuestLevels or self.db.colorCodeByDifficulty then
                        self:ApplyAllTextEnhancements()
                    end
                    

                    
                    -- Apply visual enhancements (these are independent)
                    if self.db.textOutline then
                        self:ApplyTextOutline()
                    end
                    -- Always apply custom height
                    self:ApplyCustomHeight()
                    
                    -- Apply background toggle immediately after frame update to prevent flash
                    if self.db.hideBackground then
                        self:ApplyBackgroundToggle()
                    end
                    
                    -- Apply movable state
                    self:ApplyMovableTracker()
                end
            end
        end
    end
end

-- Save current WatchFrame content and properties
function Module:SaveWatchFrameContent()
    wipe(savedWatchFrameContent)
    wipe(savedFrameProperties)
    

    
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
    
    self:Debug("Applying text outline - Enabled: " .. tostring(self.db.textOutline) .. " (Always Normal thickness)")
    
    -- Apply outline to quest objective lines (WatchFrameLine)
    for lineNum = 1, 50 do
        local watchLine = _G["WatchFrameLine" .. lineNum]
        if watchLine and watchLine.text then
            if self.db.textOutline then
                -- Apply normal outline (always normal thickness)
                watchLine.text:SetFont(watchLine.text:GetFont(), select(2, watchLine.text:GetFont()), "OUTLINE")
                self:Debug("Applied outline to WatchFrameLine" .. lineNum)
            else
                -- Remove outline
                watchLine.text:SetFont(watchLine.text:GetFont(), select(2, watchLine.text:GetFont()), "")
                self:Debug("Removed outline from WatchFrameLine" .. lineNum)
            end
        end
    end
    
    -- Apply outline to quest headers using smart detection
    self:ApplyOutlineToQuestHeaders()
end

-- Helper function to find all text elements in WatchFrame
function Module:FindAllQuestTextElements()
    local textElements = {}
    
    if not questTrackerFrame then 
        return textElements
    end
    
    -- First, try to find the main header specifically
    local mainHeaderFound = false
    local possibleHeaders = {
        _G["WatchFrameTitle"],
        _G["QuestWatchFrameTitle"],
        _G["ObjectiveTrackerFrameTitle"],
        questTrackerFrame.title,
        questTrackerFrame.header
    }
    
    for _, header in ipairs(possibleHeaders) do
        if header and header.GetText and header:GetText() then
            local text = header:GetText()
            if text and string.match(text, "Objectives") then
                table.insert(textElements, {
                    element = header,
                    text = text,
                    type = "main_header",
                    fontSize = select(2, header:GetFont()) or 12
                })
                self:Debug("Found main header via direct reference: " .. text)
                mainHeaderFound = true
                break
            end
        end
    end
    
    -- Collect all FontString regions from WatchFrame
    if questTrackerFrame.GetRegions then
        local regions = {questTrackerFrame:GetRegions()}
        for i, region in ipairs(regions) do
            if region and region.GetObjectType and region:GetObjectType() == "FontString" and region:IsVisible() then
                local text = region:GetText()
                if text and text ~= "" then
                    -- Check if this is the main header we haven't found yet
                    if not mainHeaderFound and string.match(text, "Objectives") then
                        table.insert(textElements, {
                            element = region,
                            text = text,
                            type = "main_header_region",
                            fontSize = select(2, region:GetFont()) or 12
                        })
                        self:Debug("Found main header via region scan: " .. text)
                        mainHeaderFound = true
                    else
                        table.insert(textElements, {
                            element = region,
                            text = text,
                            type = "region",
                            fontSize = select(2, region:GetFont()) or 0
                        })
                    end
                end
            end
        end
    end
    
    -- Collect all FontString children from WatchFrame
    if questTrackerFrame.GetChildren then
        local children = {questTrackerFrame:GetChildren()}
        for i, child in ipairs(children) do
            if child and child.GetObjectType and child:GetObjectType() == "FontString" and child:IsVisible() then
                local text = child:GetText()
                if text and text ~= "" then
                    table.insert(textElements, {
                        element = child,
                        text = text,
                        type = "child",
                        fontSize = select(2, child:GetFont()) or 0
                    })
                end
            end
        end
    end
    
    return textElements
end

-- Apply outline specifically to quest headers using smart detection
function Module:ApplyOutlineToQuestHeaders()
    local textElements = self:FindAllQuestTextElements()
    local headersFound = 0
    
    for _, element in ipairs(textElements) do
        local isHeader = false
        local text = element.text
        
        -- Check for main tracker header "Objectives (X)"
        if string.match(text, "Objectives") or element.type == "main_header" or element.type == "main_header_region" then
            isHeader = true
            self:Debug("Found main objectives header: " .. text .. " (type: " .. element.type .. ")")
        end
        
        -- Heuristics to detect individual quest headers:
        -- 1. Font size >= 12 (headers are usually larger)
        -- 2. Text doesn't start with numbers or common objective patterns
        -- 3. Text doesn't contain progress indicators like "1/5", "(Complete)", etc.
        if not isHeader and element.fontSize >= 12 then
            -- Check if it doesn't look like an objective
            local lowerText = string.lower(text)
            if not string.match(text, "^%d+/") and -- Not "1/5 Something"
               not string.match(text, "^%s*%d+%.") and -- Not "1. Something" 
               not string.match(lowerText, "%(complete%)") and -- Not "(Complete)"
               not string.match(lowerText, "%(failed%)") and -- Not "(Failed)"
               not string.match(text, "%d+/%d+") then -- Not containing "X/Y"
                isHeader = true
                self:Debug("Detected quest header by font size: " .. text .. " (fontSize: " .. element.fontSize .. ")")
            end
        end
        
        -- Additional check: if text starts with "[" (quest level/name format)
        if not isHeader and string.match(text, "^%[%d+%]") then
            isHeader = true
            self:Debug("Detected quest header by level format: " .. text)
        end
        
        if isHeader then
            if self.db.textOutline then
                local font, fontSize = element.element:GetFont()
                -- Always use normal outline thickness
                element.element:SetFont(font, fontSize, "OUTLINE")
                self:Debug("Applied outline to header: '" .. text .. "' (fontSize: " .. element.fontSize .. ")")
                headersFound = headersFound + 1
            else
                local font, fontSize = element.element:GetFont()
                element.element:SetFont(font, fontSize, "")
                self:Debug("Removed outline from header: '" .. text .. "'")
            end
        end
    end
    
    self:Debug("Quest header outline processing complete. Headers found: " .. headersFound)
end

-- Apply custom width to WatchFrame
function Module:ApplyCustomHeight()
    if not questTrackerFrame then 
        questTrackerFrame = WatchFrame
    end
    
    if not questTrackerFrame then 
        self:Debug("Cannot apply custom height: WatchFrame not found")
        return 
    end
    
    -- Ensure frameHeight has a default value
    if not self.db.frameHeight then
        self.db.frameHeight = 600
    end
    
    -- Always apply custom height (no UI toggle)
    local newHeight = self.db.frameHeight
    self:Debug("Applying custom height: " .. tostring(newHeight))
    questTrackerFrame:SetHeight(newHeight)
end

function Module:ApplyBackgroundToggle()
    if not questTrackerFrame then 
        questTrackerFrame = WatchFrame
    end
    
    if not questTrackerFrame then 
        self:Debug("Cannot apply background toggle: WatchFrame not found")
        return 
    end
    
    -- Initialize hidden textures table if it doesn't exist
    if not self.hiddenTextures then
        self.hiddenTextures = {}
    end
    
    if self.db.hideBackground then
        self:Debug("Hiding quest tracker background (aggressive mode)")
        
        -- Clear previous hidden textures list
        self.hiddenTextures = {}
        
        -- Set background to completely transparent as backup method
        if questTrackerFrame.SetBackdropColor then
            questTrackerFrame:SetBackdropColor(0, 0, 0, 0)
        end
        if questTrackerFrame.SetBackdropBorderColor then
            questTrackerFrame:SetBackdropBorderColor(0, 0, 0, 0)
        end
        
        -- Hide background textures
        if questTrackerFrame.background then
            questTrackerFrame.background:Hide()
            table.insert(self.hiddenTextures, questTrackerFrame.background)
        end
        
        -- Hide border textures
        if questTrackerFrame.border then
            questTrackerFrame.border:Hide()
            table.insert(self.hiddenTextures, questTrackerFrame.border)
        end
        
        -- Look for common background texture names
        local backgroundTextures = {
            "WatchFrameBackground",
            "WatchFrameBorder",
            "WatchFrameBackgroundOverlay"
        }
        
        for _, textureName in ipairs(backgroundTextures) do
            local texture = _G[textureName]
            if texture and texture.Hide then
                texture:Hide()
                table.insert(self.hiddenTextures, texture)
                self:Debug("Hid texture: " .. textureName)
            end
        end
        
        -- Hide textures that are children of WatchFrame
        if questTrackerFrame.GetNumRegions then
            for i = 1, questTrackerFrame:GetNumRegions() do
                local region = select(i, questTrackerFrame:GetRegions())
                if region and region:GetObjectType() == "Texture" then
                    local texturePath = region:GetTexture()
                    -- Hide decorative textures (but keep quest icons)
                    if texturePath and (
                        string.find(string.lower(texturePath or ""), "background") or
                        string.find(string.lower(texturePath or ""), "border") or
                        string.find(string.lower(texturePath or ""), "frame")
                    ) then
                        region:Hide()
                        table.insert(self.hiddenTextures, region)
                        self:Debug("Hid background texture region")
                    end
                end
            end
        end
        
    else
        self:Debug("Showing quest tracker background")
        
        -- Show all previously hidden textures
        if self.hiddenTextures then
            for _, texture in ipairs(self.hiddenTextures) do
                if texture and texture.Show then
                    texture:Show()
                end
            end
            self.hiddenTextures = {}
        end
        
        -- Also show background textures directly
        if questTrackerFrame.background then
            questTrackerFrame.background:Show()
        end
        
        if questTrackerFrame.border then
            questTrackerFrame.border:Show()
        end
        
        -- Show common background texture names
        local backgroundTextures = {
            "WatchFrameBackground",
            "WatchFrameBorder", 
            "WatchFrameBackgroundOverlay"
        }
        
        for _, textureName in ipairs(backgroundTextures) do
            local texture = _G[textureName]
            if texture and texture.Show then
                texture:Show()
                self:Debug("Showed texture: " .. textureName)
            end
        end
        
        -- Show all textures that are children of WatchFrame
        if questTrackerFrame.GetNumRegions then
            for i = 1, questTrackerFrame:GetNumRegions() do
                local region = select(i, questTrackerFrame:GetRegions())
                if region and region:GetObjectType() == "Texture" then
                    region:Show()
                end
            end
        end
    end
end

function Module:ApplyMovableTracker()
    if not questTrackerFrame then 
        questTrackerFrame = WatchFrame
    end
    
    if not questTrackerFrame then 
        self:Debug("Cannot apply movable tracker: WatchFrame not found")
        return 
    end
    
    -- Frame is always movable now (for SexyMap compatibility), but we control mouse interaction
    if self.db.lockPosition then
        -- Tracker is locked, disable mouse interaction (but keep movable for SexyMap)
        questTrackerFrame:EnableMouse(false)
        questTrackerFrame:SetScript("OnDragStart", nil)
        questTrackerFrame:SetScript("OnDragStop", nil)
        self:Debug("Quest tracker is locked (mouse disabled)")
    else
        -- Tracker is unlocked, enable mouse interaction for user dragging
        questTrackerFrame:EnableMouse(true)
        questTrackerFrame:RegisterForDrag("LeftButton")
        questTrackerFrame:SetScript("OnDragStart", function(self)
            self:StartMoving()
        end)
        questTrackerFrame:SetScript("OnDragStop", function(self)
            self:StopMovingOrSizing()
            -- Save new position automatically
            local x, y = self:GetLeft(), self:GetTop()
            if x and y then
                Module.db.positionX = x
                Module.db.positionY = y - GetScreenHeight()
                Module:Debug("Saved new position: " .. Module.db.positionX .. ", " .. Module.db.positionY)
            end
        end)
        self:Debug("Quest tracker is now movable by user")
    end
    
    -- Always apply our custom position (SetPoint is hooked to enforce this)
    if self.db.positionX and self.db.positionY then
        questTrackerFrame:ClearAllPoints()
        questTrackerFrame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", self.db.positionX, self.db.positionY)
        self:Debug("Applied saved position: " .. self.db.positionX .. ", " .. self.db.positionY)
    end
end

-- Enhanced quest display (simplified - no sorting)
function Module:EnhanceQuestDisplay()
    -- Enhanced display is always enabled now
    if not self.db.enabled then return end
    
    self:Debug("EnhanceQuestDisplay: Applying text enhancements only")
    
    -- Update tracked quests table
    self:UpdateTrackedQuests()
    
    -- Apply text enhancements (levels and colors)
    self:ApplyAllTextEnhancements()
    
    self:Debug("EnhanceQuestDisplay: Finished")
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
                
                -- Remove color codes for comparison
                cleanText = string.gsub(cleanText, "|c%x%x%x%x%x%x%x%x", "")
                cleanText = string.gsub(cleanText, "|r", "")
                
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
    -- NEW APPROACH - Using dash.text pattern for quest detection
    -- Based on analysis: dash.text == "-" indicates objective, otherwise it's a title
    -- NOTE: Width alignment issue (width > 210) exists in base game, not our code
    
    if not self.db.enabled then
        return
    end
    
    local playerLevel = UnitLevel("player")
    
    -- Process all visible WatchFrame lines
    for lineNum = 1, 50 do
        local watchLine = _G["WatchFrameLine" .. lineNum]
        if watchLine and watchLine:IsVisible() and watchLine.text then
            local lineText = watchLine.text:GetText()
            if lineText and lineText ~= "" then
                
                -- Core detection logic with Path to Ascension exception
                if lineText:match("Path to Ascension") then
                    -- Excepción: Path to Ascension siempre es título
                    self:ApplyQuestTitleEnhancements(watchLine, lineText, playerLevel)
                elseif watchLine.dash and watchLine.dash:GetText() == "-" then
                    -- Es un objetivo → aplicar indentado
                    self:ApplyObjectiveIndentation(watchLine, lineText)
                else
                    -- Es un título → aplicar nivel y color
                    self:ApplyQuestTitleEnhancements(watchLine, lineText, playerLevel)
                end
            end
        end
    end
end
-- Helper function to apply indentation to quest objectives
function Module:ApplyObjectiveIndentation(watchLine, lineText)
    -- ALWAYS apply indentation to objectives (lines with dash.text == "-")
    -- This is the core feature - indent all objectives for better readability
    
    -- Keep the dash invisible but present (for logic detection)
    if watchLine.dash then
        watchLine.dash:SetAlpha(0)  -- Make dash invisible to user (0% transparency)
    end
    
    -- Smart text truncation for long objectives (>100 characters)
    local processedText = self:TruncateObjectiveText(lineText)
    
    -- Check if line is already indented to avoid double indentation
    if not processedText:match("^%s%s%s%s") then
        -- Add 4 spaces for indentation
        local indentedText = "    " .. processedText
        watchLine.text:SetText(indentedText)
    end
end

-- Helper function to intelligently truncate objective text
function Module:TruncateObjectiveText(text)
    if not text or string.len(text) <= 100 then
        return text
    end
    
    -- Find the last space before character 100
    local truncatePoint = nil
    for i = 100, 1, -1 do
        if string.sub(text, i, i) == " " then
            truncatePoint = i
            break
        end
    end
    
    -- If we found a space, truncate there and add "..."
    if truncatePoint then
        return string.sub(text, 1, truncatePoint - 1) .. "..."
    else
        -- If no space found (very rare case), just cut at 97 and add "..."
        return string.sub(text, 1, 97) .. "..."
    end
end

-- Helper function to apply level and color enhancements to quest titles
function Module:ApplyQuestTitleEnhancements(watchLine, lineText, playerLevel)
    -- This is a quest title line
    local finalText = lineText
    
    -- Exception: Path to Ascension quests don't show level (they are special quest type)
    if lineText:match("Path to Ascension") then
        -- Only apply color if enabled, no level for Path to Ascension
        local questLevel = self:GetQuestLevelFromTitle(lineText)
        if questLevel and playerLevel and self.db.colorCodeByDifficulty then
            local color, closeColor = self:GetQuestDifficultyColor(questLevel, playerLevel)
            finalText = color .. finalText .. closeColor
        end
        watchLine.text:SetText(finalText)
        return
    end
    
    -- Try to find quest info for this title
    local questLevel = self:GetQuestLevelFromTitle(lineText)
    
    if questLevel and playerLevel then
        -- Add quest level if enabled
        if self.db.showQuestLevels then
            finalText = "[" .. questLevel .. "] " .. finalText
        end
        
        -- Apply color coding if enabled
        if self.db.colorCodeByDifficulty then
            local color, closeColor = self:GetQuestDifficultyColor(questLevel, playerLevel)
            finalText = color .. finalText .. closeColor
        end
        
        watchLine.text:SetText(finalText)
    end
end

-- Helper function to extract quest level from title by matching with quest log
function Module:GetQuestLevelFromTitle(titleText)
    -- Remove any existing level prefix like "[40] " to get clean title
    local cleanTitle = titleText:gsub("^%[%d+%] ", "")
    
    -- Search through quest log to find matching title
    local numEntries = GetNumQuestLogEntries()
    for i = 1, numEntries do
        local title, level, questTag, suggestedGroup, isHeader, isCollapsed, isComplete, isDaily, questID = GetQuestLogTitle(i)
        if title and not isHeader and title == cleanTitle then
            return level
        end
    end
    return nil
end

-- Helper function to get difficulty color based on level difference
function Module:GetQuestDifficultyColor(questLevel, playerLevel)
    local levelDiff = questLevel - playerLevel
    
    -- WoW standard difficulty colors
    if levelDiff >= 5 then
        return "|cffff0000", "|r" -- Bright Red (5+ levels above)
    elseif levelDiff >= 3 then
        return "|cffff6600", "|r" -- Bright Orange (3-4 levels above)
    elseif levelDiff >= -2 then
        return "|cffffff00", "|r" -- Bright Yellow (-2 to +2 levels)
    elseif levelDiff >= -10 then
        return "|cff00ff00", "|r" -- Bright Green (-10 to -3 levels)
    else
        return "|cff999999", "|r" -- Light Gray (more than -10 levels)
    end
end

-- Format quest objectives by adding indentation - simplified dash-based approach








-- COMPREHENSIVE WATCHFRAME DEBUGGING SYSTEM
-- This system provides detailed analysis of WatchFrame structure and content
-- to understand how quest titles are organized internally for better detection

function Module:AnalyzeWatchFrameStructure()
    print("DEBUG: AnalyzeWatchFrameStructure function called!")
    
    if not WatchFrame then 
        print("ERROR: WatchFrame not found!")
        return 
    end
    
    print("=== COMPREHENSIVE WATCHFRAME ANALYSIS ===")
    
    -- Basic WatchFrame properties
    print("WatchFrame Basic Properties:")
    print("  - IsVisible: " .. tostring(WatchFrame:IsVisible()))
    print("  - NumLines: " .. tostring(WatchFrame.numLines or "nil"))
    print("  - Height: " .. tostring(WatchFrame:GetHeight()))
    print("  - Width: " .. tostring(WatchFrame:GetWidth()))
    
    -- Analyze all child frames
    print("\nWatchFrame Child Analysis:")
    local children = {WatchFrame:GetChildren()}
    for i, child in ipairs(children) do
        if child then
            local name = child:GetName() or "unnamed"
            local childType = child:GetObjectType()
            print("  Child " .. i .. ": " .. name .. " (" .. childType .. ")")
            
            -- If it has text, show it
            if child.GetText and child:GetText() then
                print("    Text: '" .. child:GetText() .. "'")
            end
        end
    end
    
    -- Analyze all WatchFrameLine elements (WatchFrameLine1, WatchFrameLine2, etc.)
    print("\nWatchFrameLine Analysis:")
    for lineNum = 1, 50 do
        local watchLine = _G["WatchFrameLine" .. lineNum]
        if watchLine then
            print("  WatchFrameLine" .. lineNum .. ":")
            print("    - Visible: " .. tostring(watchLine:IsVisible()))
            
            if watchLine.text then
                local text = watchLine.text:GetText()
                if text and text ~= "" then
                    print("    - Text: '" .. text .. "'")
                    print("    - Text Color: R=" .. string.format("%.2f", watchLine.text:GetTextColor()))
                    print("    - Font: " .. tostring(watchLine.text:GetFont()))
                end
            end
            
            -- Check for dash element
            if watchLine.dash then
                print("    - Has dash element: " .. tostring(watchLine.dash:IsVisible()))
                if watchLine.dash.GetText and watchLine.dash:GetText() then
                    print("    - Dash text: '" .. watchLine.dash:GetText() .. "'")
                end
            end
            
            -- Check for other common elements
            if watchLine.check then
                print("    - Has check element: " .. tostring(watchLine.check:IsVisible()))
            end
            
        else
            -- Stop when we hit the first non-existent line
            break
        end
    end
    
    -- Quest-specific analysis
    print("\nQuest Data Analysis:")
    local numWatched = GetNumQuestWatches()
    print("  Number of watched quests: " .. numWatched)
    
    for i = 1, numWatched do
        local questIndex = GetQuestIndexForWatch(i)
        if questIndex then
            local title, level, questTag, suggestedGroup, isHeader, isCollapsed, isComplete, isDaily, questID = GetQuestLogTitle(questIndex)
            print("  Quest " .. i .. ":")
            print("    - Title: '" .. (title or "nil") .. "'")
            print("    - Level: " .. (level or "nil"))
            print("    - QuestID: " .. (questID or "nil"))
            print("    - IsHeader: " .. tostring(isHeader))
            print("    - IsComplete: " .. tostring(isComplete))
            
            -- Try to find this quest in the WatchFrame lines
            if title then
                local foundLine = self:FindQuestTitleInWatchFrame(title)
                if foundLine then
                    print("    - Found in WatchFrameLine" .. foundLine)
                else
                    print("    - NOT FOUND in any WatchFrameLine!")
                end
            end
        end
    end
    
    print("=== END WATCHFRAME ANALYSIS ===")
end

-- Helper to find which WatchFrameLine contains a specific quest title
function Module:FindQuestTitleInWatchFrame(questTitle)
    if not questTitle then return nil end
    
    for lineNum = 1, 50 do
        local watchLine = _G["WatchFrameLine" .. lineNum]
        if watchLine and watchLine.text then
            local lineText = watchLine.text:GetText()
            if lineText then
                -- Try exact match first
                if lineText == questTitle then
                    return lineNum
                end
                
                -- Try partial match (in case of level prefixes or other modifications)
                if string.find(lineText, questTitle, 1, true) then
                    return lineNum
                end
                
                -- Try clean match (remove colors and level prefixes)
                local cleanLineText = self:GetCleanText(lineText)
                local cleanQuestTitle = self:GetCleanText(questTitle)
                if cleanLineText == cleanQuestTitle then
                    return lineNum
                end
            end
        else
            break
        end
    end
    
    return nil
end

-- Helper function to get clean text for comparison (removes colors and formatting)
function Module:GetCleanText(text)
    if not text then return "" end
    
    local clean = text
    
    -- Remove color codes
    clean = string.gsub(clean, "|c%x%x%x%x%x%x%x%x", "")
    clean = string.gsub(clean, "|r", "")
    
    -- Remove level prefix
    clean = string.gsub(clean, "^%[%d+%]%s*", "")
    
    -- Clean whitespace
    clean = string.gsub(clean, "^%s+", "")
    clean = string.gsub(clean, "%s+$", "")
    
    return clean
end

-- Show progress percentages
function Module:ShowProgressPercentages()
    -- Implementation for showing progress percentages
    -- This would calculate and display completion percentages for objectives
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
    
    -- Debug commands
    self:RegisterChatCommand("qtdebug", function() 
        print("|cff00ff00[YATP]|r Quest Tracker Debug Info:")
        print("  Module enabled: " .. tostring(self:IsEnabled()))
        print("  forceTrackAll: " .. tostring(self.db.forceTrackAll))
        print("  autoTrackByZone: " .. tostring(self.db.autoTrackByZone))
        print("  Watched quests: " .. GetNumQuestWatches())
    end)
    self:RegisterChatCommand("qtrestore", function()
        print("|cff00ff00[YATP]|r Restoring quest tracker...")
        -- Force refresh the watch frame
        if WatchFrame and WatchFrame.Update then
            WatchFrame:Update()
        else
            -- Alternative method for 3.3.5
            for i = 1, GetNumQuestWatches() do
                local questIndex = GetQuestIndexForWatch(i)
                if questIndex then
                    RemoveQuestWatch(questIndex)
                    AddQuestWatch(questIndex)
                end
            end
        end
        print("|cff00ff00[YATP]|r Quest tracker restored!")
    end)

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

    self:RegisterEvent("PLAYER_ENTERING_WORLD", "OnPlayerEnteringWorld")
    self:RegisterEvent("QUEST_ABANDONED", "OnQuestAbandoned")
    self:RegisterEvent("ZONE_CHANGED", "OnZoneChanged")
    self:RegisterEvent("ZONE_CHANGED_NEW_AREA", "OnZoneChanged")
    self:RegisterEvent("ADDON_LOADED", "OnAddonLoaded")
    
    self:Debug("Quest Tracker module enabled")
    
    -- Start maintenance timer to periodically check and re-apply enhancements
    if not maintenanceTimer then
        maintenanceTimer = self:ScheduleRepeatingTimer("MaintenanceCheck", 10) -- Check every 10 seconds (less frequent to avoid duplicates)
        self:Debug("Started maintenance timer")
    end
    
    -- Ensure at least one tracking mode is enabled
    if not self.db.forceTrackAll and not self.db.autoTrackByZone then
        self.db.autoTrackByZone = true
        -- Auto-enabled zone tracking by default silently
    end
    
    -- Apply all enhancements on enable to ensure settings are applied after reload
    self:ScheduleTimer(function()
        self:ReapplyAllEnhancements()
    end, 2) -- Delay to ensure WatchFrame is fully loaded
    
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
        -- Restore original SetPoint if we hooked it
        if questTrackerFrame.originalSetPoint then
            questTrackerFrame.SetPoint = questTrackerFrame.originalSetPoint
            questTrackerFrame.originalSetPoint = nil
        end
        -- Restore original SetUserPlaced if we hooked it
        if questTrackerFrame.originalSetUserPlaced then
            questTrackerFrame.SetUserPlaced = questTrackerFrame.originalSetUserPlaced
            questTrackerFrame.originalSetUserPlaced = nil
        end
        -- Restore original GetUserPlaced if we hooked it
        if questTrackerFrame.originalGetUserPlaced then
            questTrackerFrame.GetUserPlaced = questTrackerFrame.originalGetUserPlaced
            questTrackerFrame.originalGetUserPlaced = nil
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
        -- Check if background setting needs to be reapplied
        if self.db.hideBackground then
            -- Check if any background textures are visible when they shouldn't be
            local backgroundTextures = {"WatchFrameBackground", "WatchFrameBorder", "WatchFrameBackgroundOverlay"}
            for _, textureName in ipairs(backgroundTextures) do
                local texture = _G[textureName]
                if texture and texture:IsVisible() then
                    self:ApplyBackgroundToggle() -- Reapply if background is showing when it shouldn't
                    break
                end
            end
        end
        
        -- Check if position needs to be reapplied
        if self.db.positionX and self.db.positionY then
            local currentX, currentY = questTrackerFrame:GetLeft(), questTrackerFrame:GetTop()
            if currentX and currentY then
                local expectedY = self.db.positionY + GetScreenHeight()
                -- Check if position is significantly different (tolerance of 5 pixels)
                if math.abs(currentX - self.db.positionX) > 5 or math.abs(currentY - expectedY) > 5 then
                    questTrackerFrame:ClearAllPoints()
                    questTrackerFrame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", self.db.positionX, self.db.positionY)
                    self:Debug("Position corrected in maintenance check")
                end
            end
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

function Module:OnAddonLoaded(event, addonName)
    -- Re-apply background settings when other addons load (they might interfere with quest tracker)
    if self.db.hideBackground then
        self:ScheduleTimer(function()
            self:ApplyBackgroundToggle()
        end, 1)
    end
end

function Module:OnQuestWatchUpdate(event, questID)
    self:Debug("Quest watch updated: " .. tostring(questID))
    self:UpdateTrackedQuests()
    
    -- Re-apply quest enhancements with small delay to allow frame update to complete
    -- This prevents the "flash" of default background when tracker updates
    self:ScheduleTimer(function()
        self:ReapplyAllEnhancements()
    end, 0.1) -- Very small delay, just enough for frame to finish updating
end

function Module:OnQuestLogUpdate()
    self:Debug("Quest log updated")
    self:UpdateTrackedQuests()
    
    -- Auto-tracking functionality
    self:ManageAutoTracking()
    
    -- Re-apply enhancements with small delay to prevent flash
    self:ScheduleTimer(function()
        self:ReapplyAllEnhancements()
    end, 0.1)
end

-- Helper function to move "Path to Ascension" quests to the end
function Module:MovePathToAscensionQuestsToEnd()
    local numWatched = GetNumQuestWatches()
    if numWatched <= 1 then return end -- Nothing to reorder
    
    local pathQuests = {}
    local regularQuests = {}
    
    -- Collect quest indices and categorize them
    for i = 1, numWatched do
        local questIndex = GetQuestIndexForWatch(i)
        if questIndex then
            local questTitle = GetQuestLogTitle(questIndex)
            if questTitle and questTitle:match("Path to Ascension") then
                table.insert(pathQuests, questIndex)
            else
                table.insert(regularQuests, questIndex)
            end
        end
    end
    
    -- Only reorder if we have Path to Ascension quests that aren't already at the end
    if #pathQuests > 0 and numWatched > #pathQuests then
        -- Remove all watched quests
        for i = numWatched, 1, -1 do
            local questIndex = GetQuestIndexForWatch(i)
            if questIndex then
                RemoveQuestWatch(questIndex)
            end
        end
        
        -- Re-add in desired order: regular quests first, then Path to Ascension quests
        for _, questIndex in ipairs(regularQuests) do
            AddQuestWatch(questIndex)
        end
        for _, questIndex in ipairs(pathQuests) do
            AddQuestWatch(questIndex)
        end
        
        self:Debug("Moved " .. #pathQuests .. " Path to Ascension quest(s) to end of tracker")
    end
end

-- Simplified auto-tracking management (only two options)
function Module:ManageAutoTracking()
    if not self.db.enabled then return end
    
    if self.db.forceTrackAll then
        self:TrackAllQuests()
    elseif self.db.autoTrackByZone then
        self:AutoTrackByCurrentZone()
    end
end

-- Track all quests in quest log (simplified)
function Module:TrackAllQuests()
    local numEntries = GetNumQuestLogEntries()
    local trackedCount = 0
    
    for i = 1, numEntries do
        local questTitle, level, questTag, suggestedGroup, isHeader, isCollapsed, isComplete, isDaily, questID = GetQuestLogTitle(i)
        
        if not isHeader and questTitle then
            -- Check if quest is already being tracked
            local isTracked = false
            for j = 1, GetNumQuestWatches() do
                local watchedIndex = GetQuestIndexForWatch(j)
                if watchedIndex == i then
                    isTracked = true
                    break
                end
            end
            
            -- Track all quests (including completed ones)
            if not isTracked then
                AddQuestWatch(i)
                trackedCount = trackedCount + 1
                self:Debug("Auto-tracked quest: " .. (questTitle or "Unknown"))
            end
        end
    end
    
    -- Silent operation - no user feedback needed
    
    -- Move Path to Ascension quests to the end
    if trackedCount > 0 then
        self:MovePathToAscensionQuestsToEnd()
    end
    
    -- Force quest tracker update to show changes immediately
    self:ForceQuestTrackerUpdate()
end

-- Track quests only for current zone (and always track Ascension Main Quest)
function Module:AutoTrackByCurrentZone()
    local currentZone = GetRealZoneText() or GetZoneText()
    if not currentZone or currentZone == "" then
        return
    end
    
    self:Debug("Auto-tracking by zone: " .. currentZone)
    
    local numEntries = GetNumQuestLogEntries()
    local questsToTrack = {}
    local questsToUntrack = {}
    local currentCategory = nil
    
    -- First, collect all quests and their zones
    for i = 1, numEntries do
        local questTitle, level, questTag, suggestedGroup, isHeader, isCollapsed, isComplete, isDaily, questID = GetQuestLogTitle(i)
        
        -- Track current category
        if isHeader then
            currentCategory = questTitle
            self:Debug("Category: " .. tostring(currentCategory))
        end
        
        if not isHeader and questTitle then
            -- Debug quest information
            self:Debug("Quest " .. i .. ": " .. questTitle .. " | Category: " .. tostring(currentCategory) .. " | Tag: " .. tostring(questTag))
            
            -- Always track Ascension-related quests
            local shouldTrack = false
            
            -- Method 1: Check by category name
            if currentCategory and (
                currentCategory == "Ascension Main Quest" or 
                currentCategory == "Path to Ascension" or
                string.find(currentCategory, "Ascension") or
                string.find(currentCategory, "Path to")
            ) then
                shouldTrack = true
                self:Debug("  -> Marked for tracking: Ascension quest by category (" .. currentCategory .. ")")
            end
            
            -- Method 2: Check by questTag
            if not shouldTrack and questTag and (questTag == "Ascension Main Quest" or questTag == "Path to Ascension") then
                shouldTrack = true
                self:Debug("  -> Marked for tracking: Ascension quest by tag (" .. questTag .. ")")
            end
            
            -- Method 3: Check by quest title patterns (backup method)
            if not shouldTrack and questTitle then
                local lowerTitle = string.lower(questTitle)
                if string.find(lowerTitle, "ascension") or string.find(lowerTitle, "path to") then
                    shouldTrack = true
                    self:Debug("  -> Marked for tracking: Ascension quest by title pattern")
                end
            end
            
            -- Also track quests for current zone (if not already marked as Ascension)
            if not shouldTrack then
                -- Simple zone detection: find the last zone header before this quest
                local questZone = nil
                for k = i, 1, -1 do
                    local headerTitle, _, _, _, isHeaderCheck = GetQuestLogTitle(k)
                    if isHeaderCheck then
                        questZone = headerTitle
                        break
                    end
                end
                
                if questZone and questZone == currentZone then
                    shouldTrack = true
                    self:Debug("  -> Marked for tracking: Current zone quest (" .. questZone .. ")")
                end
            end
            

            
            -- Check current tracking status
            local isTracked = false
            for j = 1, GetNumQuestWatches() do
                local watchedIndex = GetQuestIndexForWatch(j)
                if watchedIndex == i then
                    isTracked = true
                    break
                end
            end
            
            if shouldTrack and not isTracked then
                table.insert(questsToTrack, i)
            elseif not shouldTrack and isTracked then
                table.insert(questsToUntrack, i)
            end
        end
    end
    
    -- Apply tracking changes
    local ascensionTracked = 0
    local zoneTracked = 0
    
    for _, questIndex in ipairs(questsToTrack) do
        AddQuestWatch(questIndex)
        local title = GetQuestLogTitle(questIndex)
        if title and (string.find(string.lower(title), "ascension") or string.find(string.lower(title), "path to")) then
            ascensionTracked = ascensionTracked + 1
            self:Debug("Auto-tracked Ascension quest: " .. title)
        else
            zoneTracked = zoneTracked + 1
            self:Debug("Auto-tracked zone quest: " .. (title or "Unknown"))
        end
    end
    
    for _, questIndex in ipairs(questsToUntrack) do
        RemoveQuestWatch(questIndex)
        local title = GetQuestLogTitle(questIndex)
        self:Debug("Auto-untracked quest (wrong zone): " .. (title or "Unknown"))
    end
    
    self:Debug("Auto-track summary: " .. ascensionTracked .. " Ascension quests, " .. zoneTracked .. " zone quests, " .. #questsToUntrack .. " untracked")
    
    -- Silent operation - no user feedback needed
    
    -- Move Path to Ascension quests to the end
    if #questsToTrack > 0 or #questsToUntrack > 0 then
        self:MovePathToAscensionQuestsToEnd()
    end
    
    -- Force quest tracker update to show changes immediately
    self:ForceQuestTrackerUpdate()
end

function Module:OnZoneChanged()
    self:Debug("Zone changed, re-applying quest tracker enhancements")
    
    -- Auto-tracking by zone when zone changes
    if self.db.autoTrackByZone then
        self:AutoTrackByCurrentZone()
    end
    
    -- Re-apply enhancements after zone change with slight delay for loading
    self:ScheduleTimer(function() 
        self:ReapplyAllEnhancements()
    end, 0.3)
end

-- New function to re-apply all active enhancements
function Module:ReapplyAllEnhancements()
    -- Enhanced display is always enabled now
    if not self.db.enabled then return end
    
    self:Debug("ReapplyAllEnhancements called - hideBackground: " .. tostring(self.db.hideBackground))
    
    -- Apply text enhancements (levels and colors) in one unified pass
    -- Always call - the function internally checks what to apply
    self:ApplyAllTextEnhancements()
    
    -- Apply visual enhancements (these don't conflict with text)
    if self.db.textOutline then
        self:ApplyTextOutline()
    end
    
    -- Always apply custom height
    self:ApplyCustomHeight()
    
    -- Apply background toggle with multiple attempts to fight frame regeneration
    self:ApplyBackgroundToggle()
    if self.db.hideBackground then
        -- Apply background toggle multiple times to ensure it sticks during frame updates
        self:ScheduleTimer(function() self:ApplyBackgroundToggle() end, 0.2)
        self:ScheduleTimer(function() self:ApplyBackgroundToggle() end, 0.5)
    end
    
    -- Apply movable tracker with multiple position attempts to fight frame regeneration
    self:ApplyMovableTracker()
    if self.db.positionX and self.db.positionY then
        -- Apply position multiple times to ensure it sticks during frame updates
        self:ScheduleTimer(function() 
            if questTrackerFrame then
                questTrackerFrame:ClearAllPoints()
                questTrackerFrame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", self.db.positionX, self.db.positionY)
                self:Debug("Reapplied position: " .. self.db.positionX .. ", " .. self.db.positionY)
            end
        end, 0.2)
        self:ScheduleTimer(function() 
            if questTrackerFrame then
                questTrackerFrame:ClearAllPoints()
                questTrackerFrame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", self.db.positionX, self.db.positionY)
                self:Debug("Final position reapplication: " .. self.db.positionX .. ", " .. self.db.positionY)
            end
        end, 0.5)
    end
    
    -- Ensure Path to Ascension quests stay at the end
    self:ScheduleTimer(function()
        self:MovePathToAscensionQuestsToEnd()
    end, 0.3)
    
    self:Debug("All enhancements reapplied")
end

function Module:OnUIInfoMessage(event, messageType, message)

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
        elseif key == "lockPosition" then
            -- Apply position lock immediately
            self:ApplyVisualEnhancements()
        elseif key == "textOutline" then
            -- Apply text outline immediately
            if self:IsEnabled() then
                self:ApplyTextOutline()
            end
        elseif key == "showQuestLevels" or key == "colorCodeByDifficulty" then
            -- Force a clean update - let the unified system handle everything
            if self:IsEnabled() then
                self:ForceQuestTrackerUpdate()
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
                    lockPosition = {
                        type = "toggle", order = 1,
                        name = L["Lock Position"] or "Lock Position",
                        desc = L["Lock the quest tracker in place. When disabled, you can drag the tracker to move it around."] or "Lock the quest tracker in place. When disabled, you can drag the tracker to move it around.",
                        get=get, set=function(info, val)
                            set(info, val)
                            if self:IsEnabled() then
                                self:ApplyMovableTracker()
                            end
                        end,
                    },
                    textOutline = {
                        type = "toggle", order = 2,
                        name = L["Text Outline"] or "Text Outline",
                        desc = L["Add outline to quest tracker text for better readability."] or "Add outline to quest tracker text for better readability.",
                        get=get, set=set,
                    },
                    frameHeight = {
                        type = "range", order = 3,
                        name = L["Frame Height"] or "Frame Height",
                        desc = L["Set the height of the quest tracker frame in pixels."] or "Set the height of the quest tracker frame in pixels.",
                        min = 300, max = 1000, step = 50,
                        get=get, set=function(info, val)
                            set(info, val)
                            if self:IsEnabled() then
                                self:ApplyCustomHeight()
                            end
                        end,
                    },
                    hideBackground = {
                        type = "toggle", order = 4,
                        name = L["Hide Background"] or "Hide Background",
                        desc = L["Hide the quest tracker background and border artwork."] or "Hide the quest tracker background and border artwork.",
                        get=get, set=function(info, val)
                            set(info, val)
                            if self:IsEnabled() then
                                self:ApplyBackgroundToggle()
                            end
                        end,
                    },
                }
            },
            
            autoGroup = {
                type = "group", inline = true, order = 30,
                name = L["Tracking"] or "Tracking",
                args = {
                    forceTrackAll = {
                        type = "toggle", order = 1,
                        name = L["All Quests"] or "All Quests",
                        desc = L["Automatically track all quests in your quest log. Disables zone-based tracking."] or "Automatically track all quests in your quest log. Disables zone-based tracking.",
                        get=get, set=function(info, val) 
                            if val then 
                                -- Activating Force Track All, disable Zone tracking
                                self.db.autoTrackByZone = false
                                set(info, val)
                                -- Apply changes immediately
                                if self:IsEnabled() then
                                    self:TrackAllQuests()
                                end
                            else 
                                -- Trying to disable Force Track All
                                if not self.db.autoTrackByZone then
                                    -- If Zone tracking is also disabled, auto-enable Zone tracking
                                    self.db.autoTrackByZone = true
                                    -- Auto-enabled zone tracking silently
                                    if self:IsEnabled() then
                                        self:AutoTrackByCurrentZone()
                                    end
                                end
                                set(info, val)
                            end
                        end,
                    },
                    autoTrackByZone = {
                        type = "toggle", order = 2,
                        name = L["By Zone"] or "By Zone",
                        desc = L["Automatically track quests for your current zone only. Always tracks Ascension Main Quest and Path to Ascension categories. Disables force tracking."] or "Automatically track quests for your current zone only. Always tracks Ascension Main Quest and Path to Ascension categories. Disables force tracking.",
                        get=get, set=function(info, val) 
                            if val then 
                                -- Activating Zone tracking, disable Force Track All
                                self.db.forceTrackAll = false
                                set(info, val)
                                -- Apply changes immediately
                                if self:IsEnabled() then
                                    self:AutoTrackByCurrentZone()
                                end
                            else 
                                -- Trying to disable Zone tracking
                                if not self.db.forceTrackAll then
                                    -- If Force Track All is also disabled, auto-enable Force Track All
                                    self.db.forceTrackAll = true
                                    -- Auto-enabled force track all silently
                                    if self:IsEnabled() then
                                        self:TrackAllQuests()
                                    end
                                end
                                set(info, val)
                            end
                        end,
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
    end
    self:Debug("Enhanced display: " .. tostring(self.db.enhancedDisplay))
    self:Debug("Show quest levels: " .. tostring(self.db.showQuestLevels))
    self:Debug("Text outline: " .. tostring(self.db.textOutline))
    self:Debug("Using normal outline thickness (always)")
    
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
    self:ApplyAllTextEnhancements()
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



-- Register command to analyze dash elements
SLASH_YATPQTDASH1 = "/qtdash"
SlashCmdList["YATPQTDASH"] = function()
    if YATP.modules.QuestTracker then
        YATP.modules.QuestTracker:DebugDashAnalysis()
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

-- Register comprehensive WatchFrame analysis command
SLASH_YATPQTANALYZE1 = "/qtanalyze"
SlashCmdList["YATPQTANALYZE"] = function()
    print("DEBUG: /qtanalyze command executed!")
    if YATP then
        print("DEBUG: YATP addon found")
        if YATP.modules then
            print("DEBUG: YATP.modules found")
            if YATP.modules.QuestTracker then
                print("DEBUG: QuestTracker module found")
                local module = YATP.modules.QuestTracker
                if module.AnalyzeWatchFrameStructure then
                    print("DEBUG: AnalyzeWatchFrameStructure function found, calling it...")
                    module:AnalyzeWatchFrameStructure()
                else
                    print("ERROR: AnalyzeWatchFrameStructure function not found!")
                end
            else
                print("ERROR: Quest Tracker module not found in YATP.modules")
            end
        else
            print("ERROR: YATP.modules not found")
        end
    else
        print("ERROR: YATP addon not found")
    end
end

return Module