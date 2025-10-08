# YATP 0.4.1 Release Notes

Date: 2025-10-08
Tag: v0.4.1

## Highlights

- PlayerAuras module split: filtering logic moved to new PlayerAuraFilter module.
- Both PlayerAuras and PlayerAuraFilter are temporarily disabled pending layout & aura API review.
- Standardized enable/disable UX with reload prompt across modules.
- Added missing localization keys and cleaned deprecated ones.

## Added

- PlayerAuraFilter: standalone name-based buff hide list (currently disabled; clean slate, no migration).
- XPRepBar: master enable toggle.
- ChatBubbles: standardized enable toggle wording.
- Universal reload confirmation dialog after toggling module enable state.

## Changed

- PlayerAuras now layout-only (filter removed) but presently disabled.
- Unified AceAddon enable/disable patterns across modules.
- Consistent tooltips advising /reload.
- Translated remaining Spanish inline comments to English.

## Removed

- Obsolete filtering UI & data (`knownBuffs`) from PlayerAuras.
- ChatBubbles aggressive scan options.
- QuickConfirm legacy exit auto-confirm logic (scope narrowed to transmog confirmations only).
- Hotkeys burst refresh system (steady interval retained).
- ChatFilters legacy loot money filter option.

## Fixed

- Hotkeys interval slider triggers immediate recolor pass.
- Scheduler safely ignores removed option keys (no dangling references).
- Locale warnings resolved (added missing strings).

## Temporary Suspension

- PlayerAuras & PlayerAuraFilter disabled intentionally for this release to avoid confusion while layout & filtering strategy is revisited.

## Internal / Maintenance

- Refactored Hotkeys task to allow future adaptive timing.
- Locales cleaned and synchronized.

Enjoy the update! Report issues or suggestions via GitHub.
