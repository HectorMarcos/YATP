# Idea Parking Lot

Concise backlog of potential ideas (non-binding). Priority formula: `(Impact*2) - Effort - Risk`.

Scales: Impact (1-3), Effort (1-3), Risk (1-3). Status: seed | explore | spec | queued.

Only pending items are listed (shipped removed). Keep each idea short.

## Modules / Features (Ordered)

### Priority 2

Highest current priority (score 2). Internal ordering: Impact desc, then Effort asc.

### PlayerAuraFilter Rewrite From Scratch

Status: seed  
Problem: Existing PlayerAuraFilter code is incremental and hard to extend (complex condition chains, limited performance profiling, difficult to share/import rules).  
Proposal: Full rewrite with a normalized rule model (include/exclude lists, tagging, fast hash lookups) and clear API for modules to register temporary filters. Add import/export alignment with planned blacklist feature.  
Notes: Plan phased migration: build new engine side-by-side, mirror outputs, then flip. Include benchmarking hooks.  
Score: I=3 E=2 R=2 -> Priority=2

### Auto Item Compare Hover
 
Status: seed  
Problem: Players must hold Shift (or the configured modifier) every time to see side-by-side comparison when mousing over equippable items, adding friction to quick loot evaluation.  
Proposal: Automatically show equipped item comparison tooltips on hover for equippable gear without requiring the modifier key (simulate modifier or call comparison API). Provide a toggle and optional key to suppress (e.g. hold Alt to hide compare).  
Notes: Hook GameTooltip `OnTooltipSetItem` and call `GameTooltip_ShowCompareItem()` if not already shown; ensure it respects in-combat restrictions and doesn't conflict with other tooltip addons. Add throttle to avoid re-calling on same hyperlink.  
Score (recalc): I=2 E=1 R=1 -> Priority=2

### Hunter Pet Whistle Suppression
 
Status: seed  
Problem: Repeated hunter pet summon whistle is aurally fatiguing when calling/dismissing frequently (macro spam, arena prep), offering no new information after first confirmation.  
Proposal: Optional toggle to suppress (filter) the specific whistle soundKitID while enabled. Lightweight debug sub-option to log sound IDs once to help identify the correct one before silencing.  
Notes: Wrap PlaySound/PlaySoundFile, early-return on matched ID; cache original to avoid taint. Provide fallback in case the ID changes (log mode). Guard re-entrancy and avoid touching other channels.  
Score (draft): I=2 E=1 R=1 -> Priority=2

### Priority 1

Ideas with priority 1 (score 1) or manually promoted. Ordered: higher Impact first; for equal Impact, lower Effort/Risk; then alphabetical.

### PlayerAuras Rewrite From Scratch

Status: seed  
Problem: Current PlayerAuras module has accumulated ad-hoc formatting, update throttling, and duration logic making maintenance and feature additions (e.g., compact formatting, advanced sorting, future performance micro-panel hooks) harder; performance during large raid aura churn spikes.  
Proposal: Re-architect with a virtualized aura model, diff-based frame updates, unified formatting utilities, and configuration schema supporting future grouping/sorting. Provide clean separation of data acquisition, filtering, and rendering layers.  
Notes: High effort & risk; must ensure parity (visibility, timers, filtering) before replacement. Build shadow mode for validation.  
Score: I=3 E=3 R=2 -> Priority=1

### Performance Profiler Micro-Panel
 
Status: seed  
Problem: Default minimap clutter & inconsistent scaling across UIs.  
Proposal: Module to unify border, hide zone text until hover, add quick toggles (tracking, difficulty).  
Notes: Could optionally consolidate minimap button cleanup.  
Score (recalc): I=2 E=2 R=1 -> Priority=1

### Reaction Skills Warning
 
Status: seed  
Problem: Sharing custom aura filters between players is manual.  
Proposal: Export to compressed string & import (AceSerializer + LibDeflate).  
Notes: Security note: sanitize length.  
Score (recalc): I=2 E=2 R=1 -> Priority=1

### Aura Blacklist Import / Export
 
Status: seed  
Problem: Players resize Blizzard frames manually each session.  
Proposal: Store & restore scale for selected frames (Map, Who, LFG, etc.).  
Notes: Provide reset & safe minimum/maximum clamps.  
Score (recalc): I=2 E=2 R=1 -> Priority=1

### Compact Minimap Enhancer
 
Status: seed  
Problem: Players miss reactive abilities (proc / aura triggers) if they don't run WeakAuras.  
Proposal: Editable spell list that triggers a glow / border highlight on its action button when conditions are met (aura active, usable, off cooldown).  
Notes: Use `UNIT_AURA`, `ACTIONBAR_UPDATE_COOLDOWN`; reuse Blizzard overlay glow (`ActionButton_ShowOverlayGlow`); avoid creating extra frames.  
Score (recalc): I=3 E=3 R=2 -> Priority=1

### Frame Scale Memory
 
Status: seed  
Problem: Users suspect addon cost but no at-a-glance info.  
Proposal: On-demand panel listing per-module update counts / cpu (if profiling enabled).  
Notes: Needs conditional use of `UpdateAddOnCPUUsage`.  
Score (recalc): I=3 E=3 R=2 -> Priority=1

### Party Member Names Only

Status: seed  
Problem: In crowded zones or dungeons with many players, it's hard to visually pick out party members because all other player overhead names are hidden globally; user wants ONLY party member overhead names visible while all non-party remain suppressed.  
Proposal: Override Blizzard name display logic: keep global player names disabled, but on `GROUP_ROSTER_UPDATE` + proximity/nameplate/name update events, selectively show overhead names for current party members (not relying on nameplates, just the floating overhead name). Hide them when party disbands or member leaves. Config option to always show in dungeons only / everywhere.  
Notes: Likely leverages `SetCVar("UnitNamePlayerPVPTitle", 0)` style CVars plus direct frame name region toggling on party member units; must avoid taint in combat and handle dynamic join/leave. Provide lightweight cache to avoid constant toggling.  
Score: I=2 E=2 R=1 -> Priority=1

### Priority 0

### Buff Duration Compact Formatting

Status: seed  
Problem: Buff duration text shows a space between value and unit ("23 m"), wasting horizontal space and causing slight alignment jitter.  
Proposal: Normalize formatting to compact style ("23m", "45s", "2h") in PlayerAuras (and any other duration displays) while preserving color logic.  
Notes: Adjust duration formatting function to strip spaces before unit; verify it doesn't break localization (handle singular vs plural gracefully). Consider an option if users prefer spaced style.  
Score (recalc): I=1 E=1 R=1 -> Priority=0

### Negative Priority (Re-evaluate / Needs Justification)

Items where cost + risk > impact; keep only if scope can be redefined. (Currently none.)


