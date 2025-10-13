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
    
    -- Sorting options
    customSorting = true,      -- Enable custom sorting by default
    sortByLevel = true,        -- Sort by level by default
    sortByZone = false,        -- Keep zone sorting disabled
    sortByDistance = false,
    filterByZone = false,      -- Zone filtering option
    
    -- Position and size
    positionX = 0,
    positionY = 0,
    trackerScale = 1.0,
    trackerAlpha = 1.0,
    lockPosition = true,
    
    -- Notifications
    progressNotifications = true,
    completionSound = true,
    objectiveCompleteAlert = true,
    
    -- Auto-tracking
    autoTrackNew = true,
    autoUntrackComplete = false,
    maxTrackedQuests = 25,
    forceTrackAll = false,     -- Force tracking of all quests
    autoTrackByZone = true,    -- Auto-track quests by current zone (default enabled)
    
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
    customHeight = false,
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
    if self.db.outlineThickness == nil then
        self.db.outlineThickness = 1
    end
    if self.db.customWidth == nil then
        self.db.customWidth = false
    end
    if self.db.frameWidth == nil then
        self.db.frameWidth = 300
    end

    if self.db.customHeight == nil then
        self.db.customHeight = false
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
                    if self.db.customWidth then
                        self:ApplyCustomWidth()
                    end
                    if self.db.customHeight then
                        self:ApplyCustomHeight()
                    end
                    
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
    
    -- Apply outline to quest objective lines (WatchFrameLine)
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
                if self.db.outlineThickness == 2 then
                    element.element:SetFont(font, fontSize, "THICKOUTLINE")
                else
                    element.element:SetFont(font, fontSize, "OUTLINE")
                end
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
    
    if self.db.customHeight then
        local newHeight = self.db.frameHeight
        self:Debug("Applying custom height: " .. tostring(newHeight))
        questTrackerFrame:SetHeight(newHeight)
    else
        self:Debug("Restoring default WatchFrame height")
        -- Restore default height (WatchFrame default varies, but around 500-600)
        questTrackerFrame:SetHeight(600)
    end
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

-- Enhanced quest display with flash prevention
function Module:EnhanceQuestDisplay()
    -- Enhanced display is always enabled now
    if not self.db.enabled then return end
    
    print("|cff00ff00[YATP - DEBUG]|r EnhanceQuestDisplay: Starting")
    print("|cff00ff00[YATP - DEBUG]|r  customSorting: " .. tostring(self.db.customSorting))
    print("|cff00ff00[YATP - DEBUG]|r  sortByLevel: " .. tostring(self.db.sortByLevel))
    print("|cff00ff00[YATP - DEBUG]|r  filterByZone: " .. tostring(self.db.filterByZone))
    
    -- Update tracked quests table
    self:UpdateTrackedQuests()
    
    -- FIRST: Apply text enhancements (levels and colors) so they're there for reordering
    if self.db.showQuestLevels or self.db.colorCodeByDifficulty then
        print("|cff00ff00[YATP - DEBUG]|r Applying text enhancements first")
        self:ApplyAllTextEnhancements()
    else
        self:RemoveQuestLevels()
        self:RemoveDifficultyColors()
    end
    
    -- THEN: Apply custom sorting if enabled (now with levels already applied)
    if self.db.customSorting and self.db.sortByLevel then
        print("|cff00ff00[YATP - DEBUG]|r Calling SortQuestsByLevel")
        self:SortQuestsByLevel()
    else
        print("|cff00ff00[YATP - DEBUG]|r Skipping SortQuestsByLevel (not enabled)")
    end
    
    -- FINALLY: Apply zone filtering if enabled
    if self.db.filterByZone then
        print("|cff00ff00[YATP - DEBUG]|r Calling ApplyZoneFilter")
        self:ApplyZoneFilter()
    else
        print("|cff00ff00[YATP - DEBUG]|r Skipping ApplyZoneFilter (not enabled)")
    end
    
    print("|cff00ff00[YATP - DEBUG]|r EnhanceQuestDisplay: Finished")
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

