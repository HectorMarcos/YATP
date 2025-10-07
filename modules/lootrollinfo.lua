--========================================================--
-- YATP - LootRollInfo Module
-- Shows who rolled Need/Greed/DE/Pass on active group loot frames with counters + tooltips.
-- Ported & refactored from standalone prototype to Ace3 module under YATP.
--========================================================--
local ADDON = "YATP"
local ModuleName = "LootRollInfo"

local YATP = LibStub("AceAddon-3.0"):GetAddon(ADDON, true)
if not YATP then return end
local L = LibStub("AceLocale-3.0"):GetLocale(ADDON, true) or setmetatable({}, { __index=function(_,k) return k end })

local Module = YATP:NewModule(ModuleName, "AceEvent-3.0")

--========================================================--
-- Defaults
--========================================================--
Module.defaults = {
  enabled = true,
  hideChatRollMessages = true,
  showTooltips = true,
  showCounts = true,
  fontSizeDelta = 4,      -- extra size applied to number overlay
  classColorNames = false,
  clearOnCancel = true,
  rarityThreshold = 0,    -- 0=poor,1=common,2=uncommon,... only track >= threshold (0 means all)
  debug = false,
}

-- runtime roll storage
local rolls = {}  -- [rollID] = { itemLink=..., itemName=..., need={}, greed={}, de={}, pass={}, quality=integer }

-- quick color table
local ACTION_COLORS = {
  need  = { r=0.2, g=1.0, b=0.2 },
  greed = { r=1.0, g=0.9, b=0.2 },
  de    = { r=0.8, g=0.5, b=1.0 },
  pass  = { r=0.7, g=0.7, b=0.7 },
}

local function dprint(self, ...)
  if not self.db or not self.db.debug then return end
  local msg = "|cff33ff99LRInfo|r "..string.format(...)
  DEFAULT_CHAT_FRAME:AddMessage(msg)
end

--========================================================--
-- Init / Enable
--========================================================--
function Module:OnInitialize()
  if not YATP.db.profile.modules then YATP.db.profile.modules = {} end
  if not YATP.db.profile.modules[ModuleName] then
    YATP.db.profile.modules[ModuleName] = CopyTable(self.defaults)
  end
  self.db = YATP.db.profile.modules[ModuleName]

  if YATP.AddModuleOptions then
    YATP:AddModuleOptions(ModuleName, self:BuildOptions(), "QualityOfLife")
  end
end

function Module:OnEnable()
  if not self.db.enabled then return end
  self:RegisterEvent("START_LOOT_ROLL")
  self:RegisterEvent("CANCEL_LOOT_ROLL")
  self:RegisterEvent("CHAT_MSG_LOOT")
  if self.db.hideChatRollMessages and not self._chatFilterApplied then
    ChatFrame_AddMessageEventFilter("CHAT_MSG_LOOT", function(...) return self:ChatFilter(...) end)
    self._chatFilterApplied = true
  end
  self:HookGroupLootFrames()
  self:SetupDebugSlash()
end

function Module:OnDisable()
  -- we keep data ephemeral; clear
  for k in pairs(rolls) do rolls[k] = nil end
end

