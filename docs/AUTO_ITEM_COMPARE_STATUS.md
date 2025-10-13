# Auto Item Compare Hover - Development Status

**Branch:** `feature/auto-item-compare-hover`  
**Status:** Work In Progress - Functional but with visual flashing issue  
**Last Updated:** 2025-10-13

## Current State

### ✅ What Works
- ✅ Item validation system fully functional
  - Class-based armor type restrictions (Warlock can only wear Cloth)
  - Red text detection in tooltips for restrictions
  - `IsEquippableItem()` API validation
  - Combat mode respecting
  - Suppress key (ALT) functionality
- ✅ Direct ShoppingTooltip display using `SetInventoryItem()`
- ✅ No game freezes (all unsafe hooks removed)
- ✅ Proper state management with delayed reset (0.3s)
- ✅ Module loads and initializes correctly
- ✅ Locale support (EN/ES)

### ❌ Current Issue
**Tooltip Flashing:** Comparison tooltips appear briefly then disappear/flash repeatedly during hover

**Root Cause:**
- `GameTooltip` has internal hide/show refresh cycles during continuous hover
- When `OnHide` fires, we hide `ShoppingTooltip1/2`
- When `OnTooltipSetItem` fires again (during refresh), we detect it as "already processed" and don't re-show
- Result: Comparison appears once, then disappears

## Approaches Tried (All Documented in Commit)

### ❌ Failed Approaches (Caused Game Freezes)
1. **Global `IsShiftKeyDown()` override** - Caused complete game freeze
2. **Global `IsModifiedClick()` override** - Caused mouse lockup
3. **OnUpdate frame with shift simulation** - Caused game freeze
4. **Temporary `IsModifiedClick` override during call** - Still caused hide/show cycles

### 🔄 Current Approach (Functional but Flashing)
5. **Direct ShoppingTooltip manipulation**
   - Uses `SetInventoryItem("player", slotId)` directly
   - Manual positioning with `SetPoint()`
   - Hides tooltips on `GameTooltip:OnHide`
   - Problem: Tooltips disappear during GameTooltip refresh cycles

## Next Steps to Try (Priority Order)

### Option 1: OnUpdate Hook to Maintain Visibility
```lua
-- Hook GameTooltip:OnUpdate to keep ShoppingTooltips visible
GameTooltip:HookScript("OnUpdate", function()
    if comparisonShown and lastCheckedItem then
        -- Check if ShoppingTooltips are hidden and re-show
        if ShoppingTooltip1 and not ShoppingTooltip1:IsShown() then
            ShowComparisonTooltips()
        end
    end
end)
```
**Pros:** Continuously maintains tooltip visibility  
**Cons:** May cause performance issues with frequent checks

### Option 2: Investigate WoW Addon Examples
Research how these addons handle item comparison:
- **TipTac** - Popular tooltip enhancement addon
- **RatingBuster** - Shows item comparisons with stats
- **Pawn** - Item upgrade advisor with comparisons
- **AtlasLoot** - Shows item comparisons in loot tables

**Action:** Search for their source code and see how they keep comparison tooltips visible

### Option 3: Use SetScript Instead of HookScript
```lua
-- Store original OnHide handler
local originalOnHide = GameTooltip:GetScript("OnHide")

-- Replace with custom handler
GameTooltip:SetScript("OnHide", function(self)
    -- Don't hide ShoppingTooltips during flickers
    if not actuallyHiding then
        return
    end
    
    -- Call original
    if originalOnHide then
        originalOnHide(self)
    end
end)
```
**Pros:** More control over hide behavior  
**Cons:** May break other addons that hook OnHide

### Option 4: Persistent Anchor Frame
```lua
-- Create invisible frame that persists
local anchorFrame = CreateFrame("Frame", nil, UIParent)
anchorFrame:SetPoint("CENTER")

-- Anchor ShoppingTooltips to this frame instead of GameTooltip
ShoppingTooltip1:SetOwner(anchorFrame, "ANCHOR_NONE")
ShoppingTooltip1:SetPoint("TOPLEFT", GameTooltip, "TOPRIGHT", 2, 0)
```
**Pros:** ShoppingTooltips won't hide when GameTooltip hides/shows  
**Cons:** May cause positioning issues during GameTooltip movement

