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
    autoOpenNameplatesConfig = false, -- Si abrir automáticamente la config de nameplates
    
    -- Global Health Bar Texture Override
    globalHealthBarTexture = {
        enabled = false,
        texture = "Blizzard2", -- Default texture name from SharedMedia
    },
    
    -- Mouseover Glow Configuration
    mouseoverGlow = {
        enabled = false, -- Disable mouseover glow globally
        disableOnTarget = true, -- Disable mouseover glow on current target
        intensity = 0.8, -- Glow intensity (0.1 to 1.0)
        hideBorder = true, -- Hide mouseover border
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
}

-------------------------------------------------
-- OnInitialize
-------------------------------------------------
function Module:OnInitialize()
    self.db = YATP.db:RegisterNamespace("NamePlates", { profile = Module.defaults })
end

-------------------------------------------------
-- OnEnable
-------------------------------------------------
function Module:OnEnable()
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
    
    self:SetupTargetGlow()
    self:SetupMouseoverGlow()
    self:DisableAllNameplateGlows()
    
    -- Setup everything after a longer delay to ensure all addons are loaded
    C_Timer.After(2.0, function()
        self:CheckNamePlatesAddon()
        self:SetupThreatSystem()
    end)
    
    -- Apply global health bar texture if enabled
    self:ApplyGlobalHealthBarTexture()
end

-------------------------------------------------
-- OnDisable
-------------------------------------------------
function Module:OnDisable()
    -- Clean up active functionality but keep module registered
    self:CleanupTargetGlow()
    self:CleanupThreatSystem()
    
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

function Module:OnDisable()
    -- Clean up active functionality but keep module registered
    self:CleanupTargetGlow()
    self:CleanupThreatSystem()
    
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
    
    -- Unregister events but don't unregister from options
    self:UnregisterEvent("NAME_PLATE_UNIT_ADDED")
    self:UnregisterEvent("PLAYER_TARGET_CHANGED")
    
    -- Hide any active UI elements without destroying settings
    if self.targetGlowFrames then
        for nameplate, borderData in pairs(self.targetGlowFrames) do
            if borderData.borderFrame then
                borderData.borderFrame:Hide()
            end
        end
    end
end

-------------------------------------------------
-- Target Border System
-------------------------------------------------
function Module:SetupTargetGlow()
    if not self.db.profile.enabled then 
        return 
    end
    
    if not self.db.profile.targetGlow.enabled then
        return
    end
    
    -- Initialize target border data
    self.targetGlowFrames = {}
    self.currentTargetFrame = nil
    
    -- Register events for target border
    self:RegisterEvent("PLAYER_TARGET_CHANGED", "OnTargetChanged")
    self:RegisterEvent("NAME_PLATE_UNIT_ADDED", "OnNamePlateAdded") 
    self:RegisterEvent("NAME_PLATE_UNIT_REMOVED", "OnNamePlateRemoved")
    
    -- Test current target if any
    if UnitExists("target") then
        self:OnTargetChanged()
    end
end

function Module:CleanupTargetGlow()
    -- Remove all existing borders
    if self.targetGlowFrames then
        for nameplate, borderData in pairs(self.targetGlowFrames) do
            self:RemoveTargetGlow(nameplate)
        end
        self.targetGlowFrames = {}
    end
    
    self.currentTargetFrame = nil
    
    -- Unregister events
    self:UnregisterEvent("PLAYER_TARGET_CHANGED")
    self:UnregisterEvent("NAME_PLATE_UNIT_ADDED")
    self:UnregisterEvent("NAME_PLATE_UNIT_REMOVED")
end

function Module:OnTargetChanged()
    if not self.db.profile.enabled or not self.db.profile.targetGlow.enabled then 
        return 
    end
    
    -- Remove glow from previous target
    if self.currentTargetFrame then
        self:RemoveTargetGlow(self.currentTargetFrame)
        self.currentTargetFrame = nil
    end
    
    -- Add glow to new target
    local targetUnit = "target"
    if UnitExists(targetUnit) then
        local targetName = UnitName(targetUnit) or "Unknown"
        
        local found = false
        for nameplate in C_NamePlateManager.EnumerateActiveNamePlates() do
            if nameplate.UnitFrame and nameplate.UnitFrame.unit and UnitIsUnit(nameplate.UnitFrame.unit, targetUnit) then
                self:AddTargetGlow(nameplate)
                self.currentTargetFrame = nameplate
                found = true
                break
            end
        end
    end
