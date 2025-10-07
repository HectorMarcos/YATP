# Idea Parking Lot

Lightweight scratchpad for potential modules, enhancements, or refactors. These are intentionally *not* commitments.

Use this file to jot raw concepts; when an item becomes concrete enough (problem statement + rough scope + acceptance), promote it to the Roadmap.

## Conventions
- Status values: `seed` (just a thought), `explore` (gathering info), `spec` (ready to design), `queued` (candidate for next release window).
- Keep each idea concise (aim < 8 lines) – detailed specs belong in their own design doc.
- Prefer problem-first wording: *"Hard to see debuff types in raid"* instead of *"Add colored borders"*.

## Quick Scoring (Optional)
| Criterion | 1 (Low) | 2 (Med) | 3 (High) |
|-----------|---------|---------|---------|
| Impact    | Minor QoL | Noticeable improvement | Major usability / performance gain |
| Effort    | Trivial | Moderate | Large / multi-module |
| Risk      | Isolated | Some shared code | Touches core architecture |

Compute a draft priority: `(Impact * 2) - Effort - Risk` (higher = better). Purely informal.

## Template
```
### <Idea Title>
Status: seed | explore | spec | queued
Problem: <what user pain / limitation exists>
Proposal: <short solution concept>
Notes: <integration points, libs, edge cases>
Score: I=?, E=?, R=? -> Priority=?
```

---

## Modules / Features (Unsorted)

### Chat System Filters (Shipped in 0.3)
Status: shipped  
Problem: Repetitive interface error lines ("Interface action failed because of an AddOn", UI error variants) spam the chat and distract.  
Solution: Implemented as the `ChatFilters` module (Quality of Life). Substring + token matching with color code stripping suppresses noisy lines; hidden diagnostics available for future expansion.  
Notes: Future enhancements could add user-defined pattern list & summary counters.  
Score (historic): I=2 E=2 R=1 -> Priority=2

### Party Name Privacy
Status: seed  
Problem: Player wants to hide other players' names (immersion / screenshots) but still see group/raid members for coordination.  
Proposal: Rewrite non-party names to "Player" or configurable alias except party/raid, target, focus.  
Notes: Hook UNIT_NAME_UPDATE + tooltip / nameplate text substitution. Risk: conflicts with nameplate addons.  
Score: I=2 E=3 R=2 -> Priority=1

### Background FPS Limit Toggle
Status: seed  
Problem: Background FPS limit too low wastes smoothness (or too high wastes resources).  
Proposal: Expose a slider (0 = no change) for `/console maxfpsbk <n>` plus quick toggle in InfoBar.  
Notes: Store previous value and restore when disabling; optionally consider foreground `maxfps`.  
Score: I=2 E=1 R=1 -> Priority=2

### Reaction Skills Warning
Status: seed  
Problem: Players miss reactive abilities (proc / aura triggers) if they don't run WeakAuras.  
Proposal: Editable spell list that triggers a glow / border highlight on its action button when conditions are met (aura active, usable, off cooldown).  
Notes: Use `UNIT_AURA`, `ACTIONBAR_UPDATE_COOLDOWN`; reuse Blizzard overlay glow (`ActionButton_ShowOverlayGlow`); avoid creating extra frames.  
Score: I=3 E=3 R=2 -> Priority=1


### Compact Minimap Enhancer
Status: seed  
Problem: Default minimap clutter & inconsistent scaling across UIs.  
Proposal: Module to unify border, hide zone text until hover, add quick toggles (tracking, difficulty).  
Notes: Could optionally consolidate minimap button cleanup.  
Score: I=2 E=2 R=1 -> Priority=2

### Aura Blacklist Import / Export
Status: seed  
Problem: Sharing custom aura filters between players is manual.  
Proposal: Export to compressed string & import (AceSerializer + LibDeflate).  
Notes: Security note: sanitize length.  
Score: I=2 E=2 R=1 -> Priority=2

### DataBroker Bridge
Status: seed  
Problem: Users wanting LDB feeds (latency, fps, durability) for existing panels.  
Proposal: Optional lightweight LDB provider toggled via Extras.  
Notes: Avoid creating if Titan/ChocolateBar not loaded to save cycles.  
Score: I=2 E=2 R=2 -> Priority=0

### In-Game Profile Snapshot Export
Status: seed  
Problem: Hard to compare config differences across machines.  
Proposal: Serialize enabled modules + key settings into a readable block for pastebin.  
Notes: Reuse same lib pair as blacklist export.  
Score: I=2 E=3 R=1 -> Priority=0

### Performance Profiler Micro-Panel
Status: seed  
Problem: Users suspect addon cost but no at-a-glance info.  
Proposal: On-demand panel listing per-module update counts / cpu (if profiling enabled).  
Notes: Needs conditional use of `UpdateAddOnCPUUsage`.  
Score: I=3 E=3 R=2 -> Priority=1

### Frame Scale Memory
Status: seed  
Problem: Players resize Blizzard frames manually each session.  
Proposal: Store & restore scale for selected frames (Map, Who, LFG, etc.).  
Notes: Provide reset & safe minimum/maximum clamps.  
Score: I=2 E=2 R=1 -> Priority=2

---

Feel free to append below; keep newest entries at top of each category if they cluster later.
