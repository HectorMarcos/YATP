--========================================================--
-- YATP - Hotkeys Module (integrated & adapted from BetterKeybinds)
-- Provides hotkey font styling + ability icon tint (range/mana/usability)
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
-- Intervalo base anterior: 0.15. Ahora gestionado vía scheduler central.
local UPDATE_INTERVAL = 0.15 -- intervalo base (ajustable por usuario)
local BATCH_SIZE = 18         -- número de botones procesados por tick (round-robin)
local MIN_INTERVAL = 0.10
local MAX_INTERVAL = 0.40
-- Burst reactivo eliminado (mantener intervalo uniforme para simplificar y evitar micro picos)

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

-- Cache for button -> primary binding (updated on demand)
local buttonBindings = {}

-- Helper: get the first binding key for an action button id (e.g. "ACTIONBUTTON1")
local function GetPrimaryBindingForButton(button)
  if not button or not button.GetName then return nil end
  local name = button:GetName()
  if not name then return nil end
  -- Normalize some standard prefixes -> binding names used by Blizzard
  -- Most default bars use ActionButtonX (1..12)
  local id = button.action or (button.GetID and button:GetID())
  if id then
    -- For primary action bar 1..12
    local binding = GetBindingKey("ACTIONBUTTON"..id)
    if binding then return binding end
  end
  -- Fallback: try name directly (rare cases)
  local binding = GetBindingKey(name:upper())
  return binding
end

