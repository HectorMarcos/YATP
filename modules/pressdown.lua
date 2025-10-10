--========================================================--
-- YATP - Pressdown Module
-- Enables key press actions to trigger on key down instead of key release
-- Based on SnowfallKeyPress methodology using SecureActionButtonTemplate and override bindings
--========================================================--

local ADDON = "YATP"
local ModuleName = "Pressdown"

local YATP = LibStub("AceAddon-3.0"):GetAddon(ADDON, true)
if not YATP then return end
local L = LibStub("AceLocale-3.0"):GetLocale(ADDON, true) or setmetatable({}, { __index=function(_,k) return k end })

local Module = YATP:NewModule(ModuleName, "AceConsole-3.0", "AceEvent-3.0")

-- Import string functions for performance
local stringmatch = string.match
local stringgsub = string.gsub
local pairs = pairs
local ipairs = ipairs
local _G = _G

-- ========================================================
-- Load settings 
-- ========================================================
-- Ensure settings are loaded
if not YATP.Pressdown then YATP.Pressdown = {} end
if not YATP.Pressdown.settings then
  -- Default settings if not loaded
  YATP.Pressdown.settings = {
    keys = {
      "1", "2", "3", "4", "5", "6", "7", "8", "9", "0", "-", "=",
      "Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P", "[", "]",
      "A", "S", "D", "F", "G", "H", "J", "K", "L", ";", "'",
      "Z", "X", "C", "V", "B", "N", "M", ",", ".", "/",
      "F1", "F2", "F3", "F4", "F5", "F6", "F7", "F8", "F9", "F10", "F11", "F12",
      "NUMPAD1", "NUMPAD2", "NUMPAD3", "NUMPAD4", "NUMPAD5", "NUMPAD6", "NUMPAD7", "NUMPAD8", "NUMPAD9", "NUMPAD0",
      "SPACE", "TAB", "ESCAPE", "ENTER", "BACKSPACE",
      "MOUSEWHEELUP", "MOUSEWHEELDOWN",
      "BUTTON3", "BUTTON4", "BUTTON5"
    },
    modifiers = { "ALT", "CTRL", "SHIFT" }
  }
end

-- ========================================================
-- Configuration and State
-- ========================================================
local keysConfig = {}
local hook = true
local overrideFrame = CreateFrame("Frame")

-- Allowed type attributes for secure buttons (security check)
local allowedTypeAttributes = {
  ["actionbar"] = true,
  ["action"] = true,
  ["pet"] = true,
  ["multispell"] = true,
  ["spell"] = true,
  ["item"] = true,
  ["macro"] = true,
  ["cancelaura"] = true,
  ["stop"] = true,
  ["target"] = true,
  ["focus"] = true,
  ["assist"] = true,
  ["maintank"] = true,
  ["mainassist"] = true
}

-- ========================================================
-- Command Templates (adapted from SnowfallKeyPress)
-- ========================================================
local templates = {
  {command = "^ACTIONBUTTON(%d+)$",          attributes = {{"type", "macro"}, {"actionbutton", "%1"                         }}},
  {command = "^MULTIACTIONBAR1BUTTON(%d+)$", attributes = {{"type", "click"}, {"clickbutton",  "MultiBarBottomLeftButton%1" }}},
  {command = "^MULTIACTIONBAR2BUTTON(%d+)$", attributes = {{"type", "click"}, {"clickbutton",  "MultiBarBottomRightButton%1"}}},
  {command = "^MULTIACTIONBAR3BUTTON(%d+)$", attributes = {{"type", "click"}, {"clickbutton",  "MultiBarRightButton%1"      }}},
  {command = "^MULTIACTIONBAR4BUTTON(%d+)$", attributes = {{"type", "click"}, {"clickbutton",  "MultiBarLeftButton%1"       }}},
  {command = "^SHAPESHIFTBUTTON(%d+)$",      attributes = {{"type", "click"}, {"clickbutton",  "ShapeshiftButton%1"         }}},
  {command = "^BONUSACTIONBUTTON(%d+)$",     attributes = {{"type", "click"}, {"clickbutton",  "PetActionButton%1"          }}},
  {command = "^MULTICASTSUMMONBUTTON(%d+)$", attributes = {{"type", "click"}, {"multicastsummon", "%1"                      }}},
  {command = "^MULTICASTRECALLBUTTON1$",     attributes = {{"type", "click"}, {"clickbutton",  "MultiCastRecallSpellButton" }}},
  {command = "^CLICK (.+):([^:]+)$",         attributes = {{"type", "click"}, {"clickbutton",  "%1"                         }}},
  {command = "^MACRO (.+)$",                 attributes = {{"type", "macro"}, {"macro",        "%1"                         }}},
  {command = "^SPELL (.+)$",                 attributes = {{"type", "spell"}, {"spell",        "%1"                         }}},
  {command = "^ITEM (.+)$",                  attributes = {{"type", "item" }, {"item",         "%1"                         }}},
}

