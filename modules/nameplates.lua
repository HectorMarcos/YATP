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
    -- Register slash commands for debugging
    self:RegisterChatCommand("yatpnp", "SlashCommand")
    self:RegisterChatCommand("yatpnameplates", "SlashCommand")
    
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
    
    self:SetupTargetGlow()
    self:SetupTargetArrows()
    self:SetupMouseoverGlow()
    self:DisableAllNameplateGlows()
    
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
    self:CleanupTargetGlow()
    self:CleanupTargetArrows()
    self:CleanupThreatSystem()
    self:CleanupHealthTextPositioning()
    self:CleanupNonTargetAlpha()
    
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
    -- DEBUG: Hook mouseover on newly added nameplates
    if self.db.profile.enabled then
        self:HookMouseoverOnNameplate(nameplate)
    end
    
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
-- Target Arrows System
-------------------------------------------------
function Module:SetupTargetArrows()
    if not self.db.profile.enabled then 
        return 
    end
    
    if not self.db.profile.targetArrows.enabled then
        return
    end
    
    -- Initialize target arrows data
    self.targetArrowFrames = {}
    self.currentTargetArrowFrame = nil
    
    -- Register events for target arrows (reuse target border events)
    self:RegisterEvent("PLAYER_TARGET_CHANGED", "OnTargetArrowChanged")
    self:RegisterEvent("NAME_PLATE_UNIT_ADDED", "OnNamePlateArrowAdded") 
    self:RegisterEvent("NAME_PLATE_UNIT_REMOVED", "OnNamePlateArrowRemoved")
    
    -- Test current target if any
    if UnitExists("target") then
        self:OnTargetArrowChanged()
    end
end

function Module:CleanupTargetArrows()
    -- Remove all existing arrows
    if self.targetArrowFrames then
        for nameplate, arrowData in pairs(self.targetArrowFrames) do
            self:RemoveTargetArrows(nameplate)
        end
        self.targetArrowFrames = {}
    end
    
    self.currentTargetArrowFrame = nil
    
    -- Don't unregister events as they're shared with target border system
end

function Module:OnTargetArrowChanged()
    if not self.db.profile.enabled or not self.db.profile.targetArrows.enabled then 
        return 
    end
    
    -- Remove arrows from previous target
    if self.currentTargetArrowFrame then
        self:RemoveTargetArrows(self.currentTargetArrowFrame)
        self.currentTargetArrowFrame = nil
    end
    
    -- Add arrows to new target
    local targetUnit = "target"
    if UnitExists(targetUnit) then
        for nameplate in C_NamePlateManager.EnumerateActiveNamePlates() do
            if nameplate.UnitFrame and nameplate.UnitFrame.unit and UnitIsUnit(nameplate.UnitFrame.unit, targetUnit) then
                self:AddTargetArrows(nameplate)
                self.currentTargetArrowFrame = nameplate
                break
            end
        end
    end
end

function Module:OnNamePlateArrowAdded(unit, nameplate)
    if not self.db.profile.enabled or not self.db.profile.targetArrows.enabled then 
        return 
    end
    
    -- Check if this nameplate is for our current target
    if UnitExists("target") and nameplate.UnitFrame and nameplate.UnitFrame.unit and UnitIsUnit(nameplate.UnitFrame.unit, "target") then
        self:AddTargetArrows(nameplate)
        self.currentTargetArrowFrame = nameplate
    end
end

function Module:OnNamePlateArrowRemoved(unit, nameplate)
    -- Clean up arrows if this nameplate had them
    if self.targetArrowFrames and self.targetArrowFrames[nameplate] then
        self:RemoveTargetArrows(nameplate)
        if self.currentTargetArrowFrame == nameplate then
            self.currentTargetArrowFrame = nil
        end
    end
end

function Module:AddTargetArrows(nameplate)
    if not nameplate or not nameplate.UnitFrame then 
        return 
    end
    
    -- Don't add arrows if already exists
    if self.targetArrowFrames and self.targetArrowFrames[nameplate] then
        return
    end
    
    local healthBar = nameplate.UnitFrame.healthBar
    if not healthBar then 
        return 
    end
    
    -- Get settings
    local arrowSize = self.db.profile.targetArrows.size or 32
    local offsetX = self.db.profile.targetArrows.offsetX or 15
    local offsetY = self.db.profile.targetArrows.offsetY or 0
    local color = self.db.profile.targetArrows.color or {1, 1, 1, 1}
    
    -- Create arrow container frame with high strata
    local arrowFrame = CreateFrame("Frame", nil, nameplate)
    arrowFrame:SetFrameStrata("HIGH") -- Above all nameplate elements
    arrowFrame:SetFrameLevel(healthBar:GetFrameLevel() + 10) -- Well above level/elite icons
    
    -- Left arrow texture (pointing RIGHT toward nameplate)
    local leftArrow = arrowFrame:CreateTexture(nil, "OVERLAY")
    leftArrow:SetTexture("Interface\\AddOns\\YATP\\media\\arrow")
    leftArrow:SetSize(arrowSize, arrowSize)
    leftArrow:SetPoint("RIGHT", healthBar, "LEFT", -offsetX, offsetY)
    leftArrow:SetVertexColor(color[1], color[2], color[3], color[4])
    -- Normal orientation (pointing right toward nameplate)
    leftArrow:SetTexCoord(0, 1, 0, 1)
    
    -- Right arrow texture (pointing LEFT toward nameplate)
    local rightArrow = arrowFrame:CreateTexture(nil, "OVERLAY")
    rightArrow:SetTexture("Interface\\AddOns\\YATP\\media\\arrow")
    rightArrow:SetSize(arrowSize, arrowSize)
    rightArrow:SetPoint("LEFT", healthBar, "RIGHT", offsetX, offsetY)
    rightArrow:SetVertexColor(color[1], color[2], color[3], color[4])
    -- Flip horizontally to point left toward nameplate
    rightArrow:SetTexCoord(1, 0, 0, 1)
    
    -- Store arrow data
    if not self.targetArrowFrames then
        self.targetArrowFrames = {}
    end
    
    self.targetArrowFrames[nameplate] = {
        arrowFrame = arrowFrame,
        arrows = {
            left = leftArrow,
            right = rightArrow
        }
    }