--========================================================--
-- Options
--========================================================--
function Module:BuildOptions()
  local get = function(info) return self.db[ info[#info] ] end
  local set = function(info, val)
    local key = info[#info]
    self.db[key] = val
    if key == "enabled" then
      if val then self:Enable() else self:Disable() end
    elseif key == "hideChatRollMessages" then
      -- just reload UI for simplicity or toggle filter; we'll re-add filter next enable
      if val and not self._chatFilterApplied then
        ChatFrame_AddMessageEventFilter("CHAT_MSG_LOOT", function(...) return self:ChatFilter(...) end)
        self._chatFilterApplied = true
      elseif not val and self._chatFilterApplied then
        ChatFrame_RemoveMessageEventFilter("CHAT_MSG_LOOT", self._lastFilter or self.ChatFilter)
        self._chatFilterApplied = false
      end
    end
  end
  return {
    type = "group",
    name = L[ModuleName] or ModuleName,
    args = {
      enabled = { type="toggle", order=1, name=L["Enable Module"] or "Enable Module", get=get, set=set },
      desc = { type="description", order=2, name = L["Shows who rolled Need/Greed/DE/Pass on loot frames."] or "Shows who rolled Need/Greed/DE/Pass on loot frames." },
      headerDisplay = { type="header", order=5, name = L["Display"] or "Display" },
      showTooltips = { type="toggle", order=10, name=L["Show Tooltips"] or "Show Tooltips", get=get, set=set },
      showCounts   = { type="toggle", order=11, name=L["Show Counters"] or "Show Counters", get=get, set=set },
      fontSizeDelta = { type="range", order=12, name=L["Counter Size Delta"] or "Counter Size Delta", min=0, max=10, step=1, get=get, set=set },
      classColorNames = { type="toggle", order=13, name=L["Class Color Names"] or "Class Color Names", get=get, set=set },
      headerBehavior = { type="header", order=20, name = L["Behavior"] or "Behavior" },
      hideChatRollMessages = { type="toggle", order=21, name=L["Hide Chat Messages"] or "Hide Chat Messages", desc=L["Suppress system loot roll lines from chat."] or "Suppress system loot roll lines from chat.", get=get, set=set },
      clearOnCancel = { type="toggle", order=22, name=L["Clear on Cancel"] or "Clear on Cancel", desc=L["Remove stored roll data when a roll is canceled."] or "Remove stored roll data when a roll is canceled.", get=get, set=set },
      rarityThreshold = { type="range", order=23, name=L["Track Minimum Rarity"] or "Track Minimum Rarity", min=0, max=5, step=1, get=get, set=set },
      headerDebug = { type="header", order=50, name = L["Debug"] or "Debug" },
      debug = { type="toggle", order=51, name=L["Debug Messages"] or "Debug Messages", get=get, set=set },
    }
  }
end

--========================================================--
-- Event Handlers
--========================================================--
function Module:START_LOOT_ROLL(event, rollID)
  if not self.db.enabled then return end
  local texture, name, count, quality, bop, canNeed, canGreed, canDE, canPass, reasonNeed, reasonGreed, reasonDE, deSkillRequired, canTransmog = GetLootRollItemInfo(rollID)
  if quality and quality < (self.db.rarityThreshold or 0) then
    dprint(self, "Skipping rollID %s due to quality %d < threshold %d", tostring(rollID), quality, self.db.rarityThreshold or 0)
    return
  end
  local link = GetLootRollItemLink(rollID)
  rolls[rollID] = { itemLink = link, itemName = name, need = {}, greed = {}, de = {}, pass = {}, quality = quality }
  dprint(self, "Start roll %s for %s", tostring(rollID), tostring(link))
  self:HookButtons(rollID)
end

function Module:CANCEL_LOOT_ROLL(event, rollID)
  if not self.db.enabled then return end
  if self.db.clearOnCancel then
    rolls[rollID] = nil
  end
end

function Module:CHAT_MSG_LOOT(event, msg)
  if not self.db.enabled then return end
  self:ParseLootMessage(msg)
end

--========================================================--
-- Chat Filter
--========================================================--
function Module:ChatFilter(_, event, msg, ...)
  if not self.db or not self.db.hideChatRollMessages then return false end
  if msg:find(" has selected Need for:") or msg:find(" has selected Greed for:") or msg:find(" has selected Disenchant for:") or msg:find(" has passed on:") then
    return true
  end
  return false
end

--========================================================--
-- Frame Hooking
--========================================================--
function Module:HookGroupLootFrames()
  for i=1,4 do
    local frame = _G["GroupLootFrame"..i]
    if frame and not frame._LRIFixed then
      frame:HookScript("OnShow", function(f)
        if f.rollID then self:HookButtons(f.rollID) end
      end)
      frame._LRIFixed = true
    end
  end
end

function Module:HookButtons(rollID)
  for i=1,4 do
    local frame = _G["GroupLootFrame"..i]
    if frame and frame:IsShown() and frame.rollID == rollID then
      local prefix = frame:GetName()
      local btnNeed  = _G[prefix.."RollButton"]       or frame.needButton
      local btnGreed = _G[prefix.."GreedButton"]      or frame.greedButton
      local btnDE    = _G[prefix.."DisenchantButton"] or frame.disenchantButton
      local btnPass  = _G[prefix.."PassButton"]       or frame.passButton

      local map = {
        { key="need",  btn=btnNeed },
        { key="greed", btn=btnGreed },
        { key="de",    btn=btnDE },
        { key="pass",  btn=btnPass },
      }

      for _,entry in ipairs(map) do
        local key, btn = entry.key, entry.btn
        if btn then
          if not btn._LRIHooked then
            if self.db.showTooltips then
              btn:HookScript("OnEnter", function(b) self:ShowTooltip(b, key) end)
              btn:HookScript("OnLeave", function() GameTooltip:Hide() end)
            end
            -- create fontstring now so later updates (when action messages arrive) always have it
            if self.db.showCounts and not btn.LRIText then
              btn.LRIText = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
              local font, size, flags = btn.LRIText:GetFont()
              btn.LRIText:SetFont(font, size + (self.db.fontSizeDelta or 4), flags or "OUTLINE")
              -- mimic working prototype: numbers in top-right corner with a slight negative offset
              btn.LRIText:ClearAllPoints()
              btn.LRIText:SetPoint("TOPRIGHT", btn, "TOPRIGHT", -3, -2)
            end
            btn._LRIHooked = true
          end
          self:UpdateButtonText(rollID, key, btn) -- initial update (may hide if 0)
        end
      end
      return
    end
  end
end

--========================================================--
-- Tooltip
--========================================================--
function Module:ShowTooltip(btn, key)
  if not self.db.showTooltips then return end
  local rid = btn:GetParent() and btn:GetParent().rollID
  local data = rid and rolls[rid]
  if not data then return end
  local list = data[key]
  if not list then return end
  GameTooltip:SetOwner(btn, "ANCHOR_RIGHT")
  GameTooltip:ClearLines()
  local color = ACTION_COLORS[key] or {r=1,g=1,b=1}
  GameTooltip:AddLine(string.format("%s (%d)", key:sub(1,1):upper()..key:sub(2), #list), color.r, color.g, color.b)
  for _,name in ipairs(list) do
    local r,g,b = 0.9,0.9,0.9
    if self.db.classColorNames and RAID_CLASS_COLORS then
      local class = select(2, UnitClass(name))
      local cc = class and RAID_CLASS_COLORS[class]
      if cc then r,g,b = cc.r, cc.g, cc.b end
    end
    GameTooltip:AddLine(" - "..name, r,g,b)
  end
  GameTooltip:Show()
end

--========================================================--
-- Update counters
--========================================================--
function Module:UpdateButtonText(rollID, key, btn)
  if not self.db.showCounts then return end
  local data = rolls[rollID]
  if not data then return end

  -- If button not provided (e.g., called from RefreshRoll), locate it like the standalone version did
  if not btn then
    for i=1,4 do
      local frame = _G["GroupLootFrame"..i]
      if frame and frame:IsShown() and frame.rollID == rollID then
        local prefix = frame:GetName()
        if key == "need" then btn = _G[prefix.."RollButton"] or frame.needButton end
        if key == "greed" then btn = _G[prefix.."GreedButton"] or frame.greedButton end
        if key == "de" then btn = _G[prefix.."DisenchantButton"] or frame.disenchantButton end
        if key == "pass" then btn = _G[prefix.."PassButton"] or frame.passButton end
        if btn then break end
      end
    end
  end
  if not btn then return end

  local count = data[key] and #data[key] or 0
  if not btn.LRIText then
    btn.LRIText = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    local font, size, flags = btn.LRIText:GetFont()
    btn.LRIText:SetFont(font, size + (self.db.fontSizeDelta or 4), flags or "OUTLINE")
    btn.LRIText:ClearAllPoints()
    btn.LRIText:SetPoint("TOPRIGHT", btn, "TOPRIGHT", -3, -2)
  end
  if count > 0 then
    btn.LRIText:SetText(count)
    btn.LRIText:Show()
  else
    btn.LRIText:SetText("")
    btn.LRIText:Hide()
  end
end

--========================================================--
-- Parse loot system messages (multi-locale via global strings)
--========================================================--
function Module:ParseLootMessage(msg)
  -- Build localized patterns once
  if not self._patternsBuilt then
    self._patternsBuilt = true
    local function esc(str)
      str = gsub(str, "%%", "%%%%")         -- escape %
      str = gsub(str, "%%s", "(.+)")        -- capture greedy player/item sections
      str = gsub(str, "%%d", "(%%d+)")
      return str
    end
    -- Client globals (fallback to English literal if missing)
    local needStr   = _G.LOOT_ROLL_NEED   or "%s has selected Need for: %s"
    local greedStr  = _G.LOOT_ROLL_GREED  or "%s has selected Greed for: %s"
    local deStr     = _G.LOOT_ROLL_DISENCHANT or "%s has selected Disenchant for: %s"
    local passStr   = _G.LOOT_ROLL_PASSED or "%s has passed on: %s"
    self._pNeed  = esc(needStr)
    self._pGreed = esc(greedStr)
    self._pDE    = esc(deStr)
    self._pPass  = esc(passStr)
  end

  local player, item, action
  -- Try each pattern
  do
    local a,b = msg:match(self._pNeed)
    if a and b then player, item, action = a, b, "need" end
  end
  if not player then
    local a,b = msg:match(self._pGreed)
    if a and b then player, item, action = a, b, "greed" end
  end
  if not player then
    local a,b = msg:match(self._pDE)
    if a and b then player, item, action = a, b, "de" end
  end
  if not player then
    local a,b = msg:match(self._pPass)
    if a and b then player, item, action = a, b, "pass" end
  end
  -- Fallback to simple English patterns (like working prototype) if localized ones failed
  if not (player and item and action) then
    local p, act, it = msg:match("^(.-) has selected (.-) for: (.+)$")
    if p and act and it then
      player, item = p, it
      act = act:lower()
      if act == "disenchant" then action = "de" elseif act == "greed" then action = "greed" elseif act == "need" then action = "need" end
    else
      local p2, it2 = msg:match("^(.-) has passed on: (.+)$")
      if p2 and it2 then
        player, item, action = p2, it2, "pass"
      end
    end
  end
  if not (player and item and action) then return end
  -- Extract item name inside link if present
  local linkName = item:match("%[(.+)%]") or item
  if not linkName then return end
  -- Find roll entry by matching name (if two identical names could mis-attribute; acceptable for now)
  for rid,data in pairs(rolls) do
    if data.itemLink then
      local dName = data.itemLink:match("%[(.+)%]")
      if dName == linkName then
        local key = action
        local list = data[key]
        if list then
          local exists
          for _,n in ipairs(list) do if n == player then exists = true break end end
          if not exists then
            table.insert(list, player)
            self:RefreshRoll(rid, key)
          end
        end
        return
      end
    end
  end
end

function Module:RefreshRoll(rollID, lastKey)
  self:HookButtons(rollID) -- ensures new buttons are hooked if needed
  -- update just the affected key
  self:UpdateButtonText(rollID, lastKey, nil) -- if btn nil, HookButtons already handled
end

--========================================================--
-- Debug Helpers (simulate Blizzard group loot frame)
--========================================================--
-- We re-use the existing GroupLootFrame1 to display a synthetic test item
-- Commands (only active if debug option enabled):
--   /lriblizz [itemID]
--   /lripop   <Name action>  (action = need/greed/de/pass)
--   /lrihide

local DEBUG_ROLL_ID = "LRI_DBG1"

function Module:Debug_ShowBlizzFrame(itemID)
  if not self.db.debug then
    dprint(self, "Debug disabled in options.")
    return
  end
  local frame = _G["GroupLootFrame1"]
  if not frame then
    dprint(self, "GroupLootFrame1 not found (UI replaced?).")
    return
  end

  itemID = tonumber(itemID) or 18803
  local link = select(2, GetItemInfo(itemID))
  if not link then
    link = "|cff0070dd|Hitem:18803:0:0:0:0:0:0:0|h[Finkle's Lava Dredger]|h|r" -- fallback if not cached
  end

  rolls[DEBUG_ROLL_ID] = { itemLink = link, itemName = link:match("%[(.+)%]") or link, need = {}, greed = {}, de = {}, pass = {}, quality = 3 }

  local prefix = frame:GetName()
  local icon   = _G[prefix.."Icon"] or frame.Icon
  local nameFS = _G[prefix.."Name"] or frame.Name
  local tex = GetItemIcon(itemID)
  if icon and tex then icon:SetTexture(tex) end
  if nameFS then nameFS:SetText(link) end

  frame.rollID = DEBUG_ROLL_ID
  frame:Show()

  self:HookButtons(DEBUG_ROLL_ID)
  for _,k in ipairs({"need","greed","de","pass"}) do
    self:UpdateButtonText(DEBUG_ROLL_ID, k)
  end
  dprint(self, "Debug loot frame shown for %s", link)
end

function Module:Debug_HideBlizzFrame()
  if not self.db.debug then return end
  local frame = _G["GroupLootFrame1"]
  if frame then frame:Hide() end
  rolls[DEBUG_ROLL_ID] = nil
  dprint(self, "Debug loot frame hidden.")
end

function Module:Debug_PopRoll(msg)
  if not self.db.debug then return end
  if not rolls[DEBUG_ROLL_ID] then
    dprint(self, "No debug roll active. Use /lriblizz first.")
    return
  end
  local who, act = msg:match("^(%S+)%s+(%S+)")
  who = who or "Tester"
  act = act and act:lower() or "need"
  local data = rolls[DEBUG_ROLL_ID]
  local itemName = data.itemLink:match("%[(.+)%]") or data.itemName or "Item"
  local actionWord = (act == "de" and "Disenchant") or (act == "greed" and "Greed") or (act == "pass" and "Pass") or "Need"
  local line = (act == "pass")
    and (who.." has passed on: ["..itemName.."]")
    or (who.." has selected "..actionWord.." for: ["..itemName.."]")
  self:ParseLootMessage(line)
end

function Module:SetupDebugSlash()
  if self._debugSlashRegistered then return end
  -- Always register so user can toggle debug on via options without /reload
  SLASH_LRIBLIZZ1 = "/lriblizz"
  SlashCmdList["LRIBLIZZ"] = function(msg) self:Debug_ShowBlizzFrame(msg) end
  SLASH_LRIPOP1 = "/lripop"
  SlashCmdList["LRIPOP"] = function(msg) self:Debug_PopRoll(msg or "") end
  SLASH_LRIHIDE1 = "/lrihide"
  SlashCmdList["LRIHIDE"] = function() self:Debug_HideBlizzFrame() end
  self._debugSlashRegistered = true
end

--========================================================--
-- Public helper to open config
--========================================================--
function Module:OpenConfig()
  if YATP.OpenConfig then YATP:OpenConfig(ModuleName) end
end

return Module
