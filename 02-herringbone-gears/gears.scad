// gears.scad — Meshing herringbone double-helical gear pair on a display baseplate
// Requires BOSL2 (https://github.com/BelfrySCAD/BOSL2). Units: mm.
// Center distance comes from BOSL2 gear_dist() — never hand-computed.
// Display/demo assembly, not a load-rated mechanical design.

include <BOSL2/std.scad>
include <BOSL2/gears.scad>

/* ------------------------- Parameters ------------------------- */

mod            = 2;      // mm, gear module (tooth size)
teeth_a        = 18;     // tooth count, pinion (gear A)
teeth_b        = 30;     // tooth count, wheel (gear B)
thickness      = 8;      // mm, gear face width
helix          = 25;     // degrees, helix angle of each herringbone half
bore           = 5;      // mm, center bore diameter
hub            = true;   // add a raised hub around the bore on each gear
hub_d_extra    = 6;      // mm, added to bore diameter for the hub OD
hub_h          = 2;      // mm, hub height above the gear face
show_baseplate = true;   // include baseplate + posts in the assembly
base_th        = 3;      // mm, baseplate thickness
base_margin    = 6;      // mm, baseplate margin beyond the gear tips
base_round     = 4;      // mm, baseplate corner rounding
post_clearance = 0.25;   // mm, diametral clearance between post and bore
show           = "assembly"; // "assembly" | "gearA" | "gearB"

// Presentation colors (render-only; color() never affects STL geometry)
col_gear_a     = [0.55, 0.62, 0.72]; // pinion: muted steel blue-gray
col_gear_b     = [0.76, 0.68, 0.50]; // wheel: muted brass-like tan
col_plate      = [0.36, 0.36, 0.39]; // baseplate/posts: neutral dark gray
hub_shade      = 0.85;               // hubs: same hue, slightly darker

$fn = 32; // iteration quality; override with -D '$fn=96' for final renders/exports

/* ------------------- Derived values (no edit) ------------------ */

eps = 0.01;                       // mm, overshoot for difference() cuts
// Center distance for this external parallel-axis pair (BOSL2, includes
// any automatic profile shift). helical takes the magnitude of the angle.
ctr_dist   = gear_dist(mod=mod, teeth1=teeth_a, teeth2=teeth_b, helical=helix);
mesh_phase = 180/teeth_b;         // deg, half-tooth spin so B's gap faces A's tooth
tip_r_a    = outer_radius(mod=mod, teeth=teeth_a, helical=helix);
tip_r_b    = outer_radius(mod=mod, teeth=teeth_b, helical=helix);
post_d     = bore - post_clearance;             // mm, display post diameter
post_h     = base_th + thickness + hub_h;       // mm, post top flush with hub top
plate_l    = ctr_dist + tip_r_a + tip_r_b + 2*base_margin; // plate size in X
plate_w    = 2*max(tip_r_a, tip_r_b) + 2*base_margin;      // plate size in Y
plate_cx   = (ctr_dist + tip_r_b - tip_r_a)/2;  // plate center between gear tips

/* --------------------------- Asserts --------------------------- */

assert(mod > 0, "mod must be > 0");
assert(teeth_a > 8 && teeth_b > 8, "teeth counts must be > 8");
assert(thickness > 0, "thickness must be > 0");
assert(bore > 0, "bore must be > 0");
assert(post_clearance >= 0 && post_clearance < bore, "bad post_clearance");
assert(hub_d_extra > 0 && hub_h >= 0, "bad hub dimensions");

/* --------------------------- Modules --------------------------- */

// Raised hub ring around the bore, sits on top of a gear face
module hub() {
    difference() {
        cyl(d = bore + hub_d_extra, h = hub_h, anchor = BOTTOM);
        translate([0, 0, -eps])
            cyl(d = bore, h = hub_h + 2*eps, anchor = BOTTOM);
    }
}

// Pinion: +helix herringbone, bore through, optional hub. Bottom face on z=0.
module gearA() {
    color(col_gear_a)
        spur_gear(mod = mod, teeth = teeth_a, thickness = thickness,
                  helical = helix, herringbone = true,
                  shaft_diam = bore, anchor = BOTTOM);
    if (hub)
        color(col_gear_a * hub_shade)
            translate([0, 0, thickness - eps]) hub();
}

// Wheel: -helix herringbone (opposite hand so the pair meshes on parallel axes)
module gearB() {
    color(col_gear_b)
        spur_gear(mod = mod, teeth = teeth_b, thickness = thickness,
                  helical = -helix, herringbone = true,
                  shaft_diam = bore, anchor = BOTTOM);
    if (hub)
        color(col_gear_b * hub_shade)
            translate([0, 0, thickness - eps]) hub();
}

// Rounded display plate with one post at each gear center
module baseplate() {
    color(col_plate) {
    translate([plate_cx, 0, 0])
        cuboid([plate_l, plate_w, base_th],
               rounding = base_round, edges = "Z", anchor = BOTTOM);
    for (x = [0, ctr_dist])
        translate([x, 0, 0])
            cyl(d = post_d, h = post_h, anchor = BOTTOM);
    }
}

// Both gears meshed at gear_dist() spacing, sitting on the baseplate posts
module assembly() {
    if (show_baseplate) baseplate();
    up(base_th) {
        gearA();
        right(ctr_dist) zrot(mesh_phase) gearB();
    }
}

/* -------------------------- Top level -------------------------- */

if (show == "gearA")      gearA();
else if (show == "gearB") gearB();
else                      assembly();
