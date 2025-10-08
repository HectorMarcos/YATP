# Changelog

All notable changes to this project will be documented in this file.

The format is based on Keep a Changelog (https://keepachangelog.com/en/1.1.0/)
and this project adheres (aspirationally) to Semantic Versioning once it reaches 1.0.

## [Unreleased]

### Added (placeholder)

### Changed (placeholder)

### Fixed (placeholder)

### Removed (placeholder)

* ChatFilters: removed loot money filtering option (redundant – can be disabled in base client). Profiles keep legacy key ignored.

### Security (placeholder)

### Internal / Maintenance (placeholder)

## [0.3.3] - 2025-10-08

### Changed

- QuickConfirm: scope reduced to only auto-confirm full client exit (QUIT / CONFIRM_EXIT). It no longer auto-confirms logout / CAMP dialogs.

### Removed

- QuickConfirm: detection of CAMP (logout) which id, textual cue "camp", "leave world", and logout countdown phrases ("seconds until logout").

### Internal / Maintenance

- Adjusted exit text cue list to minimal set ("exit", "quit") to prevent accidental logout confirmation in multi-locale setups.

## [0.3.2] - 2025-10-08

### Added

- ChatFilters: automatic suppression of first login/reload /played dump (manual /played remains visible).
- IDEAS: added concept for loot item quality filtering (threshold + quest/gathering exceptions).

### Changed

- ChatFilters: consolidated advanced toggles (AddMessage hook, /played suppression options) into hidden defaults; user-facing option now a single "Suppress Login Welcome Lines" toggle.
- README: updated ChatFilters module summary to reflect current behavior (money lines, login spam, first /played suppression).

### Fixed

- ChatFilters: dynamic Session Stats now refresh via throttled AceConfigRegistry notifications; first /played suppression increments login spam counter.

### Removed

- ChatFilters: exposed UI options for AddMessage hook and /played fine-grain settings (retained internally for compatibility).

### Internal / Maintenance

- Refactored time played hook to a narrow proxy around ChatFrame_DisplayTimePlayed with first-call suppression logic and safe restore on module disable.

## [0.3.1] - 2025-10-07

### 0.3.1 Additions

- BackgroundFPSFix module (Extras > Tweaks): provides a configurable background framerate cap (`/console maxfpsbk`) with restore-on-disable behavior and slider up to 240 FPS (0 = no override). Replaces earlier experimental embedding attempt inside WAAdiFixes.

### 0.3.1 Changes

- TOC: added `modules/backgroundfpsfix.lua` entry.
- README: documented Tweaks panel presence (Background FPS Fix).
- IDEAS: moved "Background FPS Limit Toggle" to Historical as shipped.

### 0.3.1 Internal / Maintenance

- Refactored WAAdiFixes to remove temporary background FPS logic.
- Introduced Tweaks group under Extras for future small performance toggles.

## [0.3] - 2025-10-07

### Added
- ChatFilters module (Quality of Life): suppresses repetitive system error spam ("Interface action failed because of an AddOn" / UI Error variants) with substring + token matching, color code stripping, optional diagnostic logging.

### Changed
- README: documented new ChatFilters module.
- TOC: version bump to 0.3.

### Fixed
- Locale: added missing keys (Debug Mode, verbose debug description, ChatFilters labels) eliminating AceLocale missing entry warnings.

### Internal / Maintenance
- ChatFilters logic includes extensible placeholders for future pattern list & summary counters (currently hidden advanced toggles).

## [0.2] - 2025-10-07

### Added
- Global Debug Mode toggle under `YATP > Extras` controlling verbose output for all modules.
- Consolidated debug helper API: `YATP:IsDebug()` and `YATP:Debug(msg)`.
- Loot Roll Info module: debug simulation commands `/lriblizz`, `/lripop`, `/lrihide`.

### Changed
- LootRollInfo: migrated from standalone script; counters & tooltips refined; fallback English pattern parsing added.
- LootRollInfo: button counter placement unified (top-right) and resilient button lookup.
- QuickConfirm: now uses global debug mode; removed per-module debug toggle and `/qcdebug` command.
- Template module: removed per-module debug toggle; now references global debug.

### Removed
- Per-module `debug` toggles in LootRollInfo, QuickConfirm, Template.
- Obsolete duplicate root `config.lua` (already documented in TOC Notes-ESMX).

### Internal / Maintenance
- Added this CHANGELOG.md file.
- Standardized internal debug print prefix formatting.

## [0.1] - Initial Snapshot

### Added
- Core addon skeleton with Ace3 framework (core + config hubs: Interface Hub, Quality of Life, Extras).
- Modules included: xprepbar, chatbubbles, playerauras, infobar, quickconfirm, hotkeys, waadifix, lootrollinfo (early integration).
- Basic localization scaffold (`locales/enUS.lua`).

### Commit History Notes
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

[Unreleased]: https://github.com/zavahcodes/YATP/compare/v0.3.3...HEAD
[0.3.3]: https://github.com/zavahcodes/YATP/releases/tag/v0.3.3
[0.3.2]: https://github.com/zavahcodes/YATP/releases/tag/v0.3.2
[0.3.1]: https://github.com/zavahcodes/YATP/releases/tag/v0.3.1
[0.3]: https://github.com/zavahcodes/YATP/releases/tag/v0.3
[0.2]: https://github.com/zavahcodes/YATP/releases/tag/v0.2
[0.1]: https://github.com/zavahcodes/YATP/releases/tag/v0.1
