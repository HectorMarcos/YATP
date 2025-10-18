--========================================================--
-- YATP - NamePlates Module
--========================================================--
-- This module provides configuration interface for the Ascension NamePlates addon
-- through YATP's interface hub system.

local L = LibStub("AceLocale-3.0"):GetLocale("YATP", true) or setmetatable({}, { __index=function(_,k) return k end })
local YATP = LibStub("AceAddon-3.0"):GetAddon("YATP", true)
if not YATP then
    return
end

local Module = YATP:NewModule("NamePlates", "AceEvent-3.0", "AceConsole-3.0")

-------------------------------------------------
-- Defaults
-------------------------------------------------
Module.defaults = {
    enabled = true,
    autoLoadNamePlates = true, -- Auto-load Ascension_NamePlates on startup/reload if it's enabled
    autoOpenNameplatesConfig = false, -- Si abrir automáticamente la config de nameplates
    
    -- Global Health Bar Texture Override
    globalHealthBarTexture = {
        enabled = false,
        texture = "Blizzard2", -- Default texture name from SharedMedia
    },
    
    -- Health Text Positioning
    healthTextPosition = {
        enabled = false, -- Enable custom health text positioning
        offsetX = 0,     -- Horizontal offset from center
        offsetY = 1,     -- Vertical offset from center (default: 1)
    },
    
    -- Mouseover Glow Configuration
    mouseoverGlow = {
        enabled = false, -- Disable mouseover glow globally
        disableOnTarget = true, -- Disable mouseover glow on current target
        intensity = 0.8, -- Glow intensity (0.1 to 1.0)
        hideBorder = true, -- Hide mouseover border
    },
    
    -- Mouseover Border Glow Block (Always ON - blocks the border color change on mouseover)
    -- This feature is always enabled and uses a fixed black color (0, 0, 0, 1)
    blockMouseoverBorderGlow = {
        enabled = true, -- Always enabled
        keepOriginalColor = false, -- Use custom color (black)
        customColor = {0, 0, 0, 1}, -- Fixed black color (RGBA)
    },
    
    -- Mouseover Health Bar Highlight (subtle color change on non-target nameplates)
    mouseoverHealthBarHighlight = {
        enabled = true, -- Enable mouseover highlight on health bars
        tintAmount = 0.5, -- Fixed tint amount: mix 50% white for visibility
    },
    
    -- Enemy Target specific options (legacy - will be cleaned up)
    highlightEnemyTarget = false,
    highlightColor = {1, 1, 0, 0.8}, -- Yellow with 80% opacity
    enhancedTargetBorder = false,
    alwaysShowTargetHealth = false,
    targetHealthFormat = "inherit",
    
    -- Target Border System
    targetGlow = {
        enabled = true,
        color = {1, 1, 0, 0.6}, -- Yellow with 60% opacity
        size = 2, -- Border thickness in pixels
    },
    
    -- Target Arrows System
    targetArrows = {
        enabled = false,
        size = 32, -- Arrow size in pixels
        offsetX = 15, -- Horizontal distance from nameplate edges
        offsetY = 0, -- Vertical offset from nameplate center
        color = {1, 1, 1, 1}, -- White with full opacity (tints the texture)
    },
    
    -- Black Border System (All Nameplates)
    blackBorder = {
        enabled = true,
        thickness = 1, -- Border thickness in pixels (fixed, not configurable)
        color = {0, 0, 0, 1}, -- RGBA: Black with full opacity
    },
    
    -- Threat System
    threatSystem = {
        enabled = true,
        method = "healthcolor", -- Only use health bar color
        colors = {
            none = {0.5, 0.5, 0.5, 1.0},     -- Gray - no threat
            low = {1.0, 1.0, 0.0, 1.0},      -- Yellow - low threat
            medium = {1.0, 0.5, 0.0, 1.0},   -- Orange - medium threat  
            high = {1.0, 0.0, 0.0, 1.0},     -- Red - high threat
            tanking = {0.5, 0.0, 1.0, 1.0},  -- Purple - you have aggro
        }
    },
    
    -- Non-Target Alpha Fade System
    nonTargetAlpha = {
        enabled = false,
        alpha = 0.5, -- Alpha value for non-target nameplates (0.0 to 1.0)
        outOfCombatAlpha = 0.3, -- Alpha value for non-target nameplates NOT in combat with you (0.0 to 1.0)
    },
    
    -- Quest Icon System
    questIcons = {
        enabled = true,
        size = 24, -- Icon size in pixels
        position = "TOP", -- TOP, BOTTOM, LEFT, RIGHT
        offsetX = 0,
        offsetY = 8,
    },
}

-------------------------------------------------
-- State Variables
-------------------------------------------------
-- Track nameplates by unitID for quest icon system
Module.questTrackedUnits = {}

-- Track nameplate frames by their ID (nameplate1, nameplate2, etc.)
Module.nameplateFrames = {}

-- Hidden tooltip for scanning quest objectives without mouseover
Module.questScanTooltip = nil

-------------------------------------------------
-- OnInitialize
-------------------------------------------------
function Module:OnInitialize()
    self.db = YATP.db:RegisterNamespace("NamePlates", { profile = Module.defaults })
    
    -- Create hidden tooltip for quest scanning
    self.questScanTooltip = CreateFrame("GameTooltip", "YATPQuestScanTooltip", nil, "GameTooltipTemplate")
    self.questScanTooltip:SetOwner(WorldFrame, "ANCHOR_NONE")
end

-------------------------------------------------
-- OnEnable
-------------------------------------------------
function Module:OnEnable()
    -- AUTO-LOAD: Try to load Ascension_NamePlates if it's enabled but not loaded
    self:AutoLoadAscensionNamePlates()
    
    -- Register for addon loading events to detect when Ascension NamePlates loads
    self:RegisterEvent("ADDON_LOADED", "OnAddonLoaded")
    
    -- Always register the module options so the toggle is available
    -- Register this module as its own category (not under Interface Hub)
    local AceConfig = LibStub("AceConfig-3.0")
    local AceConfigDialog = LibStub("AceConfigDialog-3.0")
    
    if AceConfig and AceConfigDialog then
        -- Create the main NamePlates category with childGroups = "tab"
        local namePlatesOptions = {
            type = "group",
            name = L["NamePlates"] or "NamePlates",
            childGroups = "tab",
            args = self:BuildTabStructure()
        }
        
        -- Register as a separate category under YATP main panel
        AceConfig:RegisterOptionsTable("YATP-NamePlates", namePlatesOptions)
        AceConfigDialog:AddToBlizOptions("YATP-NamePlates", L["NamePlates"] or "NamePlates", "YATP")
    else
        -- AceConfig not available - silent fallback
    end
    
    -- Only initialize functionality if enabled
    if not self.db.profile.enabled then
        return
    end
    
    -- Register core nameplate events (needed for compatibility)
    self:RegisterEvent("NAME_PLATE_UNIT_ADDED", "OnNamePlateAdded")
    self:RegisterEvent("NAME_PLATE_UNIT_REMOVED", "OnNamePlateRemoved")
    
    -- Register to Ascension_NamePlates custom events
    if EventRegistry then
        local module = self
        
        EventRegistry:RegisterCallback("NamePlateManager.UnitAdded", function(unit, nameplateID)
            module:OnNamePlateAdded(unit, nameplateID, nil)
        end)
        
        EventRegistry:RegisterCallback("NamePlateManager.UnitRemoved", function(unit, nameplate)
            module:OnNamePlateRemoved(unit, nameplate)
        end)
        
        -- Register callback for when nameplate frames are created
        EventRegistry:RegisterCallback("NamePlateDriver.UnitFrameCreated", function(...)
            local nameplateFrame = select(2, ...)
            
            if nameplateFrame then
                -- Store frame by _unit identifier ("nameplate1", "nameplate2", etc.)
                local nameplateID = nameplateFrame._unit
                if nameplateID then
                    module.nameplateFrames[nameplateID] = nameplateFrame
                end
                
                -- Also store by UnitFrame.unit when available
                if nameplateFrame.UnitFrame and nameplateFrame.UnitFrame.unit then
                    local unitID = nameplateFrame.UnitFrame.unit
                    module.nameplateFrames[unitID] = nameplateFrame
                end
                
                module:OnAscensionNamePlateCreated(nameplateFrame)
            end
        end)
    end
    
    -- Setup mouseover functionality
    self:SetupMouseoverGlow()
    self:SetupMouseoverBorderBlock()
    self:SetupMouseoverHealthBarHighlight()
    self:SetupQuestIcons()
    self:DisableAllNameplateGlows()
    
    -- Setup black borders for all nameplates
    self:SetupBlackBorders()
    
    -- Setup everything after a longer delay to ensure all addons are loaded
    C_Timer.After(2.0, function()
        self:CheckNamePlatesAddon()
        self:SetupThreatSystem()
    end)
    
    -- Apply global health bar texture if enabled
    self:ApplyGlobalHealthBarTexture()
    
    -- Setup health text positioning if enabled
    self:SetupHealthTextPositioning()
    
    -- Setup non-target alpha fade if enabled
    self:SetupNonTargetAlpha()
end

-------------------------------------------------
-- OnDisable
-------------------------------------------------
function Module:OnDisable()
    -- Clean up active functionality but keep module registered
    self:CleanupThreatSystem()
    self:CleanupHealthTextPositioning()
    self:CleanupNonTargetAlpha()
    self:CleanupMouseoverBorderBlock()
    self:CleanupMouseoverHealthBarHighlight()
    self:UnblockAllBorderGlows()
    
    -- Restore original C_NamePlateManager.UpdateAll if we hooked it
    if self.originalUpdateAll and C_NamePlateManager then
        C_NamePlateManager.UpdateAll = self.originalUpdateAll
        self.originalUpdateAll = nil
    end
    
    -- Stop glow disable timer
    if self.glowDisableTimer then
        self.glowDisableTimer:Cancel()
        self.glowDisableTimer = nil
    end
    
    -- Stop alpha fade OnUpdate frame (safety check)
    if self.alphaFadeUpdateFrame then
        self.alphaFadeUpdateFrame:Hide()
        self.alphaFadeUpdateFrame:SetScript("OnUpdate", nil)
    end
    
    -- Unregister events but don't unregister from options
end

function Module:OnAddonLoaded(event, addonName)
    if addonName == "Ascension_NamePlates" then
        -- Give it a small delay to ensure it's fully initialized
        C_Timer.After(1.0, function()
            self:SetupThreatSystem()
        end)
    end
end

-------------------------------------------------
-- Target Border System
-------------------------------------------------
-------------------------------------------------
-- Quest Icon System
-------------------------------------------------

-- Scan unit's tooltip to detect quest objectives
-- Returns true if unit is a quest objective that is NOT complete
function Module:ScanUnitForQuest(unitID)
    if not unitID or not UnitExists(unitID) then
        return false
    end
    
    if not self.questScanTooltip then
        return false
    end
    
    self.questScanTooltip:ClearLines()
    self.questScanTooltip:SetUnit(unitID)
    
    local numLines = self.questScanTooltip:NumLines()
    
    -- Look for quest progress lines (examples: " - Salty Scorpid Venom: 0/6", "Kill count: 5/10")
    for i = 1, numLines do
        local leftText = _G["YATPQuestScanTooltipTextLeft" .. i]
        if leftText then
            local text = leftText:GetText()
            if text then
                -- Check if line contains quest progress pattern (e.g., "6/6" or "0/10")
                local current, total = text:match("(%d+)/(%d+)")
                if current and total then
                    current = tonumber(current)
                    total = tonumber(total)
                    
                    -- Show icon if quest is NOT complete (current != total)
                    -- Hide icon if quest is complete (current >= total)
                    if current >= total then
                        return false  -- Quest complete, hide icon
                    else
                        return true   -- Quest incomplete, show icon
                    end
                end
            end
        end
    end
    
    return false  -- No quest pattern found, hide icon
end

-- Create quest icon on a nameplate
function Module:CreateQuestIcon(nameplate)
    if not nameplate or not nameplate.UnitFrame then
        return
    end
    
    local frame = nameplate.UnitFrame
    
    -- Don't create if already exists
    if frame.YATPQuestIcon then
        return
    end
    
    -- Create container frame with proper parent and strata
    frame.YATPQuestIcon = CreateFrame("Frame", nil, frame)
    local qi = frame.YATPQuestIcon
    
    -- CRITICAL: Hide immediately BEFORE setting any geometry to prevent visual flash
    qi:Hide()
    
    qi:SetFrameStrata("HIGH")
    qi:SetFrameLevel(frame:GetFrameLevel() + 10)
    
    -- Create icon texture
    qi.icon = qi:CreateTexture(nil, "OVERLAY")
    qi.icon:SetTexture("Interface\\AddOns\\YATP\\media\\questionmark")
    qi.icon:SetAllPoints(qi)
    
    -- Size and position will be set by UpdateQuestIcon when quest is detected
end

-- Update quest icon size and position based on config
function Module:UpdateQuestIconSize(nameplate)
    if not nameplate or not nameplate.UnitFrame or not nameplate.UnitFrame.YATPQuestIcon then
        return
    end
    
    local qi = nameplate.UnitFrame.YATPQuestIcon
    local config = self.db.profile.questIcons
    
    -- Set size
    qi:SetSize(config.size, config.size)
    
    -- Position relative to health bar
    local healthBar = nameplate.UnitFrame.healthBar
    if not healthBar then
        return
    end
    
    qi:ClearAllPoints()
    if config.position == "TOP" then
        qi:SetPoint("BOTTOM", healthBar, "TOP", config.offsetX, config.offsetY)
    elseif config.position == "BOTTOM" then
        qi:SetPoint("TOP", healthBar, "BOTTOM", config.offsetX, -config.offsetY)
    elseif config.position == "LEFT" then
        qi:SetPoint("RIGHT", healthBar, "LEFT", -config.offsetX, config.offsetY)
    elseif config.position == "RIGHT" then
        qi:SetPoint("LEFT", healthBar, "RIGHT", config.offsetX, config.offsetY)
    end
end