end

function Module:OnNamePlateAdded(unit, nameplate)
    if not self.db.profile.enabled or not self.db.profile.targetGlow.enabled then 
        return 
    end
    
    -- Check if this nameplate is for our current target
    if UnitExists("target") and nameplate.UnitFrame and nameplate.UnitFrame.unit and UnitIsUnit(nameplate.UnitFrame.unit, "target") then
        self:AddTargetGlow(nameplate)
        self.currentTargetFrame = nameplate
    end
end

function Module:OnNamePlateRemoved(unit, nameplate)
    -- Clean up glow if this nameplate had one
    if self.targetGlowFrames and self.targetGlowFrames[nameplate] then
        self:RemoveTargetGlow(nameplate)
        if self.currentTargetFrame == nameplate then
            self.currentTargetFrame = nil
        end
    end
end

function Module:AddTargetGlow(nameplate)
    if not nameplate or not nameplate.UnitFrame then 
        return 
    end
    
    -- Don't add border if already exists
    if self.targetGlowFrames and self.targetGlowFrames[nameplate] then
        return
    end
    
    local healthBar = nameplate.UnitFrame.healthBar
    if not healthBar then 
        return 
    end
    
    -- Create border frame
    local borderFrame = CreateFrame("Frame", nil, nameplate)
    borderFrame:SetFrameLevel(healthBar:GetFrameLevel() + 1)
    
    -- Create border textures (4 sides)
    local borderThickness = self.db.profile.targetGlow.size or 2
    local borderColor = self.db.profile.targetGlow.color or {1, 1, 0, 0.8}
    
    -- Top border
    local topBorder = borderFrame:CreateTexture(nil, "OVERLAY")
    topBorder:SetColorTexture(borderColor[1], borderColor[2], borderColor[3], borderColor[4])
    topBorder:SetPoint("TOPLEFT", healthBar, "TOPLEFT", -borderThickness, borderThickness)
    topBorder:SetPoint("TOPRIGHT", healthBar, "TOPRIGHT", borderThickness, borderThickness)
    topBorder:SetHeight(borderThickness)
    
    -- Bottom border
    local bottomBorder = borderFrame:CreateTexture(nil, "OVERLAY")
    bottomBorder:SetColorTexture(borderColor[1], borderColor[2], borderColor[3], borderColor[4])
    bottomBorder:SetPoint("BOTTOMLEFT", healthBar, "BOTTOMLEFT", -borderThickness, -borderThickness)
    bottomBorder:SetPoint("BOTTOMRIGHT", healthBar, "BOTTOMRIGHT", borderThickness, -borderThickness)
    bottomBorder:SetHeight(borderThickness)
    
    -- Left border
    local leftBorder = borderFrame:CreateTexture(nil, "OVERLAY")
    leftBorder:SetColorTexture(borderColor[1], borderColor[2], borderColor[3], borderColor[4])
    leftBorder:SetPoint("TOPLEFT", healthBar, "TOPLEFT", -borderThickness, borderThickness)
    leftBorder:SetPoint("BOTTOMLEFT", healthBar, "BOTTOMLEFT", -borderThickness, -borderThickness)
    leftBorder:SetWidth(borderThickness)
    
    -- Right border
    local rightBorder = borderFrame:CreateTexture(nil, "OVERLAY")
    rightBorder:SetColorTexture(borderColor[1], borderColor[2], borderColor[3], borderColor[4])
    rightBorder:SetPoint("TOPRIGHT", healthBar, "TOPRIGHT", borderThickness, borderThickness)
    rightBorder:SetPoint("BOTTOMRIGHT", healthBar, "BOTTOMRIGHT", borderThickness, -borderThickness)
    rightBorder:SetWidth(borderThickness)
    
    -- Store border data (always static)
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

