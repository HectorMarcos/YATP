--========================================================--
-- YATP - NamePlates Module
--========================================================--
-- This module provides configuration interface for the Ascension NamePlates addon
-- through YATP's interface hub system.

local L = LibStub("AceLocale-3.0"):GetLocale("YATP", true) or setmetatable({}, { __index=function(_,k) return k end })
local YATP = LibStub("AceAddon-3.0"):GetAddon("YATP", true)
if not YATP then
    DEFAULT_CHAT_FRAME:AddMessage("|cffff0000YATP not found, aborting nameplates.lua module|r")
    return
end

local Module = YATP:NewModule("NamePlates", "AceEvent-3.0", "AceConsole-3.0")

-------------------------------------------------
-- Debug helper
-------------------------------------------------
function Module:Debug(msg)
    if not YATP or not YATP.IsDebug or not YATP:IsDebug() then return end
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99YATP:NamePlates|r "..tostring(msg))
end

-------------------------------------------------
-- Defaults
-------------------------------------------------
Module.defaults = {
    enabled = true,
    autoOpenNameplatesConfig = false, -- Si abrir automáticamente la config de nameplates
    
    -- Enemy Target specific options
    highlightEnemyTarget = false,
    highlightColor = {1, 1, 0, 0.8}, -- Yellow with 80% opacity
    enhancedTargetBorder = false,
    alwaysShowTargetHealth = false,
    targetHealthFormat = "inherit",
}

-------------------------------------------------
-- OnInitialize
-------------------------------------------------
function Module:OnInitialize()
    self.db = YATP.db:RegisterNamespace("NamePlates", { profile = Module.defaults })
    self:Debug("NamePlates module initialized")
end

-------------------------------------------------
-- OnEnable
-------------------------------------------------
function Module:OnEnable()
    if not self.db.profile.enabled then
        self:Debug("NamePlates module disabled")
        return
    end
    
    -- Register this module as its own category (not under Interface Hub)
    if YATP.AddModuleOptions then
        -- Create the main NamePlates category with childGroups = "tab"
        local namePlatesOptions = {
            type = "group",
            name = L["NamePlates"] or "NamePlates",
            childGroups = "tab",
            args = self:BuildTabStructure()
        }
        
        -- Register as a separate category under YATP main panel
        local AceConfig = LibStub("AceConfig-3.0")
        local AceConfigDialog = LibStub("AceConfigDialog-3.0")
        
        AceConfig:RegisterOptionsTable("YATP-NamePlates", namePlatesOptions)
        AceConfigDialog:AddToBlizOptions("YATP-NamePlates", L["NamePlates"] or "NamePlates", "YATP")
    end
    
    self:Debug("NamePlates module enabled and registered as separate category")
    self:CheckNamePlatesAddon()
    self:SetupTargetEnhancements()
end

-------------------------------------------------
-- OnDisable
-------------------------------------------------
function Module:OnDisable()
    self:Debug("NamePlates module disabled")
end

-------------------------------------------------
-- Check if Ascension NamePlates addon is available
-------------------------------------------------
function Module:CheckNamePlatesAddon()
    local isLoaded = IsAddOnLoaded("Ascension_NamePlates")
    local canLoad = select(4, GetAddOnInfo("Ascension_NamePlates"))
    
    if isLoaded then
        self:Debug("Ascension NamePlates addon is loaded")
        return true
    elseif canLoad then
        self:Debug("Ascension NamePlates addon is available but not loaded")
        return false
    else
        self:Debug("Ascension NamePlates addon is not available")
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
        self:Debug("Loaded Ascension NamePlates addon")
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
                        self:Enable()
                    else
                        self:Disable()
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
        
        -- Clickable area settings
        clickableHeader = { type = "header", name = L["Clickable Area"] or "Clickable Area", order = 20 },
        
        clickableDesc = {
            type = "description",
            name = L["These settings control the invisible clickable area of nameplates. This does not affect the visual appearance of health bars."] or "These settings control the invisible clickable area of nameplates. This does not affect the visual appearance of health bars.",
            order = 21,
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
            order = 22,
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
            order = 23,
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
            order = 24,
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
            name = L["Configure nameplate settings for enemy units that you have targeted. The primary option here is Target Scale, which is the only target-specific setting available in the NamePlates addon."] or "Configure nameplate settings for enemy units that you have targeted. The primary option here is Target Scale, which is the only target-specific setting available in the NamePlates addon.",
            order = 1,
        },
        
        spacer1 = { type = "description", name = "\n", order = 5 },
        
        -- Target scaling (the only real target-specific option)
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
            name = "|cffFFD700" .. (L["Information"] or "Information") .. ":|r " .. (L["This is the primary setting for targeted nameplates. It makes the nameplate larger when you target an enemy, helping you identify your current target more easily."] or "This is the primary setting for targeted nameplates. It makes the nameplate larger when you target an enemy, helping you identify your current target more easily."),
            fontSize = "small",
            order = 12,
        },
        
        spacer2 = { type = "description", name = "\n", order = 15 },
        
        -- Additional enemy options reference
        additionalHeader = { type = "header", name = L["Additional Enemy Options"] or "Additional Enemy Options", order = 20 },
        
        additionalInfo = {
            type = "description",
            name = L["For more enemy nameplate customization options, visit the"] or "For more enemy nameplate customization options, visit the" .. " |cff00ff00" .. (L["Enemy"] or "Enemy") .. "|r " .. (L["tab. There you can configure:"] or "tab. There you can configure:") .. "\n\n" ..
                   "• " .. (L["Health bar appearance and size"] or "Health bar appearance and size") .. "\n" ..
                   "• " .. (L["Name display and fonts"] or "Name display and fonts") .. "\n" ..
                   "• " .. (L["Cast bar settings"] or "Cast bar settings") .. "\n" ..
                   "• " .. (L["Level indicators"] or "Level indicators") .. "\n" ..
                   "• " .. (L["Quest objective icons"] or "Quest objective icons") .. "\n\n" ..
                   (L["All these settings apply to enemy nameplates, including when they are targeted."] or "All these settings apply to enemy nameplates, including when they are targeted."),
            order = 21,
        },
        
        spacer3 = { type = "description", name = "\n", order = 25 },
        
        -- Technical note
        technicalHeader = { type = "header", name = L["Technical Note"] or "Technical Note", order = 30 },
        
        technicalInfo = {
            type = "description",
            name = "|cffFF8C00" .. (L["Note about Target-Specific Options"] or "Note about Target-Specific Options") .. ":|r " .. (L["The Ascension NamePlates addon only provides one target-specific setting: Target Scale. Other visual enhancements for targets would require custom implementation beyond the scope of the base addon."] or "The Ascension NamePlates addon only provides one target-specific setting: Target Scale. Other visual enhancements for targets would require custom implementation beyond the scope of the base addon."),
            fontSize = "small",
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