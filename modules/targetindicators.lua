-------------------------------------------------
-- Target Indicators Module
-- Adds custom borders and arrows to the target nameplate
-- Uses OnUpdate hook per nameplate (inspired by Kui_Nameplates)
-- Each frame checks itself if it's the target (handles frame recycling)
-------------------------------------------------

local addonName, YATP = ...
local AceAddon = LibStub("AceAddon-3.0")
local Module = AceAddon:GetAddon("YATP"):NewModule("TargetIndicators", "AceEvent-3.0", "AceTimer-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("YATP", true) or {}

-------------------------------------------------
-- Module Defaults
-------------------------------------------------

Module.defaults = {
    profile = {
        enabled = true,
        
        -- Custom Border Settings
        border = {
            enabled = true,
            color = {1, 1, 0, 0.8}, -- Yellow by default
            size = 1,
        },
        
        -- Target Arrows Settings
        arrows = {
            enabled = true,
            size = 32,
            offsetX = 15,
            offsetY = 0,
            color = {1, 1, 1, 1}, -- White by default
        },
        
        -- Health Bar Tint Settings
        healthBarTint = {
            enabled = true,
            tintAmount = 0.3, -- 30% white tint by default (less than mouseover)
        },
    }
}

-------------------------------------------------
-- Initialization
-------------------------------------------------

function Module:OnInitialize()
    -- Get main addon
    local addon = AceAddon:GetAddon("YATP")
    
    -- Register default settings
    self.db = addon.db:RegisterNamespace("TargetIndicators", Module.defaults)
    
    -- Storage for tracked nameplates
    self.trackedFrames = {}
end

function Module:OnEnable()
    if not self.db.profile.enabled then
        return
    end
    
    print("[YATP Target Indicators] Module enabled")
    
    -- Register events
    self:RegisterEvent("NAME_PLATE_UNIT_ADDED", "OnNamePlateAdded")
    self:RegisterEvent("NAME_PLATE_UNIT_REMOVED", "OnNamePlateRemoved")
    
    -- Clean up any existing visuals
    self:CleanupAllVisuals()
    
    -- Start the update loop
    self:StartUpdateLoop()
end

function Module:OnDisable()
    self:StopUpdateLoop()
    self:CleanupAllVisuals()
end

-------------------------------------------------
-- Update Loop (checks all nameplates periodically)
-------------------------------------------------

function Module:StartUpdateLoop()
    if self.updateTicker then
        self.updateTicker:Cancel()
    end
    
    self.updateTicker = C_Timer.NewTicker(0.1, function()
        Module:CheckAllNameplates()
    end)
end

function Module:StopUpdateLoop()
    if self.updateTicker then
        self.updateTicker:Cancel()
        self.updateTicker = nil
    end
end

function Module:CheckAllNameplates()
    if not self.db.profile.enabled then return end
    if not UnitExists("target") then 
        -- No target, remove visuals from all
        for nameplate in C_NamePlateManager.EnumerateActiveNamePlates() do
            if nameplate.UnitFrame and nameplate.UnitFrame.isYATPTarget then
                nameplate.UnitFrame.isYATPTarget = false
                self:RemoveTargetVisuals(nameplate.UnitFrame)
            end
        end
        return 
    end
    
    local targetGUID = UnitGUID("target")
    if not targetGUID then return end
    
    -- Check all active nameplates
    for nameplate in C_NamePlateManager.EnumerateActiveNamePlates() do
        local frame = nameplate.UnitFrame
        if frame and frame.unit then
            local frameGUID = UnitGUID(frame.unit)
            local shouldBeTarget = (frameGUID == targetGUID)
            
            if shouldBeTarget and not frame.isYATPTarget then
                -- This frame became the target
                frame.isYATPTarget = true
                self:ApplyTargetVisuals(frame)
            elseif not shouldBeTarget and frame.isYATPTarget then
                -- This frame is no longer the target
                frame.isYATPTarget = false
                self:RemoveTargetVisuals(frame)
            end
        end
    end
end

-------------------------------------------------
-- Nameplate Lifecycle Events (not needed with ticker system)
-------------------------------------------------

function Module:OnNamePlateAdded(event, unit)
    -- Not used - ticker system handles all detection
end

function Module:OnNamePlateRemoved(event, unit)
    -- Not used - ticker system handles cleanup automatically
end

-------------------------------------------------
-- Visual Application
-------------------------------------------------

function Module:ApplyTargetVisuals(frame)
    if not frame or not frame.unit then 
        return 
    end
    
    -- Apply custom border
    if self.db.profile.border.enabled then
        self:AddCustomBorder(frame)
    end
    
    -- Apply target arrows
    if self.db.profile.arrows.enabled then
        self:AddTargetArrows(frame)
    end
    
    -- Apply health bar tint (only if NOT mouseover)
    if self.db.profile.healthBarTint.enabled then
        self:ApplyHealthBarTint(frame)
    end
end

function Module:RemoveTargetVisuals(frame)
    if not frame then 
        return 
    end
    
    -- Remove arrows
    if frame.YATPTargetArrows then
        self:RemoveTargetArrows(frame)
    end
    
    -- Remove custom border
    if frame.YATPCustomBorder then
        self:RemoveCustomBorder(frame)
    end
    
    -- Restore health bar color
    if frame.YATPOriginalHealthColor then
        self:RestoreHealthBarColor(frame)
    end
end

-------------------------------------------------
-- Custom Border System
-------------------------------------------------

function Module:AddCustomBorder(frame)
    if not frame or not frame.healthBar then
        return
    end
    
    local healthBar = frame.healthBar
    
    -- Remove existing border if any
    if frame.YATPCustomBorder then
        self:RemoveCustomBorder(frame)
    end
    
    local borderSize = self.db.profile.border.size
    local color = self.db.profile.border.color
    
    -- Create border container (same level as healthBar to stay below statusText which is in OVERLAY layer)
    local borderFrame = CreateFrame("Frame", nil, healthBar)
    borderFrame:SetFrameLevel(healthBar:GetFrameLevel())  -- Same level as healthBar, textures will be below statusText
    borderFrame:SetAllPoints(healthBar)
    
    -- Create 4 border edges (using BORDER layer to stay below OVERLAY layer where statusText is)
    local borders = {}
    
    -- Top (extends to cover corners)
    borders.top = borderFrame:CreateTexture(nil, "BORDER")
    borders.top:SetColorTexture(color[1], color[2], color[3], color[4])
    borders.top:SetPoint("TOPLEFT", healthBar, "TOPLEFT", -borderSize, borderSize)
    borders.top:SetPoint("TOPRIGHT", healthBar, "TOPRIGHT", borderSize, borderSize)
    borders.top:SetHeight(borderSize)
    
    -- Bottom (extends to cover corners)
    borders.bottom = borderFrame:CreateTexture(nil, "BORDER")
    borders.bottom:SetColorTexture(color[1], color[2], color[3], color[4])
    borders.bottom:SetPoint("BOTTOMLEFT", healthBar, "BOTTOMLEFT", -borderSize, -borderSize)
    borders.bottom:SetPoint("BOTTOMRIGHT", healthBar, "BOTTOMRIGHT", borderSize, -borderSize)
    borders.bottom:SetHeight(borderSize)
    
    -- Left (only vertical part, no corners)
    borders.left = borderFrame:CreateTexture(nil, "BORDER")
    borders.left:SetColorTexture(color[1], color[2], color[3], color[4])
    borders.left:SetPoint("TOPLEFT", healthBar, "TOPLEFT", -borderSize, 0)
    borders.left:SetPoint("BOTTOMLEFT", healthBar, "BOTTOMLEFT", -borderSize, 0)
    borders.left:SetWidth(borderSize)
    
    -- Right (only vertical part, no corners)
    borders.right = borderFrame:CreateTexture(nil, "BORDER")
    borders.right:SetColorTexture(color[1], color[2], color[3], color[4])
    borders.right:SetPoint("TOPRIGHT", healthBar, "TOPRIGHT", borderSize, 0)
    borders.right:SetPoint("BOTTOMRIGHT", healthBar, "BOTTOMRIGHT", borderSize, 0)
    borders.right:SetWidth(borderSize)
    
    -- Store border data
    frame.YATPCustomBorder = {
        frame = borderFrame,
        borders = borders
    }
end

function Module:RemoveCustomBorder(frame)
    if not frame or not frame.YATPCustomBorder then
        return
    end
    
    local borderData = frame.YATPCustomBorder
    
    -- Hide and destroy border frame
    if borderData.frame then
        borderData.frame:Hide()
        borderData.frame:SetParent(nil)
    end
    
    -- Clear reference
    frame.YATPCustomBorder = nil
end

-------------------------------------------------
-- Target Arrows System
-------------------------------------------------

function Module:AddTargetArrows(frame)
    if not frame or not frame.healthBar then
        return
    end
    
    local healthBar = frame.healthBar
    
    -- Remove existing arrows if any
    if frame.YATPTargetArrows then
        self:RemoveTargetArrows(frame)
    end
    
    local arrowSize = self.db.profile.arrows.size
    local offsetX = self.db.profile.arrows.offsetX
    local offsetY = self.db.profile.arrows.offsetY
    local color = self.db.profile.arrows.color
    
    -- Create arrow container
    local arrowFrame = CreateFrame("Frame", nil, frame)
    arrowFrame:SetFrameStrata("HIGH")
    arrowFrame:SetFrameLevel(healthBar:GetFrameLevel() + 10)
    
    -- Left arrow (pointing right toward nameplate)
    local leftArrow = arrowFrame:CreateTexture(nil, "OVERLAY")
    leftArrow:SetTexture("Interface\\AddOns\\YATP\\media\\arrow")
    leftArrow:SetSize(arrowSize, arrowSize)
    leftArrow:SetPoint("RIGHT", healthBar, "LEFT", -offsetX, offsetY)
    leftArrow:SetVertexColor(color[1], color[2], color[3], color[4])
    leftArrow:SetTexCoord(0, 1, 0, 1)
    
    -- Right arrow (pointing left toward nameplate)
    local rightArrow = arrowFrame:CreateTexture(nil, "OVERLAY")
    rightArrow:SetTexture("Interface\\AddOns\\YATP\\media\\arrow")
    rightArrow:SetSize(arrowSize, arrowSize)
    rightArrow:SetPoint("LEFT", healthBar, "RIGHT", offsetX, offsetY)
    rightArrow:SetVertexColor(color[1], color[2], color[3], color[4])
    rightArrow:SetTexCoord(1, 0, 0, 1) -- Flip horizontally
    
    -- Store arrow data
    frame.YATPTargetArrows = {
        frame = arrowFrame,
        left = leftArrow,
        right = rightArrow
    }
end

function Module:RemoveTargetArrows(frame)
    if not frame or not frame.YATPTargetArrows then
        return
    end
    
    local arrowData = frame.YATPTargetArrows
    
    -- Hide and destroy arrow frame
    if arrowData.frame then
        arrowData.frame:Hide()
        arrowData.frame:SetParent(nil)
    end
    
    -- Clear reference
    frame.YATPTargetArrows = nil
end

-------------------------------------------------
-- Utility Functions
-------------------------------------------------

function Module:ProcessAllNameplates()
    -- Update visual properties for current target (if any)
    if not UnitExists("target") then
        return
    end
    
    local targetGUID = UnitGUID("target")
    if not targetGUID then
        return
    end
    
    -- Find and update the target nameplate
    for nameplate in C_NamePlateManager.EnumerateActiveNamePlates() do
        local frame = nameplate.UnitFrame
        if frame and frame.unit then
            local frameGUID = UnitGUID(frame.unit)
            if frameGUID == targetGUID then
                -- Remove old visuals and reapply with new settings
                self:RemoveTargetVisuals(frame)
                self:ApplyTargetVisuals(frame)
                break
            end
        end
    end
end

-------------------------------------------------
-- Health Bar Tint System
-------------------------------------------------

function Module:ApplyHealthBarTint(frame)
    if not frame or not frame.healthBar then
        return
    end
    
    -- Check if this nameplate is currently being moused over
    -- We don't want to apply target tint if mouseover highlight is active
    local nameplate = frame:GetParent()
    if nameplate and nameplate.UnitFrame then
        -- Get the nameplates module to check mouseover state
        local nameplatesModule = AceAddon:GetAddon("YATP"):GetModule("Nameplates", true)
        if nameplatesModule and nameplatesModule.mouseoverHealthBarData and nameplatesModule.mouseoverHealthBarData[nameplate] then
            local mouseoverData = nameplatesModule.mouseoverHealthBarData[nameplate]
            if mouseoverData.isMouseover then
                -- This nameplate is being moused over, don't apply target tint
                return
            end
        end
    end
    
    local healthBar = frame.healthBar
    
    -- Get current color
    local r, g, b, a = healthBar:GetStatusBarColor()
    
    -- Store original color if not already stored
    if not frame.YATPOriginalHealthColor then
        frame.YATPOriginalHealthColor = {r, g, b, a}
    end
    
    -- Apply white tint
    local tintAmount = self.db.profile.healthBarTint.tintAmount or 0.3
    local newR, newG, newB, newA = self:ApplyWhiteTint(r, g, b, a, tintAmount)
    
    -- Apply new color
    healthBar:SetStatusBarColor(newR, newG, newB, newA)
    
    -- Also apply to texture
    local texture = healthBar:GetStatusBarTexture()
    if texture then
        texture:SetVertexColor(newR, newG, newB, newA)
    end
end

function Module:RestoreHealthBarColor(frame)
    if not frame or not frame.healthBar or not frame.YATPOriginalHealthColor then
        return
    end
    
    local healthBar = frame.healthBar
    local color = frame.YATPOriginalHealthColor
    
    healthBar:SetStatusBarColor(color[1], color[2], color[3], color[4])
    
    -- Also restore texture color
    local texture = healthBar:GetStatusBarTexture()
    if texture then
        texture:SetVertexColor(color[1], color[2], color[3], color[4])
    end
    
    frame.YATPOriginalHealthColor = nil
end

-- Helper function to apply white tint to a color
function Module:ApplyWhiteTint(r, g, b, a, tintAmount)
    -- Mix with white (1, 1, 1) based on tintAmount
    -- tintAmount of 0 = no change, 1 = full white
    local newR = r + (1 - r) * tintAmount
    local newG = g + (1 - g) * tintAmount
    local newB = b + (1 - b) * tintAmount
    return newR, newG, newB, a
end

function Module:CleanupAllVisuals()
    -- Remove visuals from all nameplates
    for nameplate in C_NamePlateManager.EnumerateActiveNamePlates() do
        if nameplate.UnitFrame then
            self:RemoveTargetVisuals(nameplate.UnitFrame)
        end
    end
end

-------------------------------------------------
-- Configuration
-------------------------------------------------

function Module:GetOptions()
    local options = {
        type = "group",
        name = L["Target Indicators"] or "Target Indicators",
        desc = L["Customize target nameplate indicators"] or "Customize target nameplate indicators",
        args = {
            enabled = {
                type = "toggle",
                name = L["Enable"] or "Enable",
                desc = L["Enable target indicators"] or "Enable target indicators",
                get = function() return self.db.profile.enabled end,
                set = function(_, value)
                    self.db.profile.enabled = value
                    if value then
                        self:OnEnable()
                    else
                        self:OnDisable()
                    end
                end,
                order = 1,
            },
            
            borderHeader = {
                type = "header",
                name = L["Custom Border"] or "Custom Border",
                order = 10,
            },
            
            borderEnabled = {
                type = "toggle",
                name = L["Enable Border"] or "Enable Border",
                desc = L["Show custom border on target nameplate"] or "Show custom border on target nameplate",
                get = function() return self.db.profile.border.enabled end,
                set = function(_, value)
                    self.db.profile.border.enabled = value
                    self:ProcessAllNameplates()
                end,
                disabled = function() return not self.db.profile.enabled end,
                order = 11,
            },
            
            borderColor = {
                type = "color",
                name = L["Border Color"] or "Border Color",
                desc = L["Color of the target border"] or "Color of the target border",
                hasAlpha = true,
                get = function()
                    local c = self.db.profile.border.color
                    return c[1], c[2], c[3], c[4]
                end,
                set = function(_, r, g, b, a)
                    self.db.profile.border.color = {r, g, b, a}
                    self:ProcessAllNameplates()
                end,
                disabled = function() return not self.db.profile.enabled or not self.db.profile.border.enabled end,
                order = 12,
            },
            
            arrowsHeader = {
                type = "header",
                name = L["Target Arrows"] or "Target Arrows",
                order = 20,
            },
            
            arrowsEnabled = {
                type = "toggle",
                name = L["Enable Arrows"] or "Enable Arrows",
                desc = L["Show arrows pointing to target nameplate"] or "Show arrows pointing to target nameplate",
                get = function() return self.db.profile.arrows.enabled end,
                set = function(_, value)
                    self.db.profile.arrows.enabled = value
                    self:ProcessAllNameplates()
                end,
                disabled = function() return not self.db.profile.enabled end,
                order = 21,
            },
            
            arrowsColor = {
                type = "color",
                name = L["Arrow Color"] or "Arrow Color",
                desc = L["Color of the target arrows"] or "Color of the target arrows",
                hasAlpha = true,
                get = function()
                    local c = self.db.profile.arrows.color
                    return c[1], c[2], c[3], c[4]
                end,
                set = function(_, r, g, b, a)
                    self.db.profile.arrows.color = {r, g, b, a}
                    self:ProcessAllNameplates()
                end,
                disabled = function() return not self.db.profile.enabled or not self.db.profile.arrows.enabled end,
                order = 22,
            },
            
            arrowsSize = {
                type = "range",
                name = L["Arrow Size"] or "Arrow Size",
                desc = L["Size of the target arrows"] or "Size of the target arrows",
                min = 16, max = 64, step = 2,
                get = function() return self.db.profile.arrows.size end,
                set = function(_, value)
                    self.db.profile.arrows.size = value
                    self:ProcessAllNameplates()
                end,
                disabled = function() return not self.db.profile.enabled or not self.db.profile.arrows.enabled end,
                order = 23,
            },
            
            arrowsOffsetX = {
                type = "range",
                name = L["Horizontal Offset"] or "Horizontal Offset",
                desc = L["Horizontal distance from nameplate"] or "Horizontal distance from nameplate",
                min = 0, max = 50, step = 1,
                get = function() return self.db.profile.arrows.offsetX end,
                set = function(_, value)
                    self.db.profile.arrows.offsetX = value
                    self:ProcessAllNameplates()
                end,
                disabled = function() return not self.db.profile.enabled or not self.db.profile.arrows.enabled end,
                order = 24,
            },
            
            arrowsOffsetY = {
                type = "range",
                name = L["Vertical Offset"] or "Vertical Offset",
                desc = L["Vertical distance from nameplate"] or "Vertical distance from nameplate",
                min = -20, max = 20, step = 1,
                get = function() return self.db.profile.arrows.offsetY end,
                set = function(_, value)
                    self.db.profile.arrows.offsetY = value
                    self:ProcessAllNameplates()
                end,
                disabled = function() return not self.db.profile.enabled or not self.db.profile.arrows.enabled end,
                order = 25,
            },
            
            healthBarHeader = {
                type = "header",
                name = L["Health Bar Tint"] or "Health Bar Tint",
                order = 30,
            },
            
            healthBarTintEnabled = {
                type = "toggle",
                name = L["Enable Health Bar Tint"] or "Enable Health Bar Tint",
                desc = L["Apply a white tint to the target's health bar for better visibility. Does not apply when mousing over the target."] or "Apply a white tint to the target's health bar for better visibility. Does not apply when mousing over the target.",
                get = function() return self.db.profile.healthBarTint.enabled end,
                set = function(_, value)
                    self.db.profile.healthBarTint.enabled = value
                    self:ProcessAllNameplates()
                end,
                disabled = function() return not self.db.profile.enabled end,
                order = 31,
            },
            
            healthBarTintAmount = {
                type = "range",
                name = L["Tint Amount"] or "Tint Amount",
                desc = L["Amount of white tint to apply (0 = no tint, 1 = full white)"] or "Amount of white tint to apply (0 = no tint, 1 = full white)",
                min = 0.0, max = 1.0, step = 0.05,
                get = function() return self.db.profile.healthBarTint.tintAmount end,
                set = function(_, value)
                    self.db.profile.healthBarTint.tintAmount = value
                    self:ProcessAllNameplates()
                end,
                disabled = function() return not self.db.profile.enabled or not self.db.profile.healthBarTint.enabled end,
                order = 32,
            },
        }
    }
    
    return options
end
