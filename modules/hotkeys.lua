--========================================================--
-- YATP - Hotkeys Module (integrated & adapted from BetterKeybinds)
-- Provides hotkey font styling + ability icon tint (range/mana/usability)
-- Note: Click behavior (pressdown) is handled by the separate Pressdown module
--========================================================--

local ADDON = "YATP"
local ModuleName = "Hotkeys" -- Short, clear and extensible

local YATP = LibStub("AceAddon-3.0"):GetAddon(ADDON, true)
if not YATP then return end
local L = LibStub("AceLocale-3.0"):GetLocale(ADDON, true) or setmetatable({}, { __index=function(_,k) return k end })

local Module = YATP:NewModule(ModuleName, "AceConsole-3.0", "AceEvent-3.0")

-- ========================================================
-- Constantes / Config por defecto
-- ========================================================
-- Sistema replicado de Bartender4: cada botón tiene su propio rangeTimer
local TOOLTIP_UPDATE_TIME = 0.2 -- intervalo entre checks de rango (matching Bartender4)
local RANGE_INDICATOR = "•" -- indicador visual cuando no hay hotkey

local FONTS = {
  FRIZQT   = { name = "Friz Quadrata", path = "Fonts\\FRIZQT__.TTF" },
  ARIALN   = { name = "Arial Narrow",  path = "Fonts\\ARIALN.TTF"  },
  MORPHEUS = { name = "Morpheus",      path = "Fonts\\MORPHEUS.TTF"},
  SKURRI   = { name = "Skurri",        path = "Fonts\\SKURRI.TTF"  },
}

local FLAG_LABELS = {
  [""]             = "None",
  ["OUTLINE"]      = "Outline",
  ["THICKOUTLINE"] = "Thick Outline",
  ["MONOCHROME"]   = "Monochrome",
  ["MONOCHROME,OUTLINE"] = "Mono+Outline",
}

local BUTTON_GROUPS = {
  { "ActionButton", 12 },
  { "BonusActionButton", 12 },
  { "MultiBarBottomLeftButton", 12 },
  { "MultiBarBottomRightButton", 12 },
  { "MultiBarRightButton", 12 },
  { "MultiBarLeftButton", 12 },
  { "PetActionButton", 10 },
  { "ShapeshiftButton", 10 },
}

Module.defaults = {
  enabled = true,
  font = "FRIZQT",
  size = 13,
  flags = "OUTLINE",
  hotkeyColor = {1,1,1},
  tintEnabled = true, -- allow turning icon tinting off
  outofrange = "button", -- "none", "button", "hotkey" (matching Bartender4)
  colors = {
    range = {0.8,0.1,0.1},
    mana  = {0.5,0.5,1.0},
    unusable = {0.4,0.4,0.4},
    normal = {1,1,1},
  },
}

-- ========================================================
-- Helpers
-- ========================================================
local function GetButtonIcon(button)
  if not button then return nil end
  return button.icon or (button.GetName and _G[button:GetName().."Icon"]) or nil
end

local function fontValues()
  local t = {}
  for k,v in pairs(FONTS) do t[k] = v.name end
  return t
end

-- ========================================================
-- Hotkey Styling
-- ========================================================
function Module:StyleHotkey(button)
  if not button then return end
  local hotkey = button.HotKey or (button.GetName and _G[button:GetName().."HotKey"]) or nil
  if not hotkey then return end

  local db = self.db
  if not (db and db.enabled) then return end

  local fontPath = (FONTS[db.font] and FONTS[db.font].path) or FONTS.FRIZQT.path
  local flags = db.flags ~= "" and db.flags or nil
  hotkey:SetFont(fontPath, db.size, flags)
  hotkey:ClearAllPoints()
  hotkey:SetPoint("TOPLEFT", button, "TOPLEFT", 1, -1)

  -- Lock Blizzard recolor attempts
  if not hotkey.__YATP_HK_ColorLocked then
    hotkey.__YATP_HK_OrigSetTextColor   = hotkey.SetTextColor
    hotkey.__YATP_HK_OrigSetVertexColor = hotkey.SetVertexColor
    hotkey.SetTextColor   = function() end
    hotkey.SetVertexColor = function() end
    hotkey.__YATP_HK_ColorLocked = true
  end
  local r,g,b = unpack(db.hotkeyColor)
  local f1 = hotkey.__YATP_HK_OrigSetTextColor or hotkey.SetTextColor
  local f2 = hotkey.__YATP_HK_OrigSetVertexColor or hotkey.SetVertexColor
  f1(hotkey, r,g,b)
  f2(hotkey, r,g,b)
end

-- ========================================================
-- Range Check Logic (Bartender4 Style - Per-Button Timer)
-- ========================================================
local activeButtons = {}   -- set de botones registrados