end

function Module:RemoveTargetArrows(nameplate)
    if not self.targetArrowFrames or not self.targetArrowFrames[nameplate] then
        return
    end
    
    local arrowData = self.targetArrowFrames[nameplate]
    
    -- Remove arrow frame and all its textures
    if arrowData.arrowFrame then
        arrowData.arrowFrame:Hide()
    end
    
    -- Remove from tracking
    self.targetArrowFrames[nameplate] = nil
end

function Module:UpdateAllTargetArrows()
    -- Remove all existing arrows
    if self.targetArrowFrames then
        for nameplate, arrowData in pairs(self.targetArrowFrames) do
            self:RemoveTargetArrows(nameplate)
        end
    end
    
    -- Re-add arrows to current target if enabled
    if self.db.profile.targetArrows.enabled and UnitExists("target") then
        self:OnTargetArrowChanged()
    end
end

-------------------------------------------------
-- Mouseover Glow System
-------------------------------------------------
function Module:SetupMouseoverGlow()
    if not self.db.profile.enabled then return end
    
    -- Hook into nameplate creation to control selectionHighlight
    self:SetupSelectionHighlightHooks()
    
    -- DEBUG: Hook mouseover detection
    self:SetupMouseoverDebug()
end

-------------------------------------------------
-- Mouseover Debug System
-------------------------------------------------
function Module:SetupMouseoverDebug()
    -- Hook UPDATE_MOUSEOVER_UNIT event to catch mouseover changes
    self:RegisterEvent("UPDATE_MOUSEOVER_UNIT", "OnMouseoverDebug")
    
    -- Hook nameplate frames to detect mouseover on the actual frame
    for nameplate in C_NamePlateManager.EnumerateActiveNamePlates() do
        if nameplate.UnitFrame then
            self:HookMouseoverOnNameplate(nameplate)
        end
    end
    
    -- Start a timer to periodically capture pre-mouseover state
    if not self.stateCaptureTicker then
        self.stateCaptureTicker = C_Timer.NewTicker(0.5, function()
            if Module.mouseoverDebugEnabled then
                -- Capture state of all nameplates that are NOT mouseover
                for nameplate in C_NamePlateManager.EnumerateActiveNamePlates() do
                    if nameplate.UnitFrame and nameplate.UnitFrame.unit then
                        local isMouseover = UnitIsUnit(nameplate.UnitFrame.unit, "mouseover")
                        if not isMouseover then
                            nameplate.preMouseoverState = Module:CaptureNameplateState(nameplate)
                        end
                    end
                end
            end
        end)
    end
end

function Module:OnMouseoverDebug()
    -- Only print if debug mode is enabled
    if not self.mouseoverDebugEnabled then
        return
    end
    
    if UnitExists("mouseover") then
        local mouseoverName = UnitName("mouseover") or "Unknown"
        local mouseoverGUID = UnitGUID("mouseover")
        print(string.format("[YATP NamePlates] MOUSEOVER DETECTED: %s (GUID: %s)", mouseoverName, tostring(mouseoverGUID)))
        
        -- Check what's happening with the nameplate
        for nameplate in C_NamePlateManager.EnumerateActiveNamePlates() do
            if nameplate.UnitFrame and nameplate.UnitFrame.unit then
                if UnitIsUnit(nameplate.UnitFrame.unit, "mouseover") then
                    print(string.format("[YATP NamePlates] Found matching nameplate for: %s", mouseoverName))
                    self:DebugNameplateState(nameplate)
                    break
                end
            end
        end
    else
        print("[YATP NamePlates] MOUSEOVER CLEARED (no unit)")
    end
end