function Module:RemoveTargetGlow(nameplate)
    if not self.targetGlowFrames or not self.targetGlowFrames[nameplate] then
        return
    end
    
    local borderData = self.targetGlowFrames[nameplate]
    
    -- Remove border frame and all its textures
    if borderData.borderFrame then
        borderData.borderFrame:Hide()
        -- The textures will be cleaned up with the frame
    end
    
    -- Remove from tracking
    self.targetGlowFrames[nameplate] = nil
    
    -- Debug removed - too spammy for target border
end

function Module:UpdateAllTargetGlows()
    -- Remove all existing borders
    if self.targetGlowFrames then
        for nameplate, borderData in pairs(self.targetGlowFrames) do
            self:RemoveTargetGlow(nameplate)
        end
    end
    
    -- Re-add border to current target if enabled
    if self.db.profile.targetGlow.enabled and UnitExists("target") then
        self:OnTargetChanged()
    end
end

-------------------------------------------------
-- Mouseover Glow System
-------------------------------------------------
function Module:SetupMouseoverGlow()
    if not self.db.profile.enabled then return end
    
    -- Hook into nameplate creation to control selectionHighlight
    self:SetupSelectionHighlightHooks()
end

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

function Module:OnNamePlateGlowDisable()
    -- Disable glows whenever nameplates are added or target changes
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
end

function Module:OnThreatUpdate(event, unit)
    if not self.db.profile.threatSystem.enabled then return end
    
    -- Update threat for all nameplates when threat changes
    self:UpdateAllThreatIndicators()
end

function Module:OnThreatTargetChanged()
    if not self.db.profile.threatSystem.enabled then return end
    
    self:UpdateAllThreatIndicators()
    
    -- IMPORTANT: Also call target border system since this event handler is the active one
    self:OnTargetChanged()
end

function Module:OnThreatUnitTarget(event, unit)
    if not self.db.profile.threatSystem.enabled then return end
    
    self:UpdateAllThreatIndicators()
end

function Module:OnThreatCombatStart()
    if not self.db.profile.threatSystem.enabled then return end
    
    self:UpdateAllThreatIndicators()
end

function Module:OnThreatCombatEnd()
    if not self.db.profile.threatSystem.enabled then return end
    
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
    
    -- Reset to default nameplate health bar color
    -- This will restore the original color (usually red for enemies)
    unitFrame.healthBar:SetStatusBarColor(1, 0, 0, 1) -- Default red for enemies
    
    -- Also reset texture color
    local texture = unitFrame.healthBar:GetStatusBarTexture()
    if texture then
        texture:SetVertexColor(1, 0, 0, 1)
    end
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
    
    -- Reset name color to default
    if unitFrame.name then
        -- Let the game handle default name coloring
        unitFrame.name:SetTextColor(1, 1, 1, 1)
    end
    
    -- Reset health bar color to default  
    if unitFrame.healthBar then
        -- Let the game handle default health bar coloring
        unitFrame.healthBar:SetStatusBarColor(0, 1, 0, 1)
    end
    
    -- Hide threat border
    if unitFrame.threatBorder then
        unitFrame.threatBorder:Hide()
    end
end

