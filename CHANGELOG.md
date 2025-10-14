# Changelog

All notable changes to this project will be documented in this file.

The format is based on Keep a Changelog (https://keepachangelog.com/en/1.1.0/)
and this project adheres (aspirationally) to Semantic Versioning once it reaches 1.0.

## [Unreleased]

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

[Unreleased]: https://github.com/zavahcodes/YATP/compare/v0.6.2...HEAD
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
