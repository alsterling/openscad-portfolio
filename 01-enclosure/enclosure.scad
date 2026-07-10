// enclosure.scad — Parametric two-part snap-fit PCB enclosure (base + lid)
// Native OpenSCAD only (no libraries) so the model stays portable.
// Units: mm. Base prints open-side-up; lid is modeled print-flat (lip up).

/* ------------------------- Parameters ------------------------- */

cavity        = [50, 30, 15];  // mm, inner cavity size: L x W x H
wall          = 2;             // mm, wall thickness (sides and floor)
corner_r      = 3;             // mm, outside corner radius
standoff_pts  = [[6,6],[44,6],[6,24],[44,24]]; // mm, PCB standoff centers from inner cavity origin
standoff_d    = 6;             // mm, standoff outer diameter
standoff_h    = 4;             // mm, standoff height above cavity floor
screw_d       = 2.5;           // mm, screw pilot hole diameter
lid_clearance = 0.2;           // mm, fit gap between lid lip and base cavity wall
lid_th        = 2;             // mm, lid plate thickness
lip_h         = 3;             // mm, lid lip height (depth it enters the base)
lip_th        = 1.2;           // mm, lid lip wall thickness
snap_tabs     = true;          // add snap nubs on lip + pockets in base walls
snap_tab_w    = 8;             // mm, snap nub ridge length
snap_tab_h    = 3;             // mm, snap pocket height in base wall
snap_nub      = 0.6;           // mm, snap nub protrusion (ridge radius)
cable_cut     = [12, 6];       // mm, cable notch W x H through one long wall, at base top edge
vents         = true;          // add vent slots in lid top
vent_count    = 5;             // number of vent slots
vent_slot     = [12, 1.2];     // mm, vent slot L x W
vent_pitch    = 4;             // mm, spacing between vent slot centers
assembly_gap  = 10;            // mm, gap between base and lid in "both" layout
part          = "both";        // which part to build: "both" | "base" | "lid"

// Presentation colors (render-only; color() never affects STL geometry)
col_base      = [0.80, 0.80, 0.82]; // base: light neutral gray
col_lid       = [0.64, 0.70, 0.78]; // lid: muted blue-gray

$fn = 32; // iteration quality; override with -D '$fn=96' for final renders/exports

/* ------------------- Derived values (no edit) ------------------ */

eps     = 0.01;                              // mm, overshoot for all cuts
osize   = [cavity.x + 2*wall,                // outer footprint and height
           cavity.y + 2*wall,
           cavity.z + wall];
inner_r = max(corner_r - wall, 0);           // cavity corner radius (uniform wall)
lip_o   = [cavity.x - 2*lid_clearance,       // lip outer footprint
           cavity.y - 2*lid_clearance];
lip_r   = max(inner_r - lid_clearance, 0);   // lip outer corner radius
pilot_depth = standoff_h + wall/2;           // pilot hole depth (halfway into floor)
// Snap nub center, measured down from the lid underside. Midpoint of the
// feasible band: below it the base pocket loses its retention shoulder,
// above it the nub pokes past the lip tip.
nub_zc  = ((lip_h - snap_nub) + snap_tab_h/2) / 2;

/* --------------------------- Asserts --------------------------- */

assert(wall > 0, "wall must be > 0");
assert(lid_clearance >= 0, "lid_clearance must be >= 0");
assert(lid_th > 0 && lip_h > 0 && lip_th > 0, "lid dimensions must be > 0");
assert(corner_r >= 0, "corner_r must be >= 0");
assert(screw_d < standoff_d, "screw pilot must be smaller than standoff");
assert(standoff_h < cavity.z, "standoffs must fit under the lid");
assert(cable_cut.x < cavity.x && cable_cut.y < cavity.z,
       "cable cutout must fit within the wall");
assert(lip_th + lid_clearance < min(cavity.x, cavity.y)/2,
       "lip does not fit in cavity");
assert(!snap_tabs || (lip_h - snap_nub > snap_tab_h/2),
       "snap nub does not fit: increase lip_h or reduce snap_tab_h/snap_nub");
assert(!vents || (vent_slot.x < lip_o.x - 2*lip_th &&
                  (vent_count-1)*vent_pitch + vent_slot.y < lip_o.y - 2*lip_th),
       "vent slots must fit inside the lip");
