# Roadmap

High-level view of how raw ideas become shipped features. This is intentionally lightweight; deeper specs live in ad-hoc design docs when needed.

## Stages
1. Idea (in `docs/IDEAS.md`).
2. Specification (problem statement + acceptance + rough data structures).
3. Planned (slotted for a target version).
4. In Progress (actively being implemented on `main` or a feature branch).
5. Shipped (released in a tagged version, reflected in `CHANGELOG.md`).

## Promotion Criteria
- Clear user problem articulated.
- No simpler existing solution already in the addon.
- Complexity fits within upcoming version scope.
- Low coupling or justified core changes.
- Acceptance tests bullet list written.

## Version Buckets (Tentative)
### 0.3 (Next)
- (placeholder) Select 1–2 quick wins from IDEAS with high Impact / low Effort.
- Possibly: Aura Blacklist Import/Export.

### 0.4
- DataBroker Bridge (conditional loading).
- Frame Scale Memory utility.

### 0.5
- Performance Profiler Micro-Panel (depends on validation of CPU cost benefits).

### 1.0 Goal Themes
- Stable API for module lifecycle helpers.
- Comprehensive localization coverage (at least 3 extra locales).
- Export/import for key module profiles.
- Polished documentation & in-game help panel.

## Tracking
When moving an item forward, reference its short title in commits, e.g.:
```
feat(aura-filters): add blacklist export serialization
```
Then add the change under `[Unreleased]` in `CHANGELOG.md`.

## Deferral / Dropping
If an idea repeatedly stalls (e.g. >3 versions), note a reason instead of silently removing:
```
Dropped: DataBroker Bridge (overlap with external LDB plugins, minimal extra value)
```

## Notes
- Keep roadmap flexible: actual delivery may shift if bugs / regressions appear.
- Favor small increments over large monolithic drops.
