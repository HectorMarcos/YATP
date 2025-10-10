--========================================================--
-- YATP - BackgroundFPSFix Module (Extras > Tweaks)
--========================================================--
-- Simple toggle to manage /console maxfpsbk preserving previous value.
-- No slider by request: just enable = apply chosen cap (default 60), disable = restore.
-- A minimal internal setting 'targetFPS' retained (user invisible) for future extension.
--========================================================--
local ADDON = "YATP"
local ModuleName = "BackgroundFPSFix"

local YATP = LibStub("AceAddon-3.0"):GetAddon(ADDON, true)
if not YATP then return end
local L = LibStub("AceLocale-3.0"):GetLocale(ADDON, true) or setmetatable({}, { __index=function(_,k) return k end })

local Module = YATP:NewModule(ModuleName, "AceConsole-3.0")

Module.defaults = {
  enabled = true,
  targetFPS = 60, -- user adjustable now; 0 = do not override
}

function Module:OnInitialize()
  if not YATP.db.profile.modules then YATP.db.profile.modules = {} end
  if not YATP.db.profile.modules[ModuleName] then
    YATP.db.profile.modules[ModuleName] = CopyTable(self.defaults)
  end
  self.db = YATP.db.profile.modules[ModuleName]

  if YATP.AddModuleOptions then
    YATP:AddModuleOptions("Tweaks", self:BuildOptions(), "Extras")
  end
end

function Module:OnEnable()
  if not self.db.enabled then return end
  self:Apply()
end

function Module:OnDisable()
  self:Restore()
end

-- Apply / restore
function Module:Apply()
  if not self.db or not self.db.enabled then return end
  local target = tonumber(self.db.targetFPS) or 60
  if target <= 0 then
    -- treat as disable override; restore if previously applied
    if self._applied then
      self:Restore()
    end
    return
  end
  local current = GetCVar("maxfpsbk")
  if not self._applied then
    self._previous = current
  end
  local desired = tostring(target)
  if current ~= desired then
    SetCVar("maxfpsbk", desired)
  end
  self._applied = true
end

function Module:Restore()
  if not self._applied then return end
  if self._previous then
    SetCVar("maxfpsbk", self._previous)
  end
  if YATP and YATP:IsDebug() then
    YATP:Debug("BackgroundFPSFix restored maxfpsbk to "..tostring(self._previous))
  end
  self._applied = false
end

-- Options
function Module:BuildOptions()
  local get = function(info) return self.db[ info[#info] ] end
  local set = function(info, val)
    local key = info[#info]
    self.db[key] = val
    if key == "enabled" then
      if val then self:Enable() else self:Disable() end
    elseif key == "targetFPS" then
      if self.db.enabled then
        self:Apply()
      end
    end
  end

  return {
    type = "group",
    name = L["Tweaks"] or "Tweaks",
    args = {
  enabled = { type="toggle", order=1, name=L["Enable Background FPS Fix"] or "Enable Background FPS Fix", desc = (L["When enabled, forces a background FPS cap and restores the previous value when disabled."] or "When enabled, forces a background FPS cap and restores the previous value when disabled.") .. "\n" .. (L["Requires /reload to fully apply enabling or disabling."] or "Requires /reload to fully apply enabling or disabling."), get=get, set=function(info,val) set(info,val); if YATP and YATP.ShowReloadPrompt then YATP:ShowReloadPrompt() end end },
      targetFPS = { type="range", order=2, name=L["Background FPS Cap"] or "Background FPS Cap", desc = L["Set the background framerate cap. 0 = do not override. This slider removes the old 60 FPS ceiling."] or "Set the background framerate cap. 0 = do not override. This slider removes the old 60 FPS ceiling.", min=0, max=240, step=1, get=get, set=set },
      status = { type="description", order=5, fontSize="small", name=function()
        local cur = GetCVar("maxfpsbk")
        local prev = self._previous or "-"
        local state = self._applied and (L["Active"] or "Active") or (L["Inactive"] or "Inactive")
        return string.format((L["State: %s  Current: %s  Previous: %s"] or "State: %s  Current: %s  Previous: %s"), state, tostring(cur), tostring(prev))
      end },
      note = { type="description", order=10, fontSize="small", name=L["Note: Previous UI limited this to 60 FPS; this module lets you set higher values."] or "Note: Previous UI limited this to 60 FPS; this module lets you set higher values." },
    }
  }
end

function Module:OpenConfig()
  if YATP.OpenConfig then YATP:OpenConfig("Tweaks") end
end

return Module
