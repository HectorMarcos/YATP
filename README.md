# YATP – Yet Another Tweaks Pack

A modular World of Warcraft (3.3.5 / legacy) addon that consolidates a curated set of quality‑of‑life interface tweaks under one lightweight Ace3 powered framework. Each feature lives in its own self‑contained module so you only pay for what you enable.

## Core Goals

- Keep modules decoupled and easy to maintain.
- Provide consistent configuration panels using AceConfig (grouped into Interface, Quality of Life and Extras hubs).
- Offer safe migrations for users coming from small standalone addons (chat bubbles, buffs, keybind styling, etc.).
- Remain readable: clear English comments, minimal hidden magic.

## Main Features (Modules)

| Module | Hub | Summary |
|--------|-----|---------|
| ChatBubbles | Interface | Strips default bubble art and restyles text (font face / outline / size, aggressive scan & sweep tuning). Migrates legacy NoBubbles profile values if present. |
| Hotkeys | Interface | Restyles action button hotkey text (font, outline, color) and tints ability icons based on range / mana / usability. Optional AnyDown + keyboard‑only heuristic. |
| PlayerAuras | Interface | Unified player buff & debuff filtering, sorting, scaling and duration text styling. Hide list with defaults + custom additions; optional alphabetical sorting. Migrates BetterBuffs data. |
| XPRepBar | Interface | Combined XP + Reputation bar replacement with mouseover text mode, ticks, positioning & texture customization. Auto swaps reputation bar into XP slot at max level. |
| LootRollInfo | Quality of Life | Shows per‑roll Need / Greed / Disenchant / Pass counters on Group Loot frames with tooltips listing players; optional chat suppression & rarity threshold. |
| InfoBar | Quality of Life | Compact performance/character status bar (FPS, latency, durability %) with colorized low durability warning. Drag (unlock) + font & update interval controls. |
| QuickConfirm | Quality of Life | Auto‑confirms specific StaticPopup dialogs (transmog appearance collection, exit / quit confirmations) with throttled scanning & pattern hooks. |
| ChatFilters | Quality of Life | Suppresses system spam: interface action failed, UI error variants, repetitive loot money lines, welcome/uptime login lines, and auto‑hides only the first automatic /played dump (manual /played still shows). Advanced toggle hooks hidden by default. |
| WAAdiFixes | Extras | Small compatibility patches (currently legacy resize API wrapper for WeakAuras / AdiBags). Built for future micro‑fix groups. |
| BackgroundFPSFix (Tweaks) | Extras | Adjustable background framerate cap (0 disables override) with automatic restore of original value when disabled. |

## Installation

1. Clone or download the repository.
2. Ensure the folder name inside `Interface/AddOns` is exactly `YATP` (matching the `.toc`).
3. Restart (or /reload) the client.
4. Type `/yatp` in chat to open the configuration panel.

## Configuration Hubs

YATP groups options into three parent panels under the standard Interface Options:

- Interface Hub – Core UI visual / interaction tweaks (font styling, auras, XP/Rep, bubbles, hotkeys).
- Quality of Life – Supplemental convenience automation & informational tools (loot rolls, info bar, quick confirmations).
- Extras – Small scoped fixes or compatibility shims.
  - Tweaks subgroup: lightweight performance / environment toggles (currently Background FPS Fix).

Selecting a hub exposes module groups in a tree; each module contributes its own AceConfig table via `YATP:AddModuleOptions(name, optionsTable, hub)`.

## Slash Commands

```bash
/yatp           # Open main configuration
/yatp modules   # List registered modules
/yatp reload    # Reload the UI
```
Individual modules may add their own shortcuts (e.g. `/infobar`, `/xpbar`, `/chatbubbles`).

### Debug Mode

Global debug output can be toggled either via command or the Extras hub:

```bash
/yatp debug
```
or open: YATP > Extras > Debug Mode

When enabled you'll see:

- Initialization / loaded messages
- Module registration / hub assignment lines
- Verbose per‑module diagnostic output (modules that implement debug hooks)

Disable it after troubleshooting to avoid chat clutter.

## Localization

- English (enUS) acts as the implicit fallback.
- Additional locale files (e.g. `esES.lua`, `frFR.lua`) may override any key.
- When `L["Key"]` is missing, YATP gracefully falls back to the raw key string.

## Module Development Guide

Create new functionality by copying `modules/Template.lua`:

1. Rename the file and replace `Template` with your module name.
2. Define `Module.defaults` (only persistent keys, keep them small & typed).
3. Implement `:OnInitialize()` to seed DB and register options.
4. Implement `:OnEnable()` / `:OnDisable()` for event hooks & timers.
5. Provide a `:BuildOptions()` method returning an AceConfig group (scoped, no global state leaks).
6. Use `self:Debug()` style helpers (guarded by a `debug` flag) for optional verbose logging.

### Minimal Contract

Every module should:

- Register itself with `YATP:NewModule()` and call `YATP:AddModuleOptions()`.
- Store all persistent data inside `YATP.db.profile.modules[ModuleName]`.
- Avoid poll loops if an event exists; throttle where needed.

### Defensive Patterns

- Wrap risky calls in `pcall` if external frames / global APIs may differ across forks.
- Do not assume other addons are loaded; nil‑check global references.
- Guard OnUpdate logic with small accumulators and early returns.

## Saved Variables

A single AceDB root: `YATP_DB` with a `profile.modules` table holding one sub‑table per module. Migrations copy or adapt data from previously standalone addon SVs (e.g. `_G.NoBubblesDB`, `BetterBuffsDB`) exactly once.

## Performance Notes

- Chat bubble styling uses targeted sweeps plus optional aggressive interval scanning. Configurable `scanInterval` and post‑detection sweeps minimize CPU burst.
- Hotkeys range/mana tinting centralizes updates through a single throttle frame (`UPDATE_INTERVAL`).
- PlayerAuras marks state dirty and batches layout work to a throttled OnUpdate instead of per‑event reflow.

## Extensibility Roadmap (Ideas)

- Additional filtering categories (e.g., whitelist/blacklist patterns) for PlayerAuras.
- Optional minimal DataBroker feed for InfoBar stats.
- Export/import profile snippets per module.
- Shared color & font presets across modules.

## Contributing

1. Open an issue with a concise description & reproduction steps.
2. For pull requests, keep changes module‑scoped; avoid editing third‑party libraries under `libs/`.
3. Follow existing code style: tabs vs spaces preserved per file; descriptive English comments.
4. Test with a clean profile to confirm migrations and defaults behave.

## License

(If a license applies, specify here. Add a LICENSE file if distributing.)

## Credits

- Original standalone functionality integrated from small prototype addons (NoBubbles, BetterBuffs, etc.).
- Built on the Ace3 framework and LibSharedMedia.

Enjoy a cleaner UI with modular control!

---

### Changelog

See `CHANGELOG.md` for a curated list of added / changed / removed items between releases. New development entries accumulate under the `[Unreleased]` section until the next version tag.

### Roadmap & Idea Parking Lot

High-level planned themes live in `docs/ROADMAP.md`.
Early / unrefined feature thoughts are collected (not guaranteed) in `docs/IDEAS.md` so the README stays concise.