function Module:UpdateThreatSettings()
    -- Update all threat indicators when settings change
    self:UpdateAllThreatIndicators()
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
        
        tabs.friendly = {
            type = "group",
            name = L["Friendly"] or "Friendly",
            desc = L["Settings for friendly unit nameplates"] or "Settings for friendly unit nameplates",
            order = 3,
            args = self:BuildFriendlyTab()
        }
        
        tabs.enemy = {
            type = "group",
            name = L["Enemy"] or "Enemy",
            desc = L["Settings for enemy unit nameplates"] or "Settings for enemy unit nameplates",
            order = 4,
            args = self:BuildEnemyTab()
        }
        
        tabs.enemyTarget = {
            type = "group",
            name = L["Enemy Target"] or "Enemy Target",
            desc = L["Settings for targeted enemy nameplates"] or "Settings for targeted enemy nameplates",
            order = 5,
            args = self:BuildEnemyTargetTab()
        }
        
        tabs.personal = {
            type = "group",
            name = L["Personal"] or "Personal",
            desc = L["Settings for your own nameplate"] or "Settings for your own nameplate",
            order = 6,
            args = self:BuildPersonalTab()
        }
    else
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
                    self.db.profile.enabled = value
                    if value then
                        -- Re-enable functionality without calling AceAddon Enable
                        self:SetupTargetGlow()
                        self:SetupMouseoverGlow()
                        self:SetupThreatSystem()
                        self:DisableAllNameplateGlows()
                        self:ApplyGlobalHealthBarTexture()
                    else
                        -- Disable functionality without calling AceAddon Disable
                        self:CleanupTargetGlow()
                        self:CleanupThreatSystem()
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
        
        loadAddon = {
            type = "execute",
            name = L["Load NamePlates Addon"] or "Load NamePlates Addon",
            desc = L["Attempt to load the Ascension NamePlates addon"] or "Attempt to load the Ascension NamePlates addon",
            func = function()
                if self:LoadNamePlatesAddon() then
                    YATP:Print("Ascension NamePlates addon loaded successfully.")
                    -- Refresh the options to show new tabs
                    LibStub("AceConfigRegistry-3.0"):NotifyChange("YATP-NamePlates")
                else
                    YATP:Print("Could not load Ascension NamePlates addon.")
                end
            end,
            disabled = function() 
                local currentStatus = self:GetNamePlatesStatus()
                return currentStatus.loaded or not currentStatus.loadable 
            end,
            order = 21,
        },
        
        openOriginal = {
            type = "execute",
            name = L["Open Original Configuration"] or "Open Original Configuration",
            desc = L["Open the original configuration panel for Ascension NamePlates"] or "Open the original configuration panel for Ascension NamePlates",
            func = function() self:OpenNamePlatesConfig() end,
            disabled = function() return not self:CanConfigureNamePlates() end,
            order = 22,
        },
        
        spacer3 = { type = "description", name = "\n", order = 25 },
        
        -- Information section
        infoHeader = { type = "header", name = L["Information"] or "Information", order = 30 },
        
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
            order = 31,
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
        
        -- Style settings
        styleHeader = { type = "header", name = L["Style"] or "Style", order = 10 },
        
        useClassicStyle = {
            type = "toggle",
            name = L["Classic Style"] or "Classic Style",
            desc = L["Use classic style textures for nameplates"] or "Use classic style textures for nameplates",
            get = function() return self:GetNamePlatesOption("general", "useClassicStyle") end,
            set = function(_, value) self:SetNamePlatesOption("general", "useClassicStyle", nil, value) end,
            order = 11,
        },
        
        targetScale = {
            type = "range",
            name = L["Target Scale"] or "Target Scale",
            desc = L["Sets the scale of the NamePlate when it is the target"] or "Sets the scale of the NamePlate when it is the target",
            min = 0.8, max = 1.4, step = 0.1,
            get = function() return self:GetNamePlatesOption("general", "clickable", "targetScale") or 1.1 end,
            set = function(_, value) self:SetNamePlatesOption("general", "clickable", "targetScale", value) end,
            order = 12,
        },
        
        spacer2 = { type = "description", name = "\n", order = 15 },
        
        -- Global Health Bar Texture Override
        globalTextureHeader = { type = "header", name = L["Global Health Bar Texture"] or "Global Health Bar Texture", order = 16 },
        
        globalTextureDesc = {
            type = "description",
            name = L["Override the health bar texture for ALL nameplates (friendly, enemy, and personal). This ensures consistent texture across all nameplate types, including targets."] or "Override the health bar texture for ALL nameplates (friendly, enemy, and personal). This ensures consistent texture across all nameplate types, including targets.",
            order = 17,
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
            order = 18,
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
            order = 19,
        },
        
        spacer3 = { type = "description", name = "\n", order = 25 },
        
        -- Threat System (YATP Custom Feature)
        threatHeader = { type = "header", name = L["Threat System (YATP Custom)"] or "Threat System (YATP Custom)", order = 30 },
        
        threatEnabled = {
            type = "toggle",
            name = L["Enable Threat System"] or "Enable Threat System",
            desc = L["Color nameplates based on your threat level with that enemy"] or "Color nameplates based on your threat level with that enemy",
            get = function() return self.db.profile.threatSystem.enabled end,
            set = function(_, value) 
                self.db.profile.threatSystem.enabled = value
                if value then
                    self:SetupThreatSystem()
                else
                    self:CleanupThreatSystem()
                end
            end,
            order = 31,
        },
        
        threatColors = {
            type = "group",
            name = L["Threat Colors"] or "Threat Colors",
            desc = L["Configure colors for different threat levels"] or "Configure colors for different threat levels",
            inline = true,
            disabled = function() return not self.db.profile.threatSystem.enabled end,
            order = 33,
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
        
        spacer4 = { type = "description", name = "\n", order = 34 },
        
        -- Clickable area settings
        clickableHeader = { type = "header", name = L["Clickable Area"] or "Clickable Area", order = 35 },
        
        clickableDesc = {
            type = "description",
            name = L["These settings control the invisible clickable area of nameplates. This does not affect the visual appearance of health bars."] or "These settings control the invisible clickable area of nameplates. This does not affect the visual appearance of health bars.",
            order = 36,
        },
        
        clickableWidth = {
            type = "range",
            name = L["Clickable Width"] or "Clickable Width",
            desc = L["Controls the clickable area width of the NamePlate"] or "Controls the clickable area width of the NamePlate",
            min = 50, max = 200, step = 1,
            get = function() 
                return self:GetNamePlatesOption("general", "clickable", "width") or 
                       (C_CVar and C_CVar.GetDefaultNumber and C_CVar.GetDefaultNumber("nameplateWidth")) or 110
            end,
            set = function(_, value) 
                self:SetNamePlatesOption("general", "clickable", "width", value)
                if C_NamePlateManager and C_NamePlateManager.SetNamePlateSize then
                    local height = self:GetNamePlatesOption("general", "clickable", "height") or 45
                    C_NamePlateManager.SetNamePlateSize(value, height)
                end
            end,
            order = 37,
        },
        
        clickableHeight = {
            type = "range",
            name = L["Clickable Height"] or "Clickable Height",
            desc = L["Controls the clickable area height of the NamePlate"] or "Controls the clickable area height of the NamePlate",
            min = 20, max = 80, step = 1,
            get = function() 
                return self:GetNamePlatesOption("general", "clickable", "height") or 
                       (C_CVar and C_CVar.GetDefaultNumber and C_CVar.GetDefaultNumber("nameplateHeight")) or 45
            end,
            set = function(_, value) 
                self:SetNamePlatesOption("general", "clickable", "height", value)
                if C_NamePlateManager and C_NamePlateManager.SetNamePlateSize then
                    local width = self:GetNamePlatesOption("general", "clickable", "width") or 110
                    C_NamePlateManager.SetNamePlateSize(width, value)
                end
            end,
            order = 38,
        },
        
        showClickableBox = {
            type = "toggle",
            name = L["Show Clickable Box"] or "Show Clickable Box",
            desc = L["Draw a white box over the clickable area on all NamePlates"] or "Draw a white box over the clickable area on all NamePlates",
            get = function() 
                return C_CVar and C_CVar.GetBool and C_CVar.GetBool("DrawNameplateClickBox") 
            end,
            set = function(_, value) 
                if C_CVar and C_CVar.Set then
                    C_CVar.Set("DrawNameplateClickBox", value)
                end
                local addon = self:GetNamePlatesAddon()
                if addon and addon.UpdateAll then
                    addon:UpdateAll()
                end
            end,
            order = 39,
        },
    }
