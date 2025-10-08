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

```text
### <Idea Title>
Status: seed | explore | spec | queued
Problem: <what user pain / limitation exists>
Proposal: <short solution concept>
Notes: <integration points, libs, edge cases>
Score: I=?, E=?, R=? -> Priority=?
```

---

## Modules / Features (Ordered)

> Priority formula recalculated: `Priority = (Impact * 2) - Effort - Risk`. Negative values allowed (indicate low leverage). Historical shipped items moved to a separate section.

### Priority 2

These score highest by formula (2). Focus first among seeds.
 
<!-- Moved to Historical (shipped as BackgroundFPSFix module in 0.3.1) -->

<!-- ChatFilters: Loot Coin Spam Suppression (moved to Historical; implemented as simple full suppression without summary/threshold) -->

### ChatFilters: Loot Item Quality Filtering

Status: seed
Problem: Chat gets flooded with low‑value item loot messages (white/grey/green quality) during farming, making it harder to notice important (rare/epic, quest, or gatherable) drops.
Proposal: Extend ChatFilters to optionally suppress item loot lines below a configurable quality threshold (e.g. hide <= Uncommon). Always allow: quest items (flagged by quality or special text), profession gathering results (herbs, ore, skins) and bind‑on‑pickup rare+ items. Provide a simple threshold slider (Poor/Common/Uncommon/Rare/Epic) plus checkboxes to force‑show quest & gather items.
Notes: Need reliable parsing of item links: extract itemID via pattern, query GetItemInfo for quality (may require delayed cache handling). Avoid hiding group loot roll announcements. Consider a short queue to retry unknown item qualities until cached.
Score (draft): I=2 E=3 R=2 -> Priority= -1 (could rise if combined with summary of counts like “Hidden: 27 common items”).


<!-- ChatFilters Bug: Residual Interface Action Failed (moved to Historical; addressed with token + compact matching) -->

<!-- ChatFilters: Suppress Login Welcome Spam (moved to Historical; implemented with first /played auto suppression) -->

### Auto Item Compare Hover

Status: seed  
Problem: Players must hold Shift (or the configured modifier) every time to see side-by-side comparison when mousing over equippable items, adding friction to quick loot evaluation.  
Proposal: Automatically show equipped item comparison tooltips on hover for equippable gear without requiring the modifier key (simulate modifier or call comparison API). Provide a toggle and optional key to suppress (e.g. hold Alt to hide compare).  
Notes: Hook GameTooltip `OnTooltipSetItem` and call `GameTooltip_ShowCompareItem()` if not already shown; ensure it respects in-combat restrictions and doesn't conflict with other tooltip addons. Add throttle to avoid re-calling on same hyperlink.  
Score (recalc): I=2 E=1 R=1 -> Priority=2

### Compact Minimap Enhancer

Status: seed  
Problem: Default minimap clutter & inconsistent scaling across UIs.  
Proposal: Module to unify border, hide zone text until hover, add quick toggles (tracking, difficulty).  
Notes: Could optionally consolidate minimap button cleanup.  
Score (recalc): I=2 E=2 R=1 -> Priority=1 (was 2 manual)

### Aura Blacklist Import / Export

Status: seed  
Problem: Sharing custom aura filters between players is manual.  
Proposal: Export to compressed string & import (AceSerializer + LibDeflate).  
Notes: Security note: sanitize length.  
Score (recalc): I=2 E=2 R=1 -> Priority=1 (was 2 manual)

### Frame Scale Memory

Status: seed  
Problem: Players resize Blizzard frames manually each session.  
Proposal: Store & restore scale for selected frames (Map, Who, LFG, etc.).  
Notes: Provide reset & safe minimum/maximum clamps.  
Score (recalc): I=2 E=2 R=1 -> Priority=1 (was 2 manual)

### Priority 1

Medium leverage or upgraded manually from formula 0/negative.

### Reaction Skills Warning

Status: seed  
Problem: Players miss reactive abilities (proc / aura triggers) if they don't run WeakAuras.  
Proposal: Editable spell list that triggers a glow / border highlight on its action button when conditions are met (aura active, usable, off cooldown).  
Notes: Use `UNIT_AURA`, `ACTIONBAR_UPDATE_COOLDOWN`; reuse Blizzard overlay glow (`ActionButton_ShowOverlayGlow`); avoid creating extra frames.  
Score (recalc): I=3 E=3 R=2 -> Priority=1

