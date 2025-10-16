# Changelog

All notable changes to this project will be documented in this file.

The format is based on Keep a Changelog (https://keepachangelog.com/en/1.1.0/)
and this project adheres (aspirationally) to Semantic Versioning once it reaches 1.0.

## [Unreleased]

## [0.8.1] - 2025-10-16

### Fixed

- **NamePlates**: Threat System no longer applies colors when player is solo (not in party/raid)
  - Added multiple defensive checks in `OnGroupChanged()`, `UpdateAllThreatIndicators()`, and `OnThreatCombatStart()`
  - `OnGroupChanged()` now clears colors BEFORE attempting updates to prevent race conditions
  - Combat end now properly clears all threat colors instead of attempting to update them
  - Eliminates brief flashes of threat colors when leaving groups or during combat transitions

- **NamePlates**: Neutral NPCs now correctly maintain their yellow color
  - Fixed `ResetHealthBarColor()`, `ResetNameplateColors()`, and `ClearAllThreatColors()` functions
  - These functions were forcing red (1,0,0) or green (0,1,0) colors on all units
  - Now correctly preserve game's natural faction-based coloring system:
    * Red for hostile enemies
    * Yellow for neutral NPCs
    * Green for friendly units
  - Reset functions no longer call `SetStatusBarColor()` or `SetTextColor()`
  - Game's default nameplate system handles color restoration naturally

- **NamePlates**: Missing localization entry for mouseover highlight description
  - Added English translation for "Highlight the health bar when mousing over non-target nameplates. Uses a white tint effect (50% mix) for subtle visibility."
  - Resolves AceLocale-3.0 missing entry error message

### Technical Improvements

- **NamePlates**: Threat system now implements defense-in-depth approach with multiple verification layers
  - Group status checked at multiple points (event handlers, update functions, combat handlers)
  - Immediate cleanup when going solo prevents any color persistence
  - Combat end triggers cleanup instead of update to ensure clean state

- **NamePlates**: Color reset philosophy changed from "force default" to "let game handle it"
  - Removes dependency on hardcoded color values that don't account for faction/reaction states
  - Preserves WoW's built-in nameplate color system for all unit types
  - Only cleans up YATP-specific custom elements (threat borders)

## [0.8.0] - 2025-10-16

### Added

- **NamePlates**: Mouseover Border Glow Blocking (YATP Custom Enhancement)
  - Forces all nameplate borders to remain black (0, 0, 0, 1) regardless of mouseover state
  - Eliminates the distracting white/yellow border glow that appears when hovering over nameplates
  - Uses aggressive OnUpdate frame system that forces black color every frame
  - Intercepts all color change attempts via SetVertexColor hooks
  - 100% consistent blocking - works on all nameplates including dynamically created ones
  - Configurable via "Block Mouseover Border Glow" toggle in NamePlates settings

- **NamePlates**: Mouseover Health Bar Highlight (YATP Custom Enhancement)
  - Adds subtle visual feedback when mousing over non-target nameplates
  - Applies white tint to health bar color for gentle highlighting effect
  - Configurable tint amount (0.0 = no change, 1.0 = pure white), default 0.5 (50% white mix)
  - Automatically excludes current target to avoid visual conflicts
  - OnUpdate frame maintains color every frame to prevent overwrites from threat system
  - Respects threat system colors - reapplies threat color after mouseover ends
  - Smart color restoration system tracks original colors per nameplate
  - Works seamlessly with Ascension's dynamic nameplate system

### Technical Improvements

- **NamePlates**: Border blocking uses dual-strategy approach
  - OnUpdate frame scans all nameplates every frame checking for non-black borders
  - SetVertexColor hook intercepts any color change attempts at the source
  - Hook system stores original function reference for safe cleanup
  - Frame-by-frame enforcement ensures 100% consistency even with external interference

- **NamePlates**: Health bar highlight system architecture
  - Event-driven via UPDATE_MOUSEOVER_UNIT for efficient state tracking
  - Per-nameplate data structure stores original colors, highlight colors, and mouseover state
  - OnUpdate frame verifies UnitIsUnit(unit, "mouseover") every frame for accuracy
  - Automatic cleanup when mouseover lost - clears highlight and restores original
  - Color application to both SetStatusBarColor AND texture.SetVertexColor for compatibility
  - Integrated with threat system via conditional checks (skips threat color during mouseover)

- **NamePlates**: Production-ready code cleanup
  - Removed all debug print statements (silent operation)
  - Eliminated unused retry functions (BlockNameplateBorderGlowWithRetry)
  - Removed all event handler debug calls in NAME_PLATE_UNIT_ADDED handlers
  - Cleaned up 248 lines of debug code while adding only 36 lines of production code
  - Simplified function signatures (removed silent parameter, removed retry parameters)

### Changed

- **NamePlates**: Border blocking now uses OnUpdate frame as primary method
  - Previous approach relied on event timing and retry logic
  - New approach scans and corrects every frame for foolproof consistency
  - Eliminates all timing-related edge cases and race conditions

- **NamePlates**: Mouseover system no longer uses brightness method
  - Removed brightness adjustment option (was redundant with tint)
  - Simplified to single tint method for cleaner UX
  - Fixed tint default value to 0.5 (50% white mix)

### Fixed

- **NamePlates**: Border blocking now works on ALL nameplates consistently
  - Resolved issue where some nameplates (especially behind camera) failed to block
  - Fixed event registration conflicts (multiple NAME_PLATE_UNIT_ADDED handlers)
  - Eliminated dependency on unit availability timing
  - OnUpdate approach catches and corrects any border color changes immediately

- **NamePlates**: Mouseover color now persists correctly during hover
  - Fixed threat system immediately overwriting mouseover colors
  - OnUpdate frame now maintains highlight color every frame
  - Added check in ApplyThreatToHealthBar to skip color during mouseover
  - Proper cleanup of highlightColor in data when mouseover ends

### Localization

- **NamePlates**: Complete English localization for border blocking system
  - "Block Mouseover Border Glow (YATP Custom)" section header
  - "Enable Border Glow Blocking" toggle with detailed tooltip
  - "Custom Border Color" picker (fixed to black, 0,0,0,1)

- **NamePlates**: Complete English localization for mouseover highlight system
  - "Mouseover Health Bar Highlight (YATP Custom)" section header
  - "Enable Mouseover Highlight" toggle with behavior explanation
  - "Tint" slider description (0.0-1.0 range, default 0.5)

### Documentation

- **NamePlates**: Border blocking intercepts color changes at two levels:
  1. SetVertexColor hook prevents changes at the API level
  2. OnUpdate frame scans and corrects any colors that slip through
- **NamePlates**: Mouseover highlight designed to work alongside existing nameplate addons
- **NamePlates**: Both features are YATP-specific enhancements to Ascension_NamePlates

## [0.7.0] - 2025-10-16

### Added

- **NamePlates**: Target Arrows System (YATP Custom Enhancement)
  - Arrow indicators appear on both sides of your current target's nameplate for enhanced visibility
  - Arrows point inward toward the nameplate center for intuitive target identification
  - Fully configurable: size (16-64px), horizontal distance (0-50px), vertical offset (-20 to 20px)
  - Color customization with alpha channel support for arrow tinting
  - Uses custom arrow.tga texture with SetTexCoord for proper left/right orientation
  - High frame strata ensures arrows display above level/elite/rare icons
  - Integrated with threat system for seamless target change updates

- **NamePlates**: Non-Target Alpha Fade System (YATP Custom Enhancement)
  - Automatically reduces opacity of non-targeted enemy nameplates for improved target focus
  - Only active when you have a target selected - all nameplates remain fully visible when no target exists
  - Configurable alpha value (0.0 = fully transparent to 1.0 = fully opaque)
  - Triple-hook protection system blocks external addons (including Ascension_NamePlates) from overriding alpha values
  - SetAlpha() override intercepts any alpha change requests and enforces configured value
  - SetPoint() hook re-applies alpha during nameplate repositioning
  - Show() hook maintains alpha during visibility changes
  - OnUpdate frame provides continuous enforcement running every frame as final safety net
  - Eliminates alpha reset issues during camera movement and nameplate updates

### Technical Improvements

- **NamePlates**: Implemented comprehensive Target Arrows System with full event integration
  - `SetupTargetArrows()` initializes frame tracking and registers PLAYER_TARGET_CHANGED event
  - `AddTargetArrows()` creates left/right arrow textures with proper positioning and orientation
  - `RemoveTargetArrows()` cleanup function with frame hiding and tracking removal
  - `UpdateAllTargetArrows()` refreshes arrows when configuration changes
  - `OnTargetArrowChanged()` event handler integrates with existing threat system chain
  - Arrow textures positioned relative to healthBar with configurable offsets
  - SetTexCoord used for horizontal flip: left arrow (0,1,0,1), right arrow (1,0,0,1)
  - Frame level set to healthBar:GetFrameLevel() + 10 for proper z-ordering

- **NamePlates**: Enhanced Non-Target Alpha Fade with multi-layer protection
  - `SetupNonTargetAlpha()` creates OnUpdate frame running every frame for continuous enforcement
  - `UpdateAllNameplateAlphas()` only applies alpha when target exists, restores full opacity otherwise
  - `UpdateNameplateAlpha()` implements triple-hook system:
    * SetAlpha() override blocks all external alpha changes (most effective protection)
    * SetPoint() hook detects repositioning and re-applies alpha
    * Show() hook maintains alpha during visibility changes
  - `CleanupNonTargetAlpha()` properly removes all hooks and resets alpha on disable
  - `alphaFadeUpdateFrame` with OnUpdate script for continuous alpha enforcement
  - Hook tracking via `alphaHooksApplied` flag prevents duplicate hook application

- **NamePlates**: UI Controls Integration
  - Enemy Target tab now includes both Target Arrows and Non-Target Alpha sections
  - All controls properly ordered with logical grouping (21-26 for arrows, 31-34 for alpha)
  - Enable/disable toggles call appropriate setup/cleanup functions
  - Slider controls call update functions on value change
  - Color picker integrated with alpha channel support
  - Controls automatically disabled when parent feature not enabled

### Changed

- **NamePlates**: Removed all debug print statements for silent operation
  - Eliminated "[YATP Alpha] Applied all alpha hooks on: %s" spam
  - Removed "Auto-loaded Ascension_NamePlates" confirmation message
  - Module now operates completely silently without chat spam

### Localization

- **NamePlates**: Added complete English localization for Target Arrows System
  - "Target Arrows (YATP Custom)" section header
  - "Enable Target Arrows" toggle with descriptive tooltip
  - "Arrow Size" slider description
  - "Horizontal Distance" slider for edge offset configuration
  - "Vertical Offset" slider with negative/positive direction explanation
  - "Arrow Color" picker with tint description

- **NamePlates**: Complete English localization already present for Non-Target Alpha System
  - "Non-Target Alpha Fade (YATP Custom)" section header
  - "Enable Non-Target Alpha Fade" toggle with target-only behavior explanation
  - "Non-Target Alpha" slider with transparency level description (0.0-1.0 range)

### Documentation

- **NamePlates**: Target Arrows implementation uses arrow.tga texture from media folder
- **NamePlates**: Non-Target Alpha system successfully blocks interference from Ascension_NamePlates addon
- **NamePlates**: Both features integrated into feature/nameplates-enhancements branch for testing

## [0.6.5] - 2025-10-16

### Added

- **NamePlates**: Auto-Load on Startup feature to automatically load Ascension_NamePlates on every UI reload
  - New toggle in Status tab: "Auto-Load on Startup" (enabled by default)
  - Automatically calls `LoadAddOn("Ascension_NamePlates")` on module initialization
  - Solves the LoadOnDemand issue without requiring file modifications
  - Shows confirmation message: "[NamePlates] Auto-loaded Ascension_NamePlates"
  - Works seamlessly with Ascension's LoadOnDemand addon architecture

- **NamePlates**: Comprehensive documentation suite for LoadOnDemand troubleshooting
  - `REACTIVAR_ASCENSION_NAMEPLATES.txt` - Complete reactivation guide in Spanish
  - `SOLUCION_DEFINITIVA_NamePlates.txt` - Definitive solution guide with all methods
  - `README_LoadOnDemand_Fix.md` - Technical explanation of the LoadOnDemand issue
  - `Fix_Ascension_NamePlates_LoadOnDemand.ps1` - Automated PowerShell script for .toc modification

- **NamePlates**: "Check for Conflicts" diagnostic tool
  - Scans for conflicting nameplate addons (Plater, TidyPlates, Kui_Nameplates, etc.)
  - Shows which addons are loaded, enabled, or disabled
  - Provides exact commands to disable conflicting addons
  - Moved to new "Diagnostics" section for better organization

### Changed

- **NamePlates**: Simplified and streamlined Status tab interface
  - "Enable & Force Load" renamed to "Load NamePlates Now" (clearer action name)
  - Removed "Load NamePlates Addon" button (redundant with main load button)
  - Removed "Fix LoadOnDemand Issue" button (Auto-Load solves this elegantly)
  - Reorganized actions into logical sections: Actions, Diagnostics, Information
  - Reduced button count from 5 to 3 for cleaner, less cluttered interface

- **NamePlates**: Improved Status tab help text and troubleshooting guide
  - Added "Quick Setup Guide" with 3-step process
  - Updated troubleshooting section with clearer, more actionable advice
  - Emphasized Auto-Load as the recommended solution
  - Better visual hierarchy with section headers

### Fixed

- **NamePlates**: Resolved persistent issue where Ascension_NamePlates would unload after every `/reload`
  - Root cause: Addon has `LoadOnDemand: 1` in .toc, preventing automatic loading
  - Solution: Auto-Load system forces loading on every UI initialization
  - Eliminates need for manual LoadAddOn() commands after each reload
  - Users no longer need to modify game files or use external scripts

### Technical Improvements

- **NamePlates**: Implemented `AutoLoadAscensionNamePlates()` function with smart detection
  - Checks if addon is enabled but not loaded before attempting load
  - Respects user preference if Auto-Load is disabled
  - Silent operation - only shows message on successful load
  - Integrated into `OnEnable()` for automatic execution on module startup

- **NamePlates**: Enhanced module defaults with Auto-Load configuration
  - New `autoLoadNamePlates` setting (default: true)
  - Allows users to disable Auto-Load if they prefer manual control
  - Persists across sessions and UI reloads

### Documentation

- **NamePlates**: Created comprehensive troubleshooting and solution documentation
  - Explains LoadOnDemand behavior and why it causes issues
  - Compares three solution approaches: Auto-Load, .toc modification, manual commands
  - Includes step-by-step guides for all user skill levels
  - Provides FAQ section with common questions and answers

## [0.6.4] - 2025-10-15

### Added

- **InfoBar**: Soul Shard counter for Warlocks with automatic low threshold colorization
  - Displays current soul shard count for Warlock characters
  - Automatically highlights in red when below configurable threshold (default: 3 shards)
  - Multilingual support - searches for shards by name in English, Spanish, and French
  - Threshold configurable from 1-10 shards

### Changed

- **InfoBar**: Position settings now saved per-character instead of per-profile
  - Each character can have the info bar in a different position on screen
  - General settings (appearance, metrics, thresholds) remain shared across profile
  - Automatic migration of old position data to character-specific storage
  - Improved user experience for players with multiple characters

- **InfoBar**: Reorganized options panel for better class-specific organization
  - Hunter and Warlock options now in separate inline groups
  - Class-specific sections only visible to appropriate classes
  - Cleaner interface with reduced visual clutter
  - Automatic colorization enabled by default (options hidden from UI)

### Improved

- **InfoBar**: Enhanced Hunter ammo counter reliability
  - Uses both item ID (6265) and name-based detection
  - Better support for WoW 3.3.5 client variations

### Technical Improvements

- **InfoBar**: Split database structure into profile (shared) and char (per-character) sections
- **InfoBar**: Added `positionDefaults` separate from general `defaults` for cleaner code organization
- **InfoBar**: Implemented `IsPlayerWarlock()` function parallel to existing `IsPlayerHunter()`
- **InfoBar**: Options panel uses dynamic `hidden` functions to show/hide class-specific sections

## [0.6.3] - 2025-10-15

### Added

- **QuestTracker**: Quest type indicators in level display for easy identification at a glance
  - Elite/Group quests now show as `[30+]` instead of `[30]`
  - Dungeon quests now show as `[30D]`
  - Raid quests now show as `[30R]`
  - Heroic quests now show as `[30H]`
  - PvP quests now show as `[30PvP]`
  - Automatically detects quest type from API (questTag and suggestedGroup fields)

- **QuestTracker**: New debug command `/qtinfo` to display detailed quest log information
  - Shows all quests with their level, tags, group size, daily status, and completion state
  - Displays tracking status for each quest
  - Useful for troubleshooting and understanding quest properties
  - Color-coded output for better readability

### Technical Improvements

- **QuestTracker**: Created `GetQuestInfoFromTitle()` function to retrieve level, tag, and group info in one call
- **QuestTracker**: Created `GetQuestTagSuffix()` function to generate appropriate type indicators
- **QuestTracker**: Updated `GetQuestLevelFromTitle()` to handle new tag suffix formats in quest titles

## [0.6.2] - 2025-10-14

### Fixed

- **XPRepBar**: Resolved overflow issue where the XP bar occasionally extended beyond its bounds to the right
  - Changed StatusBar from relative positioning to explicit sizing with proper padding calculation (width-4, height-4)
  - Rewrote rested XP overlay to use `SetSize()` + `LEFT` anchor instead of `SetPoint()` + `SetWidth()`
  - Implemented percentage-based calculations with multiple safety clamps (0-1 range)
  - Added spark positioning with strict boundary enforcement to prevent overflow
  - Added `OnSizeChanged` handlers for dynamic updates when bar dimensions change
  - Applied fixes to both XP and reputation bars for consistency

- **ChatFilters**: Fixed "Interface action failed because of an AddOn" message still appearing despite filter being active
  - Added `UIErrorsFrame.AddMessage` hook to catch messages that bypass chat events entirely
  - Many error messages go directly to UIErrorsFrame instead of through the chat system
  - Simplified interface action failed filter to use basic substring match for all variants
  - Added additional event filters for `CHAT_MSG_TEXT_EMOTE` and `SYSMSG` as safety net
  - Proper hook installation/removal in `OnEnable`/`OnDisable` with reference preservation

### Added

- **InfoBar**: Soul Shard counter for Warlocks with configurable low threshold warning
  - Shows current soul shard count in the info bar
  - Configurable threshold (1-10 shards) for low shard warning
  - Red colorization when below threshold
  - Searches bags for Soul Shard items by name (multilingual support)

- **ChatFilters**: Test command `/yatptestfilter` for verifying filter functionality
  - `/yatptestfilter help` - Show all available test commands
  - `/yatptestfilter chat` - Test via CHAT_MSG_SYSTEM event
  - `/yatptestfilter ui` - Test via UIErrorsFrame (most common path)
  - `/yatptestfilter all` - Test all methods at once with summary
  - `/yatptestfilter stats` - Show current suppression statistics
  - Helpful for troubleshooting and confirming the filter is working correctly

### Documentation

- **QuickConfirm**: Added comprehensive Ascension implementation notes document (`QUICKCONFIRM_ASCENSION_NOTES.md`)
  - Documents key differences between Retail WoW and Ascension WoW for BoP loot handling
  - Explains why `ConfirmLootSlot()` only confirms but doesn't loot in Ascension (requires manual `LootSlot()` call)
  - Includes testing results comparing different implementation approaches
  - Provides troubleshooting guide with verification commands
  - Documents performance metrics and technical implementation details

### Technical Improvements

- **XPRepBar**: All child elements now guaranteed to stay within parent StatusBar's explicit dimensions
- **ChatFilters**: Comprehensive multi-path message filtering ensures no error messages slip through
- **InfoBar**: Localization support for Soul Shards across English, Spanish, and French

## [0.6.1] - 2025-10-14

### Changed

- **QuickConfirm**: Complete refactoring to event-driven architecture for both transmog and BoP loot confirmations
  - **Performance**: BoP loot now instant (~10ms vs 0-600ms), 0% CPU when idle (vs constant polling)
  - **Code Quality**: 26% code reduction (267 → 198 lines) with cleaner, more maintainable structure
  - **Architecture**: Direct event handlers (`LOOT_BIND_CONFIRM`) and StaticPopup hooks replace polling/retry system
  - **Reliability**: Event-driven approach eliminates race conditions and missed popups
  - **Ascension-Specific**: Custom implementation with `LootSlot()` call required after `ConfirmLootSlot()` due to client differences

### Removed

- **QuickConfirm**: Legacy polling system including scanner, retry scheduler, and complex pattern matching
  - Removed `TRANSMOG_PATTERNS` and `BOP_LOOT_PATTERNS` constant tables (replaced by direct event/hook detection)
  - Removed `EVENTS` reference table (replaced by direct AceEvent registration)
  - Eliminated scheduler dependency for popup detection

### Documentation

- **QuickConfirm**: Added 4 comprehensive technical documents (895 lines total):
  - `QUICKCONFIRM_REFACTOR.md` - Technical analysis and implementation details
  - `QUICKCONFIRM_TESTING.md` - Complete testing procedures and scenarios
  - `QUICKCONFIRM_COMPLETION.md` - Feature completion summary and metrics
  - `QUICKCONFIRM_ASCENSION_NOTES.md` - Ascension-specific implementation notes

## [0.6.0] - 2025-10-13

### Added

- **QuestTracker**: Complete new module for quest tracking enhancements with unified text processing system.
- **QuestTracker**: Quest level display with configurable toggle - shows `[Level] QuestTitle` format for all tracked quests.
- **QuestTracker**: Color coding by difficulty using WoW standard colors (Red: 5+ levels above, Orange: 3-4 above, Yellow: ±2 levels, Green: 3-10 below, Gray: 11+ below).
- **QuestTracker**: Automatic objective indentation (4 spaces) for better visual hierarchy and readability.
- **QuestTracker**: Smart objective text truncation for lines over 100 characters with word-boundary detection.
- **QuestTracker**: Dash invisibility system - quest objective dashes remain functional but are visually hidden.
- **QuestTracker**: Path to Ascension quest auto-positioning - automatically moves these special quests to the end of the tracker.
- **QuestTracker**: Dual auto-tracking modes: "All Quests" (force track everything) and "By Zone" (current zone + always track Ascension quests).
- **QuestTracker**: Custom frame positioning with drag-and-drop support and position locking toggle.
- **QuestTracker**: Configurable frame height (300-1000 pixels) for accommodating different quest loads.
- **QuestTracker**: Text outline toggle for improved readability against various backgrounds.
- **QuestTracker**: Background hiding option to remove quest tracker artwork for minimal UI setups.
- **QuestTracker**: Comprehensive SexyMap compatibility with position management hooks.
- **QuickConfirm**: Integrated automatic AdiBags refresh after transmog appearance confirmations for seamless bag organization when collecting appearances.

### Improved

- **QuestTracker**: Complete code architecture overhaul - eliminated all legacy dual-system approaches in favor of unified `ApplyAllTextEnhancements()` processing.
- **QuestTracker**: Implemented dash-based quest detection system (`dash.text == "-"`) for 100% accurate distinction between quest titles and objectives.
- **QuestTracker**: Streamlined configuration to only essential, functional options - removed 8 unused/problematic settings.
- **QuestTracker**: Enhanced auto-tracking intelligence with zone-based filtering and special Ascension quest category detection.
- **QuestTracker**: Optimized performance by reducing codebase by 24% (515 lines removed) while maintaining full functionality.
- **Hotkeys**: Completely redesigned range checking system with per-button independent timers for more accurate and responsive out-of-range detection.
- **Hotkeys**: Replaced batch/round-robin processing with individual OnUpdate handlers for each button, eliminating delay between checks.
- **Hotkeys**: Added reactive event handlers for instant updates on target changes (`PLAYER_TARGET_CHANGED`), action slot changes (`ACTIONBAR_SLOT_CHANGED`), and binding updates (`UPDATE_BINDINGS`).
- **Hotkeys**: Optimized color caching system to minimize unnecessary `SetVertexColor` calls, improving performance.
- **Hotkeys**: Simplified configuration interface by removing unused range display modes, keeping only the full button tinting mode.
- **Hotkeys**: Range check interval now fixed at 0.2 seconds per button for consistent responsiveness matching game engine tooltip updates.
- **QuickConfirm**: Optimized retry attempts (3) and retry intervals (0.2s) for better performance and reliability.
- **QuickConfirm**: Cleaned up code by removing debug messages and translating all comments to English.

### Changed

- **QuestTracker**: Removed all legacy quest sorting functionality - quests now maintain natural WoW order with only Path to Ascension repositioning.
- **QuestTracker**: Simplified auto-tracking to two clear modes: "All Quests" and "By Zone" with mutual exclusivity and auto-fallback.
- **QuestTracker**: Configuration interface streamlined from 12+ options to 8 essential, working options.
- **Hotkeys**: Removed user-adjustable update interval slider in favor of optimal fixed timing.
- **Hotkeys**: Removed scheduler dependency for range checks, each button now manages its own timer independently.
- **QuickConfirm**: Hidden advanced configuration options (retry attempts, retry interval, AdiBags refresh delay) from UI while maintaining configurable defaults internally.

### Fixed

- **QuestTracker**: Resolved WatchFrame corruption issues that occurred when toggling "Show Quest Levels" and "Color Code by Difficulty" options mid-session.
- **QuestTracker**: Fixed duplicate quest level prefixes that could appear after multiple toggle operations.
- **QuestTracker**: Eliminated conflicting legacy cleanup functions (`RemoveQuestLevels`, `ShowQuestLevels`, etc.) that caused state management issues.
- **QuestTracker**: Fixed text outline thickness defaulting to "Normal" consistently across all UI elements.
- **QuestTracker**: Resolved issues with quest reordering logic interfering with native WoW quest tracking behavior.
- **Hotkeys**: Fixed range indicator lag that occurred with many active buttons due to batching delays.
- **Hotkeys**: Resolved delayed range updates when changing targets or switching action bars.
- **QuickConfirm**: Fixed AdiBags refresh to use proper `SendMessage('AdiBags_FiltersChanged')` API for reliable bag updates.

### Removed

- **QuestTracker**: All legacy debugging commands (`/qttest`, `/qtfix`, `/qtdash`, `/qtdebug`, `/qtanalyze`) and their associated functions (`TestFunction`, `DebugDashAnalysis`, etc.).
- **QuestTracker**: Removed unused configuration options: `showProgressPercent`, `compactMode`, `highlightNearbyObjectives`, `showQuestIcons` (never implemented or non-functional).
- **QuestTracker**: Legacy dual-system functions: `RemoveQuestLevels()`, `ShowQuestLevels()`, `ApplyDifficultyColors()` replaced by unified processing.
- **QuestTracker**: Complex quest sorting system including `SortQuestsByLevel()`, `ReorderWatchFrameLines()`, `ApplyZoneFilter()` and related utilities.
- **QuestTracker**: Unused variables: `savedWatchFrameContent`, `savedFrameProperties`, `isApplyingLevels`, `lastProcessedQuests`, `nearbyObjectives`.
- **QuestTracker**: Analysis and debugging functions: `AnalyzeWatchFrameStructure()`, `FindQuestTitleInWatchFrame()`, `GetCleanText()`, `ShowProgressPercentages()`.
- **QuestTracker**: Text outline thickness configuration - now always uses "Normal" thickness when enabled.

### Technical Improvements

- **QuestTracker**: Reduced codebase from 2153 to 1638 lines (24% reduction) while maintaining all core functionality.
- **QuestTracker**: Implemented dash-based detection system using `dash.text == "-"` pattern for 100% accurate quest title vs objective identification.
- **QuestTracker**: Unified all text enhancements into single `ApplyAllTextEnhancements()` function eliminating race conditions and duplicate processing.
- **QuestTracker**: Enhanced maintenance system with intelligent background/position reapplication during frame updates.
- **QuestTracker**: Improved SexyMap compatibility with comprehensive position management hooks and intercepts.

## [0.5.0] - 2025-10-10

### Added

- NamePlates: comprehensive integration module for Ascension NamePlates addon providing status monitoring, loading controls, and direct configuration access through YATP's Interface Hub.
- NamePlates: independent category with tab-based structure replicating the original addon's organization (Status, General, Friendly, Enemy, Personal tabs).
- NamePlates: Enemy Target tab with specialized options for targeted enemy nameplates including enhanced visibility, custom highlighting, borders, and health display formats.
- NamePlates: embedded configuration panel with the most commonly used settings directly accessible within YATP interface without needing to open the original addon configuration.
- NamePlates: real-time option synchronization with the original addon allowing seamless configuration changes that immediately affect the nameplates.
- NamePlates: adaptive interface that shows configuration tabs only when the addon is loaded and available.
- NamePlates: YATP-specific enhancements for enemy targets including highlight effects, enhanced borders, and flexible health text formatting.

## [1.0.3] - 2024-XX-XX

### Fixed
- **Enemy Target Tab**: Removed non-functional custom options that don't exist in the Ascension NamePlates addon
- **Real Options Only**: Enemy Target tab now only includes Target Scale, the only real target-specific option from the original addon
- **Documentation**: Updated to accurately reflect available options vs custom implementations

### Changed
- **Enemy Target Tab**: Simplified to focus on working Target Scale option and information about other available settings
- **Localization**: Updated Enemy Target tab text to reflect actual functionality
- **Code Cleanup**: Removed placeholder functions for non-existent features (UpdateTargetHighlight, UpdateTargetBorder, etc.)

### Added
- **Better Information**: Enemy Target tab now provides clear guidance on where to find other nameplate customization options
- **Technical Notes**: Added explanation of what target-specific options are actually available in the base addon

### Documentation
- **ENEMY_TARGET_REAL_OPTIONS.md**: Comprehensive documentation of actual vs non-existent options
- **Honest Interface**: Tab now provides functional options rather than placeholders that don't work

## [1.0.2] - 2024-XX-XX

### Added

- QuickConfirm: bind-on-pickup (BOP) loot auto-confirmation feature with comprehensive detection via `LOOT_BIND` which value and text pattern fallback ("will bind it to you", "bind it to you", "looting").
- QuickConfirm: extended retry scheduling system to handle both transmog and BOP loot confirmations with mode-specific logic.
- XPRepBar: animated spark indicator showing current XP progress position with configurable show/hide toggle.
- XPRepBar: enhanced max level detection with `YATP_GetEffectiveMaxLevel()` function supporting multiple client builds and expansion levels.
- Localization: complete English and Spanish translations for new BOP loot functionality.

### Changed

- QuickConfirm: updated module description to include both transmog and bind-on-pickup loot functionality.
- XPRepBar: improved rested XP overlay positioning - now correctly starts at current XP position instead of bar beginning.
- Error handling: standardized error messages across modules with proper formatting and red color coding.

### Fixed

- XPRepBar: better handling of various client builds and expansion levels with improved error handling for edge cases.
- Code quality: replaced generic `print()` statements with properly formatted `DEFAULT_CHAT_FRAME:AddMessage()` calls across multiple modules.

### Completed Features

- Removed completed "QuickConfirm: Auto-accept world loot (BOP)" idea from IDEAS.md as it has been successfully implemented and tested.

## [0.4.1] - 2025-10-08

### Added

- ChatBubbles: standardized "Enable Module" toggle (previous wording "Hide Chat Bubbles" could be ambiguous).
- XPRepBar: new "Enable Module" master toggle (hides frames & unregisters events when disabled).
- Core: confirmation dialog for /reload after toggling any module enable state (YES / CANCEL).
- All modules: enable toggle tooltips now indicate a /reload is recommended for a fully clean apply.
- PlayerAuraFilter: new separated module for name-based buff hiding (starts empty; no migration of legacy PlayerAuras list).

### Changed

- Unified enable/disable pattern to consistently use AceAddon `:Enable()` / `:Disable()` across modules (Hotkeys, QuickConfirm, etc.).
- UX consistency: post-toggle reload prompt avoids confusion about partial state without UI reload.
- PlayerAuras: now layout-only (scale, rows, growth, sort, duration font). Filtering logic extracted to PlayerAuraFilter.
- Localization: remaining Spanish comments in PlayerAuras translated to English for repository consistency.

### Removed

- ChatBubbles: Aggressive Scan toggle and scan interval option.
- QuickConfirm: legacy exit watcher & auto-exit logic (now focused narrowly on transmog confirmations only).
- Hotkeys: temporary target-change burst refresh system (replaced by steady timer + immediate recolor on adjustments).
- ChatFilters: obsolete loot money filtering option (redundant with base client; legacy profile key now ignored).
- PlayerAuras: old `knownBuffs` keys and filter UI (superseded by the new PlayerAuraFilter module). Prior hidden list data intentionally discarded.

### Fixed

- Hotkeys: changing interval slider triggers immediate one-pass recolor for fast visual feedback.
- Scheduler: updated to ignore removed option keys gracefully (no dangling references / errors).
- Locale: added missing keys to eliminate AceLocale runtime warnings.

### Temporarily Disabled Modules

- PlayerAuras: forcibly disabled this release pending review of recent aura frame/API behavior; Blizzard default layout in use.
- PlayerAuraFilter: forcibly disabled (filter logic suspended) to avoid confusion while layout module is inactive.

### Internal / Maintenance

- Hotkeys task refactored to dynamic interval function (future adaptive tuning hook).
- Locales cleaned of deprecated keys to prevent stale UI clutter; added missing runtime keys.
- README updated to reflect module split and temporary suspension notice for aura modules.

## [0.3.3] - 2025-10-08

Changed:

- QuickConfirm: scope reduced to only auto-confirm full client exit (QUIT / CONFIRM_EXIT). It no longer auto-confirms logout / CAMP dialogs.

Removed:

- QuickConfirm: detection of CAMP (logout) which id, textual cue "camp", "leave world", and logout countdown phrases ("seconds until logout").

Internal / Maintenance:

- Adjusted exit text cue list to minimal set ("exit", "quit") to prevent accidental logout confirmation in multi-locale setups.

## [0.3.2] - 2025-10-08

Added:

- ChatFilters: automatic suppression of first login/reload /played dump (manual /played remains visible).
- IDEAS: added concept for loot item quality filtering (threshold + quest/gathering exceptions).

Changed:

- ChatFilters: consolidated advanced toggles (AddMessage hook, /played suppression options) into hidden defaults; user-facing option now a single "Suppress Login Welcome Lines" toggle.
- README: updated ChatFilters module summary to reflect current behavior (money lines, login spam, first /played suppression).

Fixed:

- ChatFilters: dynamic Session Stats now refresh via throttled AceConfigRegistry notifications; first /played suppression increments login spam counter.

Removed:

- ChatFilters: exposed UI options for AddMessage hook and /played fine-grain settings (retained internally for compatibility).

Internal / Maintenance:

- Refactored time played hook to a narrow proxy around ChatFrame_DisplayTimePlayed with first-call suppression logic and safe restore on module disable.

## [0.3.1] - 2025-10-07

Additions:

- BackgroundFPSFix module (Extras > Tweaks): provides a configurable background framerate cap (`/console maxfpsbk`) with restore-on-disable behavior and slider up to 240 FPS (0 = no override). Replaces earlier experimental embedding attempt inside WAAdiFixes.

Changes:

- TOC: added `modules/backgroundfpsfix.lua` entry.
- README: documented Tweaks panel presence (Background FPS Fix).
- IDEAS: moved "Background FPS Limit Toggle" to Historical as shipped.

Internal / Maintenance:

- Refactored WAAdiFixes to remove temporary background FPS logic.
- Introduced Tweaks group under Extras for future small performance toggles.

## [0.3] - 2025-10-07

Added:

- ChatFilters module (Quality of Life): suppresses repetitive system error spam ("Interface action failed because of an AddOn" / UI Error variants) with substring + token matching, color code stripping, optional diagnostic logging.

Changed:

- README: documented new ChatFilters module.
- TOC: version bump to 0.3.

Fixed:

- Locale: added missing keys (Debug Mode, verbose debug description, ChatFilters labels) eliminating AceLocale missing entry warnings.

Internal / Maintenance:

- ChatFilters logic includes extensible placeholders for future pattern list & summary counters (currently hidden advanced toggles).

## [0.2] - 2025-10-07

Added:

- Global Debug Mode toggle under `YATP > Extras` controlling verbose output for all modules.
- Consolidated debug helper API: `YATP:IsDebug()` and `YATP:Debug(msg)`.
- Loot Roll Info module: debug simulation commands `/lriblizz`, `/lripop`, `/lrihide`.

Changed:

- LootRollInfo: migrated from standalone script; counters & tooltips refined; fallback English pattern parsing added.
- LootRollInfo: button counter placement unified (top-right) and resilient button lookup.
- QuickConfirm: now uses global debug mode; removed per-module debug toggle and `/qcdebug` command.
- Template module: removed per-module debug toggle; now references global debug.

Removed:

- Per-module `debug` toggles in LootRollInfo, QuickConfirm, Template.
- Obsolete duplicate root `config.lua` (already documented in TOC Notes-ESMX).

Internal / Maintenance:

- Added this CHANGELOG.md file.
- Standardized internal debug print prefix formatting.

## [0.1] - Initial Snapshot

Added:

- Core addon skeleton with Ace3 framework (core + config hubs: Interface Hub, Quality of Life, Extras).
- Modules included: xprepbar, chatbubbles, playerauras, infobar, quickconfirm, hotkeys, waadifix, lootrollinfo (early integration).
- Basic localization scaffold (`locales/enUS.lua`).

Commit History Notes:

The following early commits were consolidated into this initial snapshot:

- `8605cc3` xbar test (prototype groundwork for XP/Rep bar)
- `e6d5e6f` xpbar (establish XP/Rep bar module structure)
- `057763b` xprepbar (refinement & rename of the bar module)
- `8e81e7e` chatbubbles (chat bubble styling module)
- `e6ceda8` playerauras (aura filtering & layout module)
- `dd32f60` infobar (performance / durability bar)
- `19c2727` quick confirm (auto popup confirmation logic)
- `451a629` hotkeys (action button hotkey styling & usability tints)
- `55aa76f` loot roll info (initial integration before later refactor)
- `8224f9a` debug clean (preparation for unified debug approach)
- `a9c80b7` lootrollinfo debugmode (forms the basis of changes now under [Unreleased])

[Unreleased]: https://github.com/zavahcodes/YATP/compare/v0.6.3...HEAD
[0.6.3]: https://github.com/zavahcodes/YATP/releases/tag/v0.6.3
[0.6.2]: https://github.com/zavahcodes/YATP/releases/tag/v0.6.2
[0.6.1]: https://github.com/zavahcodes/YATP/releases/tag/v0.6.1
[0.6.0]: https://github.com/zavahcodes/YATP/releases/tag/v0.6.0
[0.5.0]: https://github.com/zavahcodes/YATP/releases/tag/v0.5.0
[0.4.2]: https://github.com/zavahcodes/YATP/releases/tag/v0.4.2
[0.4.1]: https://github.com/zavahcodes/YATP/releases/tag/v0.4.1
[0.3.3]: https://github.com/zavahcodes/YATP/releases/tag/v0.3.3
[0.3.2]: https://github.com/zavahcodes/YATP/releases/tag/v0.3.2
[0.3.1]: https://github.com/zavahcodes/YATP/releases/tag/v0.3.1
[0.3]: https://github.com/zavahcodes/YATP/releases/tag/v0.3
[0.2]: https://github.com/zavahcodes/YATP/releases/tag/v0.2
[0.1]: https://github.com/zavahcodes/YATP/releases/tag/v0.1