-- ========================================================
-- Defaults
-- ========================================================
Module.defaults = {
  enabled = true
}

-- ========================================================
-- Helper Functions
-- ========================================================
local function isSecureButton(x)
  return not not (
    type(x) == "table"
    and type(x.IsObjectType) == "function"
    and issecurevariable(x, "IsObjectType")
    and x:IsObjectType("Button")
    and select(2, x:IsProtected())
  )
end

-- Create modifier combinations
local function createModifierCombos(base, modifierNum, modifiers, modifierCombos)
  local modifier = modifiers[modifierNum]
  if (not modifier) then
    table.insert(modifierCombos, base)
    return
  end

  local nextModifierNum = modifierNum + 1
  createModifierCombos(base, nextModifierNum, modifiers, modifierCombos)
  createModifierCombos(base .. modifier .. "-", nextModifierNum, modifiers, modifierCombos)
end

-- Populate keysConfig with all key combinations
local function populateKeysConfig()
  if not Module.db then return end
  
  wipe(keysConfig)
  local modifierCombos = {}
  local keys = YATP.Pressdown.settings.keys
  local modifiers = YATP.Pressdown.settings.modifiers
  
  createModifierCombos("", 1, modifiers, modifierCombos)
  
  for _, key in ipairs(keys) do
    if stringmatch(key, "-.") then
      table.insert(keysConfig, stringmatch(key, "^-?(.*)$"))
    else
      for _, modifierCombo in ipairs(modifierCombos) do
        table.insert(keysConfig, modifierCombo .. key)
      end
    end
  end
end

-- ========================================================
-- Core Override Binding System
-- ========================================================