### Performance Profiler Micro-Panel

Status: seed  
Problem: Users suspect addon cost but no at-a-glance info.  
Proposal: On-demand panel listing per-module update counts / cpu (if profiling enabled).  
Notes: Needs conditional use of `UpdateAddOnCPUUsage`.  
Score (recalc): I=3 E=3 R=2 -> Priority=1

### Party Name Privacy

Status: seed  
Problem: Player wants to hide other players' names (immersion / screenshots) but still see group/raid members for coordination.  
Proposal: Rewrite non-party names to "Player" or configurable alias except party/raid, target, focus.  
Notes: Hook UNIT_NAME_UPDATE + tooltip / nameplate text substitution. Risk: conflicts with nameplate addons.  
Score (recalc): I=2 E=3 R=2 -> Priority=-1 (was 1 manual)

### Priority 0

Low leverage or deferred.

### DataBroker Bridge

Status: seed  
Problem: Users wanting LDB feeds (latency, fps, durability) for existing panels.  
Proposal: Optional lightweight LDB provider toggled via Extras.  
Notes: Avoid creating if Titan/ChocolateBar not loaded to save cycles.  
Score (recalc): I=2 E=2 R=2 -> Priority=0

### In-Game Profile Snapshot Export

Status: seed  
Problem: Hard to compare config differences across machines.  
Proposal: Serialize enabled modules + key settings into a readable block for pastebin.  
Notes: Reuse same lib pair as blacklist export.  
Score (recalc): I=2 E=3 R=1 -> Priority=0

### Buff Duration Compact Formatting

Status: seed  
Problem: Buff duration text shows a space between value and unit ("23 m"), wasting horizontal space and causing slight alignment jitter.  
Proposal: Normalize formatting to compact style ("23m", "45s", "2h") in PlayerAuras (and any other duration displays) while preserving color logic.  
Notes: Adjust duration formatting function to strip spaces before unit; verify it doesn't break localization (handle singular vs plural gracefully). Consider an option if users prefer spaced style.  
Score (recalc): I=1 E=1 R=1 -> Priority=0

### Negative Priority (Re-evaluate / Needs Justification)

Items where cost + risk outweigh immediate impact per formula.

### Party Name Privacy (duplicate listing for clarity)

See above; formula gives -1. Decide to (a) lower effort via scoping (e.g. only nameplates, not tooltips) or (b) raise impact by bundling screenshot / streamer mode features to justify promotion.

### Historical (Shipped)

Reference of completed ideas (retain for context, remove later if cluttered).

### Chat System Filters (Shipped in 0.3)

Status: shipped  
Solution: Implemented as the `ChatFilters` module (Quality of Life). Future enhancements could add user-defined patterns & counters.  
Score (historic): I=2 E=2 R=1 -> Priority=2

### ChatFilters Enhancements (Shipped incremental through 0.3.x)

Status: shipped  
Solution: Added money loot line suppression (simple hide mode), robust interface action failed / UI error token matching, and login welcome spam + first automatic /played dump suppression (manual /played preserved). Session stats update live; advanced toggles consolidated/hidden.  
Deferred: Summary accumulation + copper threshold modes (initial idea) postponed; potential future re-spec.  
Notes: AddMessage hook retained as legacy hidden escape hatch due to crash risk on some clients.  
Score (historic blended): I=2 E=2 R=2 -> Priority=0 (stabilized, low immediate ROI for further tweaks).

### QuickConfirm: Auto-accept world loot (BOP)
Status: seed
Problem: StaticPopup "Looting [item] will bind it to you." interrupts fast gathering when picking many bind-on-pickup world items.
Proposal: Add a QuickConfirm option to auto-accept world-loot BOP StaticPopups. Detect popups that contain an item link and a bind message, then auto-click Yes. Expose whitelist/blacklist and a "disable in combat" toggle.
Notes: Prefer item-link / BOP flag detection (GetItemInfo / BIND_ON_PICKUP) over exact English text to handle localization. Ensure only loot popups are auto-confirmed and provide a hook so other addons can override.
Score (draft): I=2 E=1 R=1 -> Priority=2
