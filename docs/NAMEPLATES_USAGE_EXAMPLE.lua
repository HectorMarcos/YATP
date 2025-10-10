--========================================================--
-- YATP NamePlates Integration - Usage Example
--========================================================--
-- This file demonstrates how to use the NamePlates integration module

-- Example usage once the addon is loaded:

--[[

-- Access the NamePlates module
local nameplatesModule = YATP:GetModule("NamePlates", true)
if nameplatesModule then
    
    -- Check if NamePlates addon is available
    local status = nameplatesModule:GetNamePlatesStatus()
    print("NamePlates Status:", status.loaded and "Loaded" or "Not Loaded")
    
    -- Load the addon if available
    if not status.loaded and status.loadable then
        nameplatesModule:LoadNamePlatesAddon()
    end
    
    -- Get current configuration values
    local classicStyle = nameplatesModule:GetNamePlatesOption("general", "useClassicStyle")
    local targetScale = nameplatesModule:GetNamePlatesOption("general", "clickable", "targetScale")
    
    print("Classic Style:", classicStyle)
    print("Target Scale:", targetScale)
    
    -- Set configuration values
    nameplatesModule:SetNamePlatesOption("general", "useClassicStyle", nil, false)
    nameplatesModule:SetNamePlatesOption("general", "clickable", "targetScale", 1.2)
    
    -- Open the configuration panel
    nameplatesModule:OpenNamePlatesConfig()
    
end

--]]

-- Available embedded configuration options:

--[[

GENERAL SETTINGS:
- useClassicStyle (boolean)
- clickable.targetScale (number: 0.8-1.4)
- clickable.width (number: 50-200)
- clickable.height (number: 20-80)

FRIENDLY UNITS:
- health.nameOnly (boolean)
- health.width (number: 40-200)
- health.height (number: 4-60)
- health.showTextFormat (boolean)

ENEMY UNITS:
- health.width (number: 40-200)
- health.height (number: 4-60)
- health.showTextFormat (boolean)
- castBar.enabled (boolean)
- castBar.height (number: 4-32)

PERSONAL NAMEPLATE:
- health.width (number: 40-200)
- health.height (number: 4-60)
- health.showTextFormat (boolean)

--]]

-- Command examples:
-- /yatp                    - Open YATP config
-- /yatp reload             - Reload UI
-- /yatp debug              - Toggle debug mode

return {}