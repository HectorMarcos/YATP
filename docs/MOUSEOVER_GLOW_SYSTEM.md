# Mouseover Glow Configuration - Implementation

## Overview
This feature addresses the issue where the standard mouseover glow effect persists on enemy targets, potentially conflicting with the custom Target Glow system. It provides full control over when and how the mouseover glow appears.

## Problem Solved
- **Persistent Mouseover Glow**: Mouseover glow remains visible on targeted enemies
- **Glow Conflicts**: Standard mouseover glow interfering with custom Target Glow
- **No Control**: Unable to customize or disable mouseover glow behavior
- **Visual Clutter**: Multiple glow effects appearing simultaneously

## Solution Implemented
A comprehensive mouseover glow management system that provides:
- **Global Enable/Disable**: Turn mouseover glow on or off entirely
- **Target Override**: Prevent mouseover glow on current target
- **Intensity Control**: Adjust the strength/opacity of the glow effect
- **Smart Integration**: Works alongside the Target Glow system

## Technical Implementation

### Configuration Structure
```lua
mouseoverGlow = {
    enabled = true,          -- Enable mouseover glow globally
    disableOnTarget = true,  -- Disable mouseover glow on current target
    intensity = 0.8,         -- Glow intensity (0.1 to 1.0)
}
```

### Core Functions

#### Setup and Hooking
```lua
function Module:SetupMouseoverGlow()
    -- Initialize the mouseover glow system
    self:SetupMouseoverHooks()
end

function Module:SetupMouseoverHooks()
    -- Hook into nameplate frame setup
    self:SecureHook("CompactUnitFrame_SetUpFrame", "OnNamePlateSetup")
end
```

#### Event Handling
```lua
function Module:OnNamePlateSetup(frame)
    -- Add custom mouseover scripts to nameplate frames
    -- Preserves original scripts while adding our functionality
end

function Module:OnNamePlateMouseEnter(frame)
    -- Handle mouse entering nameplate
    -- Check target status and apply glow if appropriate
end

function Module:OnNamePlateMouseLeave(frame)
    -- Handle mouse leaving nameplate
    -- Remove mouseover glow
end
```

#### Glow Management
```lua
function Module:AddMouseoverGlow(frame)
    -- Create and apply mouseover glow texture
    -- Respects intensity and target settings
end

function Module:RemoveMouseoverGlow(frame)
    -- Clean up mouseover glow texture
end
```

### Hooking Strategy
- **SecureHook**: Non-intrusive hooking that preserves original functionality
- **Script Preservation**: Stores and calls original OnEnter/OnLeave scripts
- **Conditional Application**: Only applies glow when conditions are met

## Configuration Options

### Location
- **Tab**: General
- **Section**: Mouseover Glow
- **Position**: Between Global Health Bar Texture and Clickable Area

### Controls

#### Enable Mouseover Glow
- **Type**: Toggle
- **Function**: Globally enable/disable mouseover glow
- **Default**: Enabled

#### Disable on Current Target
- **Type**: Toggle  
- **Function**: Prevent mouseover glow on targeted units
- **Default**: Enabled (recommended with Target Glow)
- **Dependency**: Disabled when Mouseover Glow is off

#### Glow Intensity
- **Type**: Range (0.1 to 1.0)
- **Function**: Control opacity/strength of glow effect
- **Default**: 0.8 (80% intensity)
- **Dependency**: Disabled when Mouseover Glow is off

## Usage Scenarios

### Recommended Configuration (with Target Glow)
```
✅ Enable Mouseover Glow: ON
✅ Disable on Current Target: ON  
⚪ Glow Intensity: 0.8
```
**Result**: Mouseover glow on all nameplates except your target, which uses Target Glow instead

### Clean Interface
```
❌ Enable Mouseover Glow: OFF
```
**Result**: No mouseover glow anywhere, clean visual experience

### Maximum Visibility
```
✅ Enable Mouseover Glow: ON
❌ Disable on Current Target: OFF
⚪ Glow Intensity: 1.0
```
**Result**: Strong mouseover glow on all nameplates including targets

## Technical Details

### Glow Implementation
- **Texture**: `Interface\\TargetingFrame\\UI-TargetingFrame-Flash`
- **Layer**: OVERLAY (above nameplate elements)
- **Blend Mode**: ADD (creates glow effect)
- **Positioning**: Covers entire health bar area

### Performance Considerations
- **Efficient Hooking**: Only hooks frames as they're created
- **Lazy Loading**: Glow textures created only when needed
- **Proper Cleanup**: Textures removed when no longer needed
- **Conditional Processing**: Skips processing when disabled

### Compatibility
- **Original Scripts**: Preserves existing OnEnter/OnLeave functionality
- **Other Addons**: Uses secure hooks to avoid conflicts
- **Target Glow**: Designed to work alongside Target Glow system

## Integration with Target Glow

### Smart Interaction
When both systems are enabled with recommended settings:
1. **Non-Target Units**: Show mouseover glow when hovered
2. **Target Units**: Show Target Glow (static/animated)
3. **Target + Mouseover**: Only Target Glow visible (cleaner appearance)

### Visual Hierarchy
- **Target Glow**: Primary visual indicator for current target
- **Mouseover Glow**: Secondary indicator for units under cursor
- **No Overlap**: Target overrides mouseover for clean visuals

## Troubleshooting

### Common Issues
1. **Glow not appearing**: Check if globally enabled
2. **Glow on target**: Disable "Disable on Current Target" if desired
3. **Too intense/weak**: Adjust Glow Intensity setting
4. **Conflicts**: May require `/reload` for full effect

### Debug Information
- Debug messages show when glow is added/removed
- Settings changes logged for troubleshooting
- Recommendations provided for reload when needed

## Future Enhancements

### Potential Additions
- **Color Customization**: Different glow colors
- **Animation Options**: Animated mouseover effects
- **Unit Type Filtering**: Different behavior for friendly/enemy/neutral
- **Distance-Based**: Glow intensity based on distance

This implementation provides comprehensive control over mouseover glow behavior while maintaining compatibility and performance.