function Module:HookMouseoverOnNameplate(nameplate)
    if not nameplate.UnitFrame or nameplate.UnitFrame.mouseoverHooked then
        return
    end
    
    -- Store state before mouseover for comparison
    nameplate.preMouseoverState = nil
    
    -- Hook OnEnter script on UnitFrame
    if nameplate.UnitFrame:HasScript("OnEnter") then
        nameplate.UnitFrame:HookScript("OnEnter", function(frame)
            -- Only print if debug mode is enabled
            if not Module.mouseoverDebugEnabled then
                return
            end
            
            local unit = frame.unit or frame.displayedUnit
            if unit then
                local unitName = UnitName(unit) or "Unknown"
                print(string.format("[YATP NamePlates] UnitFrame OnEnter: %s", unitName))
                
                -- Debug immediately (don't wait)
                Module:DebugAllNameplateChildren(nameplate)
                Module:CompareNameplateStates(nameplate)
            end
        end)
    end
    
    -- CRITICAL: Hook OnEnter on the BASE nameplate frame too!
    if nameplate:HasScript("OnEnter") then
        nameplate:HookScript("OnEnter", function(frame)
            if Module.mouseoverDebugEnabled then
                print("[YATP NamePlates] *** BASE NAMEPLATE OnEnter ***")
            end
        end)
    end
    
    -- Try to enable mouse on base frame if it's disabled
    if not nameplate:IsMouseEnabled() then
        nameplate:EnableMouse(true)
        if Module.mouseoverDebugEnabled then
            print("[YATP NamePlates] Enabled mouse on base nameplate frame")
        end
    end
    
    -- Hook OnLeave script
    if nameplate.UnitFrame:HasScript("OnLeave") then
        nameplate.UnitFrame:HookScript("OnLeave", function(frame)
            -- Only print if debug mode is enabled
            if not Module.mouseoverDebugEnabled then
                return
            end
            
            local unit = frame.unit or frame.displayedUnit
            if unit then
                local unitName = UnitName(unit) or "Unknown"
                print(string.format("[YATP NamePlates] Frame OnLeave: %s", unitName))
                
                -- Show state after leaving
                if Module.mouseoverDebugEnabled then
                    Module:DebugNameplateState(nameplate)
                end
            end
        end)
    end
    
    -- Hook healthBar.border Show/Hide if it exists
    if nameplate.UnitFrame.healthBar and nameplate.UnitFrame.healthBar.border then
        local border = nameplate.UnitFrame.healthBar.border
        
        -- Hook Show
        hooksecurefunc(border, "Show", function()
            if Module.mouseoverDebugEnabled then
                local unit = nameplate.UnitFrame.unit or nameplate.UnitFrame.displayedUnit
                local unitName = unit and UnitName(unit) or "Unknown"
                print(string.format("[YATP NamePlates] healthBar.border SHOW called for: %s", unitName))
            end
        end)
        
        -- Hook Hide
        hooksecurefunc(border, "Hide", function()
            if Module.mouseoverDebugEnabled then
                local unit = nameplate.UnitFrame.unit or nameplate.UnitFrame.displayedUnit
                local unitName = unit and UnitName(unit) or "Unknown"
                print(string.format("[YATP NamePlates] healthBar.border HIDE called for: %s", unitName))
            end
        end)
        
        -- Hook SetAlpha
        hooksecurefunc(border, "SetAlpha", function(self, alpha)
            if Module.mouseoverDebugEnabled then
                local unit = nameplate.UnitFrame.unit or nameplate.UnitFrame.displayedUnit
                local unitName = unit and UnitName(unit) or "Unknown"
                print(string.format("[YATP NamePlates] healthBar.border SetAlpha(%.2f) called for: %s", alpha, unitName))
            end
        end)
        
        -- Hook SetVertexColor to detect color changes
        if border.SetVertexColor then
            hooksecurefunc(border, "SetVertexColor", function(self, r, g, b, a)
                if Module.mouseoverDebugEnabled then
                    local unit = nameplate.UnitFrame.unit or nameplate.UnitFrame.displayedUnit
                    local unitName = unit and UnitName(unit) or "Unknown"
                    print(string.format("[YATP NamePlates] healthBar.border SetVertexColor(%.2f,%.2f,%.2f,%.2f) for: %s", 
                        r or 0, g or 0, b or 0, a or 0, unitName))
                end
            end)
        end
        
        -- Hook the Texture if it exists
        if border.Texture then
            hooksecurefunc(border.Texture, "SetVertexColor", function(self, r, g, b, a)
                if Module.mouseoverDebugEnabled then
                    local unit = nameplate.UnitFrame.unit or nameplate.UnitFrame.displayedUnit
                    local unitName = unit and UnitName(unit) or "Unknown"
                    print(string.format("[YATP NamePlates] *** border.Texture SetVertexColor(%.2f,%.2f,%.2f,%.2f) for: %s ***", 
                        r or 0, g or 0, b or 0, a or 0, unitName))
                end
            end)
        end
    end
    
    -- Hook selectionHighlight Show/Hide/SetAlpha if it exists (THIS IS THE MOUSEOVER GLOW!)
    if nameplate.UnitFrame.selectionHighlight then
        local highlight = nameplate.UnitFrame.selectionHighlight
        
        -- Hook Show
        hooksecurefunc(highlight, "Show", function()
            if Module.mouseoverDebugEnabled then
                local unit = nameplate.UnitFrame.unit or nameplate.UnitFrame.displayedUnit
                local unitName = unit and UnitName(unit) or "Unknown"
                print(string.format("[YATP NamePlates] *** selectionHighlight SHOW called for: %s ***", unitName))
            end
        end)
        
        -- Hook Hide
        hooksecurefunc(highlight, "Hide", function()
            if Module.mouseoverDebugEnabled then
                local unit = nameplate.UnitFrame.unit or nameplate.UnitFrame.displayedUnit
                local unitName = unit and UnitName(unit) or "Unknown"
                print(string.format("[YATP NamePlates] *** selectionHighlight HIDE called for: %s ***", unitName))
            end
        end)
        
        -- Hook SetAlpha
        hooksecurefunc(highlight, "SetAlpha", function(self, alpha)
            if Module.mouseoverDebugEnabled then
                local unit = nameplate.UnitFrame.unit or nameplate.UnitFrame.displayedUnit
                local unitName = unit and UnitName(unit) or "Unknown"
                print(string.format("[YATP NamePlates] *** selectionHighlight SetAlpha(%.2f) called for: %s ***", alpha, unitName))
            end
        end)
        
        -- Hook SetVertexColor
        hooksecurefunc(highlight, "SetVertexColor", function(self, r, g, b, a)
            if Module.mouseoverDebugEnabled then
                local unit = nameplate.UnitFrame.unit or nameplate.UnitFrame.displayedUnit
                local unitName = unit and UnitName(unit) or "Unknown"
                print(string.format("[YATP NamePlates] *** selectionHighlight SetVertexColor(%.2f,%.2f,%.2f,%.2f) for: %s ***", 
                    r or 0, g or 0, b or 0, a or 0, unitName))
            end
        end)
    end
    
    nameplate.UnitFrame.mouseoverHooked = true
end

function Module:CaptureNameplateState(nameplate)
    if not nameplate then
        return nil
    end
    
    local state = {
        textures = {},
        baseTextures = {}
    }
    
    -- Capture all visible textures from UnitFrame (if exists)
    if nameplate.UnitFrame then
        local allRegions = {nameplate.UnitFrame:GetRegions()}
        for i, region in ipairs(allRegions) do
            if region:GetObjectType() == "Texture" then
                local shown = region:IsShown()
                local alpha = region:GetAlpha()
                if shown and alpha > 0 then
                    local name = region:GetName() or ("UF_Anonymous_" .. i)
                    local texture = region:GetTexture()
                    local r, g, b, a = region:GetVertexColor()
                    state.textures[name] = {
                        texture = texture,
                        alpha = alpha,
                        r = r, g = g, b = b, a = a
                    }
                end
            end
        end
    end
    
    -- IMPORTANT: Capture textures from the BASE NAMEPLATE FRAME (where mouseover glow might be!)
    local baseRegions = {nameplate:GetRegions()}
    for i, region in ipairs(baseRegions) do
        if region:GetObjectType() == "Texture" then
            local shown = region:IsShown()
            local alpha = region:GetAlpha()
            if shown and alpha > 0 then
                local name = region:GetName() or ("Base_Anonymous_" .. i)
                local texture = region:GetTexture()
                local r, g, b, a = region:GetVertexColor()
                state.baseTextures[name] = {
                    texture = texture,
                    alpha = alpha,
                    r = r, g = g, b = b, a = a,
                    source = "base nameplate frame"
                }
            end
        end
    end
    
    return state
end

function Module:DebugAllNameplateChildren(nameplate)
    if not nameplate then
        return
    end
    
    print("[YATP NamePlates] ===== ALL CHILD FRAMES SCAN =====")
    
    -- Get all children of the base nameplate
    local children = {nameplate:GetChildren()}
    print(string.format("  Base nameplate has %d child frame(s)", #children))
    
    for i, child in ipairs(children) do
        local childName = child:GetName() or ("Anonymous Child " .. i)
        local childType = child:GetObjectType()
        local isShown = child:IsShown()
        local alpha = child:GetAlpha()
        
        print(string.format("  [%d] %s (Type: %s, Shown: %s, Alpha: %.2f)", 
            i, childName, childType, tostring(isShown), alpha))
        
        -- If this child is visible, scan its regions
        if isShown and alpha > 0 then
            local childRegions = {child:GetRegions()}
            for j, region in ipairs(childRegions) do
                if region:GetObjectType() == "Texture" then
                    local regionName = region:GetName() or "Anonymous Texture"
                    local regionShown = region:IsShown()
                    local regionAlpha = region:GetAlpha()
                    
                    if regionShown and regionAlpha > 0 then
                        local texture = region:GetTexture()
                        local r, g, b, a = region:GetVertexColor()
                        print(string.format("      Texture: %s, Path=%s, Alpha=%.2f, Color=RGBA(%.2f,%.2f,%.2f,%.2f)",
                            regionName, tostring(texture), regionAlpha, r, g, b, a))
                    end
                end
            end
        end
    end
    
    print("[YATP NamePlates] ===== END CHILD FRAMES =====")
end

function Module:CompareNameplateStates(nameplate)
    if not nameplate.preMouseoverState then
        print("[YATP NamePlates] No pre-mouseover state captured to compare")
        return
    end
    
    local currentState = Module:CaptureNameplateState(nameplate)
    if not currentState then
        return
    end
    
    local unit = nameplate.UnitFrame and (nameplate.UnitFrame.unit or nameplate.UnitFrame.displayedUnit)
    local unitName = unit and UnitName(unit) or "Unknown"
    
    print(string.format("[YATP NamePlates] ===== CHANGES DETECTED for %s =====", unitName))
    
    local foundChanges = false
    
    -- Check UnitFrame textures
    for name, data in pairs(currentState.textures) do
        if not nameplate.preMouseoverState.textures[name] then
            print(string.format("  [NEW UnitFrame] %s: Texture=%s, Alpha=%.2f, Color=RGBA(%.2f,%.2f,%.2f,%.2f)",
                name, tostring(data.texture), data.alpha, data.r, data.g, data.b, data.a))
            foundChanges = true
        else
            -- Check if alpha or color changed
            local old = nameplate.preMouseoverState.textures[name]
            if math.abs(old.alpha - data.alpha) > 0.01 then
                print(string.format("  [ALPHA CHANGE] %s: %.2f -> %.2f", name, old.alpha, data.alpha))
                foundChanges = true
            end
            if math.abs(old.r - data.r) > 0.01 or math.abs(old.g - data.g) > 0.01 or 
               math.abs(old.b - data.b) > 0.01 or math.abs(old.a - data.a) > 0.01 then
                print(string.format("  [COLOR CHANGE] %s: RGBA(%.2f,%.2f,%.2f,%.2f) -> RGBA(%.2f,%.2f,%.2f,%.2f)",
                    name, old.r, old.g, old.b, old.a, data.r, data.g, data.b, data.a))
                foundChanges = true
            end
        end
    end
    
    -- Check BASE nameplate frame textures (THIS IS KEY!)
    for name, data in pairs(currentState.baseTextures) do
        if not nameplate.preMouseoverState.baseTextures[name] then
            print(string.format("  [NEW BASE FRAME] *** %s ***: Texture=%s, Alpha=%.2f, Color=RGBA(%.2f,%.2f,%.2f,%.2f)",
                name, tostring(data.texture), data.alpha, data.r, data.g, data.b, data.a))
            foundChanges = true
        else
            -- Check if alpha or color changed
            local old = nameplate.preMouseoverState.baseTextures[name]
            if math.abs(old.alpha - data.alpha) > 0.01 then
                print(string.format("  [ALPHA CHANGE BASE] *** %s ***: %.2f -> %.2f", name, old.alpha, data.alpha))
                foundChanges = true
            end
            if math.abs(old.r - data.r) > 0.01 or math.abs(old.g - data.g) > 0.01 or 
               math.abs(old.b - data.b) > 0.01 or math.abs(old.a - data.a) > 0.01 then
                print(string.format("  [COLOR CHANGE BASE] *** %s ***: RGBA(%.2f,%.2f,%.2f,%.2f) -> RGBA(%.2f,%.2f,%.2f,%.2f)",
                    name, old.r, old.g, old.b, old.a, data.r, data.g, data.b, data.a))
                foundChanges = true
            end
        end
    end
    
    if not foundChanges then
        print("  No visual changes detected in UnitFrame or base nameplate frame!")
    end
    
    print("[YATP NamePlates] ===== END CHANGES =====")
end

function Module:DebugNameplateState(nameplate)
    if not nameplate or not nameplate.UnitFrame then
        print("[YATP NamePlates] DEBUG: Invalid nameplate")
        return
    end
    
    local unitFrame = nameplate.UnitFrame
    local unit = unitFrame.unit or unitFrame.displayedUnit
    local unitName = UnitName(unit) or "Unknown"
    
    print(string.format("[YATP NamePlates] ===== NAMEPLATE STATE DEBUG: %s =====", unitName))
    
    -- Check selectionHighlight (this is likely the mouseover glow!)
    if unitFrame.selectionHighlight then
        local isShown = unitFrame.selectionHighlight:IsShown()
        local alpha = unitFrame.selectionHighlight:GetAlpha()
        local r, g, b, a = unitFrame.selectionHighlight:GetVertexColor()
        print(string.format("  selectionHighlight: Shown=%s, Alpha=%.2f, Color=RGBA(%.2f,%.2f,%.2f,%.2f)", 
            tostring(isShown), alpha, r, g, b, a))
        
        -- Check if it has a texture
        if unitFrame.selectionHighlight.GetTexture then
            local texture = unitFrame.selectionHighlight:GetTexture()
            print(string.format("  selectionHighlight.Texture: %s", tostring(texture or "None")))
        end
        
        -- Check its draw layer
        local layer, sublayer = unitFrame.selectionHighlight:GetDrawLayer()
        print(string.format("  selectionHighlight.DrawLayer: %s (sublayer: %d)", tostring(layer), sublayer or 0))
    else
        print("  selectionHighlight: NOT FOUND")
    end
    
    -- Check aggroHighlight
    if unitFrame.aggroHighlight then
        local isShown = unitFrame.aggroHighlight:IsShown()
        local alpha = unitFrame.aggroHighlight:GetAlpha()
        print(string.format("  aggroHighlight: Shown=%s, Alpha=%.2f", tostring(isShown), alpha))
    else
        print("  aggroHighlight: NOT FOUND")
    end
    
    -- Check healthBar
    if unitFrame.healthBar then
        local r, g, b, a = unitFrame.healthBar:GetStatusBarColor()
        print(string.format("  healthBar color: R=%.2f, G=%.2f, B=%.2f, A=%.2f", r, g, b, a))
        
        -- Check for border and its properties
        if unitFrame.healthBar.border then
            local borderShown = unitFrame.healthBar.border:IsShown()
            local borderAlpha = unitFrame.healthBar.border:GetAlpha()
            local br, bg, bb, ba = 0, 0, 0, 0
            if unitFrame.healthBar.border.GetVertexColor then
                br, bg, bb, ba = unitFrame.healthBar.border:GetVertexColor()
            end
            print(string.format("  healthBar.border: Shown=%s, Alpha=%.2f, Color=RGBA(%.2f,%.2f,%.2f,%.2f)", 
                tostring(borderShown), borderAlpha, br, bg, bb, ba))
            
            -- Check if border has a texture
            if unitFrame.healthBar.border.Texture then
                local texturePath = unitFrame.healthBar.border.Texture:GetTexture()
                print(string.format("  healthBar.border.Texture: %s", tostring(texturePath or "None")))
            end
        else
            print("  healthBar.border: NOT FOUND")
        end
        
        -- Check for any glow textures
        if unitFrame.healthBar.glow then
            local glowShown = unitFrame.healthBar.glow:IsShown()
            local glowAlpha = unitFrame.healthBar.glow:GetAlpha()
            print(string.format("  healthBar.glow: Shown=%s, Alpha=%.2f", tostring(glowShown), glowAlpha))
        end
    else
        print("  healthBar: NOT FOUND")
    end
    
    -- Check all regions of healthBar for unexpected textures
    if unitFrame.healthBar then
        print("  healthBar regions scan:")
        local regions = {unitFrame.healthBar:GetRegions()}
        for i, region in ipairs(regions) do
            if region:GetObjectType() == "Texture" then
                local name = region:GetName() or "Anonymous"
                local texture = region:GetTexture()
                local shown = region:IsShown()
                local alpha = region:GetAlpha()
                if shown and alpha > 0 then
                    local layer, sublayer = region:GetDrawLayer()
                    print(string.format("    Texture[%d]: %s, Texture=%s, Alpha=%.2f, Layer=%s", 
                        i, name, tostring(texture or "None"), alpha, tostring(layer)))
                end
            end
        end
    end
    
    -- Scan ALL regions of the entire UnitFrame for mouseover effects
    print("  UnitFrame ALL regions scan (looking for mouseover effects):")
    local allRegions = {unitFrame:GetRegions()}
    local foundAny = false
    for i, region in ipairs(allRegions) do
        if region:GetObjectType() == "Texture" then
            local name = region:GetName() or "Anonymous"
            local shown = region:IsShown()
            local alpha = region:GetAlpha()
            
            -- Only show textures that are visible and might be mouseover related
            if shown and alpha > 0 and (name:lower():find("highlight") or name:lower():find("glow") or 
                name:lower():find("selection") or name:lower():find("border") or name:lower():find("mouseover")) then
                local texture = region:GetTexture()
                local r, g, b, a = region:GetVertexColor()
                local layer, sublayer = region:GetDrawLayer()
                print(string.format("    [%d] %s: Texture=%s, Alpha=%.2f, Color=RGBA(%.2f,%.2f,%.2f,%.2f), Layer=%s", 
                    i, name, tostring(texture or "None"), alpha, r, g, b, a, tostring(layer)))
                foundAny = true
            end
        end
    end
    if not foundAny then
        print("    (none found)")
    end
    
    -- CRITICAL: Scan BASE NAMEPLATE FRAME (parent) for mouseover effects
    print("  BASE nameplate frame regions scan:")
    local baseRegions = {nameplate:GetRegions()}
    local foundBaseTextures = false
    for i, region in ipairs(baseRegions) do
        if region:GetObjectType() == "Texture" then
            local name = region:GetName() or ("Base_Anonymous_" .. i)
            local shown = region:IsShown()
            local alpha = region:GetAlpha()
            
            if shown and alpha > 0 then
                local texture = region:GetTexture()
                local r, g, b, a = region:GetVertexColor()
                local layer, sublayer = region:GetDrawLayer()
                print(string.format("    [%d] *** %s ***: Texture=%s, Alpha=%.2f, Color=RGBA(%.2f,%.2f,%.2f,%.2f), Layer=%s", 
                    i, name, tostring(texture or "None"), alpha, r, g, b, a, tostring(layer)))
                foundBaseTextures = true
            end
        end
    end
    if not foundBaseTextures then
        print("    (no visible textures in base frame)")
    end
    
    -- Check frame level and strata
    print(string.format("  Frame Level: %d, Strata: %s", unitFrame:GetFrameLevel(), unitFrame:GetFrameStrata()))
    
    -- Check if unit is mouseover
    local isMouseover = UnitIsUnit(unit, "mouseover")
    print(string.format("  Is Mouseover: %s", tostring(isMouseover)))
    
    -- Check parent nameplate base frame
    if nameplate.UnitFrame:GetParent() then
        local parent = nameplate.UnitFrame:GetParent()
        print(string.format("  Parent Frame: %s", tostring(parent:GetName() or "Anonymous")))
    end
    
    print("[YATP NamePlates] ===== END DEBUG =====")
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
    
    -- IMPORTANT: Also call target border system since this event handler is the active one
    self:OnTargetChanged()
    
    -- IMPORTANT: Also call target arrows system
    self:OnTargetArrowChanged()
    
    -- IMPORTANT: Also call alpha fade system for non-target nameplates
    self:OnAlphaFadeTargetChanged()
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

function Module:OnGroupChanged()
    if not self.db.profile.threatSystem.enabled then return end
    
    -- When group status changes, update all threat indicators
    -- This will automatically enable/disable threat colors based on group status
    self:UpdateAllThreatIndicators()
    
    -- If player is now solo, clear any existing threat colors
    if not IsInGroup() and not IsInRaid() then
        self:ClearAllThreatColors()
    end
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

function Module:ClearAllThreatColors()
    -- Remove threat colors from all nameplates when going solo
    for nameplate in C_NamePlateManager.EnumerateActiveNamePlates() do
        if nameplate.UnitFrame then
            self:ResetNameplateColors(nameplate)
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

function Module:UpdateAllNameplateAlphas()
    if not self.db.profile.nonTargetAlpha.enabled then
        return
    end
    
    local hasTarget = UnitExists("target")
    
    -- IMPORTANT: Only apply alpha fade if player has a target
    -- When no target exists, all nameplates should remain at full alpha
    if not hasTarget then
        -- Reset all nameplates to full alpha when no target
        for nameplate in C_NamePlateManager.EnumerateActiveNamePlates() do
            if nameplate.UnitFrame then
                nameplate.UnitFrame:SetAlpha(1.0)
            end
        end
        return
    end
    
    -- Update alpha for all active nameplates when there IS a target
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
    
    -- Set alpha: full for target, reduced for non-targets
    local targetAlpha = isTarget and 1.0 or self.db.profile.nonTargetAlpha.alpha
    
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
            if self.db.profile.nonTargetAlpha.enabled and UnitExists("target") then
                local frameUnit = frame.unit
                if frameUnit then
                    local frameIsTarget = UnitIsUnit(frameUnit, "target")
                    local frameAlpha = frameIsTarget and 1.0 or self.db.profile.nonTargetAlpha.alpha
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
            if self.db.profile.nonTargetAlpha.enabled and UnitExists("target") then
                local frameUnit = frame.unit
                if frameUnit then
                    local frameIsTarget = UnitIsUnit(frameUnit, "target")
                    local frameAlpha = frameIsTarget and 1.0 or self.db.profile.nonTargetAlpha.alpha
                    -- Apply immediately since SetPoint is the repositioning call
                    frame:SetAlpha(frameAlpha)
                end
            end
        end)
        
        -- Hook SetAlpha() itself to prevent external changes
        local originalSetAlpha = nameplate.UnitFrame.SetAlpha
        nameplate.UnitFrame.SetAlpha = function(frame, alpha)
            if self.db.profile.nonTargetAlpha.enabled and UnitExists("target") then
                local frameUnit = frame.unit
                if frameUnit then
                    local frameIsTarget = UnitIsUnit(frameUnit, "target")
                    -- Override requested alpha with our value
                    alpha = frameIsTarget and 1.0 or self.db.profile.nonTargetAlpha.alpha
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
                        self:SetupTargetGlow()
                        self:SetupTargetArrows()
                        self:SetupMouseoverGlow()
                        self:SetupThreatSystem()
                        self:DisableAllNameplateGlows()
                        self:ApplyGlobalHealthBarTexture()
                        self:SetupHealthTextPositioning()
                        self:SetupNonTargetAlpha()
                    else
                        -- Disable functionality without calling AceAddon Disable
                        self:CleanupTargetGlow()
                        self:CleanupTargetArrows()
                        self:CleanupThreatSystem()
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
        threatHeader = { type = "header", name = L["Threat System (YATP Custom)"] or "Threat System (YATP Custom)", order = 30 },
        
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
            order = 31,
        },
        
        threatColors = {
            type = "group",
            name = L["Threat Colors"] or "Threat Colors",
            desc = L["Configure colors for different threat levels"] or "Configure colors for different threat levels",
            inline = true,
            disabled = function() return not self.db.profile.threatSystem.enabled end,
            order = 32,
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
                self:UpdateAllTargetGlows()
            end,
            order = 11,
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
            order = 12,
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
            order = 13,
        },
        
        spacer2 = { type = "description", name = "\n", order = 20 },
        
        -- Target Arrows System (YATP Custom Feature)
        targetArrowsHeader = { type = "header", name = L["Target Arrows (YATP Custom)"] or "Target Arrows (YATP Custom)", order = 21 },
        
        targetArrowsEnabled = {
            type = "toggle",
            name = L["Enable Target Arrows"] or "Enable Target Arrows",
            desc = L["Show arrow indicators on both sides of your current target's nameplate for better visibility"] or "Show arrow indicators on both sides of your current target's nameplate for better visibility",
            get = function() return self.db.profile.targetArrows.enabled end,
            set = function(_, value) 
                self.db.profile.targetArrows.enabled = value
                self:UpdateAllTargetArrows()
            end,
            order = 22,
        },
        
        targetArrowsSize = {
            type = "range",
            name = L["Arrow Size"] or "Arrow Size",
            desc = L["Size of the arrow indicators in pixels"] or "Size of the arrow indicators in pixels",
            min = 16, max = 64, step = 2,
            get = function() return self.db.profile.targetArrows.size or 32 end,
            set = function(_, value) 
                self.db.profile.targetArrows.size = value
                self:UpdateAllTargetArrows()
            end,
            disabled = function() return not self.db.profile.targetArrows.enabled end,
            order = 23,
        },
        
        targetArrowsOffsetX = {
            type = "range",
            name = L["Horizontal Distance"] or "Horizontal Distance",
            desc = L["Distance of arrows from the nameplate edges"] or "Distance of arrows from the nameplate edges",
            min = 0, max = 50, step = 1,
            get = function() return self.db.profile.targetArrows.offsetX or 15 end,
            set = function(_, value) 
                self.db.profile.targetArrows.offsetX = value
                self:UpdateAllTargetArrows()
            end,
            disabled = function() return not self.db.profile.targetArrows.enabled end,
            order = 24,
        },
        
        targetArrowsOffsetY = {
            type = "range",
            name = L["Vertical Offset"] or "Vertical Offset",
            desc = L["Vertical offset of arrows from nameplate center. Negative moves down, positive moves up."] or "Vertical offset of arrows from nameplate center. Negative moves down, positive moves up.",
            min = -20, max = 20, step = 1,
            get = function() return self.db.profile.targetArrows.offsetY or 0 end,
            set = function(_, value) 
                self.db.profile.targetArrows.offsetY = value
                self:UpdateAllTargetArrows()
            end,
            disabled = function() return not self.db.profile.targetArrows.enabled end,
            order = 25,
        },
        
        targetArrowsColor = {
            type = "color",
            name = L["Arrow Color"] or "Arrow Color",
            desc = L["Color tint applied to the arrow textures"] or "Color tint applied to the arrow textures",
            hasAlpha = true,
            get = function() 
                local color = self.db.profile.targetArrows.color
                return color[1], color[2], color[3], color[4]
            end,
            set = function(_, r, g, b, a) 
                self.db.profile.targetArrows.color = {r, g, b, a}
                self:UpdateAllTargetArrows()
            end,
            disabled = function() return not self.db.profile.targetArrows.enabled end,
            order = 26,
        },
        
        spacer3 = { type = "description", name = "\n", order = 30 },
        
        -- Non-Target Alpha Fade (YATP Custom Feature)
        nonTargetAlphaHeader = { type = "header", name = L["Non-Target Alpha Fade (YATP Custom)"] or "Non-Target Alpha Fade (YATP Custom)", order = 31 },
        
        nonTargetAlphaDesc = {
            type = "description",
            name = L["Fade out nameplates that are not your current target. This helps you focus on your target by dimming other enemy nameplates. Only active when you have a target selected - when no target exists, all nameplates remain at full opacity."] or "Fade out nameplates that are not your current target. This helps you focus on your target by dimming other enemy nameplates. Only active when you have a target selected - when no target exists, all nameplates remain at full opacity.",
            order = 32,
        },
        
        nonTargetAlphaEnabled = {
            type = "toggle",
            name = L["Enable Non-Target Alpha Fade"] or "Enable Non-Target Alpha Fade",
            desc = L["Reduce the opacity of enemy nameplates that are not your current target. Only applies when you have a target selected."] or "Reduce the opacity of enemy nameplates that are not your current target. Only applies when you have a target selected.",
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
            desc = L["Transparency level for non-target nameplates. 0.0 = fully transparent (invisible), 1.0 = fully opaque (no fade). Only applies when you have a target selected."] or "Transparency level for non-target nameplates. 0.0 = fully transparent (invisible), 1.0 = fully opaque (no fade). Only applies when you have a target selected.",
            min = 0.0, max = 1.0, step = 0.05,
            get = function() return self.db.profile.nonTargetAlpha.alpha end,
            set = function(_, value) 
                self.db.profile.nonTargetAlpha.alpha = value
                self:UpdateNonTargetAlphaSettings()
            end,
            disabled = function() return not self.db.profile.nonTargetAlpha.enabled end,
            order = 34,
        },
        
        spacer4 = { type = "description", name = "\n", order = 35 },
        
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
-- Slash Command Handler
-------------------------------------------------
function Module:SlashCommand(input)
    local args = {}
    for word in string.gmatch(input, "%S+") do
        table.insert(args, string.lower(word))
    end
    
    local command = args[1]
    
    if not command or command == "help" then
        print("|cff00ff00[YATP NamePlates]|r Available commands:")
        print("  |cffffcc00/yatpnp debug|r - Toggle mouseover debug mode")
        print("  |cffffcc00/yatpnp test|r - Test debug on current mouseover")
        print("  |cffffcc00/yatpnp hooks|r - Re-apply mouseover hooks to all nameplates")
        print("  |cffffcc00/yatpnp capture|r - Manually capture pre-mouseover state for all nameplates")
        print("  |cffffcc00/yatpnp blockborder|r - TEST: Block border color changes to test if that's the glow")
        print("  |cffffcc00/yatpnp help|r - Show this help message")
    elseif command == "debug" then
        -- Toggle debug mode
        self.mouseoverDebugEnabled = not self.mouseoverDebugEnabled
        if self.mouseoverDebugEnabled then
            print("|cff00ff00[YATP NamePlates]|r Mouseover debug mode |cff00ff00ENABLED|r")
            print("  Hover over nameplates to see detailed debug information")
            print("  State capture system activated (checks every 0.5s)")
        else
            print("|cff00ff00[YATP NamePlates]|r Mouseover debug mode |cffff0000DISABLED|r")
            -- Stop state capture ticker
            if self.stateCaptureTicker then
                self.stateCaptureTicker:Cancel()
                self.stateCaptureTicker = nil
            end
        end
    elseif command == "test" then
        -- Test current mouseover
        if UnitExists("mouseover") then
            print("|cff00ff00[YATP NamePlates]|r Testing current mouseover...")
            self:OnMouseoverDebug()
            
            -- Also scan children
            for nameplate in C_NamePlateManager.EnumerateActiveNamePlates() do
                if nameplate.UnitFrame and nameplate.UnitFrame.unit and UnitIsUnit(nameplate.UnitFrame.unit, "mouseover") then
                    print("|cff00ff00[YATP NamePlates]|r Scanning children of mouseover nameplate...")
                    self:DebugAllNameplateChildren(nameplate)
                    break
                end
            end
        else
            print("|cffff0000[YATP NamePlates]|r No unit under mouse cursor")
        end
    elseif command == "hooks" then
        -- Re-apply hooks to all nameplates
        print("|cff00ff00[YATP NamePlates]|r Re-applying mouseover hooks to all nameplates...")
        local count = 0
        for nameplate in C_NamePlateManager.EnumerateActiveNamePlates() do
            nameplate.UnitFrame.mouseoverHooked = nil -- Reset flag
            self:HookMouseoverOnNameplate(nameplate)
            count = count + 1
        end
        print("|cff00ff00[YATP NamePlates]|r Applied hooks to " .. count .. " nameplates")
    elseif command == "capture" then
        -- Manually capture pre-mouseover state for all nameplates
        print("|cff00ff00[YATP NamePlates]|r Capturing pre-mouseover state for all nameplates...")
        local count = 0
        for nameplate in C_NamePlateManager.EnumerateActiveNamePlates() do
            if nameplate.UnitFrame and nameplate.UnitFrame.unit then
                local isMouseover = UnitIsUnit(nameplate.UnitFrame.unit, "mouseover")
                if not isMouseover then
                    nameplate.preMouseoverState = self:CaptureNameplateState(nameplate)
                    count = count + 1
                end
            end
        end
        print("|cff00ff00[YATP NamePlates]|r Captured state for " .. count .. " nameplates")
        print("  Now hover over a nameplate to see what changes!")
    elseif command == "blockborder" then
        -- TEST: Force all borders to stay black to see if that removes the glow
        print("|cff00ff00[YATP NamePlates]|r BLOCKING border color changes on all nameplates...")
        local count = 0
        for nameplate in C_NamePlateManager.EnumerateActiveNamePlates() do
            if nameplate.UnitFrame and nameplate.UnitFrame.healthBar and nameplate.UnitFrame.healthBar.border then
                local border = nameplate.UnitFrame.healthBar.border
                
                -- Force black and lock it
                if border.Texture then
                    border.Texture:SetVertexColor(0, 0, 0, 1)
                    
                    -- Hook to prevent changes
                    border.Texture.SetVertexColor = function(self, r, g, b, a)
                        -- Do nothing - block all color changes
                    end
                end
                
                border:SetAlpha(1)
                border:Show()
                count = count + 1
            end
        end
        print("|cff00ff00[YATP NamePlates]|r Blocked border changes on " .. count .. " nameplates")
        print("  Now try mousing over nameplates. If the glow disappears, we found it!")
        print("  Type |cffffcc00/reload|r to restore normal behavior")
    else
        print("|cffff0000[YATP NamePlates]|r Unknown command: " .. command)
        print("Type |cffffcc00/yatpnp help|r for available commands")
    end
end