### Option 5: GameTooltip_ShowCompareItem with Pre-Hook
```lua
-- Pre-hook GameTooltip_ShowCompareItem to bypass modifier check
hooksecurefunc("GameTooltip_ShowCompareItem", function(tooltip, override)
    -- Only if we want comparison and it's not already being called
    if shouldShowComparison and not override then
        -- Call again with override flag (if function supports it)
    end
end)
```

### Option 6: Monitor ShoppingTooltip Visibility State
```lua
-- Track when ShoppingTooltips are intentionally shown
local shoppingTooltipsShown = false

-- On ShoppingTooltip1:OnShow, set flag
ShoppingTooltip1:HookScript("OnShow", function()
    shoppingTooltipsShown = true
end)

-- On ShoppingTooltip1:OnHide, check if it should still be visible
ShoppingTooltip1:HookScript("OnHide", function()
    if shoppingTooltipsShown and GameTooltip:IsShown() then
        -- Re-show after brief delay
        C_Timer.NewTimer(0.05, ShowComparisonTooltips)
    end
end)
```

## Code Location

**Main Module:** `modules/autoitemcompare.lua` (507 lines)

**Key Functions:**
- `ShowComparisonTooltips()` - Line ~160: Direct tooltip display logic
- `InstallTooltipHooks()` - Line ~280: Main hook installation
- `ShouldSimulateShift()` - Line ~218: Validation logic
- `IsItemEquippable()` - Line ~72: Comprehensive equip check

**Configuration:**
- `YATP.toc` - Module loaded after `quickconfirm.lua`
- `locales/enUS.lua` - English translations
- `locales/esES.lua` - Spanish translations
- `docs/IDEAS.md` - Feature status updated to "queued"

## Testing Scenarios

When implementing fixes, test with:
1. **Single slot items** (Head, Chest, Neck) - Should show 1 comparison
2. **Dual slot items** (Rings, Trinkets) - Should show 2 comparisons
3. **Weapons** - Should show main hand comparison
4. **Armor type mismatches** - Should NOT show comparison (Warlock + Leather)
5. **Non-equippable items** - Should NOT show comparison
6. **Combat mode** - Should respect `respectCombat` setting
7. **Suppress key** - Holding ALT should suppress comparison
8. **Rapid hovering** - Should handle quick mouse movements without errors

## Debug Mode

Module has extensive print statements for debugging:
- All validation steps logged
- Throttle checks visible
- Tooltip show/hide events tracked
- State changes printed

**To reduce spam for production:**
Remove or comment out print statements in:
- Throttle checks
- "Already processed" messages
- Tooltip hide/show events
Keep only errors and critical state changes.

## Performance Notes

Current implementation:
- No continuous loops (no OnUpdate hooks yet)
- Timer-based with 0.1s delays
- State reset after 0.3s of tooltip being hidden
- Minimal CPU impact when not hovering items

## Module Settings

```lua
Module.defaults = {
    enabled = false,          -- Disabled by default (safer)
    suppressKey = "ALT",      -- Hold ALT to suppress comparison
    respectCombat = true,     -- Don't show in combat
}
```

## Resources for Research

- **WoW API Documentation:** https://wowpedia.fandom.com/wiki/World_of_Warcraft_API
- **3.3.5 Tooltip APIs:** GameTooltip, ShoppingTooltip1/2, SetInventoryItem
- **Similar Addons:** TipTac, RatingBuster, Pawn (search GitHub/WoWInterface)

---

**Resume here tomorrow:** Focus on Option 1 (OnUpdate hook) or Option 6 (ShoppingTooltip visibility monitoring) as they seem most promising for maintaining tooltip visibility without causing game instability.