-- Accelerate a key by creating an override binding
local function accelerateKey(key, command)
  local bindButtonName, bindButton
  local attributeName, attributeValue
  local mouseButton, harmButton, helpButton
  local mouseType, harmType, helpType
  local clickButtonName, clickButton

  for _, template in ipairs(templates) do
    if stringmatch(command, template.command) then
      -- Make sure there are attributes, otherwise this key is blacklisted
      if template.attributes then
        clickButtonName, mouseButton = stringmatch(command, "^CLICK (.+):([^:]+)$")
        if clickButtonName then
          -- For clicks, check that the target is a SecureActionButton
          clickButton = _G[clickButtonName]
          if not isSecureButton(clickButton) or clickButton:GetAttribute("", "downbutton", mouseButton) then
            return
          end
          harmButton = SecureButton_GetModifiedAttribute(clickButton, "harmbutton", mouseButton)
          helpButton = SecureButton_GetModifiedAttribute(clickButton, "helpbutton", mouseButton)
          mouseType = SecureButton_GetModifiedAttribute(clickButton, "type", mouseButton)
          harmType = SecureButton_GetModifiedAttribute(clickButton, "type", harmButton)
          helpType = SecureButton_GetModifiedAttribute(clickButton, "type", helpButton)
          if (
            mouseType and not allowedTypeAttributes[mouseType]
            or harmType and not allowedTypeAttributes[harmType]
            or helpType and not allowedTypeAttributes[helpType]
          ) then
            return
          end
        else
          -- For non-clicks, the default mouse button is LeftButton
          mouseButton = "LeftButton"
        end

        -- Create the bind button if it doesn't already exist
        bindButtonName = "YATP_Pressdown_Button_" .. key
        bindButton = _G[bindButtonName]
        if not bindButton then
          bindButton = CreateFrame("Button", bindButtonName, nil, "SecureActionButtonTemplate")
          bindButton:RegisterForClicks("AnyDown")
          
          -- Set frame refs for special cases (check existence first)
          if VehicleMenuBar then
            SecureHandlerSetFrameRef(bindButton, "VehicleMenuBar", VehicleMenuBar)
          end
          if BonusActionBarFrame then
            SecureHandlerSetFrameRef(bindButton, "BonusActionBarFrame", BonusActionBarFrame)
          end
          if MultiCastSummonSpellButton then
            SecureHandlerSetFrameRef(bindButton, "MultiCastSummonSpellButton", MultiCastSummonSpellButton)
          end
          
          -- Execute secure handler setup
          local setupCode = [[
            VehicleMenuBar = self:GetFrameRef("VehicleMenuBar");
            BonusActionBarFrame = self:GetFrameRef("BonusActionBarFrame");
          ]]
          if MultiCastSummonSpellButton then
            setupCode = setupCode .. [[MultiCastSummonSpellButton = self:GetFrameRef("MultiCastSummonSpellButton");]]
          end
          SecureHandlerExecute(bindButton, setupCode)
        end

        -- Clear out any old wrap script that may exist
        SecureHandlerUnwrapScript(bindButton, "OnClick")

        -- Apply specified attributes
        for _, attribute in ipairs(template.attributes) do
          attributeName = attribute[1]
          attributeValue = stringgsub(command, template.command, attribute[2], 1)

          if attributeName == "clickbutton" then
            -- For "clickbutton" attributes, convert the button name into a button reference
            bindButton:SetAttribute(attributeName, _G[attributeValue])
          elseif attributeName == "actionbutton" then
            -- For our custom "actionbutton" attribute, handle vehicle/bonus/action buttons
            SecureHandlerWrapScript(
              bindButton, "OnClick", bindButton,
              [[
                local clickMacro = "/click ActionButton]] .. attributeValue .. [[";
                if (VehicleMenuBar and VehicleMenuBar:IsProtected() and VehicleMenuBar:IsShown() and ]] .. tostring(tonumber(attributeValue) <= 6) .. [[) then
                  clickMacro = "/click VehicleMenuBarActionButton]] .. attributeValue .. [[";
                elseif (BonusActionBarFrame and BonusActionBarFrame:IsProtected() and BonusActionBarFrame:IsShown()) then
                  clickMacro = "/click BonusActionButton]] .. attributeValue .. [[";
                end
                self:SetAttribute("macrotext", clickMacro);
              ]]
            )
          elseif attributeName == "multicastsummon" then
            -- For multicast summon buttons
            if MultiCastSummonSpellButton then
              SecureHandlerWrapScript(
                bindButton, "OnClick", bindButton,
                [[
                  if MultiCastSummonSpellButton then
                    lastID = MultiCastSummonSpellButton:GetID();
                    MultiCastSummonSpellButton:SetID(]] .. attributeValue .. [[);
                  end
                ]],
                [[
                  if MultiCastSummonSpellButton and lastID then
                    MultiCastSummonSpellButton:SetID(lastID);
                  end
                ]]
              )
              bindButton:SetAttribute("clickbutton", MultiCastSummonSpellButton)
            end
          else
            bindButton:SetAttribute(attributeName, attributeValue)
          end
        end

        -- Create a priority override
        hook = false
        SetOverrideBindingClick(overrideFrame, true, key, bindButtonName, mouseButton)
        hook = true
      end

      -- Stop since we found a matching template
      return
    end
  end
end

-- Update all bindings
local function updateBindings()
  if InCombatLockdown() then
    return
  end

  -- Remove all of our overrides so we can see other overrides
  hook = false
  ClearOverrideBindings(overrideFrame)
  hook = true

  if not Module.db or not Module.db.enabled then
    overrideFrame:UnregisterEvent("UPDATE_BINDINGS")
    hook = false
    return
  end

  -- Find all bound keys and accelerate them
  local command
  for _, key in ipairs(keysConfig) do
    command = GetBindingAction(key, true)
    if command then
      accelerateKey(key, command)
    end
  end
end

