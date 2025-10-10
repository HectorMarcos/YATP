# Global Health Bar Texture Override - Implementation

## Overview
This feature addresses a common issue where individual nameplate health bar texture settings don't consistently apply to all nameplate types, especially targeted enemies. The Global Health Bar Texture Override ensures that ALL nameplates use the same texture.

## Problem Solved
- **Inconsistent Textures**: Individual texture settings per nameplate type sometimes don't apply correctly
- **Target Issues**: Enemy target nameplates often ignore texture settings
- **Configuration Complexity**: Having to set the same texture in multiple places

## Solution Implemented
A single global override that forces the same health bar texture across all nameplate types:
- Friendly nameplates
- Enemy nameplates  
- Personal nameplate
- **Most importantly**: Targeted enemy nameplates

## Technical Implementation

### Configuration Structure
```lua
globalHealthBarTexture = {
    enabled = false,           -- Enable/disable global override
    texture = "Blizzard2",    -- SharedMedia texture name
}
```

### Core Function
```lua
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
    
    self:Debug("Global health bar texture applied: " .. textureName)
end
```

### Integration Points
1. **OnEnable**: Applies texture when module starts
2. **Setting Changes**: Immediate application when texture is changed
3. **Enable/Disable**: Instant toggle of override functionality

## UI Implementation

### Location
- **Tab**: General
- **Section**: Global Health Bar Texture
- **Position**: Between Style and Clickable Area sections

### Controls
1. **Enable Toggle**: "Enable Global Health Bar Texture"
2. **Texture Selector**: LibSharedMedia statusbar dropdown
3. **Description**: Clear explanation of the feature's purpose

### Behavior
- Texture selector disabled when override is off
- Immediate texture application when settings change
- Visual feedback through debug messages

## Usage Instructions

### How to Use
1. Open `/yatp` → `NamePlates` → `General`
2. Find "Global Health Bar Texture" section
3. Check "Enable Global Health Bar Texture"
4. Select desired texture from dropdown
5. Changes apply immediately to all nameplates

### Recommended Textures
- **Blizzard2**: Clean, minimal appearance
- **Minimalist**: Very thin, modern look
- **Smooth**: Rounded edges, professional
- **Flat**: Solid color, high contrast

### Benefits
- **Consistency**: All nameplates use same texture
- **Target Visibility**: Targeted enemies use correct texture
- **Simplicity**: One setting instead of three
- **Reliability**: Overrides individual settings that might not work

## Technical Notes

### Override Behavior
- When enabled, this setting takes precedence over individual texture settings
- Individual texture settings are not deleted, just overridden
- Disabling returns to individual settings

### Performance
- Minimal performance impact
- Only applies on setting changes
- No continuous processing needed

### Compatibility
- Works with all LibSharedMedia statusbar textures
- Compatible with custom texture packs
- Doesn't conflict with other nameplate addons

## Troubleshooting

### Common Issues
1. **Texture not changing**: Ensure override is enabled
2. **Only some nameplates affected**: Disable and re-enable override
3. **Texture reverts**: Check if other addons are overriding

### Debug
- Enable debug messages to see when texture is applied
- Use `/reload` if textures don't update immediately
- Check that chosen texture exists in LibSharedMedia

## Future Enhancements

### Potential Additions
- Different textures for different nameplate types while maintaining consistency
- Texture preview in configuration
- Integration with color customization
- Save/load texture presets

This feature provides a robust solution to texture consistency issues while maintaining simplicity and ease of use.