assert(len([for (p = standoff_pts)
            if (p.x - standoff_d/2 < 0 || p.x + standoff_d/2 > cavity.x ||
                p.y - standoff_d/2 < 0 || p.y + standoff_d/2 > cavity.y) p]) == 0,
       "all standoffs must lie fully inside the cavity");

/* --------------------------- Modules --------------------------- */

// 2D rounded rectangle, corner at origin
module rrect(size, r) {
    if (r > 0)
        translate([r, r]) offset(r = r) square([size.x - 2*r, size.y - 2*r]);
    else
        square(size);
}

// Rounded-corner box, corner at origin
module rounded_box(size, r) {
    linear_extrude(height = size.z) rrect([size.x, size.y], r);
}

// One PCB standoff post (screw pilot is drilled in base(), not here)
module standoff() {
    cylinder(d = standoff_d, h = standoff_h + eps);
}

// Cable notch through the front long wall (y = 0), open at the top edge
module cable_cutout() {
    translate([osize.x/2 - cable_cut.x/2, -eps, osize.z - cable_cut.y])
        cube([cable_cut.x, wall + 2*eps, cable_cut.y + eps]);
}

// One snap nub: horizontal ridge on the lip's outer face, axis along Y
module snap_tab() {
    rotate([-90, 0, 0])
        cylinder(r = snap_nub, h = snap_tab_w, center = true);
}

// Snap pockets carved into the inner faces of the base's short walls
module snap_pockets() {
    pocket = [snap_nub + lid_clearance + eps,           // depth into wall
              snap_tab_w + 2*lid_clearance,             // width along Y
              snap_tab_h];                              // height
    zc = osize.z - nub_zc;                              // engagement height
    for (x = [wall - pocket.x + eps, osize.x - wall - eps])
        translate([x, osize.y/2 - pocket.y/2, zc - pocket.z/2])
            cube(pocket);
}

// Vent slots cut through the lid plate, centered on the plate
module vent_slots() {
    for (i = [0 : vent_count - 1])
        translate([osize.x/2,
                   osize.y/2 + (i - (vent_count - 1)/2) * vent_pitch,
                   -eps])
            linear_extrude(height = lid_th + 2*eps)
                hull()
                    for (sx = [-1, 1])
                        translate([sx * (vent_slot.x - vent_slot.y)/2, 0])
                            circle(d = vent_slot.y);
}

// Base: open-top rounded box + standoffs, minus pilot holes, cable notch, pockets
module base() {
    difference() {
        union() {
            difference() {
                rounded_box(osize, corner_r);
                translate([wall, wall, wall])
                    rounded_box([cavity.x, cavity.y, cavity.z + eps], inner_r);
            }
            for (p = standoff_pts)
                translate([wall + p.x, wall + p.y, wall - eps])
                    standoff();
        }
        for (p = standoff_pts)
            translate([wall + p.x, wall + p.y, wall + standoff_h - pilot_depth])
                cylinder(d = screw_d, h = pilot_depth + eps);
        cable_cutout();
        if (snap_tabs) snap_pockets();
    }
}

// Lid: flat plate + perimeter lip + snap nubs, minus vents.
// Modeled print-flat: outer top face on z=0, lip pointing up.
module lid() {
    difference() {
        union() {
            rounded_box([osize.x, osize.y, lid_th], corner_r);
            translate([wall + lid_clearance, wall + lid_clearance, lid_th - eps])
                linear_extrude(height = lip_h + eps)
                    difference() {
                        rrect(lip_o, lip_r);
                        translate([lip_th, lip_th])
                            rrect([lip_o.x - 2*lip_th, lip_o.y - 2*lip_th],
                                  max(lip_r - lip_th, 0));
                    }
            if (snap_tabs)
                for (x = [wall + lid_clearance, osize.x - wall - lid_clearance])
                    translate([x, osize.y/2, lid_th + nub_zc])
                        snap_tab();
        }
        if (vents) vent_slots();
    }
}

// Base and lid side by side, lid lip-up so the fit is readable
module assembly() {
    color(col_base) base();
    translate([osize.x + assembly_gap, 0, 0]) color(col_lid) lid();
}

/* -------------------------- Top level -------------------------- */

if (part == "base")      color(col_base) base();
else if (part == "lid")  color(col_lid) lid();
else                     assembly();
