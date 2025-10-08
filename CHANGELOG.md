# Changelog

All notable changes to this project will be documented in this file.

The format is based on Keep a Changelog (https://keepachangelog.com/en/1.1.0/)
and this project adheres (aspirationally) to Semantic Versioning once it reaches 1.0.

## [Unreleased]

### Added (Unreleased)

- ChatBubbles: toggle de "Enable Module" estandarizado (antes el texto podía resultar ambiguo al decir "Hide Chat Bubbles").
- XPRepBar: nueva opción "Enable Module" para activar/desactivar completamente la barra (oculta frames y desregistra eventos al deshabilitarla).
- Core: diálogo de confirmación para /reload al cambiar cualquier "Enable Module" (aparece opción YES/CANCEL).
- Todos los módulos: tooltips de los toggles ahora indican que se recomienda /reload para aplicar totalmente el cambio.

### Changed (Unreleased)

- Unificación del patrón de enable/disable para que coincida con otros módulos (Hotkeys, QuickConfirm) usando `self:Enable()/self:Disable()` de AceAddon.
- Consistencia de UX: tras togglear se ofrece popup de reload evitando confusión sobre estados parciales sin recarga.

## [0.4.0] - 2025-10-08

### Summary

Performance consolidation release: centralized scheduler replaces multiple OnUpdate loops; simplified modules (no aggressive scans or auto-exit watcher); user‑tunable Hotkeys update interval for better range tint responsiveness with minimal CPU.

### Added

- Hotkeys: interval slider (0.10–0.40s) + slash `/yatphotkint <seconds>` for rapid tuning.
- Scheduler: dynamic interval support (task can return next delay) enabling adaptive future logic.
- Docs: `docs/INGAME_TESTS.md` in‑game validation guide.

### Changed

- Hotkeys: default update interval lowered to 0.15s (was 0.25) keeping batch size 18; removed burst prototype for predictable cadence.
- ChatBubbles: event-driven with limited post-sweeps only (aggressive scanning removed) reducing idle CPU.
- QuickConfirm: narrowed strictly to transmog confirmations (removed exit auto-confirm logic).
- Localization: pruned unused keys (Aggressive Scan, exit auto-confirm) to reduce noise.

### Removed

- ChatBubbles: Aggressive Scan toggle and scan interval option.
- QuickConfirm: exit watcher & auto-exit option plus related text cues and frame scanning logic.
- Hotkeys: temporary target-change burst refresh system (superseded by steady interval + immediate recolor on slider change).
- ChatFilters: obsolete loot money filtering option (redundant with base client; legacy profile key ignored).

### Fixed

- Hotkeys: moving interval slider triggers immediate one-pass recolor for fast feedback.
- Scheduler: tasks updated to ignore removed options cleanly (no dangling references / errors).

### Internal / Maintenance

- Hotkeys task refactored to dynamic interval function (future adaptive tuning hook).
- Locales (enUS/esES/frFR) cleaned of deprecated keys to prevent stale UI clutter.
- README & CHANGELOG synchronized with feature removals.

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

[Unreleased]: https://github.com/zavahcodes/YATP/compare/v0.4.0...HEAD
[0.4.0]: https://github.com/zavahcodes/YATP/releases/tag/v0.4.0
[0.3.3]: https://github.com/zavahcodes/YATP/releases/tag/v0.3.3
[0.3.2]: https://github.com/zavahcodes/YATP/releases/tag/v0.3.2
[0.3.1]: https://github.com/zavahcodes/YATP/releases/tag/v0.3.1
[0.3]: https://github.com/zavahcodes/YATP/releases/tag/v0.3
[0.2]: https://github.com/zavahcodes/YATP/releases/tag/v0.2
[0.1]: https://github.com/zavahcodes/YATP/releases/tag/v0.1
