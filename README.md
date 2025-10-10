# YATP – Yet Another Tweaks Pack

Modular QoL + UI tweaks for WoW 3.3.5 (Ascension / BronzeBeard). Ace3 based. Enable only what you want.

## Modules

| Module | Hub | Summary |
|--------|-----|---------|
| ChatBubbles | Interface | Restyle & clean chat bubbles (migrates NoBubbles). |
| Hotkeys | Interface | Hotkey font + range / mana tinting. |
| PlayerAuras | Interface | (Temporarily disabled) Buff/debuff layout: scale, rows, growth, sorting, duration styling. |
| PlayerAuraFilter | Interface | (Temporarily disabled) Simple name-based hide list for player buffs. |
| XPRepBar | Interface | Unified XP + Rep bar w/ mouseover text, animated spark indicator & multi-client level detection. |
| LootRollInfo | QoL | Per-option roll counters + tooltips. |
| InfoBar | QoL | FPS / latency / durability micro bar. |
| QuickConfirm | QoL | Auto-confirm transmog & bind-on-pickup loot popups. |
| ChatFilters | QoL | Suppress spam (error lines, login welcome, first /played). |
| WAAdiFixes | Extras | Small compat shims (WA / AdiBags). |
| BackgroundFPSFix | Extras | Adjustable background FPS cap. |
| Target Border | Ascension NamePlates | Colored border around current target nameplate. Configurable color & thickness. |
| Threat System | Ascension NamePlates | Color nameplates by threat level (party/raid only). Configurable colors for low/medium/high/tanking. |
| Health Text Position | Ascension NamePlates | Fine-tune health text position with X/Y offsets (-50 to +50, -20 to +20 pixels). |
| Global Health Texture | Ascension NamePlates | Override health bar texture for ALL nameplate types (friendly/enemy/personal). |

## Install

1. Put folder named `YATP` into `Interface/AddOns`.
2. Restart (or /reload if updating).
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

*Modified/adapted/improved addons specifically for BronzeBeard server:*

- **AdiBags**: <https://github.com/zavahcodes/AdiBags> - Smart bag sorting and filtering
- **AdiBags Ascension**: <https://github.com/zavahcodes/AdiBags_Ascension> - Ascension-specific AdiBags modules
- **pfQuest**: <https://github.com/zavahcodes/pfQuest> - Enhanced quest helper and database
- **EasyFrames**: <https://github.com/zavahcodes/EasyFrames> - Unit frame customization and styling
- **MoveAnything**: <https://github.com/zavahcodes/MoveAnything> - Frame positioning tool

## More Info

Changelog: `CHANGELOG.md` · Roadmap: `docs/ROADMAP.md` · Ideas: `docs/IDEAS.md`

Enjoy a cleaner UI.
