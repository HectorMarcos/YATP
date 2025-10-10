# Enemy Target Tab - Real Options

## Overview
After analyzing the original Ascension NamePlates addon, we discovered that there is only **one real target-specific option** available: **Target Scale**.

## Real Options from Ascension NamePlates

### Target Scale
- **Location**: `general.clickable.targetScale`
- **Type**: Range (0.8 to 1.4, step 0.1)
- **Default**: 1.1
- **Function**: Scales the nameplate when it becomes the target
- **Scope**: Affects ALL targeted nameplates (friendly and enemy)

This is the only option in the original addon that specifically affects targeted nameplates.

## What Was Removed
The following custom options were removed because they don't exist in the original addon:
- `highlightEnemyTarget` - Custom highlight effect
- `enhancedTargetBorder` - Custom border effect  
- `highlightColor` - Custom highlight color
- `alwaysShowTargetHealth` - Custom health display
- `targetHealthFormat` - Custom health format

## How the Enemy Target Tab Works Now

### Real Integration
- **Target Scale**: Directly connects to `AscensionNamePlates.db.profile.general.clickable.targetScale`
- When changed, it calls `AscensionNamePlates:UpdateAll()` to apply changes immediately

### Information Sections
- Explains what Target Scale does
- Directs users to the Enemy tab for other nameplate customizations
- Clarifies that other enemy settings also apply to targeted enemies

## Options Available for Enemy Targets

### Direct (Target-Specific)
- Target Scale (from General settings)

### Indirect (Apply to all enemies, including when targeted)
- Health bar size and appearance (Enemy tab)
- Name display and fonts (Enemy tab)
- Cast bar settings (Enemy tab)
- Level indicators (Enemy tab)
- Quest objective icons (Enemy tab)

## Technical Implementation

```lua
-- Real option that works
targetScale = {
    type = "range",
    name = "Target Scale",
    min = 0.8, max = 1.4, step = 0.1,
    get = function() return self:GetNamePlatesOption("general", "clickable", "targetScale") or 1.1 end,
    set = function(_, value) self:SetNamePlatesOption("general", "clickable", "targetScale", value) end,
}
```

## Why Custom Options Don't Work

The Ascension NamePlates addon uses `DefaultCompactNamePlateEnemyFrameOptions` and similar structures that don't include custom highlight or border options. Adding such features would require:

1. Hooking into nameplate creation/update events
2. Creating custom textures and animations
3. Managing target state changes
4. Implementing visual effects outside the original addon's scope

This is beyond the scope of a simple configuration integration.

## Recommendation

The Enemy Target tab now focuses on:
1. **Target Scale** - The one real option that works
2. **Information** - Directing users to other relevant options
3. **Education** - Explaining what's available vs what would need custom implementation

This provides a honest and functional interface rather than options that don't actually work.