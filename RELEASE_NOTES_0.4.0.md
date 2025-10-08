# v0.4.0 – Performance consolidation & interval control

**Highlights**
- Central scheduler replaces multiple scattered OnUpdate loops (lower idle CPU).
- Hotkeys: interval slider (0.10–0.40s) + `/yatphotkint <seconds>` for faster range tint updates.
- Removed aggressive chat bubble scanning (event + limited post-sweeps only now).
- QuickConfirm narrowed to transmog confirmations only (exit auto-confirm removed).
- Pruned unused localization keys (aggressive scan / exit) for leaner memory.
- Instant one-pass recolor when changing the Hotkeys interval.
- Removed temporary target-change burst logic (predictable steady cadence).
- Removed obsolete ChatFilters loot money filtering option.

**Install / Update**
1. Extract folder so it is exactly `Interface/AddOns/YATP`.
2. `/reload` or restart client.
3. Adjust Hotkeys interval in: /yatp > Interface > Hotkeys > Icon Tint.

**Verification**
- `/yatp` opens without errors.
- Range tint reacts within chosen interval (default 0.15s).
- Transmog popup auto-confirms.
- No missing locale warnings.

**Roadmap (Short)**
- 0.4.x: Scheduler stats panel; minor PlayerAuras search perf.
- 0.5.0: Config export/import; optional adaptive Hotkeys interval; lightweight perf overlay.
