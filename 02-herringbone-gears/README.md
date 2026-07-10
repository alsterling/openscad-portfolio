# Herringbone Gear Pair (BOSL2)

A meshing herringbone (double-helical) gear pair — an 18-tooth pinion driving a
30-tooth wheel — displayed on posts on a rounded baseplate. Built with the
[BOSL2](https://github.com/BelfrySCAD/BOSL2) gear library: the gears use
`spur_gear(..., herringbone=true)` with opposite helix hands, and the center
distance is computed with `gear_dist()` (never hand-computed), so the pair stays
correctly meshed for any module, tooth counts, or helix angle — including BOSL2's
automatic profile shifting.

![Render](render.png)

## Parameters

| Parameter | Default | Unit | Meaning |
|---|---|---|---|
| `mod` | `2` | mm | Gear module (tooth size) |
| `teeth_a` | `18` | — | Tooth count, pinion (gear A) |
| `teeth_b` | `30` | — | Tooth count, wheel (gear B) |
| `thickness` | `8` | mm | Gear face width |
| `helix` | `25` | deg | Helix angle of each herringbone half |
| `bore` | `5` | mm | Center bore diameter |
| `hub` | `true` | — | Add a raised hub around each bore |
| `hub_d_extra` | `6` | mm | Added to bore diameter for the hub OD |
| `hub_h` | `2` | mm | Hub height above the gear face |
| `show_baseplate` | `true` | — | Include baseplate + posts in the assembly |
| `base_th` | `3` | mm | Baseplate thickness |
| `base_margin` | `6` | mm | Baseplate margin beyond the gear tips |
| `base_round` | `4` | mm | Baseplate corner rounding |
| `post_clearance` | `0.25` | mm | Diametral clearance between post and bore |
| `show` | `"assembly"` | — | `"assembly"`, `"gearA"`, or `"gearB"` |
| `col_gear_a`, `col_gear_b`, `col_plate`, `hub_shade` | muted steel/brass/gray | — | Render-only presentation colors (no effect on STL geometry) |

## Render views

- [render.png](render.png) — isometric portfolio view
- [render_top.png](render_top.png) — top view showing the mesh
- [render_side.png](render_side.png) — side view showing the herringbone chevrons
- [render_detail.png](render_detail.png) — close-up of the mesh zone

## Render / export

```powershell
# Portfolio render (assembly, high quality)
& "C:\Program Files\OpenSCAD\openscad.exe" -o render.png --imgsize=1600,1200 `
  --autocenter --viewall --projection=o --camera=0,0,0,65,0,35,300 `
  -D '$fn=96' gears.scad

# STL exports
& "C:\Program Files\OpenSCAD\openscad.exe" -o gearA.stl -D '$fn=96' -D 'show="gearA"' gears.scad
& "C:\Program Files\OpenSCAD\openscad.exe" -o gearB.stl -D '$fn=96' -D 'show="gearB"' gears.scad
```

## Notes

- The mesh was verified visually from a zoomed top view of the engagement zone
  (teeth interleave with no collision and no gap band) before export.
- The display assembly (posts + plate) is a portfolio visual, not a load-rated
  mechanical design.