-- ========================================================
-- Override Binding Hooks
-- ========================================================
local function setOverrideBindingHook(_, _, overrideKey)
  if not hook or InCombatLockdown() then
    return
  end

  local command
  for _, key in ipairs(keysConfig) do
    if overrideKey == key then
      hook = false
      SetOverrideBinding(overrideFrame, false, overrideKey, nil)
      hook = true
      command = GetBindingAction(overrideKey, true)
      if command then
        accelerateKey(overrideKey, command)
      end
      break
    end
  end
end

local function clearOverrideBindingsHook()
  if not hook then
    return
  end
  updateBindings()
end

-- ========================================================
-- Module Lifecycle
-- ========================================================
function Module:OnInitialize()
  if not YATP.db.profile.modules then YATP.db.profile.modules = {} end
  if not YATP.db.profile.modules[ModuleName] then
    YATP.db.profile.modules[ModuleName] = CopyTable(self.defaults)
  end
  self.db = YATP.db.profile.modules[ModuleName]

  -- Register as a separate module but with order to appear right after Hotkeys
  if YATP.AddModuleOptions then
    YATP:AddModuleOptions(ModuleName, self:BuildOptions())
  end

  self:RegisterChatCommand("yatppressdown", function() self:OpenConfig() end)
  
  -- Clear key binding mode so that the Blizzard key binding UI doesn't look for overrides
  hooksecurefunc("ShowUIPanel", function() 
    if KeyBindingFrame then 
      KeyBindingFrame.mode = nil 
    end 
  end)
end

function Module:OnEnable()
  if not self.db.enabled then return end
  
  -- Populate keys configuration
  populateKeysConfig()
  
  -- Hook override binding functions
  hooksecurefunc("SetOverrideBinding", setOverrideBindingHook)
  hooksecurefunc("SetOverrideBindingSpell", setOverrideBindingHook)
  hooksecurefunc("SetOverrideBindingClick", setOverrideBindingHook)
  hooksecurefunc("SetOverrideBindingItem", setOverrideBindingHook)
  hooksecurefunc("SetOverrideBindingMacro", setOverrideBindingHook)
  hooksecurefunc("ClearOverrideBindings", clearOverrideBindingsHook)
  
  -- Setup event handling
  overrideFrame:UnregisterAllEvents()
  overrideFrame:SetScript("OnEvent", updateBindings)
  overrideFrame:RegisterEvent("UPDATE_BINDINGS")
  
  -- Initial binding update
  updateBindings()
end

function Module:OnDisable()
  -- Clear all override bindings
  hook = false
  ClearOverrideBindings(overrideFrame)
  hook = true
  
  -- Unregister events
  overrideFrame:UnregisterAllEvents()
  overrideFrame:SetScript("OnEvent", nil)
end

-- ========================================================
-- Configuration Options
-- ========================================================
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
    else
      -- Refresh configuration when keys/modifiers change
      if self:IsEnabled() then
        populateKeysConfig()
        updateBindings()
      end
    end
  end

  return {
    type = "group",
    name = L["Pressdown"] or "Pressdown",
    args = {
      enabled = { 
        type = "toggle", 
        order = 1, 
        name = L["Enable Pressdown"] or "Enable Pressdown",
        desc = L["Makes actions trigger on key press instead of key release."] or "Makes actions trigger on key press instead of key release.",
        get = get, 
        set = function(info, val)
          set(info, val)
          if YATP.ShowReloadPrompt then YATP:ShowReloadPrompt() end
        end 
      },
      desc = { 
        type = "description", 
        order = 2, 
        fontSize = "medium", 
        name = L["Makes key-bound actions trigger immediately when you press a key down, instead of waiting for key release. This can reduce input lag and make the game feel more responsive."] or "Makes key-bound actions trigger immediately when you press a key down, instead of waiting for key release. This can reduce input lag and make the game feel more responsive." 
      },
      spacer = {
        type = "description",
        order = 3,
        name = " ",
        fontSize = "small"
      },
      note = {
        type = "description", 
        order = 4, 
        fontSize = "small", 
        name = L["|cffFFD700Note:|r Requires /reload to fully apply enabling or disabling this feature."] or "|cffFFD700Note:|r Requires /reload to fully apply enabling or disabling this feature." 
      },
    },
  }
end

function Module:OpenConfig()
  if YATP.OpenConfig then YATP:OpenConfig(ModuleName) end
end

return Module