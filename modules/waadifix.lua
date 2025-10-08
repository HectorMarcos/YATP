--========================================================--
-- YATP - WAAdiFixes Module (Extras)
-- (Renamed from previous generic 'Fixes' container to reflect current scope)
-- Consolidates small compatibility fixes under a toggleable interface.
-- Current fix: Safe SetResizeBounds / SetMaxResize wrapper for legacy client (3.3.5) to avoid errors
-- Includes migration from old module name 'Fixes'.
--========================================================--
local ADDON = "YATP"
local ModuleName = "WAAdiFixes"  -- New canonical module name

local YATP = LibStub("AceAddon-3.0"):GetAddon(ADDON, true)
if not YATP then return end
local L = LibStub("AceLocale-3.0"):GetLocale(ADDON, true) or setmetatable({}, { __index=function(_,k) return k end })

local Module = YATP:NewModule(ModuleName, "AceConsole-3.0")

Module.defaults = {
  enabled = true,
  waAdiResizeFix = true, -- WeakAuras / AdiBags resize compatibility
}

local function ApplyResizePatch()
  if Module._resizePatched then return end
  local frame = CreateFrame("Frame")
  local meta = getmetatable(frame)
  if not meta or not meta.__index then return end
  local idx = meta.__index
  -- Wrap SetResizeBounds
  if idx.SetResizeBounds then
    local old = idx.SetResizeBounds
    if not Module._origSetResizeBounds then
      Module._origSetResizeBounds = old
    end
    idx.SetResizeBounds = function(self, minW, minH, maxW, maxH)
      if type(maxW) ~= "number" or type(maxH) ~= "number" then
        return -- ignore invalid modern signature usage
      end
      return old(self, minW, minH, maxW, maxH)
    end
  else
    idx.SetResizeBounds = function() end
  end
  if not idx.SetMaxResize then
    idx.SetMaxResize = function() end
  end
  Module._resizePatched = true
end

-- (Optional) revert function (not strictly needed, but keeps symmetry)
local function RevertResizePatch()
  if not Module._resizePatched then return end
  -- We cannot easily restore the metatable function safely unless we kept ORIGINAL reference.
  if Module._origSetResizeBounds then
    local meta = getmetatable(CreateFrame("Frame"))
    if meta and meta.__index then
      meta.__index.SetResizeBounds = Module._origSetResizeBounds
    end
  end
  Module._resizePatched = false
end

function Module:OnInitialize()
  if not YATP.db.profile.modules then YATP.db.profile.modules = {} end

  -- Migration: old container name was 'Fixes'. If present and new name absent, move it.
  if YATP.db.profile.modules["Fixes"] and not YATP.db.profile.modules[ModuleName] then
    YATP.db.profile.modules[ModuleName] = YATP.db.profile.modules["Fixes"]
    YATP.db.profile.modules["Fixes"] = nil
  end

  if not YATP.db.profile.modules[ModuleName] then
    YATP.db.profile.modules[ModuleName] = CopyTable(self.defaults)
  end
  self.db = YATP.db.profile.modules[ModuleName]

  -- Legacy key migration (resizeApiFix -> waAdiResizeFix)
  if self.db.resizeApiFix ~= nil and self.db.waAdiResizeFix == nil then
    self.db.waAdiResizeFix = self.db.resizeApiFix
    self.db.resizeApiFix = nil
  end

  if YATP.AddModuleOptions then
    YATP:AddModuleOptions(ModuleName, self:BuildOptions(), "Extras")
  elseif YATP.AddExtrasOptions then
    YATP:AddExtrasOptions(ModuleName, self:BuildOptions())
  end
end

function Module:OnEnable()
  if not self.db.enabled then return end
  if self.db.waAdiResizeFix then
    ApplyResizePatch()
  end
end

function Module:OnDisable()
  -- No runtime timers to cancel
end

function Module:BuildOptions()
  local get = function(info) return self.db[ info[#info] ] end
  local set = function(info, val)
    local key = info[#info]
    self.db[key] = val
    if key == "enabled" then
      if val then self:Enable() else self:Disable() end
    elseif key == "waAdiResizeFix" then
      if val then ApplyResizePatch() else RevertResizePatch() end
    end
  end

  return {
    type = "group",
    name = L[ModuleName] or ModuleName,
    args = {
      enabled = { type="toggle", order=1, name=L["Enable Module"] or "Enable Module",
        desc = (L["Enable or disable this module."] or "Enable or disable this module.") .. "\n" .. (L["Requires /reload to fully apply enabling or disabling."] or "Requires /reload to fully apply enabling or disabling."),
        get=get, set=function(info,val) set(info,val); if YATP and YATP.ShowReloadPrompt then YATP:ShowReloadPrompt() end end },
      desc = { type="description", order=2, name = L["Various small compatibility toggles."] or "Various small compatibility toggles." },
      compHeader = { type="header", order=5, name = L["Compatibility Fixes"] or "Compatibility Fixes" },
      waAdiGroup = { type="group", order=10, inline=true, name = L["WeakAuras / AdiBags" ] or "WeakAuras / AdiBags", args = {
        waAdiResizeFix = { type="toggle", order=1, name=L["Resize Bounds Patch"] or "Resize Bounds Patch", desc = L["Prevents errors when modern WeakAuras code calls SetResizeBounds on legacy client frames."] or "Prevents errors when modern WeakAuras code calls SetResizeBounds on legacy client frames.", get=get, set=set },
      }},
      help = { type="description", order=90, fontSize="small", name = L["You can add more inline groups here for future fixes."] or "You can add more inline groups here for future fixes." },
      legacyNote = { type="description", order=91, fontSize="small", name = L["(Migrated from 'Fixes' module name)"] or "(Migrated from 'Fixes' module name)" },
    }
  }
end

function Module:OpenConfig()
  if YATP.OpenConfig then YATP:OpenConfig(ModuleName) end
end

return Module