Module.defaults = {
  enabled = true,
  interval = 0.15, -- user adjustable (default lowered per feedback)
  font = "FRIZQT",
  size = 13,
  flags = "OUTLINE",
  hotkeyColor = {1,1,1},
  tintEnabled = true, -- allow turning icon tinting off
  colors = {
    range = {0.8,0.1,0.1},
    mana  = {0.5,0.5,1.0},
    unusable = {0.4,0.4,0.4},
    normal = {1,1,1},
  },
  anyDown = false, -- toggle para RegisterForClicks("AnyDown")
  keyboardOnly = true, -- requested: limit AnyDown to keys only (heuristic, see comments)
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
-- Tint Logic (centralizado)
-- ========================================================
local activeButtons = {}   -- set de botones registrados
local activeList = {}      -- lista indexada para batching
local activeCount = 0
local rrIndex = 1          -- índice round-robin
local scheduled = false    -- marca si la tarea del scheduler ya está añadida

local function UpdateUsable(button, db)
  local icon = GetButtonIcon(button)
  if not icon or not button.action or not HasAction(button.action) then return end
  local isUsable, notEnoughMana = IsUsableAction(button.action)
  local outOfRange = button.__YATP_OutOfRange
  local desired
  if not db.tintEnabled then
    desired = db.colors.normal
  else
    if outOfRange then
      desired = db.colors.range
    elseif not isUsable then
      desired = notEnoughMana and db.colors.mana or db.colors.unusable
    else
      desired = db.colors.normal
    end
  end
  local last = button.__YATP_LastColor
  if not last or last[1]~=desired[1] or last[2]~=desired[2] or last[3]~=desired[3] then
    if icon:IsVisible() then
      icon:SetVertexColor(desired[1], desired[2], desired[3])
      button.__YATP_LastColor = desired -- reuse table ref
    end
  end
end

-- Ejecuta un lote de botones (batch) y avanza rrIndex.
local function ProcessBatch()
  local db = Module.db
  if not (db and db.enabled) then return end
  if activeCount == 0 then return end
  local processed = 0
  while processed < BATCH_SIZE do
    if activeCount == 0 then break end
    if rrIndex > activeCount then rrIndex = 1 end
    local button = activeList[rrIndex]
    rrIndex = rrIndex + 1
    processed = processed + 1
    if button and activeButtons[button] then
      if button.action and HasAction(button.action) then
        if ActionHasRange(button.action) then
          local inRange = IsActionInRange(button.action)
          button.__YATP_OutOfRange = (inRange == 0)
        else
          button.__YATP_OutOfRange = false
        end
        UpdateUsable(button, db)
      else
        local icon = GetButtonIcon(button)
        if icon then icon:SetVertexColor(1,1,1) end
      end
    end
    if processed >= BATCH_SIZE then break end
  end
end

local function EnsureScheduled()
  if scheduled then return end
  local sched = YATP and YATP.GetScheduler and YATP:GetScheduler()
  if not sched then return end
  -- Usamos función de intervalo dinámica para soportar burst y slider
  sched:AddTask("HotkeysUpdate", function()
    local db = Module.db
    local iv = (db and tonumber(db.interval)) or UPDATE_INTERVAL
    if iv < MIN_INTERVAL then iv = MIN_INTERVAL elseif iv > MAX_INTERVAL then iv = MAX_INTERVAL end
    return iv
  end, ProcessBatch, { spread = 0 })
  scheduled = true
end

-- ========================================================
-- Button Setup
-- ========================================================
function Module:SetupButton(button)
  if not button or button.__YATP_HK_Setup then return end
  button.__YATP_HK_Setup = true

  -- AnyDown toggle (only if db.anyDown true). Keyboard-only requested:
  -- Technical note: The Blizzard API does not expose a direct way to distinguish keyboard vs mouse
  -- for RegisterForClicks decisions. To approximate "keyboard only" we check if a key binding exists;
  -- if present we register AnyDown, otherwise fall back to AnyUp. This is a safe heuristic that avoids taint.
  -- More advanced filtering (e.g. pre-cast mouse suppression) intentionally omitted for simplicity.
  local db = self.db
  if button.RegisterForClicks then
    if db.anyDown then
      if db.keyboardOnly then
        -- Only register AnyDown if button has a keyboard binding; leave mouse default (Up)
        local binding = GetPrimaryBindingForButton(button)
        buttonBindings[button] = binding
        if binding then
          button:RegisterForClicks("AnyDown")
        else
          button:RegisterForClicks("AnyUp")
        end
      else
        button:RegisterForClicks("AnyDown")
      end
    else
      button:RegisterForClicks("AnyUp")
    end
  end

  self:StyleHotkey(button)
  if not activeButtons[button] then
    activeButtons[button] = true
    activeCount = activeCount + 1
    activeList[activeCount] = button
  end
  UpdateUsable(button, self.db) -- actualización inmediata inicial
  EnsureScheduled()
end

function Module:ForceAll()
  -- reconstruir listas (útil si barras cambiaron)
  wipe(activeButtons)
  wipe(activeList)
  activeCount = 0
  rrIndex = 1
  for _, group in ipairs(BUTTON_GROUPS) do
    local prefix, count = group[1], group[2]
    for i=1, count do
      local btn = _G[prefix..i]
      if btn then self:SetupButton(btn) end
    end
  end
  EnsureScheduled()
end

-- Forzar una actualización completa inmediata (sin esperar batches) útil en burst
-- ImmediateFullRefresh eliminado (ya no necesario sin burst)

-- Reapply click registration for all active buttons when bindings/flags change
function Module:ReapplyClickRegistration()
  if not self.db then return end
  for button in pairs(activeButtons) do
    if button and button.RegisterForClicks then
      if self.db.anyDown then
        if self.db.keyboardOnly then
          local binding = GetPrimaryBindingForButton(button)
            buttonBindings[button] = binding
            if binding then
              button:RegisterForClicks("AnyDown")
            else
              button:RegisterForClicks("AnyUp")
            end
        else
          button:RegisterForClicks("AnyDown")
        end
      else
        button:RegisterForClicks("AnyUp")
      end
    end
  end
end

-- Hooks para que futuros botones ( stance / pet updates ) se integren
local function HookActionUpdate(btn)
  if btn then Module:SetupButton(btn) end
end

-- Hotkey refresh
local function HookHotkeyUpdate(btn)
  if type(btn)=="table" then Module:StyleHotkey(btn) end
end

-- Usable state change
local function HookUsableUpdate(btn)
  if btn and btn.__YATP_HK_Setup then
    UpdateUsable(btn, Module.db)
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
  -- Comando rápido para cambiar intervalo: /yatphotkint 0.18
  self:RegisterChatCommand("yatphotkint", function(input)
    local v = tonumber(input)
    if not v then
      DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99YATP:Hotkeys|r Usa /yatphotkint <segundos>. Actual: "..tostring(self.db.interval))
      return
    end
    if v < MIN_INTERVAL then v = MIN_INTERVAL elseif v > MAX_INTERVAL then v = MAX_INTERVAL end
    self.db.interval = v
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99YATP:Hotkeys|r Intervalo ajustado a "..string.format("%.2f", v))
  end)
end

function Module:OnEnable()
  if not self.db.enabled then return end
  EnsureScheduled()
  hooksecurefunc("ActionButton_Update", HookActionUpdate)
  hooksecurefunc("ActionButton_UpdateHotkeys", HookHotkeyUpdate)
  hooksecurefunc("ActionButton_UpdateUsable", HookUsableUpdate)
  -- Listen for keybinding updates so we can re-evaluate keyboardOnly heuristics
  self:RegisterEvent("UPDATE_BINDINGS", function() self:ReapplyClickRegistration() end)
  -- Burst cuando cambia el objetivo para reacción rápida de rango
  -- Sin burst: se mantiene actualización uniforme basado en intervalo
  self:ForceAll()
end

function Module:OnDisable()
  -- Limpieza ligera: no desmontamos hooksecurefunc (no se puede), sólo paramos frame
  -- Detener sólo el estado interno (el scheduler mantiene la tarea, pero inactiva al ver enabled=false)
  wipe(activeButtons)
  wipe(activeList)
  wipe(buttonBindings)
  activeCount = 0
  rrIndex = 1
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
    elseif key == "anyDown" then
      -- Reaplicar clicks
      self:ForceAll()
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
      desc = { type="description", order=2, fontSize="medium", name = L["Customize action button hotkey fonts and ability icon tint."] or "Customize action button hotkey fonts and ability icon tint." },
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
        range = { type="color", order=2, name=L["Out of Range"], get=get, set=set },
        mana = { type="color", order=3, name=L["Not Enough Mana"], get=get, set=set },
        unusable = { type="color", order=4, name=L["Unusable"], get=get, set=set },
        normal = { type="color", order=5, name=L["Normal"], get=get, set=set },
        interval = { type="range", order=6, name=L["Update Interval"], desc=L["Base seconds between tint update batches (lower = more responsive, higher = cheaper)."], min=MIN_INTERVAL, max=MAX_INTERVAL, step=0.01, get=get, set=function(info,v)
          set(info,v)
          -- Pequeño refresco rápido para que el usuario note el cambio al bajar intervalo
          for btn in pairs(activeButtons) do
            if btn and btn.action and HasAction(btn.action) then
              if ActionHasRange(btn.action) then
                local inRange = IsActionInRange(btn.action)
                btn.__YATP_OutOfRange = (inRange == 0)
              else
                btn.__YATP_OutOfRange = false
              end
              UpdateUsable(btn, self.db)
            end
          end
        end },
      }},
      behaviorGroup = { type="group", order=30, inline=true, name=L["Behavior"], args = {
        anyDown = { type="toggle", order=1, name=L["Trigger on Key Down"], desc=L["Fire actions on key press (may reduce perceived input lag)."], get=get, set=function(info,v) set(info,v); self:ReapplyClickRegistration() end },
        keyboardOnly = { type="toggle", order=2, name=L["Keyboard Only"] , desc=L["Apply 'key down' only if the button has a keyboard binding; mouse clicks stay default (on release)."], get=get, set=function(info,v) set(info,v); self:ReapplyClickRegistration() end },
      }},
    },
  }
end

function Module:OpenConfig()
  if YATP.OpenConfig then YATP:OpenConfig(ModuleName) end
end

return Module