end

-------------------------------------------------
-- Build Friendly Tab
-------------------------------------------------
function Module:BuildFriendlyTab()
    return {
        desc = {
            type = "description",
            name = L["Configure nameplate settings for friendly units (party members, guild members, etc.)."] or "Configure nameplate settings for friendly units (party members, guild members, etc.).",
            order = 1,
        },
        
        spacer1 = { type = "description", name = "\n", order = 5 },
        
        -- Display options
        displayHeader = { type = "header", name = L["Display Options"] or "Display Options", order = 10 },
        
        nameOnly = {
            type = "toggle",
            name = L["Name Only"] or "Name Only",
            desc = L["Only show the name on friendly nameplates (no health bar)"] or "Only show the name on friendly nameplates (no health bar)",
            get = function() return self:GetNamePlatesOption("friendly", "health", "nameOnly") end,
            set = function(_, value) self:SetNamePlatesOption("friendly", "health", "nameOnly", value) end,
            order = 11,
        },
        
        spacer2 = { type = "description", name = "\n", order = 15 },
        
        -- Health bar settings
        healthHeader = { type = "header", name = L["Health Bar"] or "Health Bar", order = 20 },
        
        healthWidth = {
            type = "range",
            name = L["Width"] or "Width",
            desc = L["Sets the width of friendly nameplate health bars"] or "Sets the width of friendly nameplate health bars",
            min = 40, max = 200, step = 1,
            get = function() return self:GetNamePlatesOption("friendly", "health", "width") or 110 end,
            set = function(_, value) self:SetNamePlatesOption("friendly", "health", "width", value) end,
            disabled = function() return self:GetNamePlatesOption("friendly", "health", "nameOnly") end,
            order = 21,
        },
        
        healthHeight = {
            type = "range",
            name = L["Height"] or "Height",
            desc = L["Sets the height of friendly nameplate health bars"] or "Sets the height of friendly nameplate health bars",
            min = 4, max = 60, step = 1,
            get = function() return self:GetNamePlatesOption("friendly", "health", "height") or 4 end,
            set = function(_, value) self:SetNamePlatesOption("friendly", "health", "height", value) end,
            disabled = function() return self:GetNamePlatesOption("friendly", "health", "nameOnly") end,
            order = 22,
        },
        
        showHealthText = {
            type = "toggle",
            name = L["Show Health Text"] or "Show Health Text",
            desc = L["Show health text on friendly nameplates"] or "Show health text on friendly nameplates",
            get = function() return self:GetNamePlatesOption("friendly", "health", "showTextFormat") end,
            set = function(_, value) self:SetNamePlatesOption("friendly", "health", "showTextFormat", value) end,
            disabled = function() return self:GetNamePlatesOption("friendly", "health", "nameOnly") end,
            order = 23,
        },
    }