-- Sort quests by level with completed quests at bottom
function Module:SortQuestsByLevel()
    if GetNumQuestWatches() == 0 then 
        print("|cff00ff00[YATP - DEBUG]|r SortQuestsByLevel: No watched quests")
        return 
    end
    
    print("|cff00ff00[YATP - DEBUG]|r SortQuestsByLevel: Starting with " .. GetNumQuestWatches() .. " watched quests")
    
    local questsToSort = {}
    local playerLevel = UnitLevel("player")
    
    -- Collect quest information for sorting
    for i = 1, GetNumQuestWatches() do
        local questIndex = GetQuestIndexForWatch(i)
        if questIndex then
            local title, level, questTag, suggestedGroup, isHeader, isCollapsed, isComplete, isDaily, questID = GetQuestLogTitle(questIndex)
            if title and not isHeader then
                print(string.format("|cff00ff00[YATP - DEBUG]|r Quest %d: [%d] %s (Complete: %s)", i, level or 1, title, tostring(isComplete == 1 or isComplete == -1)))
                table.insert(questsToSort, {
                    questIndex = questIndex,
                    title = title,
                    level = level or 1,
                    isComplete = isComplete == 1 or isComplete == -1,
                    watchIndex = i
                })
            end
        end
    end
    
    print("|cff00ff00[YATP - DEBUG]|r Collected " .. #questsToSort .. " quests for sorting")
    
    -- Sort: incomplete quests by level first, then completed quests at bottom
    table.sort(questsToSort, function(a, b)
        -- Completed quests go to bottom
        if a.isComplete ~= b.isComplete then
            return not a.isComplete -- Non-complete (false) comes before complete (true)
        end
        
        -- Among quests of same completion status:
        -- Special handling for Path to Ascension quests (they show level 22/23 but appear without [XX])
        local aIsPathToAscension = string.find(a.title, "Path to Ascension", 1, true)
        local bIsPathToAscension = string.find(b.title, "Path to Ascension", 1, true)
        
        if aIsPathToAscension ~= bIsPathToAscension then
            -- Path to Ascension quests go after regular leveled quests but before completed
            if not a.isComplete and not b.isComplete then
                return not aIsPathToAscension -- Regular quests (false) come before Path to Ascension (true)
            end
        end
        
        -- For regular quests of same type, sort by level
        return a.level < b.level
    end)
    
    print("|cff00ff00[YATP - DEBUG]|r After sorting:")
    for i, questInfo in ipairs(questsToSort) do
        local status = questInfo.isComplete and "COMPLETE" or "INCOMPLETE"
        local questType = string.find(questInfo.title, "Path to Ascension", 1, true) and " (PATH)" or ""
        print(string.format("|cff00ff00[YATP - DEBUG]|r  %d. [%d] %s (%s)%s", i, questInfo.level, questInfo.title, status, questType))
    end
    
    -- For WoW 3.3.5, we need to reorder visually instead of using API
    print("|cff00ff00[YATP - DEBUG]|r Using visual reordering approach...")
    self:ReorderWatchFrameLines(questsToSort)
    
    print("|cff00ff00[YATP - DEBUG]|r SortQuestsByLevel: Finished")
end

-- Reorder WatchFrame lines visually to match desired quest order
function Module:ReorderWatchFrameLines(questsToSort)
    if not WatchFrame then 
        print("|cff00ff00[YATP - DEBUG]|r WatchFrame not found")
        return 
    end
    
    -- Store all line contents with their quest associations
    local questBlocks = {}
    local currentQuestTitle = nil
    local currentBlock = {}
    local allLines = {}
    
    -- First, collect all lines and show what we have
    for i = 1, 50 do
        local line = _G["WatchFrameLine" .. i]
        if line and line.text then
            local text = line.text:GetText()
            if text and text ~= "" then
                table.insert(allLines, {lineNum = i, text = text, line = line})
                print("|cff00ff00[YATP - DEBUG]|r Line " .. i .. ": '" .. text .. "'")
            end
        end
    end
    
    print("|cff00ff00[YATP - DEBUG]|r Found " .. #allLines .. " total lines")
    
    -- Now try to group them by quest
    for _, lineData in ipairs(allLines) do
        local text = lineData.text
        
        -- Check if this is a quest title line (more flexible pattern)
        -- Look for level brackets anywhere in the line, or known quest patterns
        local hasLevel = string.match(text, "%[%d+%]")
        local isIndented = string.match(text, "^%s+") -- starts with spaces (objective)
        
        if hasLevel and not isIndented then
            -- Save previous block if exists
            if currentQuestTitle and #currentBlock > 0 then
                questBlocks[currentQuestTitle] = currentBlock
                print("|cff00ff00[YATP - DEBUG]|r Saved block for: " .. currentQuestTitle .. " (" .. #currentBlock .. " lines)")
            end
            -- Start new block - use the CLEAN title as key
            local cleanTitle = self:ExtractQuestTitle(text)
            currentQuestTitle = cleanTitle
            currentBlock = {lineData}
            print("|cff00ff00[YATP - DEBUG]|r Starting new block for: " .. cleanTitle .. " (from line: '" .. text .. "')")
        else
            -- This is likely an objective line, add to current block
            if currentQuestTitle then
                table.insert(currentBlock, lineData)
            else
                -- Orphaned line, try to match it to a quest
                local foundQuest = false
                for _, questInfo in ipairs(questsToSort) do
                    if string.find(text, questInfo.title, 1, true) then
                        currentQuestTitle = questInfo.title
                        currentBlock = {lineData}
                        print("|cff00ff00[YATP - DEBUG]|r Found orphaned quest line: " .. currentQuestTitle)
                        foundQuest = true
                        break
                    end
                end
                if not foundQuest then
                    print("|cff00ff00[YATP - DEBUG]|r Orphaned line: " .. text)
                end
            end
        end
    end
    
    -- Save the last block
    if currentQuestTitle and #currentBlock > 0 then
        questBlocks[currentQuestTitle] = currentBlock
        print("|cff00ff00[YATP - DEBUG]|r Saved final block for: " .. currentQuestTitle .. " (" .. #currentBlock .. " lines)")
    end
    
    print("|cff00ff00[YATP - DEBUG]|r Found " .. self:TableCount(questBlocks) .. " quest blocks")
    
    -- If we still have no blocks, abort to avoid clearing everything
    if self:TableCount(questBlocks) == 0 then
        print("|cff00ff00[YATP - ERROR]|r No quest blocks found, aborting reorder to prevent data loss")
        return
    end
    
    -- Clear all lines first
    for i = 1, 50 do
        local line = _G["WatchFrameLine" .. i]
        if line and line.text then
            line.text:SetText("")
            line:Hide()
        end
    end
    
    -- Reassign in sorted order
    local lineIndex = 1
    for _, questInfo in ipairs(questsToSort) do
        local questTitle = questInfo.title  -- Use the original title from quest data
        local questBlock = questBlocks[questTitle]
        
        -- If not found, try alternative keys
        if not questBlock then
            -- Try with level prefix
            local titleWithLevel = "[" .. questInfo.level .. "] " .. questTitle
            questBlock = questBlocks[titleWithLevel]
            
            -- Try finding by partial match
            if not questBlock then
                for blockKey, block in pairs(questBlocks) do
                    if string.find(blockKey, questTitle, 1, true) then
                        questBlock = block
                        print("|cff00ff00[YATP - DEBUG]|r Found block by partial match: '" .. blockKey .. "' for quest '" .. questTitle .. "'")
                        break
                    end
                end
            end
        end
        
        if questBlock then
            print("|cff00ff00[YATP - DEBUG]|r Placing quest: " .. questInfo.title .. " (Complete: " .. tostring(questInfo.isComplete) .. ")")
            for _, lineData in ipairs(questBlock) do
                local line = _G["WatchFrameLine" .. lineIndex]
                if line and line.text then
                    line.text:SetText(lineData.text)
                    line:Show()
                    print("|cff00ff00[YATP - DEBUG]|r  Line " .. lineIndex .. ": " .. lineData.text)
                    lineIndex = lineIndex + 1
                end
            end
        else
            print("|cff00ff00[YATP - DEBUG]|r Warning: No block found for quest: " .. questInfo.title)
            -- Debug: show what blocks we DO have
            print("|cff00ff00[YATP - DEBUG]|r Available blocks:")
            for blockKey, _ in pairs(questBlocks) do
                print("|cff00ff00[YATP - DEBUG]|r   '" .. blockKey .. "'")
            end
        end
    end
    
    print("|cff00ff00[YATP - DEBUG]|r Reordered " .. (lineIndex - 1) .. " lines")
end

-- Helper function to count table entries
function Module:TableCount(t)
    local count = 0
    for _ in pairs(t) do count = count + 1 end
    return count
end

-- Extract quest title from WatchFrame line text
function Module:ExtractQuestTitle(text)
    if not text then return "" end
    
    -- Remove level prefix like "[18] " 
    local title = string.gsub(text, "^%[%d+%]%s*", "")
    
    -- Remove color codes
    title = string.gsub(title, "|c%x%x%x%x%x%x%x%x", "")
    title = string.gsub(title, "|r", "")
    
    return title
end

-- Filter quests to show only current zone
function Module:ApplyZoneFilter()
    local currentZone = GetRealZoneText()
    if not currentZone or currentZone == "" then
        currentZone = GetZoneText() -- Fallback to subzone
    end
    
    if not currentZone or currentZone == "" then return end
    
    local questsToHide = {}
    
    -- Check each watched quest
    for i = 1, GetNumQuestWatches() do
        local questIndex = GetQuestIndexForWatch(i)
        if questIndex then
            local questZone = self:GetQuestZone(questIndex)
            
            -- If quest zone doesn't match current zone, mark for hiding
            if questZone and questZone ~= currentZone then
                table.insert(questsToHide, questIndex)
            end
        end
    end
    
    -- Hide quests not in current zone
    for _, questIndex in ipairs(questsToHide) do
        RemoveQuestWatch(questIndex)
    end
end

-- Get the zone for a specific quest
function Module:GetQuestZone(questIndex)
    -- This is tricky in 3.3.5 as quest zone info isn't readily available
    -- We'll use a simple approach: check quest log for zone headers
    local numEntries = GetNumQuestLogEntries()
    local currentZone = nil
    
    for i = 1, numEntries do
        local questTitle, level, questTag, suggestedGroup, isHeader, isCollapsed, isComplete, isDaily, questID = GetQuestLogTitle(i)
        
        if isHeader then
            currentZone = questTitle
        elseif i == questIndex then
            return currentZone
        end
    end
    
    return nil
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
                
                -- Remove color codes
                newText = string.gsub(newText, "|c%x%x%x%x%x%x%x%x", "")
                newText = string.gsub(newText, "|r", "")
                
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
                        difficultySymbol = "" -- No symbol, only color
                    elseif levelDiff >= 3 then
                        color = "|cffff6600" -- Bright Orange (3-4 niveles arriba)
                        difficultySymbol = "" -- No symbol, only color
                    elseif levelDiff >= -2 then
                        color = "|cffffff00" -- Bright Yellow (-2 a +2 niveles)
                        difficultySymbol = "" -- Normal, no symbol
                    elseif levelDiff >= -10 then
                        color = "|cff00ff00" -- Bright Green (-10 a -3 niveles)
                        difficultySymbol = "" -- Easy, no symbol needed
                    else
                        color = "|cff999999" -- Light Gray (más de -10 niveles)
                        difficultySymbol = "" -- No symbol, only color
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
                        
                        -- Add quest level if enabled
                        if self.db.showQuestLevels then
                            finalText = "[" .. level .. "] " .. finalText
                        end
                        
                        -- Apply color coding if enabled
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
    

    
    isApplyingLevels = false
end

-- Format quest objectives by adding indentation - simplified dash-based approach








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
    
    -- Debug commands
    self:RegisterChatCommand("qtsort", function() 
        print("|cff00ff00[YATP]|r Testing quest sorting...")
        self:EnhanceQuestDisplay() 
    end)
    self:RegisterChatCommand("qtdebug", function() 
        print("|cff00ff00[YATP]|r Quest Tracker Debug Info:")
        print("  Module enabled: " .. tostring(self:IsEnabled()))
        print("  customSorting: " .. tostring(self.db.customSorting))
        print("  sortByLevel: " .. tostring(self.db.sortByLevel))
        print("  filterByZone: " .. tostring(self.db.filterByZone))
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
    self:RegisterEvent("QUEST_COMPLETE", "OnQuestComplete")
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
    
    -- Validate tracking modes - ensure at least one is always enabled
    if not self.db.forceTrackAll and not self.db.autoTrackByZone then
        self.db.autoTrackByZone = true
        self:Print("|cffffd700[YATP]|r Auto-tracking is required. Enabled 'Auto-track by Zone' by default.")
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
        -- Simple scale/alpha check only (these don't interfere with text content)
        if questTrackerFrame:GetScale() ~= self.db.trackerScale then
            questTrackerFrame:SetScale(self.db.trackerScale)
        end
        
        if questTrackerFrame:GetAlpha() ~= self.db.trackerAlpha then
            questTrackerFrame:SetAlpha(self.db.trackerAlpha)
        end
        
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

-- New function to handle automatic quest tracking
function Module:ManageAutoTracking()
    if not self.db.enabled then return end
    
    if self.db.forceTrackAll then
        self:TrackAllQuests()
    elseif self.db.autoTrackByZone then
        self:AutoTrackByCurrentZone()
    end
end

-- Track all quests in quest log
function Module:TrackAllQuests()
    local numEntries = GetNumQuestLogEntries()
    local trackedCount = 0
    local untrackedCount = 0
    
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
            
            -- Determine if we should track this quest
            local shouldTrack = true
            
            -- Skip completed quests if auto-untrack is enabled
            if self.db.autoUntrackComplete and (isComplete == 1 or isComplete == -1) then
                shouldTrack = false
            end
            
            -- Apply tracking logic
            if shouldTrack and not isTracked then
                AddQuestWatch(i)
                trackedCount = trackedCount + 1
                self:Debug("Auto-tracked quest: " .. (questTitle or "Unknown"))
            elseif not shouldTrack and isTracked then
                RemoveQuestWatch(i)
                untrackedCount = untrackedCount + 1
                self:Debug("Auto-untracked completed quest: " .. (questTitle or "Unknown"))
            end
        end
    end
    
    -- Provide user feedback
    local message = "Force Track All: "
    if trackedCount > 0 then
        message = message .. "Added " .. trackedCount .. " quest(s)"
    end
    if untrackedCount > 0 then
        if trackedCount > 0 then message = message .. ", " end
        message = message .. "Removed " .. untrackedCount .. " completed quest(s)"
    end
    if trackedCount == 0 and untrackedCount == 0 then
        message = message .. "No changes needed"
    end
    self:Print(message)
    
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
                local questZone = self:GetQuestZone(i)
                if questZone and questZone == currentZone then
                    shouldTrack = true
                    self:Debug("  -> Marked for tracking: Current zone quest (" .. questZone .. ")")
                end
            end
            
            -- Skip completed quests if auto-untrack is enabled
            if shouldTrack and self.db.autoUntrackComplete and (isComplete == 1 or isComplete == -1) then
                shouldTrack = false
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
    
    -- Provide user feedback
    if #questsToTrack > 0 or #questsToUntrack > 0 then
        local message = "Auto-track by Zone: "
        if #questsToTrack > 0 then
            message = message .. "Added " .. #questsToTrack .. " quest(s)"
        end
        if #questsToUntrack > 0 then
            if #questsToTrack > 0 then message = message .. ", " end
            message = message .. "Removed " .. #questsToUntrack .. " quest(s)"
        end
        message = message .. " (Zone: " .. currentZone .. ")"
        self:Print(message)
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
    
    if self.db.customHeight then
        self:ApplyCustomHeight()
    end
    
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
    
    self:Debug("All enhancements reapplied")
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
                        desc = L["Lock the quest tracker in place. When disabled, you can drag the tracker to move it around."] or "Lock the quest tracker in place. When disabled, you can drag the tracker to move it around.",
                        get=get, set=function(info, val)
                            set(info, val)
                            if self:IsEnabled() then
                                self:ApplyMovableTracker()
                            end
                        end,
                    },
                    textOutline = {
                        type = "toggle", order = 7,
                        name = L["Text Outline"] or "Text Outline",
                        desc = L["Add outline to quest tracker text for better readability."] or "Add outline to quest tracker text for better readability.",
                        get=get, set=set,
                    },
                    outlineThickness = {
                        type = "select", order = 8,
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
                        type = "toggle", order = 9,
                        name = L["Custom Width"] or "Custom Width",
                        desc = L["Enable custom width for the quest tracker frame."] or "Enable custom width for the quest tracker frame.",
                        get=get, set=set,
                    },
                    frameWidth = {
                        type = "range", order = 10,
                        name = L["Frame Width"] or "Frame Width",
                        desc = L["Set the width of the quest tracker frame in pixels."] or "Set the width of the quest tracker frame in pixels.",
                        min = 200, max = 500, step = 10,
                        get=get, set=set,
                        disabled = function() return not self.db.customWidth end,
                    },
                    customHeight = {
                        type = "toggle", order = 11,
                        name = L["Custom Height"] or "Custom Height",
                        desc = L["Enable custom height for the quest tracker frame."] or "Enable custom height for the quest tracker frame.",
                        get=get, set=function(info, val)
                            set(info, val)
                            if self:IsEnabled() then
                                self:ApplyCustomHeight()
                            end
                        end,
                    },
                    frameHeight = {
                        type = "range", order = 12,
                        name = L["Frame Height"] or "Frame Height",
                        desc = L["Set the height of the quest tracker frame in pixels."] or "Set the height of the quest tracker frame in pixels.",
                        min = 300, max = 1000, step = 50,
                        get=get, set=function(info, val)
                            set(info, val)
                            if self:IsEnabled() then
                                self:ApplyCustomHeight()
                            end
                        end,
                        disabled = function() return not self.db.customHeight end,
                    },
                    hideBackground = {
                        type = "toggle", order = 13,
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
                        desc = L["Automatically untrack completed quests. Works with both 'Force Track All' and 'Auto-track by Zone' modes."] or "Automatically untrack completed quests. Works with both 'Force Track All' and 'Auto-track by Zone' modes.",
                        get=get, set=function(info, val)
                            set(info, val)
                            -- Apply changes immediately if one of the auto-tracking modes is active
                            if self:IsEnabled() then
                                if self.db.forceTrackAll then
                                    self:TrackAllQuests()
                                elseif self.db.autoTrackByZone then
                                    self:AutoTrackByCurrentZone()
                                else
                                    -- If no auto-tracking mode is active, just clean completed quests
                                    if val then
                                        local numEntries = GetNumQuestLogEntries()
                                        local untrackedCount = 0
                                        
                                        for i = 1, numEntries do
                                            local questTitle, level, questTag, suggestedGroup, isHeader, isCollapsed, isComplete, isDaily, questID = GetQuestLogTitle(i)
                                            
                                            if not isHeader and questTitle and (isComplete == 1 or isComplete == -1) then
                                                -- Check if quest is being tracked
                                                for j = 1, GetNumQuestWatches() do
                                                    local watchedIndex = GetQuestIndexForWatch(j)
                                                    if watchedIndex == i then
                                                        RemoveQuestWatch(i)
                                                        untrackedCount = untrackedCount + 1
                                                        break
                                                    end
                                                end
                                            end
                                        end
                                        
                                        if untrackedCount > 0 then
                                            self:Print("Auto-untrack Complete: Removed " .. untrackedCount .. " completed quest(s)")
                                            self:ForceQuestTrackerUpdate()
                                        end
                                    end
                                end
                            end
                        end,
                    },
                    maxTrackedQuests = {
                        type = "range", order = 3,
                        name = L["Max Tracked Quests"] or "Max Tracked Quests",
                        desc = L["Maximum number of quests to track simultaneously."] or "Maximum number of quests to track simultaneously.",
                        min = 5, max = 50, step = 1,
                        get=get, set=set,
                    },
                    spacer1 = { type = "description", order = 4, name = "", fontSize = "small" },
                    forceTrackAll = {
                        type = "toggle", order = 5,
                        name = L["Force Track All Quests"] or "Force Track All Quests",
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
                                    -- If Zone tracking is also disabled, prevent disabling this and auto-enable Zone tracking
                                    self.db.autoTrackByZone = true
                                    self:Print("|cffffd700[YATP]|r Auto-tracking is required. Enabled 'Auto-track by Zone' instead.")
                                    if self:IsEnabled() then
                                        self:AutoTrackByCurrentZone()
                                    end
                                end
                                set(info, val)
                            end
                        end,
                    },
                    autoTrackByZone = {
                        type = "toggle", order = 6,
                        name = L["Auto-track by Zone"] or "Auto-track by Zone",
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
                                    -- If Force Track All is also disabled, prevent disabling this and auto-enable Force Track All
                                    self.db.forceTrackAll = true
                                    self:Print("|cffffd700[YATP]|r Auto-tracking is required. Enabled 'Force Track All Quests' instead.")
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
            
            sortingGroup = {
                type = "group", inline = true, order = 50,
                name = L["Quest Sorting"] or "Quest Sorting",
                args = {
                    customSorting = {
                        type = "toggle", order = 1,
                        name = L["Custom Quest Sorting"] or "Custom Quest Sorting",
                        desc = L["Enable custom sorting of tracked quests."] or "Enable custom sorting of tracked quests.",
                        get=get, set=function(info,val) 
                            set(info,val)
                            if self:IsEnabled() then
                                self:EnhanceQuestDisplay()
                            end
                        end,
                    },
                    sortByLevel = {
                        type = "toggle", order = 2,
                        name = L["Sort by Level"] or "Sort by Level",
                        desc = L["Sort quests by level with completed quests at the bottom."] or "Sort quests by level with completed quests at the bottom.",
                        get=get, set=function(info,val) 
                            set(info,val)
                            if self:IsEnabled() then
                                self:EnhanceQuestDisplay()
                            end
                        end,
                        disabled = function() return not self.db.customSorting end,
                    },
                    filterByZone = {
                        type = "toggle", order = 3,
                        name = L["Filter by Zone"] or "Filter by Zone",
                        desc = L["Only show quests for the current zone."] or "Only show quests for the current zone.",
                        get=get, set=function(info,val) 
                            set(info,val)
                            if self:IsEnabled() then
                                self:EnhanceQuestDisplay()
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
        print("Indent Objectives: " .. tostring(module.db.indentObjectives))
        
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