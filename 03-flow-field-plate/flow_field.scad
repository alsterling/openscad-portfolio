// flow_field.scad — Generic parametric serpentine flow-field plate
// Inspired by fuel-cell / electrolyzer hardware concepts. This is a generic
// parametric CAD demonstration — NOT a proprietary design and NOT a
// production-ready electrochemical design. Units: mm.
//
// The serpentine is built as a 2D mask generated programmatically from the
// parameters (straight passes + rounded 180-degree U-turns + round port pads),
// then extruded down into the plate top face.

/* ------------------------- Parameters ------------------------- */

plate        = [80, 80, 6]; // mm, plate L x W x thickness
chan_w       = 1.2;         // mm, channel width
land_w       = 1.2;         // mm, rib/land width between adjacent passes
chan_d       = 0.8;         // mm, channel depth (must be < plate thickness)
passes       = 12;          // number of serpentine straight passes
seal_land    = 6;           // mm, flat gasket/seal margin around active area
bend_r       = chan_w;      // mm, baseline (minimum) U-turn centerline radius
port_d       = 4;           // mm, inlet/outlet port hole diameter
bolt_d       = 4;           // mm, bolt hole diameter
bolt_n       = 8;           // number of bolt holes (multiple of 4)
bolt_margin  = 5;           // mm, bolt center inset from the outer edge
corner_r     = 3;           // mm, plate outside corner radius
show_section = false;       // true cuts the plate at the port line (verify only)
show_ports   = true;        // cut inlet/outlet through-ports
show_bolts   = true;        // cut perimeter bolt holes

// Presentation only (render-time; must be excluded from STL exports)
show_visual_overlays = true;        // render-only channel/port color overlays
col_plate    = [0.80, 0.80, 0.82];  // plate body: light neutral gray
col_channel  = [0.30, 0.52, 0.58];  // channel inlay: muted teal

$fn = 32; // iteration quality; override with -D '$fn=96' for final renders/exports

/* ------------------- Derived values (no edit) ------------------ */

eps     = 0.01;                            // mm, overshoot for difference() cuts
active  = [plate.x - 2*seal_land,          // active area inside the seal land
           plate.y - 2*seal_land];
pitch   = chan_w + land_w;                 // mm, pass centerline spacing
// U-turn centerline radius. pitch/2 is the only radius whose semicircle
// connects adjacent passes, so bend_r acts as a baseline request: if it
// exceeds pitch/2 it is clamped (with a console warning), never honored.
r_bend  = pitch/2;
serp_w  = (passes - 1) * pitch;            // mm, centerline span across passes
pad_d   = port_d + chan_w;                 // mm, round pad at each channel end
// Keep U-turns and port pads inside the active area:
end_margin = max(r_bend, pad_d/2) + chan_w/2;
hs      = active.y/2 - end_margin;         // mm, straight pass half-length
xs      = [for (i = [0:passes-1]) -serp_w/2 + i*pitch]; // pass centerlines
// Free channel ends: first pass always ends at the bottom; the last pass
// ends bottom for even pass counts, top for odd.
port_pts = [[xs[0], -hs], [xs[passes-1], (passes % 2 == 0) ? -hs : hs]];

/* --------------------------- Asserts --------------------------- */

assert(chan_d < plate[2], "channel depth must be less than plate thickness");
assert(passes >= 2, "need at least 2 serpentine passes");
assert(chan_w > 0 && land_w > 0, "channel and land widths must be > 0");
assert(serp_w + chan_w <= active.x,
       "active area too narrow: reduce passes, chan_w or land_w");
assert(hs > pad_d, "active area too short for bends, pads and a useful pass");
if (bend_r > r_bend + eps)
    echo(str("WARNING: bend_r=", bend_r, " exceeds pitch/2=", r_bend,
             "; U-turn radius clamped to pitch/2 to keep passes connected."));
assert(port_d > 0 && port_d < 2*end_margin, "bad port diameter");
assert(bolt_n >= 4 && bolt_n % 4 == 0, "bolt_n must be a positive multiple of 4");
assert(bolt_margin + bolt_d/2 < min(plate.x, plate.y)/2, "bolts off the plate");

/* --------------------------- Modules --------------------------- */

