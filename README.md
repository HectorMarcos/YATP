# YATP – Yet Another Tweaks Pack

Modular QoL + UI tweaks for WoW 3.3.5 (Ascension / BronzeBeard). Ace3 based. Enable only what you want.

## Modules

| Module | Hub | Summary |
|--------|-----|---------|
| ChatBubbles | Interface | Restyle & clean chat bubbles (migrates NoBubbles). |
| Hotkeys | Interface | Hotkey font + range / mana tinting. |
| PlayerAuras | Interface | (Temporarily disabled) Buff/debuff layout: scale, rows, growth, sorting, duration styling. |
| PlayerAuraFilter | Interface | (Temporarily disabled) Simple name-based hide list for player buffs. |
| QuestTracker | Interface | Enhanced quest tracking: levels, colors, auto-indentation, smart tracking modes, positioning & visual customization. |
| XPRepBar | Interface | Unified XP + Rep bar w/ mouseover text, animated spark indicator & multi-client level detection. |
| LootRollInfo | QoL | Per-option roll counters + tooltips. |
| InfoBar | QoL | FPS / latency / durability micro bar. |
| QuickConfirm | QoL | Auto-confirm transmog & bind-on-pickup loot popups. |
| ChatFilters | QoL | Suppress spam (error lines, login welcome, first /played). |
| WAAdiFixes | Extras | Small compat shims (WA / AdiBags). |
| BackgroundFPSFix | Extras | Adjustable background FPS cap. |
| Target Border | Ascension NamePlates | Colored border around current target nameplate. Configurable color & thickness. |
| Target Arrows | Ascension NamePlates | Arrow indicators on both sides of target nameplate pointing inward. Configurable size, distance, offset & color. |
| Non-Target Alpha Fade | Ascension NamePlates | Reduce opacity of non-targeted nameplates for improved focus. Only active when target exists. |
| Mouseover Border Block | Ascension NamePlates | Forces all nameplate borders to remain black, eliminating white/yellow glow on mouseover. Always-on with frame-by-frame enforcement. |
| Mouseover Health Highlight | Ascension NamePlates | Subtle white tint on health bar when mousing over non-target nameplates. Configurable tint amount (default 50%). |
| Threat System | Ascension NamePlates | Color nameplates by threat level (party/raid only). Configurable colors for low/medium/high/tanking. |
| Health Text Position | Ascension NamePlates | Fine-tune health text position with X/Y offsets (-50 to +50, -20 to +20 pixels). |
| Global Health Texture | Ascension NamePlates | Override health bar texture for ALL nameplate types (friendly/enemy/personal). |
| Quest Icons | Ascension NamePlates | Custom quest objective icons with tooltip scanning. Auto-hides when complete. Replaces native icons. Configurable size & position. |

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

## Quest Tracker Details

**QuestTracker** is a comprehensive quest tracking enhancement module designed specifically for WoW 3.3.5 (Ascension). It provides a clean, unified approach to quest display and management.

### Key Features

- **Quest Level Display**: Show `[Level] QuestTitle` format with toggle control
- **Difficulty Color Coding**: Standard WoW colors (Red/Orange/Yellow/Green/Gray) based on level difference
- **Smart Objective Indentation**: Automatic 4-space indentation for better visual hierarchy
- **Intelligent Auto-Tracking**: Two modes - "All Quests" or "By Zone" (+ always track Ascension categories)
- **Path to Ascension Integration**: Special handling for Ascension server's unique quest chains
- **Custom Positioning**: Drag-and-drop repositioning with position locking
- **Visual Customization**: Text outline, background hiding, custom frame height (300-1000px)
- **Objective Text Management**: Smart truncation for long objectives (>100 chars) with word-boundary detection

### Technical Highlights

- **Dash-Based Detection**: Uses `dash.text == "-"` pattern for 100% accurate quest title vs objective identification
- **Unified Processing**: Single `ApplyAllTextEnhancements()` function eliminates race conditions and duplicate processing
- **SexyMap Compatibility**: Comprehensive position management hooks for seamless addon interaction
- **Production Ready**: 24% code reduction (515 lines removed) with full functionality maintained
- **Zero Debug Overhead**: All debugging code removed for optimal performance

### Configuration

Access via `/yatp` → Interface Hub → Quest Tracker. All options apply immediately without requiring `/reload`.

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
