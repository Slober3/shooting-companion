# Precision editor

## Interaction model

- **Plaatsen**: every valid short tap creates a distinct impact, including an
  exact overlap. Existing marker hit areas are ignored.
- **Bewerken**: marker taps select; marker drags move; empty-space drags pan.
  Candidate selection uses screen distance and newest-first tie breaking.
- **Precisie**: the scene moves underneath a fixed crosshair. `Punt plaatsen`
  confirms the crosshair position; the crosshair itself is only preview state.
- **Punten**: lists every impact and miss, making exact overlaps and positionless
  misses independently reachable.

The fixed marker glyph, number and selection halo remain readable while zooming.
The translucent projectile outline stays in scene space and therefore represents
the physical calibre at the current zoom.

## Undo and autosave

The editor stores at most 50 in-memory model snapshots. Add, move, delete,
multiplicity, miss and clear are reversible; one complete drag is one step and a
cancelled/invalid drag restores its start position. Zoom, pan and selection are
not mutations. Debounced autosave exposes Changed, Saving, Saved and Failed
states; failed saves have an explicit retry action.

## Photo realignment

Only impacts linked to the primary image and carrying normalized image
coordinates are remapped. The UI shows old/new totals before confirmation.
Alignment, remapped impacts and series aggregates are written in one database
transaction; original photos remain immutable.
