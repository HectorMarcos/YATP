# Target Glow System - Implementation Documentation

## Overview
The Target Glow system is a custom YATP feature that adds visual glow effects around the nameplate of your current target. This enhances target visibility beyond the basic target scaling provided by the Ascension NamePlates addon.

## Features Implemented

### Core Functionality
- **Automatic Target Detection**: Glow appears when you target an enemy
- **Dynamic Management**: Glow automatically moves to new targets
- **Performance Optimized**: Efficient event handling and cleanup

### Visual Customization
- **Color Selection**: Full RGBA color picker with alpha transparency
- **Size Control**: Adjustable glow size (100% to 200% of nameplate size)
- **Animation Options**: Static, Pulse (fade in/out), Breathe (scale in/out)

### Integration
- **Original Addon Compatibility**: Works alongside Ascension NamePlates
- **Event-Driven**: Responds to target changes and nameplate creation/removal
- **Clean Separation**: YATP custom feature, doesn't modify original addon

## Technical Implementation

### Event System
```lua
-- Events registered for target glow functionality
"PLAYER_TARGET_CHANGED"     -- When player changes target
"NAME_PLATE_UNIT_ADDED"     -- When nameplate appears
"NAME_PLATE_UNIT_REMOVED"   -- When nameplate disappears
```

### Core Functions

#### Target Glow Management
- `SetupTargetGlow()` - Initialize the system
- `CleanupTargetGlow()` - Clean up resources
- `OnTargetChanged()` - Handle target changes
- `OnNamePlateAdded()` - Handle new nameplates
- `OnNamePlateRemoved()` - Handle removed nameplates

#### Visual Effects
- `AddTargetGlow()` - Create glow on nameplate
- `RemoveTargetGlow()` - Remove glow from nameplate
- `UpdateAllTargetGlows()` - Refresh all glows with new settings

### Glow Creation Process
1. **Texture Creation**: Uses `Interface\\SpellActivationOverlay\\IconAlert`
2. **Positioning**: Centers on healthBar with size multiplier
3. **Blending**: Uses "ADD" blend mode for glow effect
4. **Animation**: Optional animation groups for pulse/breathe effects

### Animation Types

#### Static
- No animation, constant glow
- Best performance option

#### Pulse
- Fades between full alpha and 30% alpha
- 0.8 second duration each direction
- Smooth transition for visibility

#### Breathe
- Scales between 100% and 80% of glow size
- 1.2 second duration each direction
- Subtle size variation

## Configuration Options

### Database Structure
```lua
targetGlow = {
    enabled = true,                    -- Enable/disable system
    color = {1, 1, 0, 0.6},           -- RGBA color (yellow, 60% opacity)
    size = 1.2,                       -- Size multiplier (120% of nameplate)
    animation = "pulse",              -- Animation type: "static", "pulse", "breathe"
}
```

### UI Integration
- Located in Enemy Target tab
- Clearly marked as "YATP Custom" feature
- Disabled options when glow is turned off
- Real-time updates when settings change

## Performance Considerations

### Efficient Event Handling
- Events only registered when system is enabled
- Quick early returns if system is disabled
- Minimal processing for irrelevant events

### Memory Management
- Proper cleanup of textures and animation groups
- Tracking table cleared on disable
- No memory leaks from abandoned glows

### Visual Performance
- Single texture per glow (not multiple layers)
- Efficient animation groups (not frame-by-frame updates)
- Appropriate blend modes to avoid overdraw issues

## Usage Instructions

### Enabling Target Glow
1. Open `/yatp` configuration
2. Navigate to `NamePlates` → `Enemy Target`
3. Check "Enable Target Glow"
4. Customize color, size, and animation as desired

### Customization Tips
- **Color**: Yellow/orange works well for visibility against most backgrounds
- **Size**: 1.2-1.5 provides good visibility without being overwhelming
- **Animation**: Pulse is most noticeable, static is most performance-friendly

### Troubleshooting
- If glow doesn't appear: Ensure NamePlates module is enabled
- If glow persists: `/reload` to reset the system
- Performance issues: Try static animation and smaller glow size

## Future Enhancements

### Potential Additions
- Different glow colors for different unit types
- Threat-based glow colors (integration with threat system)
- Sound effects on target change
- Multiple glow styles/textures

### API Extensions
- Functions for other modules to trigger custom glows
- Event callbacks for target glow state changes
- Integration hooks for other visual enhancement systems

## Technical Notes

### Nameplate Structure
- Targets `nameplate.UnitFrame.healthBar` for positioning
- Compatible with both classic and modern nameplate styles
- Respects original addon's layout without interference

### Event Timing
- Target change events processed immediately
- Nameplate events handled during creation/removal
- No polling or continuous updates needed

### Error Handling
- Graceful fallback if nameplate structure changes
- Safe cleanup even if frames are destroyed unexpectedly
- Debug logging for troubleshooting

This implementation provides a solid foundation for target visibility enhancement while maintaining compatibility and performance.