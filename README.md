# YATP – Yet Another Tweaks Pack

Modular QoL + UI tweaks for WoW 3.3.5 (Ascension / BronzeBeard). Ace3 based. Enable only what you want.

## Modules

| Module | Hub | Summary |
|--------|-----|---------|
| ChatBubbles | Interface | Restyle & clean chat bubbles (migrates NoBubbles). |
| Hotkeys | Interface | Hotkey font + range / mana tinting. |
| PlayerAuras | Interface | Buff/debuff filter, sort, scale (BetterBuffs migration). |
| XPRepBar | Interface | Unified XP + Rep bar w/ mouseover text. |
| LootRollInfo | QoL | Per-option roll counters + tooltips. |
| InfoBar | QoL | FPS / latency / durability micro bar. |
| QuickConfirm | QoL | Auto-confirm select safe popups. |
| ChatFilters | QoL | Suppress spam (errors, money repeats, first /played). |
| WAAdiFixes | Extras | Small compat shims (WA / AdiBags). |
| BackgroundFPSFix | Extras | Adjustable background FPS cap. |

## Install

1. Put folder named `YATP` into `Interface/AddOns`.
2. Restart or /reload.
3. `/yatp` to open config.

Hubs: Interface / Quality of Life / Extras (Tweaks subgroup inside Extras). Each module adds its own panel.

## Slash Commands

```bash
/yatp           # Open main configuration
/yatp modules   # List registered modules
/yatp reload    # Reload the UI
/yatp debug     # Toggle global debug
```
Modules may expose short extra slash commands.

## Localization
Fallback enUS, optional overrides in `locales/`. Missing keys fall back safely.

## Dev
Copy `modules/Template.lua`, rename, set `defaults`, implement `:OnInitialize()`, `:OnEnable()`, optional `:BuildOptions()`. Register via `YATP:NewModule()` then `YATP:AddModuleOptions()`.

State: single AceDB root `YATP_DB.profile.modules[ModuleName]`. Migrations pull from older standalone SVs when found.

## Contributing
Open issue / PR. Keep changes module‑scoped, avoid editing vendored libs. Test with a fresh profile.

## Credits
Ace3, LibSharedMedia, plus original micro‑addons merged (NoBubbles, BetterBuffs, etc.).

## Related Ascension Addons

- MoveAnything (Ascension Fork): <https://github.com/zavahcodes/MoveAnything>

## More Info

Changelog: `CHANGELOG.md` · Roadmap: `docs/ROADMAP.md` · Ideas: `docs/IDEAS.md`

Enjoy a cleaner UI.