end

-------------------------------------------------
-- Build Enemy Tab
-------------------------------------------------
function Module:BuildEnemyTab()
    return {
        desc = {
            type = "description",
            name = L["Configure nameplate settings for enemy units and hostile NPCs."] or "Configure nameplate settings for enemy units and hostile NPCs.",
            order = 1,
        },
        
        spacer1 = { type = "description", name = "\n", order = 5 },
        
        -- Health bar settings
        healthHeader = { type = "header", name = L["Health Bar"] or "Health Bar", order = 10 },
        
        healthWidth = {
            type = "range",
            name = L["Width"] or "Width",
            desc = L["Sets the width of enemy nameplate health bars"] or "Sets the width of enemy nameplate health bars",
            min = 40, max = 200, step = 1,
            get = function() return self:GetNamePlatesOption("enemy", "health", "width") or 110 end,
            set = function(_, value) self:SetNamePlatesOption("enemy", "health", "width", value) end,
            order = 11,
        },
        
        healthHeight = {
            type = "range",
            name = L["Height"] or "Height",
            desc = L["Sets the height of enemy nameplate health bars"] or "Sets the height of enemy nameplate health bars",
            min = 4, max = 60, step = 1,
            get = function() return self:GetNamePlatesOption("enemy", "health", "height") or 4 end,
            set = function(_, value) self:SetNamePlatesOption("enemy", "health", "height", value) end,
            order = 12,
        },
        
        showHealthText = {
            type = "toggle",
            name = L["Show Health Text"] or "Show Health Text",
            desc = L["Show health text on enemy nameplates"] or "Show health text on enemy nameplates",
            get = function() return self:GetNamePlatesOption("enemy", "health", "showTextFormat") end,
            set = function(_, value) self:SetNamePlatesOption("enemy", "health", "showTextFormat", value) end,
            order = 13,
        },
        
        spacer2 = { type = "description", name = "\n", order = 15 },
        
        -- Cast bar settings
        castBarHeader = { type = "header", name = L["Cast Bar"] or "Cast Bar", order = 20 },
        
        castBarEnabled = {
            type = "toggle",
            name = L["Enable Cast Bars"] or "Enable Cast Bars",
            desc = L["Show cast bars on enemy nameplates"] or "Show cast bars on enemy nameplates",
            get = function() return self:GetNamePlatesOption("enemy", "castBar", "enabled") end,
            set = function(_, value) self:SetNamePlatesOption("enemy", "castBar", "enabled", value) end,
            order = 21,
        },
        
        castBarHeight = {
            type = "range",
            name = L["Cast Bar Height"] or "Cast Bar Height",
            desc = L["Height of enemy cast bars"] or "Height of enemy cast bars",
            min = 4, max = 32, step = 1,
            get = function() return self:GetNamePlatesOption("enemy", "castBar", "height") or 10 end,
            set = function(_, value) self:SetNamePlatesOption("enemy", "castBar", "height", value) end,
            disabled = function() return not self:GetNamePlatesOption("enemy", "castBar", "enabled") end,
            order = 22,
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
            name = L["Configure nameplate settings for enemy units that you have targeted. This includes the official Target Scale option and custom Target Border enhancements."] or "Configure nameplate settings for enemy units that you have targeted. This includes the official Target Scale option and custom Target Border enhancements.",
            order = 1,
        },
        
        spacer1 = { type = "description", name = "\n", order = 5 },
        
        -- Target scaling (the only real target-specific option from original addon)
        targetingHeader = { type = "header", name = L["Target Scaling"] or "Target Scaling", order = 10 },
        
        targetScale = {
            type = "range",
            name = L["Target Scale"] or "Target Scale",
            desc = L["Sets the scale of the NamePlate when it is the target. This affects ALL targeted nameplates (friendly and enemy)."] or "Sets the scale of the NamePlate when it is the target. This affects ALL targeted nameplates (friendly and enemy).",
            min = 0.8, max = 1.4, step = 0.1,
            get = function() return self:GetNamePlatesOption("general", "clickable", "targetScale") or 1.1 end,
            set = function(_, value) self:SetNamePlatesOption("general", "clickable", "targetScale", value) end,
            order = 11,
        },
        
        targetScaleInfo = {
            type = "description",
            name = "|cffFFD700" .. (L["Information"] or "Information") .. ":|r " .. (L["This is the official setting for targeted nameplates from the NamePlates addon. It makes the nameplate larger when you target an enemy."] or "This is the official setting for targeted nameplates from the NamePlates addon. It makes the nameplate larger when you target an enemy."),
            fontSize = "small",
            order = 12,
        },
        
        spacer2 = { type = "description", name = "\n", order = 15 },
        
        -- Target Border System (YATP Custom Feature)
        targetGlowHeader = { type = "header", name = L["Target Border (YATP Custom)"] or "Target Border (YATP Custom)", order = 20 },
        
        targetGlowEnabled = {
            type = "toggle",
            name = L["Enable Target Border"] or "Enable Target Border",
            desc = L["Add a colored border around the nameplate of your current target for better visibility"] or "Add a colored border around the nameplate of your current target for better visibility",
            get = function() return self.db.profile.targetGlow.enabled end,
            set = function(_, value) 
                self.db.profile.targetGlow.enabled = value
                self:UpdateAllTargetGlows()
            end,
            order = 21,
        },
        
        targetGlowColor = {
            type = "color",
            name = L["Border Color"] or "Border Color",
            desc = L["Color of the target border effect"] or "Color of the target border effect",
            hasAlpha = true,
            get = function() 
                local color = self.db.profile.targetGlow.color
                return color[1], color[2], color[3], color[4]
            end,
            set = function(_, r, g, b, a) 
                self.db.profile.targetGlow.color = {r, g, b, a}
                self:UpdateAllTargetGlows()
            end,
            disabled = function() return not self.db.profile.targetGlow.enabled end,
            order = 22,
        },
        
        targetGlowSize = {
            type = "range",
            name = L["Border Thickness"] or "Border Thickness",
            desc = L["Thickness of the border in pixels. Higher values create a thicker border"] or "Thickness of the border in pixels. Higher values create a thicker border",
            min = 1, max = 5, step = 1,
            get = function() return self.db.profile.targetGlow.size or 2 end,
            set = function(_, value) 
                self.db.profile.targetGlow.size = value
                self:UpdateAllTargetGlows()
            end,
            disabled = function() return not self.db.profile.targetGlow.enabled end,
            order = 23,
        },
        
        spacer3 = { type = "description", name = "\n", order = 25 },
        
        -- Additional enemy options reference
        additionalHeader = { type = "header", name = L["Additional Enemy Options"] or "Additional Enemy Options", order = 30 },
        
        additionalInfo = {
            type = "description",
            name = L["For more enemy nameplate customization options, visit the"] or "For more enemy nameplate customization options, visit the" .. " |cff00ff00" .. (L["Enemy"] or "Enemy") .. "|r " .. (L["tab. There you can configure:"] or "tab. There you can configure:") .. "\n\n" ..
                   "• " .. (L["Health bar appearance and size"] or "Health bar appearance and size") .. "\n" ..
                   "• " .. (L["Name display and fonts"] or "Name display and fonts") .. "\n" ..
                   "• " .. (L["Cast bar settings"] or "Cast bar settings") .. "\n" ..
                   "• " .. (L["Level indicators"] or "Level indicators") .. "\n" ..
                   "• " .. (L["Quest objective icons"] or "Quest objective icons") .. "\n\n" ..
                   (L["All these settings apply to enemy nameplates, including when they are targeted."] or "All these settings apply to enemy nameplates, including when they are targeted."),
            order = 31,
        },
    }
