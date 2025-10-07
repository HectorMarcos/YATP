# Changelog

All notable changes to this project will be documented in this file.

The format is based on Keep a Changelog (https://keepachangelog.com/en/1.1.0/)
and this project adheres (aspirationally) to Semantic Versioning once it reaches 1.0.

## [Unreleased]
### Added
### Changed
### Fixed
### Removed
### Security
### Internal / Maintenance

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

[Unreleased]: https://example.com/compare/v0.2...HEAD
[0.2]: https://example.com/releases/tag/v0.2
[0.1]: https://example.com/releases/tag/v0.1