-- OnUpdate handler para cada botón (estilo Bartender4)
local function Button_OnUpdate(self, elapsed)
  local db = Module.db
  if not (db and db.enabled) then return end
  
  -- Range timer check
  if self.__YATP_rangeTimer then
    self.__YATP_rangeTimer = self.__YATP_rangeTimer - elapsed
    if self.__YATP_rangeTimer <= 0 then
      -- Check range
      if self.action and HasAction(self.action) and ActionHasRange(self.action) then
        local valid = IsActionInRange(self.action)
        self.__YATP_OutOfRange = (valid == 0)
      else
        self.__YATP_OutOfRange = false
      end
      
      -- Update usable state
      Module:UpdateUsable(self)
      
      -- Reset timer
      self.__YATP_rangeTimer = TOOLTIP_UPDATE_TIME
    end
  end
end

-- Actualiza el estado visual del botón (usable/mana/range)
function Module:UpdateUsable(button)
  local icon = GetButtonIcon(button)
  if not icon or not button.action or not HasAction(button.action) then return end
  
  local db = self.db
  local isUsable, notEnoughMana = IsUsableAction(button.action)
  local outOfRange = button.__YATP_OutOfRange
  
  local desired
  if not db.tintEnabled then
    desired = db.colors.normal
  else
    -- Bartender4 logic: range check first, then usability
    if db.outofrange == "button" and outOfRange then
      desired = db.colors.range
    elseif not isUsable then
      desired = notEnoughMana and db.colors.mana or db.colors.unusable
    else
      desired = db.colors.normal
    end
  end
  
  -- Optimización: solo actualizar si el color cambió
  local last = button.__YATP_LastColor
  if not last or last[1]~=desired[1] or last[2]~=desired[2] or last[3]~=desired[3] then
    if icon:IsVisible() then
      icon:SetVertexColor(desired[1], desired[2], desired[3])
      button.__YATP_LastColor = desired
    end
  end
end

-- Inicializa o actualiza el range timer de un botón
function Module:UpdateRange(button)
  if not button then return end
  local db = self.db
  
  if db.outofrange == "none" or not button.action or not ActionHasRange(button.action) then
    -- No necesita range check
    button.__YATP_rangeTimer = nil
    button.__YATP_OutOfRange = false
  else
    -- Necesita range check - iniciar timer
    if not button.__YATP_rangeTimer then
      button.__YATP_rangeTimer = TOOLTIP_UPDATE_TIME
    end
  end
  
  self:UpdateUsable(button)
  -- Forzar actualización inmediata
  Button_OnUpdate(button, 10)
end

-- ========================================================
-- Button Setup
-- ========================================================
function Module:SetupButton(button)
  if not button or button.__YATP_HK_Setup then return end
  button.__YATP_HK_Setup = true

  self:StyleHotkey(button)
  
  -- Registrar botón
  if not activeButtons[button] then
    activeButtons[button] = true
  end
  
  -- Setup OnUpdate handler (estilo Bartender4)
  if not button.__YATP_OnUpdateHooked then
    button:SetScript("OnUpdate", Button_OnUpdate)
    button.__YATP_OnUpdateHooked = true
  end
  
  -- Inicializar range check
  self:UpdateRange(button)
end

function Module:ForceAll()
  -- Reconstruir lista de botones
  wipe(activeButtons)
  
  for _, group in ipairs(BUTTON_GROUPS) do
    local prefix, count = group[1], group[2]
    for i=1, count do
      local btn = _G[prefix..i]
      if btn then self:SetupButton(btn) end
    end
  end
end

-- ========================================================
-- Hooks para integración con eventos de Blizzard
-- ========================================================
local function HookActionUpdate(btn)
  if btn and btn.__YATP_HK_Setup then
    Module:UpdateRange(btn)
  else
    Module:SetupButton(btn)
  end
end

local function HookHotkeyUpdate(btn)
  if type(btn)=="table" then Module:StyleHotkey(btn) end
end

local function HookUsableUpdate(btn)
  if btn and btn.__YATP_HK_Setup then
    Module:UpdateUsable(btn)
  end
end

-- ========================================================
-- Lifecycle
-- ========================================================
function Module:OnInitialize()
  if not YATP.db.profile.modules then YATP.db.profile.modules = {} end
  if not YATP.db.profile.modules[ModuleName] then
    YATP.db.profile.modules[ModuleName] = CopyTable(self.defaults)
  end
  self.db = YATP.db.profile.modules[ModuleName]

  if YATP.AddModuleOptions then
    YATP:AddModuleOptions(ModuleName, self:BuildOptions(), "Interface")
  end

  self:RegisterChatCommand("yatphotkeys", function() self:OpenConfig() end)
end

