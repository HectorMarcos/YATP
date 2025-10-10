# Changelog

All notable changes to this project will be documented in this file.

The format is based on Keep a Changelog (https://keepachangelog.com/en/1.1.0/)
and this project adheres (aspirationally) to Semantic Versioning once it reaches 1.0.

## [Unreleased]

### Added

- NamePlates: comprehensive integration module for Ascension NamePlates addon providing status monitoring, loading controls, and direct configuration access through YATP's Interface Hub.
- NamePlates: independent category with tab-based structure replicating the original addon's organization (Status, General, Friendly, Enemy, Personal tabs).
- NamePlates: Enemy Target tab with specialized options for targeted enemy nameplates including enhanced visibility, custom highlighting, borders, and health display formats.
- NamePlates: embedded configuration panel with the most commonly used settings directly accessible within YATP interface without needing to open the original addon configuration.
- NamePlates: real-time option synchronization with the original addon allowing seamless configuration changes that immediately affect the nameplates.
- NamePlates: adaptive interface that shows configuration tabs only when the addon is loaded and available.
- NamePlates: YATP-specific enhancements for enemy targets including highlight effects, enhanced borders, and flexible health text formatting.

_No other changes yet._

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

[Unreleased]: https://github.com/zavahcodes/YATP/compare/v0.4.2...HEAD
[0.4.2]: https://github.com/zavahcodes/YATP/releases/tag/v0.4.2
[0.4.1]: https://github.com/zavahcodes/YATP/releases/tag/v0.4.1
[0.3.3]: https://github.com/zavahcodes/YATP/releases/tag/v0.3.3
[0.3.2]: https://github.com/zavahcodes/YATP/releases/tag/v0.3.2
[0.3.1]: https://github.com/zavahcodes/YATP/releases/tag/v0.3.1
[0.3]: https://github.com/zavahcodes/YATP/releases/tag/v0.3
[0.2]: https://github.com/zavahcodes/YATP/releases/tag/v0.2
[0.1]: https://github.com/zavahcodes/YATP/releases/tag/v0.1