end

-------------------------------------------------
-- Build Personal Tab
-------------------------------------------------
function Module:BuildPersonalTab()
    return {
        desc = {
            type = "description",
            name = L["Configure your own personal nameplate that appears above your character."] or "Configure your own personal nameplate that appears above your character.",
            order = 1,
        },
        
        spacer1 = { type = "description", name = "\n", order = 5 },
        
        -- Health bar settings
        healthHeader = { type = "header", name = L["Health Bar"] or "Health Bar", order = 10 },
        
        healthWidth = {
            type = "range",
            name = L["Width"] or "Width",
            desc = L["Sets the width of your personal nameplate health bar"] or "Sets the width of your personal nameplate health bar",
            min = 40, max = 200, step = 1,
            get = function() return self:GetNamePlatesOption("personal", "health", "width") or 80 end,
            set = function(_, value) self:SetNamePlatesOption("personal", "health", "width", value) end,
            order = 11,
        },
        
        healthHeight = {
            type = "range",
            name = L["Height"] or "Height",
            desc = L["Sets the height of your personal nameplate health bar"] or "Sets the height of your personal nameplate health bar",
            min = 4, max = 60, step = 1,
            get = function() return self:GetNamePlatesOption("personal", "health", "height") or 8 end,
            set = function(_, value) self:SetNamePlatesOption("personal", "health", "height", value) end,
            order = 12,
        },
        
        showHealthText = {
            type = "toggle",
            name = L["Show Health Text"] or "Show Health Text",
            desc = L["Show health text on your personal nameplate"] or "Show health text on your personal nameplate",
            get = function() return self:GetNamePlatesOption("personal", "health", "showTextFormat") end,
            set = function(_, value) self:SetNamePlatesOption("personal", "health", "showTextFormat", value) end,
            order = 13,
        },
    }
end