function Module:OnEnable()
  if not self.db.enabled then return end
  
  -- Hooks de eventos de Blizzard
  hooksecurefunc("ActionButton_Update", HookActionUpdate)
  hooksecurefunc("ActionButton_UpdateHotkeys", HookHotkeyUpdate)
  hooksecurefunc("ActionButton_UpdateUsable", HookUsableUpdate)
  
  -- Eventos para reactividad
  self:RegisterEvent("PLAYER_TARGET_CHANGED", function()
    for button in pairs(activeButtons) do
      if button.__YATP_rangeTimer then
        -- Forzar check inmediato
        button.__YATP_rangeTimer = 0
      end
    end
  end)
  
  self:RegisterEvent("ACTIONBAR_SLOT_CHANGED", function()
    for button in pairs(activeButtons) do
      if button then
        Module:UpdateRange(button)
      end
    end
  end)
  
  self:RegisterEvent("UPDATE_BINDINGS", function()
    self:ForceAll()
  end)
  
  -- Setup inicial
  self:ForceAll()
end

function Module:OnDisable()
  -- Limpiar botones
  for button in pairs(activeButtons) do
    if button then
      button.__YATP_rangeTimer = nil
      button.__YATP_OutOfRange = false
      local icon = GetButtonIcon(button)
      if icon then icon:SetVertexColor(1,1,1) end
    end
  end
  wipe(activeButtons)
end

-- ========================================================
-- Options
-- ========================================================
function Module:BuildOptions()
  local get = function(info)
    local key = info[#info]
    if key == "range" or key == "mana" or key == "unusable" or key == "normal" then
      local c = self.db.colors[key]; return c[1],c[2],c[3]
    end
    return self.db[key]
  end
  local set = function(info, val, g,b)
    local key = info[#info]
    if key == "range" or key == "mana" or key == "unusable" or key == "normal" then
      self.db.colors[key] = {val, g, b}
      self:ForceAll()
      return
    end
    self.db[key] = val
    if key == "enabled" then
      if val then self:Enable() else self:Disable() end
    else
      self:ForceAll()
    end
  end

  return {
    type = "group",
    name = L[ModuleName] or ModuleName,
    args = {
      enabled = { type="toggle", order=1, name=L["Enable Module"] or "Enable Module",
        desc = L["Requires /reload to fully apply enabling or disabling."] or "Requires /reload to fully apply enabling or disabling.",
        get=get, set=function(info,val)
          set(info,val)
          if YATP and YATP.ShowReloadPrompt then YATP:ShowReloadPrompt() end
        end },
      desc = { type="description", order=2, fontSize="medium", name = L["Customize action button hotkey fonts and ability icon tint using Bartender4-style range checking system."] or "Customize action button hotkey fonts and ability icon tint using Bartender4-style range checking system." },
      fontGroup = { type="group", order=10, inline=true, name=L["Font"], args = {
        font = { type="select", order=1, name=L["Font Face"], values=fontValues(), get=get, set=set },
        size = { type="range", order=2, name=L["Font Size"], min=8, max=24, step=1, get=get, set=set },
        flags = { type="select", order=3, name=L["Outline"], values=FLAG_LABELS, get=get, set=set },
        hotkeyColor = { type="color", order=4, name=L["Hotkey Color"], get=function()
          local c = self.db.hotkeyColor; return c[1],c[2],c[3] end,
          set=function(_,r,g,b) self.db.hotkeyColor={r,g,b}; self:ForceAll() end },
      }},
      tintGroup = { type="group", order=20, inline=true, name=L["Icon Tint"], args = {
        tintEnabled = { type="toggle", order=1, name=L["Enable Tint"], get=get, set=set },
        outofrange = { type="select", order=2, name=L["Out of Range Indicator"] or "Out of Range Indicator",
          desc = L["Configure how the Out of Range indicator displays on buttons (Bartender4 style)."] or "Configure how the Out of Range indicator displays on buttons (Bartender4 style).",
          values = { 
            none = L["No Display"] or "No Display", 
            button = L["Full Button Mode"] or "Full Button Mode", 
            hotkey = L["Hotkey Mode"] or "Hotkey Mode (Not Yet Implemented)" 
          },
          get=get, set=set },
        spacer1 = { type="description", order=3, name=" " },
        range = { type="color", order=4, name=L["Out of Range"] or "Out of Range", get=get, set=set },
        mana = { type="color", order=5, name=L["Not Enough Mana"] or "Not Enough Mana", get=get, set=set },
        unusable = { type="color", order=6, name=L["Unusable"] or "Unusable", get=get, set=set },
        normal = { type="color", order=7, name=L["Normal"] or "Normal", get=get, set=set },
      }},
    },
  }
end

function Module:OpenConfig()
  if YATP.OpenConfig then YATP:OpenConfig(ModuleName) end
end

return Module