// 2D rounded rectangle centered at origin
module rrect_c(size, r) {
    if (r > 0) offset(r = r) square([size.x - 2*r, size.y - 2*r], center = true);
    else       square(size, center = true);
}

// Solid plate blank with rounded corners, centered, bottom on z=0
module plate_body() {
    linear_extrude(height = plate.z) rrect_c([plate.x, plate.y], corner_r);
}

// One continuous 2D serpentine mask: capsule passes, half-annulus U-turns,
// and a round port pad at each free end. Centered on the active area.
module serpentine_path_2d() {
    // straight passes as capsules (rounded ends merge into bends and pads)
    for (x = xs)
        hull() for (y = [-hs, hs]) translate([x, y]) circle(d = chan_w);
    // 180-degree U-turns between pass i and i+1, alternating top/bottom
    for (i = [0:passes-2]) {
        top = (i % 2 == 0);
        cx  = xs[i] + pitch/2;
        cy  = top ? hs : -hs;
        ro  = r_bend + chan_w/2;
        ri  = r_bend - chan_w/2;
        intersection() {
            translate([cx, cy]) difference() {
                circle(r = ro);
                if (ri > 0) circle(r = ri);
            }
            // keep only the half that arcs beyond the straight pass ends
            translate([cx - ro, top ? cy : cy - ro - eps])
                square([2*ro, ro + eps]);
        }
    }
    // round pads where the ports meet the channel ends
    for (p = port_pts) translate(p) circle(d = pad_d);
}

// Serpentine mask extruded down into the plate top face by chan_d
module channel_cut() {
    translate([0, 0, plate.z - chan_d])
        linear_extrude(height = chan_d + eps)
            serpentine_path_2d();
}

// Inlet/outlet through-ports: bottom face up to the channel floor
module port_cuts() {
    for (p = port_pts)
        translate([p.x, p.y, -eps])
            cylinder(d = port_d, h = plate.z - chan_d + 2*eps);
}

// bolt_n through-holes on a rectangular ring inset bolt_margin from the edge
module bolt_holes() {
    hx = plate.x/2 - bolt_margin;
    hy = plate.y/2 - bolt_margin;
    k  = bolt_n / 4;   // bolts per side (corner included once per side)
    pts = [for (s = [0:3], j = [0:k-1])
           let (t = -1 + 2*j/k)
           s == 0 ? [ t*hx, -hy] :
           s == 1 ? [ hx,  t*hy] :
           s == 2 ? [-t*hx,  hy] :
                    [-hx, -t*hy]];
    for (p = pts)
        translate([p.x, p.y, -eps])
            cylinder(d = bolt_d, h = plate.z + 2*eps);
}

// Verification-only cutaway through the port centerline (y = -hs)
module section_cut() {
    translate([-plate.x/2 - eps, -plate.y/2 - eps, -eps])
        cube([plate.x + 2*eps, plate.y/2 - hs + eps, plate.z + 2*eps]);
}

// RENDER-ONLY teal inlay resting on the channel floor so the serpentine reads
// clearly in photos. Slightly inset and lifted to avoid z-fighting, cut away
// around the port bores (no floating color over voids) and by the section cut.
// Never part of the STL: exports must use show_visual_overlays=false.
module channel_overlay() {
    ov_inset = 0.05;                       // mm, side inset from channel walls
    ov_lift  = 0.02;                       // mm, lift off the channel floor
    ov_top   = 0.15;                       // mm, kept below the plate top face
    difference() {
        translate([0, 0, plate.z - chan_d + ov_lift])
            linear_extrude(height = chan_d - ov_top - ov_lift)
                difference() {
                    offset(r = -ov_inset) serpentine_path_2d();
                    for (p = port_pts)
                        translate(p) circle(d = port_d + 2*ov_inset);
                }
        if (show_section) section_cut();
    }
}

// Complete plate: blank minus channels, ports, bolts (and section if verifying)
module flow_plate() {
    difference() {
        plate_body();
        channel_cut();
        if (show_ports) port_cuts();
        if (show_bolts) bolt_holes();
        if (show_section) section_cut();
    }
}

/* -------------------------- Top level -------------------------- */

color(col_plate) flow_plate();
if (show_visual_overlays) color(col_channel) channel_overlay();