-- Update quest icon visibility for a specific nameplate
function Module:UpdateQuestIcon(nameplate)
    if not self.db.profile.questIcons.enabled then
        return
    end
    
    if not nameplate or not nameplate.UnitFrame then
        return
    end
    
    local frame = nameplate.UnitFrame
    
    -- Create quest icon if it doesn't exist
    if not frame.YATPQuestIcon then
        self:CreateQuestIcon(nameplate)
    end
    
    local qi = frame.YATPQuestIcon
    if not qi then
        return
    end
    
    -- Get the actual unit ID for this nameplate
    local unitID = frame.unit
    if not unitID or not UnitExists(unitID) then
        qi:Hide()
        return
    end
    
    -- ALWAYS re-scan the tooltip in real-time (don't trust cache)
    -- This ensures we catch quest completions and changes immediately
    local hasQuest = self:ScanUnitForQuest(unitID)
    
    -- Show/hide icon based on current scan
    if hasQuest then
        -- Quest is incomplete, update size/position and show
        self:UpdateQuestIconSize(nameplate)
        qi:Show()
    else
        -- Quest is complete or not a quest objective, hide immediately
        -- Don't call UpdateQuestIconSize to avoid visual flash
        qi:Hide()
    end
end

-- Control quest icons from Ascension_NamePlates system
-- Alpha: 0 = hide (when using custom icons), 1 = show (when using native icons)
function Module:SetNativeQuestIconAlpha(nameplate, alpha)
    if not nameplate or not nameplate.UnitFrame then
        return
    end
    
    local frame = nameplate.UnitFrame
    
    -- The quest icon is stored as frame.questIcon (see NamePlateTemplates.xml)
    if frame.questIcon then
        frame.questIcon:SetAlpha(alpha)
    end
end

-- Update all native quest icon alphas based on custom quest icon setting
function Module:UpdateAllNativeQuestIconAlphas()
    -- If custom quest icons are enabled, hide native icons (alpha 0)
    -- If custom quest icons are disabled, show native icons (alpha 1)
    local alpha = self.db.profile.questIcons.enabled and 0 or 1
    
    for nameplate in C_NamePlateManager.EnumerateActiveNamePlates() do
        self:SetNativeQuestIconAlpha(nameplate, alpha)
    end
end

function Module:OnAscensionNamePlateCreated(nameplate)
    if not self.db.profile.enabled then 
        return 
    end
    
    -- Setup mouseover health bar highlight for this nameplate
    self:SetupMouseoverHealthBarForNameplate(nameplate)
    
    -- Add black border to all nameplates (target borders handled by targetindicators module)
    self:AddCustomBorder(nameplate)
    
    -- NOTE: Quest icon setup is handled in OnNamePlateAdded with a delay
    -- because UnitFrame may not be ready at this point
end

function Module:OnNamePlateAdded(unit, nameplateID, nameplateFrame)
    -- Note: In Ascension's callback, 'unit' is a number and 'nameplateID' is the unitID string (nameplate1, nameplate2, etc.)
    local unitID = type(nameplateID) == "string" and nameplateID or tostring(nameplateID)
    
    if not self.db.profile.enabled then 
        return 
    end
    
    -- Try to get the nameplate frame from our stored cache
    local frame = self.nameplateFrames[unitID] or nameplateFrame
    
    if not frame then
        -- Retry after a delay
        C_Timer.After(0.2, function()
            frame = self.nameplateFrames[unitID]
            if frame then
                self:ProcessNamePlateForQuests(unitID, frame)
            end
        end)
        return
    end
    
    -- Wait a bit for UnitFrame to be fully set up
    C_Timer.After(0.15, function()
        self:ProcessNamePlateForQuests(unitID, frame)
    end)
end

-- Process a nameplate for quest icons and hook scale changes
function Module:ProcessNamePlateForQuests(unitID, nameplateFrame)
    if not nameplateFrame or not nameplateFrame.UnitFrame then
        return
    end
    
    -- Set native quest icons alpha based on our custom quest icon setting
    local alpha = self.db.profile.questIcons.enabled and 0 or 1
    self:SetNativeQuestIconAlpha(nameplateFrame, alpha)
    
    -- Create custom quest icon if it doesn't exist
    if self.db.profile.questIcons.enabled and not nameplateFrame.UnitFrame.YATPQuestIcon then
        self:CreateQuestIcon(nameplateFrame)
    end
    
    -- Update quest icon for this nameplate (will scan tooltip in real-time)
    if self.db.profile.questIcons.enabled then
        self:UpdateQuestIcon(nameplateFrame)
    end
    
end

function Module:OnNamePlateRemoved(unit, nameplate)
    -- Note: Custom borders are NOT removed when nameplate is removed
    -- They will be reused when the nameplate is recycled
    -- WoW recycles nameplate frames for performance
    
    -- Clean up quest icon if this nameplate had one
    if nameplate and nameplate.UnitFrame and nameplate.UnitFrame.YATPQuestIcon then
        nameplate.UnitFrame.YATPQuestIcon:Hide()
    end
    
    -- Clean up quest tracking data
    if unit and self.questTrackedUnits then
        self.questTrackedUnits[unit] = nil
    end
    
    -- Note: Target arrows and borders are handled by the SetScale hook
    -- They will be automatically cleaned up when scale returns to 1.0
end



-------------------------------------------------
-- Quest Icon Event Handlers
-------------------------------------------------

-- Setup quest icon system
function Module:SetupQuestIcons()
    if not self.db.profile.enabled then
        return
    end
    
    if not self.db.profile.questIcons.enabled then
        return
    end
    
    -- Hide native quest icons (alpha 0) and create custom icons on all existing nameplates
    for nameplate in C_NamePlateManager.EnumerateActiveNamePlates() do
        if nameplate.UnitFrame then
            self:SetNativeQuestIconAlpha(nameplate, 0)
            self:CreateQuestIcon(nameplate)
            self:UpdateQuestIcon(nameplate)
        end
    end
    
    -- Create periodic update frame to refresh quest icons
    -- This catches quest completions and changes in real-time
    if not self.questIconUpdateFrame then
        self.questIconUpdateFrame = CreateFrame("Frame")
        self.questIconUpdateFrame:SetScript("OnUpdate", function(frame, elapsed)
            frame.timeSinceLastUpdate = (frame.timeSinceLastUpdate or 0) + elapsed
            
            -- Update every 0.5 seconds (balance between responsiveness and performance)
            if frame.timeSinceLastUpdate >= 0.5 then
                frame.timeSinceLastUpdate = 0
                
                -- Update all visible nameplates
                if Module.db.profile.questIcons.enabled then
                    for nameplate in C_NamePlateManager.EnumerateActiveNamePlates() do
                        if nameplate.UnitFrame and nameplate.UnitFrame.YATPQuestIcon then
                            Module:UpdateQuestIcon(nameplate)
                        end
                    end
                end
            end
        end)
    end
end

-- Cleanup quest icon system
function Module:CleanupQuestIcons()
    -- Stop periodic updates
    if self.questIconUpdateFrame then
        self.questIconUpdateFrame:SetScript("OnUpdate", nil)
    end
    
    -- Hide all custom quest icons
    for nameplate in C_NamePlateManager.EnumerateActiveNamePlates() do
        if nameplate.UnitFrame then
            -- Hide custom quest icon
            if nameplate.UnitFrame.YATPQuestIcon then
                nameplate.UnitFrame.YATPQuestIcon:Hide()
            end
            -- Show native quest icons (alpha 1)
            self:SetNativeQuestIconAlpha(nameplate, 1)
        end
    end
    
    -- Clear tracked units (though we don't use cache anymore)
    self.questTrackedUnits = {}
end

-------------------------------------------------
-- Custom Border System (All Nameplates)
-------------------------------------------------

-- Create or update custom border for a nameplate
-- All nameplates get a black border by default
-- All nameplates get black borders (target borders handled by targetindicators module)
function Module:AddCustomBorder(nameplate)
    if not nameplate or not nameplate.UnitFrame then 
        return 
    end
    
    -- Check if black borders are enabled
    if not self.db.profile.blackBorder or not self.db.profile.blackBorder.enabled then
        return
    end
    
    local healthBar = nameplate.UnitFrame.healthBar
    if not healthBar then 
        return 
    end
    
    -- All nameplates get black borders
    local borderThickness = self.db.profile.blackBorder.thickness or 1
    local borderColor = self.db.profile.blackBorder.color or {0, 0, 0, 1}
    
    -- If border already exists, update its color
    if self.targetGlowFrames and self.targetGlowFrames[nameplate] then
        local borderData = self.targetGlowFrames[nameplate]
        if borderData.borders then
            borderData.borders.top:SetColorTexture(borderColor[1], borderColor[2], borderColor[3], borderColor[4])
            borderData.borders.bottom:SetColorTexture(borderColor[1], borderColor[2], borderColor[3], borderColor[4])
            borderData.borders.left:SetColorTexture(borderColor[1], borderColor[2], borderColor[3], borderColor[4])
            borderData.borders.right:SetColorTexture(borderColor[1], borderColor[2], borderColor[3], borderColor[4])
        end
        return
    end
    
    -- Create new border frame (parent to nameplate.UnitFrame to inherit alpha)
    local borderFrame = CreateFrame("Frame", nil, nameplate.UnitFrame)
    borderFrame:SetFrameLevel(healthBar:GetFrameLevel())  -- Same level as healthBar, textures below statusText
    
    -- Top border (extends to cover corners) - BACKGROUND layer to be below target border
    local topBorder = borderFrame:CreateTexture(nil, "BACKGROUND")
    topBorder:SetColorTexture(borderColor[1], borderColor[2], borderColor[3], borderColor[4])
    topBorder:SetPoint("TOPLEFT", healthBar, "TOPLEFT", -borderThickness, borderThickness)
    topBorder:SetPoint("TOPRIGHT", healthBar, "TOPRIGHT", borderThickness, borderThickness)
    topBorder:SetHeight(borderThickness)
    
    -- Bottom border (extends to cover corners)
    local bottomBorder = borderFrame:CreateTexture(nil, "BACKGROUND")
    bottomBorder:SetColorTexture(borderColor[1], borderColor[2], borderColor[3], borderColor[4])
    bottomBorder:SetPoint("BOTTOMLEFT", healthBar, "BOTTOMLEFT", -borderThickness, -borderThickness)
    bottomBorder:SetPoint("BOTTOMRIGHT", healthBar, "BOTTOMRIGHT", borderThickness, -borderThickness)
    bottomBorder:SetHeight(borderThickness)
    
    -- Left border (only vertical part, no corners)
    local leftBorder = borderFrame:CreateTexture(nil, "BACKGROUND")
    leftBorder:SetColorTexture(borderColor[1], borderColor[2], borderColor[3], borderColor[4])
    leftBorder:SetPoint("TOPLEFT", healthBar, "TOPLEFT", -borderThickness, 0)
    leftBorder:SetPoint("BOTTOMLEFT", healthBar, "BOTTOMLEFT", -borderThickness, 0)
    leftBorder:SetWidth(borderThickness)
    
    -- Right border (only vertical part, no corners)
    local rightBorder = borderFrame:CreateTexture(nil, "BACKGROUND")
    rightBorder:SetColorTexture(borderColor[1], borderColor[2], borderColor[3], borderColor[4])
    rightBorder:SetPoint("TOPRIGHT", healthBar, "TOPRIGHT", borderThickness, 0)
    rightBorder:SetPoint("BOTTOMRIGHT", healthBar, "BOTTOMRIGHT", borderThickness, 0)
    rightBorder:SetWidth(borderThickness)
    
    -- Store border data
    if not self.targetGlowFrames then
        self.targetGlowFrames = {}
    end
    
    self.targetGlowFrames[nameplate] = {
        borderFrame = borderFrame,
        borders = {
            top = topBorder,
            bottom = bottomBorder,
            left = leftBorder,
            right = rightBorder
        }
    }
end

-- Setup black borders for all existing nameplates
function Module:SetupBlackBorders()
    if not self.db.profile.enabled then 
        return 
    end
    
    -- Add borders to already existing nameplates
    C_Timer.After(0.5, function()
        for nameplate in C_NamePlateManager.EnumerateActiveNamePlates() do
            if nameplate.UnitFrame then
                self:AddCustomBorder(nameplate)
            end
        end
    end)
end

-- Legacy function name for compatibility
function Module:AddTargetGlow(nameplate)
    self:AddCustomBorder(nameplate)
end

function Module:RemoveTargetGlow(nameplate)
    -- Legacy function - kept for compatibility
    -- Borders are no longer removed, just color-updated
    -- This function is now a no-op
end

-------------------------------------------------
-- Target Arrows System
-------------------------------------------------
-------------------------------------------------
-- Mouseover Glow System
-------------------------------------------------
function Module:SetupMouseoverGlow()
    if not self.db.profile.enabled then return end
    
    -- Hook into nameplate creation to control selectionHighlight
    self:SetupSelectionHighlightHooks()
end

-------------------------------------------------
-- Selection Highlight System
-------------------------------------------------

function Module:SetupSelectionHighlightHooks()
    -- Hook nameplate updates to control selectionHighlight
    self:RegisterEvent("UPDATE_MOUSEOVER_UNIT", "OnMouseoverUpdate")
    
    -- Hook into nameplate frame updates (use global hook instead of SecureHook)
    if C_NamePlateManager then
        -- Store original function for cleanup
        if not self.originalUpdateAll and C_NamePlateManager.UpdateAll then
            self.originalUpdateAll = C_NamePlateManager.UpdateAll
            
            -- Replace with hooked version
            C_NamePlateManager.UpdateAll = function(...)
                local result = self.originalUpdateAll(...)
                self:OnNamePlateUpdate()
                return result
            end
        end
    end
end

function Module:OnMouseoverUpdate()
    if not self.db.profile.mouseoverGlow.enabled then return end
    
    -- Control selection highlight on all nameplates
    for nameplate in C_NamePlateManager.EnumerateActiveNamePlates() do
        if nameplate.UnitFrame then
            self:UpdateNamePlateSelectionHighlight(nameplate.UnitFrame)
        end
    end
end

function Module:UpdateNamePlateSelectionHighlight(unitFrame)
    if not unitFrame or not unitFrame.selectionHighlight then return end
    
    local unit = unitFrame.unit
    if not unit then return end
    
    local isMouseover = UnitIsUnit(unit, "mouseover")
    local isTarget = UnitIsUnit(unit, "target")
    
    -- Control visibility based on settings
    if self.db.profile.mouseoverGlow.enabled then
        if isMouseover and not (isTarget and self.db.profile.mouseoverGlow.disableOnTarget) then
            -- Show selection highlight with custom intensity
            unitFrame.selectionHighlight:SetAlpha(self.db.profile.mouseoverGlow.intensity * 0.25)
            unitFrame.selectionHighlight:Show()
        else
            unitFrame.selectionHighlight:Hide()
        end
    else
        -- Disable entirely
        unitFrame.selectionHighlight:Hide()
    end
    
    -- Control border visibility
    if unitFrame.healthBar and unitFrame.healthBar.border then
        if self.db.profile.mouseoverGlow.hideBorder and isMouseover then
            unitFrame.healthBar.border:SetAlpha(0)
        else
            unitFrame.healthBar.border:SetAlpha(1)
        end
    end
end

function Module:OnNamePlateUpdate()
    -- Update all nameplate highlights when nameplates refresh
    self:OnMouseoverUpdate()
end

function Module:UpdateMouseoverGlowSettings()
    -- Update all nameplate selection highlights immediately
    self:OnMouseoverUpdate()
end

-------------------------------------------------
-- Mouseover Health Bar Highlight System
-- Provides subtle visual feedback when mousing over non-target nameplates
-------------------------------------------------

function Module:SetupMouseoverHealthBarHighlight()
    if not self.db.profile.enabled or not self.db.profile.mouseoverHealthBarHighlight.enabled then
        return
    end
    
    -- Initialize tracking
    self.mouseoverHealthBarData = {}
    
    -- Register mouseover event
    self:RegisterEvent("UPDATE_MOUSEOVER_UNIT", "OnHealthBarMouseoverUpdate")
    
    -- Create OnUpdate frame to maintain colors every frame
    if not self.mouseoverUpdateFrame then
        self.mouseoverUpdateFrame = CreateFrame("Frame")
        self.mouseoverUpdateFrame:SetScript("OnUpdate", function()
            if self.db.profile.mouseoverHealthBarHighlight.enabled then
                self:MaintainMouseoverColors()
            end
        end)
    end
    self.mouseoverUpdateFrame:Show()
    
    -- Process existing nameplates
    C_Timer.After(0.5, function()
        for nameplate in C_NamePlateManager.EnumerateActiveNamePlates() do
            if nameplate.UnitFrame then
                self:SetupMouseoverHealthBarForNameplate(nameplate)
            end
        end
    end)
end

function Module:CleanupMouseoverHealthBarHighlight()
    -- Hide OnUpdate frame
    if self.mouseoverUpdateFrame then
        self.mouseoverUpdateFrame:Hide()
        self.mouseoverUpdateFrame:SetScript("OnUpdate", nil)
    end
    
    -- Restore all health bar colors
    if self.mouseoverHealthBarData then
        for nameplate, data in pairs(self.mouseoverHealthBarData) do
            if data.originalColor then
                self:RestoreHealthBarColor(nameplate, data.originalColor)
            end
        end
        self.mouseoverHealthBarData = {}
    end
    
    -- Unregister event
    self:UnregisterEvent("UPDATE_MOUSEOVER_UNIT")
end

function Module:MaintainMouseoverColors()
    -- This runs every frame to maintain mouseover colors and prevent overwrites
    if not self.mouseoverHealthBarData then
        return
    end
    
    for nameplate, data in pairs(self.mouseoverHealthBarData) do
        if data.isMouseover and data.highlightColor and nameplate.UnitFrame and nameplate.UnitFrame.healthBar then
            local unit = nameplate.UnitFrame.unit
            if not unit then
                -- No unit, clear highlight
                data.highlightColor = nil
                data.isMouseover = false
                if data.originalColor then
                    self:RestoreHealthBarColor(nameplate, data.originalColor)
                    data.originalColor = nil
                end
                return
            end
            
            -- Verify this unit still has mouseover
            local stillMouseover = UnitIsUnit(unit, "mouseover") == 1
            
            if not stillMouseover then
                -- Lost mouseover - restore original color
                data.highlightColor = nil
                data.isMouseover = false
                
                if data.originalColor then
                    self:RestoreHealthBarColor(nameplate, data.originalColor)
                    data.originalColor = nil
                end
            else
                -- Still has mouseover, maintain the highlight color
                local healthBar = nameplate.UnitFrame.healthBar
                local color = data.highlightColor
                
                -- Re-apply the highlight color every frame
                healthBar:SetStatusBarColor(color[1], color[2], color[3], color[4])
                
                -- Also to texture
                local texture = healthBar:GetStatusBarTexture()
                if texture then
                    texture:SetVertexColor(color[1], color[2], color[3], color[4])
                end
            end
        end
    end
end

function Module:SetupMouseoverHealthBarForNameplate(nameplate)
    if not nameplate or not nameplate.UnitFrame or not nameplate.UnitFrame.healthBar then
        return
    end
    
    if not self.mouseoverHealthBarData then
        self.mouseoverHealthBarData = {}
    end
    
    self.mouseoverHealthBarData[nameplate] = {
        originalColor = nil,
        isMouseover = false,
    }
end

function Module:OnHealthBarMouseoverUpdate()
    if not self.db.profile.mouseoverHealthBarHighlight.enabled then
        return
    end
    
    for nameplate in C_NamePlateManager.EnumerateActiveNamePlates() do
        if nameplate.UnitFrame then
            self:UpdateMouseoverHealthBar(nameplate)
        end
    end
end

function Module:UpdateMouseoverHealthBar(nameplate)
    if not nameplate or not nameplate.UnitFrame or not nameplate.UnitFrame.healthBar then
        return
    end
    
    local unit = nameplate.UnitFrame.unit
    if not unit then
        return
    end
    
    -- Check if this is the mouseover unit (handle nil as false)
    local isMouseover = UnitIsUnit(unit, "mouseover") == 1
    local unitName = UnitName(unit) or "Unknown"
    
    -- print(string.format("[YATP Mouseover] Unit: %s, IsMouseover: %s", unitName, tostring(isMouseover)))
    
    -- CRITICAL: Don't highlight if this is the target
    if UnitExists("target") and UnitIsUnit(unit, "target") then
        -- Ensure we restore color if it was previously moused over
        if self.mouseoverHealthBarData and self.mouseoverHealthBarData[nameplate] and 
           self.mouseoverHealthBarData[nameplate].isMouseover then
            self:RestoreHealthBarColorIfStored(nameplate)
            self.mouseoverHealthBarData[nameplate].isMouseover = false
        end
        return
    end
    
    -- Initialize data structure if needed
    if not self.mouseoverHealthBarData then
        self.mouseoverHealthBarData = {}
    end
    if not self.mouseoverHealthBarData[nameplate] then
        self.mouseoverHealthBarData[nameplate] = {
            originalColor = nil,
            isMouseover = false,
        }
    end
    
    local data = self.mouseoverHealthBarData[nameplate]
    
    if isMouseover and not data.isMouseover then
        -- Just became mouseover
        self:ApplyMouseoverHealthBarHighlight(nameplate)
        data.isMouseover = true
    elseif not isMouseover and data.isMouseover then
        -- No longer mouseover
        data.highlightColor = nil
        self:RestoreHealthBarColorIfStored(nameplate)
        data.isMouseover = false
    end
end

function Module:ApplyMouseoverHealthBarHighlight(nameplate)
    if not nameplate or not nameplate.UnitFrame or not nameplate.UnitFrame.healthBar then
        return
    end
    
    local healthBar = nameplate.UnitFrame.healthBar
    
    -- Get current color
    local r, g, b, a = healthBar:GetStatusBarColor()
    
    -- Store original color
    if not self.mouseoverHealthBarData[nameplate] then
        self.mouseoverHealthBarData[nameplate] = {}
    end
    self.mouseoverHealthBarData[nameplate].originalColor = {r, g, b, a}
    
    -- Apply tint with white
    local tintAmount = self.db.profile.mouseoverHealthBarHighlight.tintAmount or 0.5
    local newR, newG, newB, newA = self:ApplyWhiteTint(r, g, b, a, tintAmount)
    
    -- Store the highlight color for maintenance
    self.mouseoverHealthBarData[nameplate].highlightColor = {newR, newG, newB, newA}
    
    -- Apply new color
    healthBar:SetStatusBarColor(newR, newG, newB, newA)
    
    -- Also apply to texture
    local texture = healthBar:GetStatusBarTexture()
    if texture then
        texture:SetVertexColor(newR, newG, newB, newA)
    end
end

function Module:RestoreHealthBarColorIfStored(nameplate)
    if not nameplate or not self.mouseoverHealthBarData or not self.mouseoverHealthBarData[nameplate] then
        return
    end
    
    local data = self.mouseoverHealthBarData[nameplate]
    if data.originalColor then
        self:RestoreHealthBarColor(nameplate, data.originalColor)
        data.originalColor = nil
        
        -- Re-apply threat colors if enabled
        if self.db.profile.threatSystem and self.db.profile.threatSystem.enabled and nameplate.UnitFrame then
            local unit = nameplate.UnitFrame.unit
            if unit then
                self:UpdateNameplateThreat(nameplate, unit)
            end
        end
    end
end

function Module:RestoreHealthBarColor(nameplate, color)
    if not nameplate or not nameplate.UnitFrame or not nameplate.UnitFrame.healthBar or not color then
        return
    end
    
    local healthBar = nameplate.UnitFrame.healthBar
    healthBar:SetStatusBarColor(color[1], color[2], color[3], color[4])
    
    -- Also restore texture color
    local texture = healthBar:GetStatusBarTexture()
    if texture then
        texture:SetVertexColor(color[1], color[2], color[3], color[4])
    end
end

-------------------------------------------------
-- Color Manipulation Helper
-------------------------------------------------

-- White Tint Method
-- Mixes the original color with white to create a lighter tint
-- tintAmount: 0.0 = original color, 1.0 = pure white
function Module:ApplyWhiteTint(r, g, b, a, tintAmount)
    local newR = r + (1.0 - r) * tintAmount
    local newG = g + (1.0 - g) * tintAmount
    local newB = b + (1.0 - b) * tintAmount
    return newR, newG, newB, a
end

-------------------------------------------------
-- Block Mouseover Border Glow System
-- Forces all nameplate borders to remain black
-------------------------------------------------

function Module:SetupMouseoverBorderBlock()
    if not self.db.profile.enabled or not self.db.profile.blockMouseoverBorderGlow.enabled then
        return
    end
    
    -- Create OnUpdate frame to force black borders every frame
    if not self.borderBlockFrame then
        self.borderBlockFrame = CreateFrame("Frame")
    end
    
    self.borderBlockFrame:SetScript("OnUpdate", function()
        self:ForceBlackBordersOnAllNameplates()
    end)
    
    -- Hook existing nameplates
    C_Timer.After(0.5, function()
        for nameplate in C_NamePlateManager.EnumerateActiveNamePlates() do
            if nameplate.UnitFrame then
                self:BlockNameplateBorderGlow(nameplate)
                self:HideHealthBarBackground(nameplate.UnitFrame)
            end
        end
    end)
end

function Module:ForceBlackBordersOnAllNameplates()
    -- NEW BEHAVIOR: Hide all native borders completely (alpha = 0)
    -- We use custom borders for all nameplates instead
    for nameplate in C_NamePlateManager.EnumerateActiveNamePlates() do
        if nameplate.UnitFrame and 
           nameplate.UnitFrame.healthBar and 
           nameplate.UnitFrame.healthBar.border then
            
            -- Force alpha to 0 on native border (always hidden)
            nameplate.UnitFrame.healthBar.border:SetAlpha(0)
        end
        
        -- Also hide healthbar backgrounds
        if nameplate.UnitFrame then
            self:HideHealthBarBackground(nameplate.UnitFrame)
        end
    end
end

function Module:CleanupMouseoverBorderBlock()
    if self.borderBlockFrame then
        self.borderBlockFrame:SetScript("OnUpdate", nil)
    end
end

function Module:BlockNameplateBorderGlow(nameplate)
    if not nameplate or not nameplate.UnitFrame then
        return false
    end
    
    local unitFrame = nameplate.UnitFrame
    
    if not unitFrame.healthBar or not unitFrame.healthBar.border then
        return false
    end
    
    -- NEW BEHAVIOR: Simply force native border alpha to 0 (always hidden)
    unitFrame.healthBar.border:SetAlpha(0)
    
    -- Also hide the healthbar background (make it fully transparent)
    self:HideHealthBarBackground(unitFrame)
    
    return true
end

function Module:HideHealthBarBackground(unitFrame)
    if not unitFrame or not unitFrame.healthBar then
        return
    end
    
    local healthBar = unitFrame.healthBar
    
    -- Force backdrop background to transparent
    local bgFile = healthBar:GetBackdrop()
    if bgFile then
        healthBar:SetBackdropColor(0, 0, 0, 0)
    end
    
    -- Hide .bg property if it exists
    if healthBar.bg then
        healthBar.bg:SetAlpha(0)
    end
    
    -- Hide all BACKGROUND layer textures
    local regions = {healthBar:GetRegions()}
    for _, region in ipairs(regions) do
        if region:GetObjectType() == "Texture" then
            local drawLayer = region:GetDrawLayer()
            if drawLayer == "BACKGROUND" then
                region:SetAlpha(0)
            end
        end
    end
    
    -- Check for common background property names
    if healthBar.background then
        healthBar.background:SetAlpha(0)
    end
    if healthBar.Background then
        healthBar.Background:SetAlpha(0)
    end
    if healthBar.BG then
        healthBar.BG:SetAlpha(0)
    end
    if healthBar.bgTexture then
        healthBar.bgTexture:SetAlpha(0)
    end
end

function Module:UnblockAllBorderGlows()
    for nameplate in C_NamePlateManager.EnumerateActiveNamePlates() do
        if nameplate.UnitFrame and 
           nameplate.UnitFrame.healthBar and 
           nameplate.UnitFrame.healthBar.border and
           nameplate.UnitFrame.healthBar.border.Texture then
            
            local texture = nameplate.UnitFrame.healthBar.border.Texture
            
            if texture.originalSetVertexColor then
                texture.SetVertexColor = texture.originalSetVertexColor
                texture.originalSetVertexColor = nil
            end
        end
    end
end

-------------------------------------------------
-- Disable All Nameplate Glows
-------------------------------------------------

function Module:DisableAllNameplateGlows()
    if not self.db.profile.enabled then return end
    
    -- Register events to continuously disable glows on all nameplates
    self:RegisterEvent("NAME_PLATE_UNIT_ADDED", "OnNamePlateGlowDisable")
    self:RegisterEvent("PLAYER_TARGET_CHANGED", "OnNamePlateGlowDisable")
    
    -- Disable glows on existing nameplates
    self:DisableGlowsOnAllNameplates()
    
    -- Create a timer to periodically disable glows (in case they get re-enabled)
    if not self.glowDisableTimer then
        self.glowDisableTimer = C_Timer.NewTicker(2, function()
            if self.db.profile.enabled then
                self:DisableGlowsOnAllNameplates()
            end
        end)
    end
end

function Module:OnNamePlateGlowDisable(unit, nameplate)
    self:DisableGlowsOnAllNameplates()
end

function Module:DisableGlowsOnAllNameplates()
    -- Iterate through all active nameplates and disable glow effects
    for nameplate in C_NamePlateManager.EnumerateActiveNamePlates() do
        if nameplate.UnitFrame then
            self:DisableNameplateGlow(nameplate.UnitFrame)
        end
    end
end

function Module:DisableNameplateGlow(unitFrame)
    if not unitFrame then return end
    
    -- Disable selection highlight (mouseover glow)
    if unitFrame.selectionHighlight then
        unitFrame.selectionHighlight:SetAlpha(0)
        unitFrame.selectionHighlight:Hide()
    end
    
    -- Disable aggro highlight
    if unitFrame.aggroHighlight then
        unitFrame.aggroHighlight:SetAlpha(0)
        unitFrame.aggroHighlight:Hide()
    end
    
    -- Disable any other glow effects that might exist
    if unitFrame.healthBar then
        local healthBar = unitFrame.healthBar
        
        -- Check for any glow textures attached to health bar
        if healthBar.glow then
            healthBar.glow:SetAlpha(0)
            healthBar.glow:Hide()
        end
        
        -- Check for threat glow
        if healthBar.threatGlow then
            healthBar.threatGlow:SetAlpha(0)
            healthBar.threatGlow:Hide()
        end
    end
end

-------------------------------------------------
-- Threat System
-------------------------------------------------

function Module:SetupThreatSystem()
    -- Check if Ascension NamePlates is available first
    if not self:CheckNamePlatesAddon() then
        return
    end
    
    if not self.db.profile.enabled then
        return 
    end
    
    if not self.db.profile.threatSystem or not self.db.profile.threatSystem.enabled then
        -- Try to initialize config if missing
        if not self.db.profile.threatSystem then
            self.db.profile.threatSystem = {
                enabled = true,
                method = "healthcolor",
                colors = {
                    none = {0.5, 0.5, 0.5, 1.0},
                    low = {1.0, 1.0, 0.0, 1.0},
                    medium = {1.0, 0.5, 0.0, 1.0},
                    high = {1.0, 0.0, 0.0, 1.0},
                    tanking = {0.5, 0.0, 1.0, 1.0}, -- Purple for tanking
                }
            }
        end
        
        if not self.db.profile.threatSystem.enabled then
            return 
        end
    end
    
    -- Initialize threat data
    self.threatData = {}
    
    -- Register events for threat detection
    self:RegisterEvent("UNIT_THREAT_LIST_UPDATE", "OnThreatUpdate")
    self:RegisterEvent("UNIT_THREAT_SITUATION_UPDATE", "OnThreatUpdate") 
    self:RegisterEvent("NAME_PLATE_UNIT_ADDED", "OnThreatNameplateAdded")
    self:RegisterEvent("NAME_PLATE_UNIT_REMOVED", "OnThreatNameplateRemoved")
    self:RegisterEvent("PLAYER_TARGET_CHANGED", "OnThreatTargetChanged")
    self:RegisterEvent("UNIT_TARGET", "OnThreatUnitTarget")
    self:RegisterEvent("PLAYER_REGEN_ENABLED", "OnThreatCombatEnd")
    self:RegisterEvent("PLAYER_REGEN_DISABLED", "OnThreatCombatStart")
    
    -- Register group events to enable/disable threat system automatically
    self:RegisterEvent("GROUP_FORMED", "OnGroupChanged")
    self:RegisterEvent("GROUP_LEFT", "OnGroupChanged")
    self:RegisterEvent("GROUP_JOINED", "OnGroupChanged")
    self:RegisterEvent("PARTY_MEMBERS_CHANGED", "OnGroupChanged")
    self:RegisterEvent("RAID_ROSTER_UPDATE", "OnGroupChanged")
    
    -- Create a timer to periodically update threat (fallback)
    if not self.threatUpdateTimer then
        self.threatUpdateTimer = C_Timer.NewTicker(1, function()
            if self.db.profile.threatSystem.enabled then
                self:UpdateAllThreatIndicators()
            end
        end)
    end
    
    -- Update threat for existing nameplates
    self:UpdateAllThreatIndicators()
end

function Module:CleanupThreatSystem()
    -- Stop threat update timer
    if self.threatUpdateTimer then
        self.threatUpdateTimer:Cancel()
        self.threatUpdateTimer = nil
    end
    
    -- Reset all nameplate colors to default
    if self.threatData then
        for nameplate, data in pairs(self.threatData) do
            self:ResetNameplateColors(nameplate)
        end
        self.threatData = {}
    end
    
    -- Unregister threat events
    self:UnregisterEvent("UNIT_THREAT_LIST_UPDATE")
    self:UnregisterEvent("UNIT_THREAT_SITUATION_UPDATE")
    self:UnregisterEvent("PLAYER_TARGET_CHANGED")
    self:UnregisterEvent("UNIT_TARGET")
    self:UnregisterEvent("PLAYER_REGEN_ENABLED")
    self:UnregisterEvent("PLAYER_REGEN_DISABLED")
    
    -- Unregister group events
    self:UnregisterEvent("GROUP_FORMED")
    self:UnregisterEvent("GROUP_LEFT")
    self:UnregisterEvent("GROUP_JOINED")
    self:UnregisterEvent("PARTY_MEMBERS_CHANGED")
    self:UnregisterEvent("RAID_ROSTER_UPDATE")
end

function Module:OnThreatUpdate(event, unit)
    if not self.db.profile.threatSystem.enabled then return end
    
    -- Update threat for all nameplates when threat changes
    self:UpdateAllThreatIndicators()
end

function Module:OnThreatTargetChanged()
    if not self.db.profile.threatSystem.enabled then return end
    
    self:UpdateAllThreatIndicators()
    
    -- IMPORTANT: Also call alpha fade system for non-target nameplates
    self:OnAlphaFadeTargetChanged()
end

function Module:OnThreatUnitTarget(event, unit)
    if not self.db.profile.threatSystem.enabled then return end
    
    self:UpdateAllThreatIndicators()
end

function Module:OnThreatCombatStart()
    if not self.db.profile.threatSystem.enabled then return end
    
    -- Only update if in a group
    if not IsInGroup() and not IsInRaid() then
        return
    end
    
    self:UpdateAllThreatIndicators()
end

function Module:OnThreatCombatEnd()
    if not self.db.profile.threatSystem.enabled then return end
    
    -- Clear threat colors when combat ends
    self:ClearAllThreatColors()
end

function Module:OnGroupChanged()
    if not self.db.profile.threatSystem.enabled then return end
    
    -- CRITICAL FIX: Check group status FIRST before updating
    -- If player is now solo, immediately clear all threat colors and return
    if not IsInGroup() and not IsInRaid() then
        self:ClearAllThreatColors()
        return
    end
    
    -- When group status changes, update all threat indicators
    -- This will automatically enable/disable threat colors based on group status
    self:UpdateAllThreatIndicators()
end

function Module:OnThreatNameplateAdded(event, unit, nameplate)
    if not self.db.profile.threatSystem.enabled then return end
    
    -- Update threat for the new nameplate
    self:UpdateNameplateThreat(nameplate, unit)
end

function Module:OnThreatNameplateRemoved(event, unit, nameplate)
    -- Clean up threat data for removed nameplate
    if self.threatData and self.threatData[nameplate] then
        self.threatData[nameplate] = nil
    end
end

function Module:UpdateAllThreatIndicators()
    if not self.db.profile.threatSystem.enabled then 
        return 
    end
    
    -- CRITICAL FIX: Double-check group status before updating
    -- Never apply threat colors when solo, even if called accidentally
    if not IsInGroup() and not IsInRaid() then
        self:ClearAllThreatColors()
        return
    end
    
    -- Update threat for all active nameplates
    local count = 0
    for nameplate in C_NamePlateManager.EnumerateActiveNamePlates() do
        if nameplate.UnitFrame then
            count = count + 1
            self:UpdateNameplateThreat(nameplate, nameplate.UnitFrame.unit)
        end
    end
end

function Module:UpdateNameplateThreat(nameplate, unit)
    -- Early exit if threat system is not enabled
    if not self.db.profile.threatSystem or not self.db.profile.threatSystem.enabled then
        return
    end
    
    -- Only enable threat system when in a group (party or raid)
    -- When solo, threat is not meaningful since player always has 100% threat
    if not IsInGroup() and not IsInRaid() then
        return
    end
    
    if not nameplate or not nameplate.UnitFrame or not unit then 
        return 
    end
    
    local unitFrame = nameplate.UnitFrame
    local threatLevel = self:GetThreatLevel(unit)
    local unitName = UnitName(unit) or "Unknown"
    
    -- CRITICAL: Only proceed if there's actual threat
    -- Don't touch nameplates that have no threat engagement
    if threatLevel == "none" then
        -- Don't modify nameplate colors at all - leave them natural
        return
    end
    
    -- DEBUG: Only log when threat level is significant
    if threatLevel ~= "none" then
        -- Threat working - debug removed
    end
    
    -- Store threat data
    if not self.threatData then
        self.threatData = {}
    end
    self.threatData[nameplate] = {
        unit = unit,
        threatLevel = threatLevel,
        lastUpdate = GetTime()
    }
    
    -- Apply threat coloring - only health bar color
    self:ApplyThreatToHealthBar(unitFrame, threatLevel)
end

function Module:GetThreatLevel(unit)
    if not unit or not UnitExists(unit) then 
        return "none" 
    end
    
    -- Only calculate threat when in a group (party or raid)
    -- When solo, threat calculations are not meaningful
    if not IsInGroup() and not IsInRaid() then
        return "none"
    end
    
    -- Check if unit is actually attackable
    if not UnitCanAttack("player", unit) then
        return "none"
    end
    
    -- CRITICAL: Both player AND unit must be in combat
    if not UnitAffectingCombat(unit) or not UnitAffectingCombat("player") then
        return "none"  -- No combat = no threat colors
    end
    
    -- Check for direct engagement
    local unitTarget = UnitExists(unit .. "target") and UnitName(unit .. "target")
    local playerName = UnitName("player")
    local petName = UnitExists("pet") and UnitName("pet")
    local playerTarget = UnitExists("target") and UnitName("target")
    local unitName = UnitName(unit)
    
    local isTargetingPlayerOrPet = (unitTarget == playerName) or (petName and unitTarget == petName)
    local isPlayerTargeting = (playerTarget == unitName)
    
    -- STRICT: Must have direct engagement, not just "in combat"
    if not isTargetingPlayerOrPet and not isPlayerTargeting then
        return "none"  -- In combat but not with us
    end
    
    -- Method 1: Try UnitDetailedThreatSituation (might not work in Ascension)
    local isTanking, status, threatpct, rawthreatpct, threatvalue = UnitDetailedThreatSituation("player", unit)
    
    if isTanking then
        return "tanking"
    elseif status then
        -- WoW threat status: 0=not tanking, 1=higher than tank, 2=insecurely tanking, 3=securely tanking
        if status >= 2 then
            return "high"
        elseif status == 1 then
            return "medium"
        else
            return "low"
        end
    elseif threatpct and threatpct > 0 then
        -- Use threat percentage if available
        if threatpct >= 80 then
            return "high"
        elseif threatpct >= 50 then
            return "medium"
        else
            return "low"
        end
    end
    
    -- Method 2: Fallback - Check if unit is targeting player (simple aggro check)
    if unitTarget == playerName then
        return "tanking"
    elseif petName and unitTarget == petName then
        -- Only show low threat if player is actually generating threat on this target
        -- Don't show colors just because pet is tanking
        return "none"
    end
    
    -- Method 3: If we reach here and both are in combat, but no direct threat detected
    return "none"
end

function Module:ApplyThreatToNameText(unitFrame, threatLevel)
    if not unitFrame.name then return end
    
    local color = self.db.profile.threatSystem.colors[threatLevel]
    if color then
        unitFrame.name:SetTextColor(color[1], color[2], color[3], color[4])
    end
end

function Module:ApplyThreatToHealthBar(unitFrame, threatLevel)
    if not unitFrame.healthBar then 
        return 
    end
    
    -- CRITICAL: Don't override mouseover highlight colors
    -- Check if this nameplate currently has mouseover highlight active
    if self.db.profile.mouseoverHealthBarHighlight and self.db.profile.mouseoverHealthBarHighlight.enabled then
        local unit = unitFrame.unit
        if unit and UnitIsUnit(unit, "mouseover") then
            -- Skip applying threat color while moused over (silent)
            return
        end
    end
    
    local color = self.db.profile.threatSystem.colors[threatLevel]
    if color then
        unitFrame.healthBar:SetStatusBarColor(color[1], color[2], color[3], color[4])
        
        -- Also try setting the texture color if SetStatusBarColor doesn't work
        local texture = unitFrame.healthBar:GetStatusBarTexture()
        if texture then
            texture:SetVertexColor(color[1], color[2], color[3], color[4])
        end
    end
end

function Module:ResetHealthBarColor(unitFrame)
    if not unitFrame or not unitFrame.healthBar then
        return
    end
    
    -- DON'T force any color - let the game's default nameplate system handle it
    -- The game automatically assigns colors based on faction:
    -- - Red for hostile enemies
    -- - Yellow for neutral NPCs
    -- - Green for friendly units
    -- By not calling SetStatusBarColor, we preserve the game's natural coloring
    
    -- Note: We intentionally do NOT call SetStatusBarColor here
    -- This allows the nameplate system to restore its original color naturally
end

function Module:ApplyThreatToBorder(unitFrame, threatLevel)
    -- This would create a threat border similar to our target border
    -- For now, we'll implement it as a colored outline
    if not unitFrame.healthBar then return end
    
    local color = self.db.profile.threatSystem.colors[threatLevel]
    if not color or threatLevel == "none" then
        -- Remove threat border if no threat
        if unitFrame.threatBorder then
            unitFrame.threatBorder:Hide()
        end
        return
    end
    
    -- Create threat border if it doesn't exist
    if not unitFrame.threatBorder then
        unitFrame.threatBorder = CreateFrame("Frame", nil, unitFrame)
        unitFrame.threatBorder:SetFrameLevel(unitFrame.healthBar:GetFrameLevel() - 1)
        
        -- Create border background
        unitFrame.threatBorder.bg = unitFrame.threatBorder:CreateTexture(nil, "BACKGROUND")
        unitFrame.threatBorder.bg:SetAllPoints(unitFrame.healthBar)
    end
    
    -- Position and color the threat border
    unitFrame.threatBorder:SetPoint("TOPLEFT", unitFrame.healthBar, "TOPLEFT", -1, 1)
    unitFrame.threatBorder:SetPoint("BOTTOMRIGHT", unitFrame.healthBar, "BOTTOMRIGHT", 1, -1)
    unitFrame.threatBorder.bg:SetColorTexture(color[1], color[2], color[3], color[4])
    unitFrame.threatBorder:Show()
end

function Module:ResetNameplateColors(nameplate)
    if not nameplate or not nameplate.UnitFrame then return end
    
    local unitFrame = nameplate.UnitFrame
    
    -- DON'T force any colors - let the game handle default coloring
    -- The game automatically assigns colors based on faction and reaction:
    -- - Health bars: red (hostile), yellow (neutral), green (friendly)
    -- - Names: colored by class, reaction, or default white
    
    -- Note: We intentionally do NOT call SetStatusBarColor or SetTextColor
    -- This allows the nameplate system to restore its original colors naturally
    
    -- Only clean up custom elements we added
    if unitFrame.threatBorder then
        unitFrame.threatBorder:Hide()
    end
end

function Module:UpdateThreatSettings()
    -- Update all threat indicators when settings change
    self:UpdateAllThreatIndicators()
end

function Module:ClearAllThreatColors()
    -- Remove threat colors from all nameplates when going solo
    for nameplate in C_NamePlateManager.EnumerateActiveNamePlates() do
        if nameplate.UnitFrame then
            -- DON'T force any colors - just clean up our custom elements
            -- Let the game restore natural colors (red/yellow/green based on reaction)
            
            -- Hide threat border if it exists
            if nameplate.UnitFrame.threatBorder then
                nameplate.UnitFrame.threatBorder:Hide()
            end
        end
    end
    
    -- Clear threat data
    if self.threatData then
        self.threatData = {}
    end
end

-------------------------------------------------
-- Check if Ascension NamePlates addon is available
-------------------------------------------------
function Module:CheckNamePlatesAddon()
    local isLoaded = IsAddOnLoaded("Ascension_NamePlates")
    local canLoad = select(4, GetAddOnInfo("Ascension_NamePlates"))
    
    if isLoaded then
        return true
    elseif canLoad then
        return false
    else
        return false
    end
end

-------------------------------------------------
-- Get the Ascension NamePlates addon reference and its database
-------------------------------------------------
function Module:GetNamePlatesAddon()
    return _G.AscensionNamePlates
end

function Module:GetNamePlatesDB()
    local addon = self:GetNamePlatesAddon()
    return addon and addon.db
end

function Module:GetNamePlatesProfile()
    local db = self:GetNamePlatesDB()
    return db and db.profile
end

-------------------------------------------------
-- Helper functions to access NamePlates options
-------------------------------------------------
function Module:GetNamePlatesOption(section, key, subkey)
    local profile = self:GetNamePlatesProfile()
    if not profile then return nil end
    
    local value = profile[section]
    if key and value then
        value = value[key]
    end
    if subkey and value then
        value = value[subkey]
    end
    return value
end

function Module:SetNamePlatesOption(section, key, subkey, newValue)
    local profile = self:GetNamePlatesProfile()
    if not profile then return false end
    
    local target = profile[section]
    if not target then
        profile[section] = {}
        target = profile[section]
    end
    
    if subkey then
        if not target[key] then
            target[key] = {}
        end
        target[key][subkey] = newValue
    elseif key then
        target[key] = newValue
    else
        profile[section] = newValue
    end
    
    -- Trigger update
    local addon = self:GetNamePlatesAddon()
    if addon and addon.UpdateAll then
        addon:UpdateAll()
    end
    
    return true
end

function Module:ApplyGlobalHealthBarTexture()
    if not self.db.profile.globalHealthBarTexture.enabled then
        return
    end
    
    local textureName = self.db.profile.globalHealthBarTexture.texture
    if not textureName then
        return
    end
    
    -- Apply to all nameplate types
    self:SetNamePlatesOption("friendly", "health", "statusBar", textureName)
    self:SetNamePlatesOption("enemy", "health", "statusBar", textureName)
    self:SetNamePlatesOption("personal", "health", "statusBar", textureName)
end

-------------------------------------------------
-- Health Text Positioning System
-------------------------------------------------
function Module:SetupHealthTextPositioning()
    if not self.db.profile.healthTextPosition.enabled then
        return
    end
    
    -- Register events to apply positioning to nameplates
    self:RegisterEvent("NAME_PLATE_UNIT_ADDED", "OnHealthTextNameplateAdded")
    
    -- Apply positioning to existing nameplates
    self:ApplyHealthTextPositionToAll()
    
    -- Create a timer to periodically check and apply positioning
    if not self.healthTextPositionTimer then
        self.healthTextPositionTimer = C_Timer.NewTicker(1, function()
            if self.db.profile.healthTextPosition.enabled then
                self:ApplyHealthTextPositionToAll()
            end
        end)
    end
end

function Module:CleanupHealthTextPositioning()
    -- Stop positioning timer
    if self.healthTextPositionTimer then
        self.healthTextPositionTimer:Cancel()
        self.healthTextPositionTimer = nil
    end
    
    -- Reset all nameplate health text positions to default
    self:ResetHealthTextPositionOnAll()
end

function Module:OnHealthTextNameplateAdded(event, unit, nameplate)
    if not self.db.profile.healthTextPosition.enabled then
        return
    end
    
    self:ApplyHealthTextPosition(nameplate)
end

function Module:ApplyHealthTextPosition(nameplate)
    if not nameplate or not nameplate.UnitFrame then
        return
    end
    
    local unitFrame = nameplate.UnitFrame
    if not unitFrame.healthBar or not unitFrame.healthBar.Elements or not unitFrame.healthBar.Elements.statusText then
        return
    end
    
    local statusText = unitFrame.healthBar.Elements.statusText
    local offsetX = self.db.profile.healthTextPosition.offsetX or 0
    local offsetY = self.db.profile.healthTextPosition.offsetY or 1
    
    -- Clear existing points and set new position
    statusText:ClearAllPoints()
    statusText:SetPoint("CENTER", unitFrame.healthBar.Elements, "CENTER", offsetX, offsetY)
end

function Module:ApplyHealthTextPositionToAll()
    for nameplate in C_NamePlateManager.EnumerateActiveNamePlates() do
        self:ApplyHealthTextPosition(nameplate)
    end
end

function Module:ResetHealthTextPositionOnAll()
    for nameplate in C_NamePlateManager.EnumerateActiveNamePlates() do
        if nameplate and nameplate.UnitFrame and nameplate.UnitFrame.healthBar and 
           nameplate.UnitFrame.healthBar.Elements and nameplate.UnitFrame.healthBar.Elements.statusText then
            local statusText = nameplate.UnitFrame.healthBar.Elements.statusText
            statusText:ClearAllPoints()
            statusText:SetPoint("CENTER", nameplate.UnitFrame.healthBar.Elements, "CENTER", 0, 1)
        end
    end
end

function Module:UpdateHealthTextPosition()
    if self.db.profile.healthTextPosition.enabled then
        self:ApplyHealthTextPositionToAll()
    else
        self:ResetHealthTextPositionOnAll()
    end
end

-------------------------------------------------
-- Non-Target Alpha Fade System
-------------------------------------------------
function Module:SetupNonTargetAlpha()
    if not self.db.profile.nonTargetAlpha.enabled then
        return
    end
    
    -- Initialize alpha fade tracking
    self.alphaFadeFrames = {}
    
    -- Register events for target changes and nameplate updates
    self:RegisterEvent("PLAYER_TARGET_CHANGED", "OnAlphaFadeTargetChanged")
    self:RegisterEvent("NAME_PLATE_UNIT_ADDED", "OnAlphaFadeNameplateAdded")
    self:RegisterEvent("NAME_PLATE_UNIT_REMOVED", "OnAlphaFadeNameplateRemoved")
    
    -- Register combat events to update alpha when combat state changes
    self:RegisterEvent("PLAYER_REGEN_DISABLED", "OnAlphaCombatChanged") -- Player enters combat
    self:RegisterEvent("PLAYER_REGEN_ENABLED", "OnAlphaCombatChanged")  -- Player leaves combat
    self:RegisterEvent("UNIT_THREAT_SITUATION_UPDATE", "OnAlphaThreatChanged") -- Threat/combat changes
    
    -- Apply alpha to existing nameplates
    self:UpdateAllNameplateAlphas()
    
    -- Create a hidden frame with OnUpdate script for maximum responsiveness
    -- This runs every single frame, ensuring alpha is maintained even during repositioning
    if not self.alphaFadeUpdateFrame then
        self.alphaFadeUpdateFrame = CreateFrame("Frame")
        self.alphaFadeUpdateFrame:SetScript("OnUpdate", function()
            if self.db.profile.nonTargetAlpha.enabled then
                self:UpdateAllNameplateAlphas()
            end
        end)
    end
    self.alphaFadeUpdateFrame:Show()
end

function Module:CleanupNonTargetAlpha()
    -- Hide and stop the OnUpdate frame
    if self.alphaFadeUpdateFrame then
        self.alphaFadeUpdateFrame:Hide()
        self.alphaFadeUpdateFrame:SetScript("OnUpdate", nil)
    end
    
    -- Reset all nameplates to full alpha and clear hooks flag
    if self.alphaFadeFrames then
        for nameplate, _ in pairs(self.alphaFadeFrames) do
            self:ResetNameplateAlpha(nameplate)
        end
        self.alphaFadeFrames = {}
    end
    
    -- Force reset all active nameplates and clear hooks
    for nameplate in C_NamePlateManager.EnumerateActiveNamePlates() do
        if nameplate.UnitFrame then
            -- Clear hooks flag so they can be re-applied if re-enabled
            nameplate.UnitFrame.alphaHooksApplied = nil
            -- Note: We can't unhook hooksecurefunc, but the hooks check enabled flag
            -- The SetAlpha override will be naturally replaced when nameplate is recycled
            nameplate.UnitFrame:SetAlpha(1.0)
        end
    end
    
    -- Unregister alpha fade events (careful not to unregister shared events)
    -- PLAYER_TARGET_CHANGED is shared with threat and target glow systems
    -- So we won't unregister it here, just let the handler check the setting
end

function Module:OnAlphaFadeTargetChanged()
    if not self.db.profile.nonTargetAlpha.enabled then
        return
    end
    
    -- Update alpha for all nameplates when target changes
    self:UpdateAllNameplateAlphas()
end

function Module:OnAlphaFadeNameplateAdded(event, unit, nameplate)
    if not self.db.profile.nonTargetAlpha.enabled then
        return
    end
    
    -- Apply alpha to the newly added nameplate immediately
    self:UpdateNameplateAlpha(nameplate, unit)
end

function Module:OnAlphaFadeNameplateRemoved(event, unit, nameplate)
    -- Clean up alpha tracking for removed nameplate
    if self.alphaFadeFrames and self.alphaFadeFrames[nameplate] then
        self.alphaFadeFrames[nameplate] = nil
    end
end

function Module:OnAlphaCombatChanged()
    if not self.db.profile.nonTargetAlpha.enabled then
        return
    end
    
    -- Update alpha for all nameplates when combat state changes
    self:UpdateAllNameplateAlphas()
end

function Module:OnAlphaThreatChanged(event, unit)
    if not self.db.profile.nonTargetAlpha.enabled then
        return
    end
    
    -- Find the nameplate for this unit and update its alpha
    for nameplate in C_NamePlateManager.EnumerateActiveNamePlates() do
        if nameplate.UnitFrame and nameplate.UnitFrame.unit == unit then
            self:UpdateNameplateAlpha(nameplate, unit)
            break
        end
    end
end

function Module:IsUnitInDirectCombatWithPlayer(unit)
    -- Must be able to attack the unit
    if not UnitCanAttack("player", unit) then
        return false
    end
    
    -- CRITICAL: Both player AND unit must be in combat
    if not UnitAffectingCombat(unit) or not UnitAffectingCombat("player") then
        return false  -- No combat = no direct engagement
    end
    
    -- Check for direct engagement
    local unitTarget = UnitExists(unit .. "target") and UnitName(unit .. "target")
    local playerName = UnitName("player")
    local petName = UnitExists("pet") and UnitName("pet")
    local playerTarget = UnitExists("target") and UnitName("target")
    local unitName = UnitName(unit)
    
    local isTargetingPlayerOrPet = (unitTarget == playerName) or (petName and unitTarget == petName)
    local isPlayerTargeting = (playerTarget == unitName)
    
    -- Check if you have threat with this unit
    local isTanking, status, threatpct = UnitDetailedThreatSituation("player", unit)
    local hasThreat = isTanking or (status and status > 0) or (threatpct and threatpct > 0)
    
    -- Direct engagement: Unit targeting you/pet OR you targeting unit OR you have threat
    if not isTargetingPlayerOrPet and not isPlayerTargeting and not hasThreat then
        return false  -- In combat but not with us (e.g., fighting another player)
    end
    
    return true
end

function Module:UpdateAllNameplateAlphas()
    if not self.db.profile.nonTargetAlpha.enabled then
        return
    end
    
    local hasTarget = UnitExists("target")
    
    -- Update alpha for all active nameplates
    local count = 0
    for nameplate in C_NamePlateManager.EnumerateActiveNamePlates() do
        if nameplate.UnitFrame then
            local unit = nameplate.UnitFrame.unit
            count = count + 1
            self:UpdateNameplateAlpha(nameplate, unit)
        end
    end
    
    -- Debug: Print every 120 frames (roughly every 2 seconds at 60 FPS)
    -- if not self.alphaDebugCounter then
    --     self.alphaDebugCounter = 0
    -- end
    -- self.alphaDebugCounter = self.alphaDebugCounter + 1
    -- if self.alphaDebugCounter >= 120 then
    --     print(string.format("[YATP Alpha] Updated %d nameplates (Target: %s)", count, UnitName("target") or "None"))
    --     self.alphaDebugCounter = 0
    -- end
end

function Module:UpdateNameplateAlpha(nameplate, unit)
    if not nameplate or not nameplate.UnitFrame or not unit then
        return
    end
    
    -- Check if this nameplate is the current target
    local isTarget = UnitIsUnit(unit, "target")
    local unitName = UnitName(unit) or "Unknown"
    
    -- Determine alpha based on priority:
    -- 1. Target = always 100%
    -- 2. In direct combat with player = normal non-target alpha
    -- 3. Not in combat or fighting someone else = out-of-combat alpha
    local targetAlpha
    if isTarget then
        targetAlpha = 1.0
    else
        -- Check if unit is in direct combat with player
        local inDirectCombat = self:IsUnitInDirectCombatWithPlayer(unit)
        if inDirectCombat then
            -- In combat with us - use normal non-target alpha
            targetAlpha = self.db.profile.nonTargetAlpha.alpha
        else
            -- Not in combat with us - use reduced out-of-combat alpha
            targetAlpha = self.db.profile.nonTargetAlpha.outOfCombatAlpha
        end
    end
    
    -- Get current alpha to detect if WoW reset it (debug only)
    -- local currentAlpha = nameplate.UnitFrame:GetAlpha()
    -- if not isTarget and currentAlpha > (targetAlpha + 0.1) then
    --     print(string.format("[YATP Alpha] RESET DETECTED: %s alpha was %.2f, setting to %.2f", unitName, currentAlpha, targetAlpha))
    -- end
    
    -- Apply alpha directly
    nameplate.UnitFrame:SetAlpha(targetAlpha)
    
    -- Hook multiple functions to catch ALL repositioning/update moments
    if not nameplate.UnitFrame.alphaHooksApplied then
        -- Hook Show()
        hooksecurefunc(nameplate.UnitFrame, "Show", function(frame)
            if self.db.profile.nonTargetAlpha.enabled then
                local frameUnit = frame.unit
                if frameUnit then
                    local frameIsTarget = UnitExists("target") and UnitIsUnit(frameUnit, "target")
                    local frameAlpha
                    if frameIsTarget then
                        frameAlpha = 1.0
                    else
                        local inDirectCombat = self:IsUnitInDirectCombatWithPlayer(frameUnit)
                        frameAlpha = inDirectCombat and self.db.profile.nonTargetAlpha.alpha or self.db.profile.nonTargetAlpha.outOfCombatAlpha
                    end
                    C_Timer.After(0, function()
                        if frame then
                            frame:SetAlpha(frameAlpha)
                        end
                    end)
                end
            end
        end)
        
        -- Hook SetPoint() - this is called when nameplate repositions
        hooksecurefunc(nameplate.UnitFrame, "SetPoint", function(frame)
            if self.db.profile.nonTargetAlpha.enabled then
                local frameUnit = frame.unit
                if frameUnit then
                    local frameIsTarget = UnitExists("target") and UnitIsUnit(frameUnit, "target")
                    local frameAlpha
                    if frameIsTarget then
                        frameAlpha = 1.0
                    else
                        local inDirectCombat = self:IsUnitInDirectCombatWithPlayer(frameUnit)
                        frameAlpha = inDirectCombat and self.db.profile.nonTargetAlpha.alpha or self.db.profile.nonTargetAlpha.outOfCombatAlpha
                    end
                    -- Apply immediately since SetPoint is the repositioning call
                    frame:SetAlpha(frameAlpha)
                end
            end
        end)
        
        -- Hook SetAlpha() itself to prevent external changes
        local originalSetAlpha = nameplate.UnitFrame.SetAlpha
        nameplate.UnitFrame.SetAlpha = function(frame, alpha)
            if self.db.profile.nonTargetAlpha.enabled then
                local frameUnit = frame.unit
                if frameUnit then
                    local frameIsTarget = UnitExists("target") and UnitIsUnit(frameUnit, "target")
                    -- Override requested alpha with our value
                    if frameIsTarget then
                        alpha = 1.0
                    else
                        local inDirectCombat = self:IsUnitInDirectCombatWithPlayer(frameUnit)
                        alpha = inDirectCombat and self.db.profile.nonTargetAlpha.alpha or self.db.profile.nonTargetAlpha.outOfCombatAlpha
                    end
                end
            end
            originalSetAlpha(frame, alpha)
        end
        
        nameplate.UnitFrame.alphaHooksApplied = true
    end
    
    -- Track this nameplate
    if not self.alphaFadeFrames then
        self.alphaFadeFrames = {}
    end
    self.alphaFadeFrames[nameplate] = {
        unit = unit,
        targetAlpha = targetAlpha,
        lastUpdate = GetTime()
    }
end

function Module:ResetNameplateAlpha(nameplate)
    if not nameplate or not nameplate.UnitFrame then
        return
    end
    
    -- Reset to full alpha
    nameplate.UnitFrame:SetAlpha(1.0)
end

function Module:UpdateNonTargetAlphaSettings()
    -- Update all nameplates when settings change
    if self.db.profile.nonTargetAlpha.enabled then
        self:UpdateAllNameplateAlphas()
    else
        -- Reset all nameplates to full alpha
        if self.alphaFadeFrames then
            for nameplate, _ in pairs(self.alphaFadeFrames) do
                self:ResetNameplateAlpha(nameplate)
            end
        end
    end
end

function Module:IsNamePlatesConfigured()
    return self:GetNamePlatesProfile() ~= nil
end

function Module:CanConfigureNamePlates()
    return self:CheckNamePlatesAddon() and self:GetNamePlatesAddon() ~= nil
end

-------------------------------------------------
-- Open Ascension NamePlates configuration
-------------------------------------------------
function Module:OpenNamePlatesConfig()
    if not self:CanConfigureNamePlates() then
        YATP:Print("Ascension NamePlates addon is not available or loaded.")
        return
    end
    
    -- Try to open the config via Blizzard options
    InterfaceOptionsFrame_OpenToCategory("Ascension NamePlates")
    InterfaceOptionsFrame_OpenToCategory("Ascension NamePlates")
end

-------------------------------------------------
-- Auto-Load Ascension NamePlates on startup/reload
-------------------------------------------------
function Module:AutoLoadAscensionNamePlates()
    -- Check if auto-load is disabled in settings
    if self.db and self.db.profile and self.db.profile.autoLoadNamePlates == false then
        return
    end
    
    -- Check if addon exists and is enabled but not loaded
    local name, title, notes, loadable = GetAddOnInfo("Ascension_NamePlates")
    local isLoaded = IsAddOnLoaded("Ascension_NamePlates")
    
    if name and loadable and not isLoaded then
        -- Addon is enabled but not loaded - try to load it
        local loaded, reason = LoadAddOn("Ascension_NamePlates")
        
        -- Silent auto-load (no chat spam)
    end
end

-------------------------------------------------
-- Load/Enable Ascension NamePlates if possible
-------------------------------------------------
function Module:LoadNamePlatesAddon()
    local canLoad = select(4, GetAddOnInfo("Ascension_NamePlates"))
    if canLoad and not IsAddOnLoaded("Ascension_NamePlates") then
        EnableAddOn("Ascension_NamePlates")
        LoadAddOn("Ascension_NamePlates")
        return true
    end
    return false
end

-------------------------------------------------
-- Get NamePlates addon status info
-------------------------------------------------
function Module:GetNamePlatesStatus()
    local name, title, notes, loadable, reason, security = GetAddOnInfo("Ascension_NamePlates")
    local isLoaded = IsAddOnLoaded("Ascension_NamePlates")
    
    return {
        name = name or "Ascension_NamePlates",
        title = title or "Ascension NamePlates",
        notes = notes or "NamePlates addon for Ascension WoW",
        loadable = loadable,
        loaded = isLoaded,
        reason = reason,
        security = security,
        available = name ~= nil
    }
end

-------------------------------------------------
-- Build Tab Structure (replicating original addon structure)
-------------------------------------------------
function Module:BuildTabStructure()
    local isConfigured = self:IsNamePlatesConfigured()
    
    local tabs = {
        -- Status Tab (always available)
        status = {
            type = "group",
            name = L["Status"] or "Status",
            desc = L["Addon status and basic controls"] or "Addon status and basic controls",
            order = 1,
            args = self:BuildStatusTab()
        }
    }
    
    -- Only add configuration tabs if the addon is loaded and configured
    if isConfigured then
        tabs.general = {
            type = "group",
            name = L["General"] or "General",
            desc = L["General nameplate settings"] or "General nameplate settings",
            order = 2,
            args = self:BuildGeneralTab()
        }
        
        tabs.enemyTarget = {
            type = "group",
            name = L["Enemy Target"] or "Enemy Target",
            desc = L["Settings for targeted enemy nameplates"] or "Settings for targeted enemy nameplates",
            order = 3,
            args = self:BuildEnemyTargetTab()
        }
        
        tabs.questIcons = {
            type = "group",
            name = L["Quest Icons"] or "Quest Icons",
            desc = L["Custom quest objective icons on nameplates"] or "Custom quest objective icons on nameplates",
            order = 4,
            args = self:BuildQuestIconsTab()
        }
    end
    
    -- Target Indicators Tab (always available, separate module)
    local targetIndicatorsModule = YATP:GetModule("TargetIndicators", true)
    if targetIndicatorsModule and targetIndicatorsModule.GetOptions then
        tabs.targetIndicators = {
            type = "group",
            name = L["Target Indicators"] or "Target Indicators",
            desc = L["Custom border and arrows for target nameplate"] or "Custom border and arrows for target nameplate",
            order = 5,
            args = targetIndicatorsModule:GetOptions().args
        }
    end
    
    if not isConfigured then
        tabs.info = {
            type = "group",
            name = L["Information"] or "Information",
            desc = L["Information about NamePlates configuration"] or "Information about NamePlates configuration",
            order = 2,
            args = {
                configNote = {
                    type = "description",
                    name = "|cffFFD700" .. (L["Configuration Tabs"] or "Configuration Tabs") .. ":|r\n\n" ..
                           (L["Once the Ascension NamePlates addon is loaded, additional configuration tabs will appear here:"] or "Once the Ascension NamePlates addon is loaded, additional configuration tabs will appear here:") .. "\n\n" ..
                           "• |cffFFFFFF" .. (L["General"] or "General") .. "|r - " .. (L["Overall settings and clickable area"] or "Overall settings and clickable area") .. "\n" ..
                           "• |cffFFFFFF" .. (L["Friendly"] or "Friendly") .. "|r - " .. (L["Settings for friendly unit nameplates"] or "Settings for friendly unit nameplates") .. "\n" ..
                           "• |cffFFFFFF" .. (L["Enemy"] or "Enemy") .. "|r - " .. (L["Settings for enemy unit nameplates"] or "Settings for enemy unit nameplates") .. "\n" ..
                           "• |cffFFFFFF" .. (L["Enemy Target"] or "Enemy Target") .. "|r - " .. (L["Settings for targeted enemy nameplates"] or "Settings for targeted enemy nameplates") .. "\n" ..
                           "• |cffFFFFFF" .. (L["Personal"] or "Personal") .. "|r - " .. (L["Settings for your own nameplate"] or "Settings for your own nameplate") .. "\n\n" ..
                           "|cff00ff00" .. (L["Load the addon using the Status tab to unlock these configuration options."] or "Load the addon using the Status tab to unlock these configuration options.") .. "|r",
                    fontSize = "medium",
                    order = 1,
                }
            }
        }
    end
    
    return tabs
end

-------------------------------------------------
-- Build Status Tab
-------------------------------------------------
function Module:BuildStatusTab()
    local status = self:GetNamePlatesStatus()
    
    return {
        enabled = {
            type = "toggle",
            name = L["Enable NamePlates Integration"] or "Enable NamePlates Integration",
            desc = L["Enable integration with Ascension NamePlates addon through YATP"] or "Enable integration with Ascension NamePlates addon through YATP",
            get = function() return self.db and self.db.profile and self.db.profile.enabled end,
            set = function(_, value)
                if self.db and self.db.profile then
                    -- Check if trying to enable
                    if value then
                        -- Verify that Ascension NamePlates is loaded
                        if not IsAddOnLoaded("Ascension_NamePlates") then
                            YATP:Print("|cffff0000" .. (L["Cannot enable NamePlates Integration:"] or "Cannot enable NamePlates Integration:") .. "|r " .. (L["Ascension NamePlates addon is not loaded. Please load it first using the button below."] or "Ascension NamePlates addon is not loaded. Please load it first using the button below."))
                            self.db.profile.enabled = false
                            return
                        end
                    end
                    
                    self.db.profile.enabled = value
                    if value then
                        -- Re-enable functionality without calling AceAddon Enable
                        self:SetupMouseoverGlow()
                        self:SetupThreatSystem()
                        self:SetupQuestIcons()
                        self:DisableAllNameplateGlows()
                        self:ApplyGlobalHealthBarTexture()
                        self:SetupHealthTextPositioning()
                        self:SetupNonTargetAlpha()
                    else
                        -- Disable functionality without calling AceAddon Disable
                        self:CleanupThreatSystem()
                        self:CleanupQuestIcons()
                        self:CleanupHealthTextPositioning()
                        self:CleanupNonTargetAlpha()
                        if self.glowDisableTimer then
                            self.glowDisableTimer:Cancel()
                            self.glowDisableTimer = nil
                        end
                        self:UnregisterEvent("NAME_PLATE_UNIT_ADDED")
                        self:UnregisterEvent("PLAYER_TARGET_CHANGED")
                    end
                end
            end,
            order = 1,
        },
        
        autoLoad = {
            type = "toggle",
            name = L["Auto-Load on Startup"] or "Auto-Load on Startup",
            desc = L["Automatically load Ascension_NamePlates addon on every UI reload (recommended if you fixed LoadOnDemand issue)"] or "Automatically load Ascension_NamePlates addon on every UI reload (recommended if you fixed LoadOnDemand issue)",
            get = function() return self.db and self.db.profile and self.db.profile.autoLoadNamePlates end,
            set = function(_, value)
                if self.db and self.db.profile then
                    self.db.profile.autoLoadNamePlates = value
                    if value then
                        YATP:Print("|cff00ff00[NamePlates]|r Auto-load enabled. Ascension_NamePlates will load automatically on every UI reload.")
                    else
                        YATP:Print("|cffffff00[NamePlates]|r Auto-load disabled. You'll need to load the addon manually.")
                    end
                end
            end,
            order = 2,
        },
        
        spacer1 = { type = "description", name = "\n", order = 5 },
        
        -- Status section
        statusHeader = { type = "header", name = L["Addon Status"] or "Addon Status", order = 10 },
        
        addonStatus = {
            type = "description",
            name = function()
                local currentStatus = self:GetNamePlatesStatus()
                local txt = "|cffFFFFFF" .. (L["Status"] or "Status") .. ":|r "
                if currentStatus.loaded then
                    txt = txt .. "|cff00ff00" .. (L["Loaded"] or "Loaded") .. "|r"
                elseif currentStatus.loadable then
                    txt = txt .. "|cffffff00" .. (L["Available (not loaded)"] or "Available (not loaded)") .. "|r"
                else
                    txt = txt .. "|cffff0000" .. (L["Not Available"] or "Not Available") .. "|r"
                end
                return txt
            end,
            order = 11,
        },
        
        addonInfo = {
            type = "description",
            name = function()
                local currentStatus = self:GetNamePlatesStatus()
                return "|cffFFFFFF" .. (L["Title"] or "Title") .. ":|r " .. (currentStatus.title or "Unknown") .. "\n" ..
                       "|cffFFFFFF" .. (L["Notes"] or "Notes") .. ":|r " .. (currentStatus.notes or "No description")
            end,
            order = 12,
        },
        
        spacer2 = { type = "description", name = "\n", order = 15 },
        
        -- Actions section
        actionsHeader = { type = "header", name = L["Actions"] or "Actions", order = 20 },
        
        enableAddon = {
            type = "execute",
            name = L["Load NamePlates Now"] or "Load NamePlates Now",
            desc = L["Force load Ascension NamePlates immediately. Use this for the first time setup or if auto-load is disabled."] or "Force load Ascension NamePlates immediately. Use this for the first time setup or if auto-load is disabled.",
            func = function()
                -- Check if addon exists
                local name, title, notes, loadable, reason, security = GetAddOnInfo("Ascension_NamePlates")
                
                if not name then
                    YATP:Print("|cffff0000Error: Ascension_NamePlates addon not found!|r")
                    YATP:Print("Make sure the addon is installed in: Interface\\AddOns\\Ascension_NamePlates")
                    return
                end
                
                -- Check current status
                local isLoaded = IsAddOnLoaded("Ascension_NamePlates")
                local isEnabled = select(4, GetAddOnInfo("Ascension_NamePlates"))
                
                if isLoaded then
                    YATP:Print("|cff00ff00Ascension NamePlates is already loaded and running!|r")
                    -- Refresh options anyway
                    LibStub("AceConfigRegistry-3.0"):NotifyChange("YATP-NamePlates")
                    return
                end
                
                YATP:Print("|cffffff00Attempting to load Ascension NamePlates...|r")
                YATP:Print("|cffffff00Status:|r Loaded=" .. tostring(isLoaded) .. " | Enabled=" .. tostring(isEnabled))
                
                -- Enable the addon for all characters
                EnableAddOn("Ascension_NamePlates")
                
                -- Try to force load it (will work even if LoadOnDemand)
                local loaded, reason = LoadAddOn("Ascension_NamePlates")
                
                if loaded or IsAddOnLoaded("Ascension_NamePlates") then
                    YATP:Print("|cff00ff00Success! Ascension NamePlates has been loaded!|r")
                    YATP:Print("|cffffff00Refreshing configuration...|r")
                    
                    -- Wait a bit for addon to initialize
                    C_Timer.After(0.5, function()
                        -- Refresh the options to show new tabs
                        LibStub("AceConfigRegistry-3.0"):NotifyChange("YATP-NamePlates")
                        YATP:Print("|cff00ff00Done! Check the NamePlates configuration for new tabs.|r")
                    end)
                else
                    YATP:Print("|cffff0000Failed to load Ascension NamePlates.|r")
                    if reason then
                        YATP:Print("|cffff0000Reason:|r " .. tostring(reason))
                    end
                    YATP:Print("|cffffff00Try using the 'Fix LoadOnDemand' button below.|r")
                end
            end,
            order = 21,
        },
        
        spacer3 = { type = "description", name = "\n", order = 22 },
        
        openOriginal = {
            type = "execute",
            name = L["Open Original Configuration"] or "Open Original Configuration",
            desc = L["Open the original Ascension NamePlates configuration panel in Blizzard options"] or "Open the original Ascension NamePlates configuration panel in Blizzard options",
            func = function() self:OpenNamePlatesConfig() end,
            disabled = function() return not self:CanConfigureNamePlates() end,
            order = 23,
        },
        
        spacer4 = { type = "description", name = "\n", order = 24 },
        
        diagnosticsHeader = { type = "header", name = L["Diagnostics"] or "Diagnostics", order = 25 },
        
        checkConflicts = {
            type = "execute",
            name = L["Check for Conflicts"] or "Check for Conflicts",
            desc = L["Scan for other nameplate addons that might conflict with Ascension NamePlates (Plater, TidyPlates, etc)"] or "Scan for other nameplate addons that might conflict with Ascension NamePlates (Plater, TidyPlates, etc)",
            func = function()
                local conflictingAddons = {
                    "Plater",
                    "TidyPlates",
                    "TidyPlatesThreat",
                    "TidyPlates_ThreatPlates",
                    "Kui_Nameplates",
                    "KuiNameplates",
                    "PlateBuffs",
                    "Aloft",
                    "Caellian",
                    "dNameplates",
                }
                
                local foundConflicts = {}
                for _, addonName in ipairs(conflictingAddons) do
                    local name, title, notes, loadable = GetAddOnInfo(addonName)
                    if name then
                        local isLoaded = IsAddOnLoaded(addonName)
                        table.insert(foundConflicts, {name = name, title = title or name, loaded = isLoaded, loadable = loadable})
                    end
                end
                
                if #foundConflicts > 0 then
                    YATP:Print("|cffff0000Found " .. #foundConflicts .. " potentially conflicting nameplate addon(s):|r")
                    for _, addon in ipairs(foundConflicts) do
                        local status = addon.loaded and "|cffff0000(LOADED)|r" or (addon.loadable and "|cffffff00(Enabled)|r" or "|cff808080(Disabled)|r")
                        YATP:Print("  • " .. addon.title .. " " .. status)
                        if addon.loaded or addon.loadable then
                            YATP:Print("    |cffffff00To disable: /run DisableAddOn(\"" .. addon.name .. "\"); ReloadUI()|r")
                        end
                    end
                    YATP:Print("|cffffff00Consider disabling these addons before using Ascension NamePlates.|r")
                else
                    YATP:Print("|cff00ff00No conflicting nameplate addons found!|r")
                end
            end,
            order = 26,
        },
        
        -- Information section
        infoHeader = { type = "header", name = L["Information"] or "Information", order = 40 },
        
        infoText = {
            type = "description",
            name = function()
                if self:IsNamePlatesConfigured() then
                    return L["The NamePlates addon is loaded and configured. Use the tabs above to access different configuration categories."] or 
                           "The NamePlates addon is loaded and configured. Use the tabs above to access different configuration categories."
                else
                    return L["Load the NamePlates addon to unlock configuration tabs with embedded settings for General, Friendly, Enemy, and Personal nameplates."] or
                           "Load the NamePlates addon to unlock configuration tabs with embedded settings for General, Friendly, Enemy, and Personal nameplates."
                end
            end,
            order = 41,
        },
        
        spacer5 = { type = "description", name = "\n", order = 45 },
        
        troubleshootHeader = { type = "header", name = L["Troubleshooting"] or "Troubleshooting", order = 50 },
        
        troubleshootInfo = {
            type = "description",
            name = "|cffffff00Quick Setup Guide:|r\n\n" ..
                   "1. Enable |cff00ff00'Auto-Load on Startup'|r toggle (recommended)\n" ..
                   "2. Click |cff00ff00'Load NamePlates Now'|r button\n" ..
                   "3. Done! The addon will load automatically on every reload\n\n" ..
                   "|cffffff00If you have issues:|r\n\n" ..
                   "• Click |cff00ff00'Check for Conflicts'|r to find interfering addons\n" ..
                   "• Disable conflicting addons (Plater, TidyPlates, etc)\n" ..
                   "• Make sure Ascension_NamePlates addon files exist\n" ..
                   "• Try disabling Auto-Load, reload UI, then re-enable it\n\n" ..
                   "|cff808080Tip: With Auto-Load enabled, you never need to manually load the addon again!|r",
            fontSize = "medium",
            order = 51,
        }
    }
end

-------------------------------------------------
-- Build General Tab
-------------------------------------------------
function Module:BuildGeneralTab()
    return {
        desc = {
            type = "description",
            name = L["Configure general nameplate appearance and behavior settings."] or "Configure general nameplate appearance and behavior settings.",
            order = 1,
        },
        
        spacer1 = { type = "description", name = "\n", order = 5 },
        
        -- Global Health Bar Texture Override
        globalTextureHeader = { type = "header", name = L["Global Health Bar Texture"] or "Global Health Bar Texture", order = 10 },
        
        globalTextureDesc = {
            type = "description",
            name = L["Override the health bar texture for ALL nameplates (friendly, enemy, and personal). This ensures consistent texture across all nameplate types, including targets."] or "Override the health bar texture for ALL nameplates (friendly, enemy, and personal). This ensures consistent texture across all nameplate types, including targets.",
            order = 11,
        },
        
        globalTextureEnabled = {
            type = "toggle",
            name = L["Enable Global Health Bar Texture"] or "Enable Global Health Bar Texture",
            desc = L["Apply the same health bar texture to all nameplate types"] or "Apply the same health bar texture to all nameplate types",
            get = function() return self.db.profile.globalHealthBarTexture.enabled end,
            set = function(_, value) 
                self.db.profile.globalHealthBarTexture.enabled = value
                if value then
                    self:ApplyGlobalHealthBarTexture()
                end
            end,
            order = 12,
        },
        
        globalTexture = {
            type = "select",
            name = L["Health Bar Texture"] or "Health Bar Texture",
            desc = L["Texture to use for all health bars"] or "Texture to use for all health bars",
            dialogControl = "LSM30_Statusbar",
            values = function() 
                local LSM = LibStub("LibSharedMedia-3.0", true)
                return LSM and LSM:HashTable("statusbar") or {}
            end,
            get = function() return self.db.profile.globalHealthBarTexture.texture end,
            set = function(_, value) 
                self.db.profile.globalHealthBarTexture.texture = value
                if self.db.profile.globalHealthBarTexture.enabled then
                    self:ApplyGlobalHealthBarTexture()
                end
            end,
            disabled = function() return not self.db.profile.globalHealthBarTexture.enabled end,
            order = 13,
        },
        
        spacer2 = { type = "description", name = "\n", order = 15 },
        
        -- Health Text Positioning
        healthTextHeader = { type = "header", name = L["Health Text Positioning"] or "Health Text Positioning", order = 16 },
        
        healthTextDesc = {
            type = "description",
            name = L["Customize the position of the health text displayed on nameplates. The default position is centered with a 1 pixel offset upward."] or "Customize the position of the health text displayed on nameplates. The default position is centered with a 1 pixel offset upward.",
            order = 17,
        },
        
        healthTextEnabled = {
            type = "toggle",
            name = L["Enable Custom Health Text Position"] or "Enable Custom Health Text Position",
            desc = L["Enable custom positioning for health text on all nameplates"] or "Enable custom positioning for health text on all nameplates",
            get = function() return self.db.profile.healthTextPosition.enabled end,
            set = function(_, value) 
                self.db.profile.healthTextPosition.enabled = value
                if value then
                    self:SetupHealthTextPositioning()
                else
                    self:CleanupHealthTextPositioning()
                end
            end,
            order = 18,
        },
        
        healthTextOffsetX = {
            type = "range",
            name = L["Horizontal Offset (X)"] or "Horizontal Offset (X)",
            desc = L["Horizontal offset from center. Negative values move left, positive values move right. Default: 0"] or "Horizontal offset from center. Negative values move left, positive values move right. Default: 0",
            min = -50, max = 50, step = 1,
            get = function() return self.db.profile.healthTextPosition.offsetX end,
            set = function(_, value) 
                self.db.profile.healthTextPosition.offsetX = value
                self:UpdateHealthTextPosition()
            end,
            disabled = function() return not self.db.profile.healthTextPosition.enabled end,
            order = 19,
        },
        
        healthTextOffsetY = {
            type = "range",
            name = L["Vertical Offset (Y)"] or "Vertical Offset (Y)",
            desc = L["Vertical offset from center. Negative values move down, positive values move up. Default: 1"] or "Vertical offset from center. Negative values move down, positive values move up. Default: 1",
            min = -20, max = 20, step = 1,
            get = function() return self.db.profile.healthTextPosition.offsetY end,
            set = function(_, value) 
                self.db.profile.healthTextPosition.offsetY = value
                self:UpdateHealthTextPosition()
            end,
            disabled = function() return not self.db.profile.healthTextPosition.enabled end,
            order = 20,
        },
        
        healthTextReset = {
            type = "execute",
            name = L["Reset to Default"] or "Reset to Default",
            desc = L["Reset health text position to default values (X: 0, Y: 1)"] or "Reset health text position to default values (X: 0, Y: 1)",
            func = function()
                self.db.profile.healthTextPosition.offsetX = 0
                self.db.profile.healthTextPosition.offsetY = 1
                self:UpdateHealthTextPosition()
            end,
            disabled = function() return not self.db.profile.healthTextPosition.enabled end,
            order = 21,
        },
        
        spacer3 = { type = "description", name = "\n", order = 25 },
        
        -- Threat System (YATP Custom Feature)
        threatHeader = { type = "header", name = L["Threat System (YATP Custom)"] or "Threat System (YATP Custom)", order = 35 },
        
        threatEnabled = {
            type = "toggle",
            name = L["Enable Threat System"] or "Enable Threat System",
            desc = "Color nameplates based on your threat level with that enemy. Only works when in a party or raid - automatically disabled when solo since threat is not meaningful.",
            get = function() return self.db.profile.threatSystem.enabled end,
            set = function(_, value) 
                self.db.profile.threatSystem.enabled = value
                if value then
                    self:SetupThreatSystem()
                else
                    self:CleanupThreatSystem()
                end
            end,
            order = 36,
        },
        
        threatColors = {
            type = "group",
            name = L["Threat Colors"] or "Threat Colors",
            desc = L["Configure colors for different threat levels"] or "Configure colors for different threat levels",
            inline = true,
            disabled = function() return not self.db.profile.threatSystem.enabled end,
            order = 37,
            args = {
                low = {
                    type = "color",
                    name = L["Low Threat"] or "Low Threat",
                    desc = L["Color when you have low threat"] or "Color when you have low threat",
                    get = function() 
                        local c = self.db.profile.threatSystem.colors.low
                        return c[1], c[2], c[3], c[4]
                    end,
                    set = function(_, r, g, b, a) 
                        self.db.profile.threatSystem.colors.low = {r, g, b, a}
                        self:UpdateThreatSettings()
                    end,
                    order = 1,
                },
                medium = {
                    type = "color",
                    name = L["Medium Threat"] or "Medium Threat",
                    desc = L["Color when you have medium threat"] or "Color when you have medium threat",
                    get = function() 
                        local c = self.db.profile.threatSystem.colors.medium
                        return c[1], c[2], c[3], c[4]
                    end,
                    set = function(_, r, g, b, a) 
                        self.db.profile.threatSystem.colors.medium = {r, g, b, a}
                        self:UpdateThreatSettings()
                    end,
                    order = 2,
                },
                high = {
                    type = "color",
                    name = L["High Threat"] or "High Threat",
                    desc = L["Color when you have high threat"] or "Color when you have high threat",
                    get = function() 
                        local c = self.db.profile.threatSystem.colors.high
                        return c[1], c[2], c[3], c[4]
                    end,
                    set = function(_, r, g, b, a) 
                        self.db.profile.threatSystem.colors.high = {r, g, b, a}
                        self:UpdateThreatSettings()
                    end,
                    order = 3,
                },
                tanking = {
                    type = "color",
                    name = L["Tanking"] or "Tanking",
                    desc = L["Color when you have aggro"] or "Color when you have aggro",
                    get = function() 
                        local c = self.db.profile.threatSystem.colors.tanking
                        return c[1], c[2], c[3], c[4]
                    end,
                    set = function(_, r, g, b, a) 
                        self.db.profile.threatSystem.colors.tanking = {r, g, b, a}
                        self:UpdateThreatSettings()
                    end,
                    order = 4,
                },
            },
        },
        
        spacer4 = { type = "description", name = "\n", order = 40 },
        
        -- Black Border System (YATP Custom Feature)
        blackBorderHeader = { type = "header", name = L["Black Border (YATP Custom)"] or "Black Border (YATP Custom)", order = 41 },
        
        blackBorderDesc = {
            type = "description",
            name = L["Add a black border around all nameplates. This provides a clean visual separation. Target nameplates will use the custom border from Target Indicators instead."] or "Add a black border around all nameplates. This provides a clean visual separation. Target nameplates will use the custom border from Target Indicators instead.",
            order = 42,
        },
        
        blackBorderEnabled = {
            type = "toggle",
            name = L["Enable Black Border"] or "Enable Black Border",
            desc = L["Show black border on all nameplates"] or "Show black border on all nameplates",
            get = function() return self.db.profile.blackBorder.enabled end,
            set = function(_, value) 
                self.db.profile.blackBorder.enabled = value
                self:SetupBlackBorders()
            end,
            order = 43,
        },
        
        blackBorderColor = {
            type = "color",
            name = L["Border Color"] or "Border Color",
            desc = L["Color of the black border"] or "Color of the black border",
            hasAlpha = true,
            get = function()
                local c = self.db.profile.blackBorder.color or {0, 0, 0, 1}
                return c[1], c[2], c[3], c[4]
            end,
            set = function(_, r, g, b, a)
                self.db.profile.blackBorder.color = {r, g, b, a}
                self:SetupBlackBorders()
            end,
            disabled = function() return not self.db.profile.blackBorder.enabled end,
            order = 44,
        },
        
        spacer5 = { type = "description", name = "\n", order = 48 },
        
        -- Mouseover Health Bar Highlight (YATP Custom Feature)
        mouseoverHighlightHeader = { type = "header", name = L["Mouseover Health Bar Highlight (YATP Custom)"] or "Mouseover Health Bar Highlight (YATP Custom)", order = 49 },
        
        mouseoverHighlightDesc = {
            type = "description",
            name = L["Add a subtle color change to the health bar when you mouse over non-target nameplates. This provides visual feedback without the default white glow. Does not affect your current target."] or "Add a subtle color change to the health bar when you mouse over non-target nameplates. This provides visual feedback without the default white glow. Does not affect your current target.",
            order = 50,
        },
        
        mouseoverHighlightEnabled = {
            type = "toggle",
            name = L["Enable Mouseover Highlight"] or "Enable Mouseover Highlight",
            desc = L["Highlight the health bar when mousing over non-target nameplates. Uses a white tint effect (50% mix) for subtle visibility."] or "Highlight the health bar when mousing over non-target nameplates. Uses a white tint effect (50% mix) for subtle visibility.",
            get = function() return self.db.profile.mouseoverHealthBarHighlight.enabled end,
            set = function(_, value) 
                self.db.profile.mouseoverHealthBarHighlight.enabled = value
                if value then
                    self:SetupMouseoverHealthBarHighlight()
                else
                    self:CleanupMouseoverHealthBarHighlight()
                end
            end,
            order = 51,
        },
    }
end

-------------------------------------------------
-- Build Enemy Target Tab
-------------------------------------------------
function Module:BuildEnemyTargetTab()
    return {
        desc = {
            type = "description",
            name = "Configure custom Target Border enhancements for enemy units that you have targeted.",
            order = 1,
        },
        
        spacer1 = { type = "description", name = "\n", order = 5 },
        
        -- Target Border System (YATP Custom Feature)
        targetGlowHeader = { type = "header", name = L["Target Border (YATP Custom)"] or "Target Border (YATP Custom)", order = 10 },
        
        targetGlowEnabled = {
            type = "toggle",
            name = L["Enable Target Border"] or "Enable Target Border",
            desc = L["Add a colored border around the nameplate of your current target for better visibility"] or "Add a colored border around the nameplate of your current target for better visibility",
            get = function() return self.db.profile.targetGlow.enabled end,
            set = function(_, value) 
                self.db.profile.targetGlow.enabled = value
                -- Black borders are always applied automatically
            end,
            order = 11,
        },
        
        spacer2 = { type = "description", name = "\n", order = 20 },
        
        -- Non-Target Alpha Fade (YATP Custom Feature)
        nonTargetAlphaHeader = { type = "header", name = L["Non-Target Alpha Fade (YATP Custom)"] or "Non-Target Alpha Fade (YATP Custom)", order = 31 },
        
        nonTargetAlphaDesc = {
            type = "description",
            name = L["Advanced alpha fade system with combat detection. Your target is always 100% visible. Non-targets in combat with you use 'Non-Target Alpha', while mobs not fighting you use the lower 'Out-of-Combat Alpha' to reduce visual clutter."] or "Advanced alpha fade system with combat detection. Your target is always 100% visible. Non-targets in combat with you use 'Non-Target Alpha', while mobs not fighting you use the lower 'Out-of-Combat Alpha' to reduce visual clutter.",
            order = 32,
        },
        
        nonTargetAlphaEnabled = {
            type = "toggle",
            name = L["Enable Non-Target Alpha Fade"] or "Enable Non-Target Alpha Fade",
            desc = L["Enable smart alpha fade based on target and combat status. Target = 100%, fighting you = Non-Target Alpha, not fighting = Out-of-Combat Alpha."] or "Enable smart alpha fade based on target and combat status. Target = 100%, fighting you = Non-Target Alpha, not fighting = Out-of-Combat Alpha.",
            get = function() return self.db.profile.nonTargetAlpha.enabled end,
            set = function(_, value) 
                self.db.profile.nonTargetAlpha.enabled = value
                if value then
                    self:SetupNonTargetAlpha()
                else
                    self:CleanupNonTargetAlpha()
                end
            end,
            order = 33,
        },
        
        nonTargetAlphaValue = {
            type = "range",
            name = L["Non-Target Alpha"] or "Non-Target Alpha",
            desc = L["Transparency for non-target nameplates that ARE in combat with you. 0.0 = invisible, 1.0 = fully visible."] or "Transparency for non-target nameplates that ARE in combat with you. 0.0 = invisible, 1.0 = fully visible.",
            min = 0.0, max = 1.0, step = 0.05,
            get = function() return self.db.profile.nonTargetAlpha.alpha end,
            set = function(_, value) 
                self.db.profile.nonTargetAlpha.alpha = value
                self:UpdateNonTargetAlphaSettings()
            end,
            disabled = function() return not self.db.profile.nonTargetAlpha.enabled end,
            order = 34,
        },
        
        outOfCombatAlphaValue = {
            type = "range",
            name = L["Out-of-Combat Alpha"] or "Out-of-Combat Alpha",
            desc = L["Transparency for nameplates NOT in direct combat with you (neutral, fighting others, or nearby). 0.0 = invisible, 1.0 = fully visible. Should be lower than Non-Target Alpha."] or "Transparency for nameplates NOT in direct combat with you (neutral, fighting others, or nearby). 0.0 = invisible, 1.0 = fully visible. Should be lower than Non-Target Alpha.",
            min = 0.0, max = 1.0, step = 0.05,
            get = function() return self.db.profile.nonTargetAlpha.outOfCombatAlpha end,
            set = function(_, value) 
                self.db.profile.nonTargetAlpha.outOfCombatAlpha = value
                self:UpdateNonTargetAlphaSettings()
            end,
            disabled = function() return not self.db.profile.nonTargetAlpha.enabled end,
            order = 35,
        },
        
        spacer4 = { type = "description", name = "\n", order = 36 },
        
        -- Additional enemy options reference
        additionalHeader = { type = "header", name = L["Additional Enemy Options"] or "Additional Enemy Options", order = 40 },
        
        additionalInfo = {
            type = "description",
            name = L["For more enemy nameplate customization options, visit the"] or "For more enemy nameplate customization options, visit the" .. " |cff00ff00" .. (L["Enemy"] or "Enemy") .. "|r " .. (L["tab. There you can configure:"] or "tab. There you can configure:") .. "\n\n" ..
                   "• " .. (L["Health bar appearance and size"] or "Health bar appearance and size") .. "\n" ..
                   "• " .. (L["Name display and fonts"] or "Name display and fonts") .. "\n" ..
                   "• " .. (L["Cast bar settings"] or "Cast bar settings") .. "\n" ..
                   "• " .. (L["Level indicators"] or "Level indicators") .. "\n" ..
                   "• " .. (L["Quest objective icons"] or "Quest objective icons") .. "\n\n" ..
                   (L["All these settings apply to enemy nameplates, including when they are targeted."] or "All these settings apply to enemy nameplates, including when they are targeted."),
            order = 41,
        },
    }
end

-------------------------------------------------
-- Build Quest Icons Tab
-------------------------------------------------
function Module:BuildQuestIconsTab()
    return {
        desc = {
            type = "description",
            name = "Display custom quest objective icons on nameplates for NPCs you need to kill or interact with for quests. " ..
                   "This replaces the unreliable native quest icons with a custom system that scans tooltips to detect quest objectives.",
            order = 1,
        },
        
        spacer1 = { type = "description", name = "\n", order = 5 },
        
        questIconsHeader = { type = "header", name = L["Quest Icon Settings"] or "Quest Icon Settings", order = 10 },
        
        questIconsEnabled = {
            type = "toggle",
            name = L["Enable Quest Icons"] or "Enable Quest Icons",
            desc = L["Show custom quest objective icons on nameplates. When enabled, native Ascension_NamePlates quest icons are hidden. When disabled, native icons are restored."] or "Show custom quest objective icons on nameplates. When enabled, native Ascension_NamePlates quest icons are hidden. When disabled, native icons are restored.",
            get = function() return self.db.profile.questIcons.enabled end,
            set = function(_, value) 
                self.db.profile.questIcons.enabled = value
                if value then
                    self:SetupQuestIcons()
                else
                    self:CleanupQuestIcons()
                end
                -- Update all native quest icon alphas (0 if enabled, 1 if disabled)
                self:UpdateAllNativeQuestIconAlphas()
            end,
            order = 11,
        },
        
        questIconsSize = {
            type = "range",
            name = L["Icon Size"] or "Icon Size",
            desc = L["Size of the quest icon in pixels"] or "Size of the quest icon in pixels",
            min = 12, max = 48, step = 2,
            get = function() return self.db.profile.questIcons.size end,
            set = function(_, value) 
                self.db.profile.questIcons.size = value
                -- Update all quest icons
                for nameplate in C_NamePlateManager.EnumerateActiveNamePlates() do
                    if nameplate.UnitFrame then
                        self:UpdateQuestIconSize(nameplate)
                    end
                end
            end,
            disabled = function() return not self.db.profile.questIcons.enabled end,
            order = 12,
        },
        
        questIconsPosition = {
            type = "select",
            name = L["Icon Position"] or "Icon Position",
            desc = L["Where to position the quest icon relative to the health bar"] or "Where to position the quest icon relative to the health bar",
            values = {
                ["TOP"] = L["Top"] or "Top",
                ["BOTTOM"] = L["Bottom"] or "Bottom",
                ["LEFT"] = L["Left"] or "Left",
                ["RIGHT"] = L["Right"] or "Right",
            },
            get = function() return self.db.profile.questIcons.position end,
            set = function(_, value) 
                self.db.profile.questIcons.position = value
                -- Update all quest icons
                for nameplate in C_NamePlateManager.EnumerateActiveNamePlates() do
                    if nameplate.UnitFrame then
                        self:UpdateQuestIconSize(nameplate)
                    end
                end
            end,
            disabled = function() return not self.db.profile.questIcons.enabled end,
            order = 13,
        },
        
        questIconsOffsetX = {
            type = "range",
            name = L["Horizontal Offset"] or "Horizontal Offset",
            desc = L["Horizontal offset from the icon position"] or "Horizontal offset from the icon position",
            min = -50, max = 50, step = 1,
            get = function() return self.db.profile.questIcons.offsetX end,
            set = function(_, value) 
                self.db.profile.questIcons.offsetX = value
                -- Update all quest icons
                for nameplate in C_NamePlateManager.EnumerateActiveNamePlates() do
                    if nameplate.UnitFrame then
                        self:UpdateQuestIconSize(nameplate)
                    end
                end
            end,
            disabled = function() return not self.db.profile.questIcons.enabled end,
            order = 14,
        },
        
        questIconsOffsetY = {
            type = "range",
            name = L["Vertical Offset"] or "Vertical Offset",
            desc = L["Vertical offset from the icon position"] or "Vertical offset from the icon position",
            min = -50, max = 50, step = 1,
            get = function() return self.db.profile.questIcons.offsetY end,
            set = function(_, value) 
                self.db.profile.questIcons.offsetY = value
                -- Update all quest icons
                for nameplate in C_NamePlateManager.EnumerateActiveNamePlates() do
                    if nameplate.UnitFrame then
                        self:UpdateQuestIconSize(nameplate)
                    end
                end
            end,
            disabled = function() return not self.db.profile.questIcons.enabled end,
            order = 15,
        },
        
        spacer2 = { type = "description", name = "\n", order = 20 },
        
        questIconsInfoHeader = { type = "header", name = L["How It Works"] or "How It Works", order = 21 },
        
        questIconsInfo = {
            type = "description",
            name = "|cff00ff00" .. (L["Quest Detection"] or "Quest Detection") .. ":|r\n" ..
                   (L["The system scans nameplate tooltips (without requiring mouseover) to detect quest objectives. " ..
                   "It looks for quest progress patterns like '0/6' or '5/10' and only shows the icon when the objective is incomplete. " ..
                   "Once a quest objective is complete (e.g., '6/6'), the icon automatically disappears."] or 
                   "The system scans nameplate tooltips (without requiring mouseover) to detect quest objectives. " ..
                   "It looks for quest progress patterns like '0/6' or '5/10' and only shows the icon when the objective is incomplete. " ..
                   "Once a quest objective is complete (e.g., '6/6'), the icon automatically disappears.") .. "\n\n" ..
                   "|cffFFD700" .. (L["Note"] or "Note") .. ":|r " ..
                   (L["This custom system replaces the native Ascension_NamePlates quest icons, which are automatically hidden when this feature is enabled."] or
                   "This custom system replaces the native Ascension_NamePlates quest icons, which are automatically hidden when this feature is enabled."),
            order = 22,
        },
    }
end

