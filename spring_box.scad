// Spring storage box: 317 x 124 x 20 mm, 5 channels, 2-piece box + 2-piece lid
// Each piece fits on a Bambu X1 Carbon bed (256 x 256 mm).
//
// Set `part` below (or use Customizer) to choose what to render:
//   "assembly"    - everything assembled (preview only)
//   "box_a"       - box half A (has dovetail tongues)  -> print flat
//   "box_b"       - box half B (has dovetail pockets)  -> print flat
//   "lid_a"       - lid half A (has tongues)           -> print flat
//   "lid_b"       - lid half B (has pockets)           -> print flat
//   "print_plate" - all four parts laid out (for viewing; each half needs its own
//                   plate or can be arranged in the slicer: 2 x 158.5 > 256)

part = "assembly"; // [assembly, box_a, box_b, lid_a, lid_b, print_plate]

// ---------- Main dimensions (mm) ----------
L = 317;          // overall length
W = 124;          // overall width
H = 20;           // overall height, box + lid together
lid_t = 2;        // lid plate thickness
n_chan = 5;       // number of spring channels (=> n_chan-1 dividers)

// ---------- Walls ----------
side_wall = 2.0;  // long side walls
end_wall  = 4.0;  // short end walls (interior = L - 2*end_wall = 309 for 307 springs)
div_t     = 1.6;  // divider thickness
floor_t   = 3.0;  // floor thickness (holds the dovetails)

// ---------- Lid lip / joints ----------
lip_w   = 1.2;    // lid lip wall thickness
lip_h   = 3.0;    // lid lip depth into box
lip_tol = 0.25;   // clearance between lip and box walls
div_gap = 0.5;    // dividers stop this far below the lip so the lid clears them
tol     = 0.15;   // dovetail clearance per side (tune for your printer)
dt_len  = 9;      // dovetail length (along X)
dt_w1   = 6;      // dovetail narrow width (at the seam)
dt_w2   = 10;     // dovetail wide width (far end)

// ---------- Derived ----------
box_h = H - lid_t;                                            // 18
chan_w = (W - 2*side_wall - (n_chan-1)*div_t) / n_chan;        // ~22.72
half = L / 2;
function chan_y(i) = side_wall + i*(chan_w + div_t);           // start of channel i
function chan_c(i) = chan_y(i) + chan_w/2;                     // centre of channel i
joint_ys = [chan_c(0), chan_c(2), chan_c(4)];                  // dovetails in channels 1,3,5

$fn = 48;
eps = 0.01;

// ---------- Dovetail helpers (sliding direction = Z) ----------
module dovetail_2d(o = 0) {
    // narrow at the seam (x=0), wide at the far end; o grows it for pockets
    offset(delta = o)
        polygon([[0, -dt_w1/2], [dt_len, -dt_w2/2], [dt_len, dt_w2/2], [0, dt_w1/2]]);
}
module tongues(t) {
    for (y = joint_ys)
        translate([half, y, 0]) linear_extrude(t) dovetail_2d(0);
}
module pockets(t) {
    for (y = joint_ys)
        translate([half, y, -eps]) linear_extrude(t + 2*eps) dovetail_2d(tol);
}

// ---------- Box ----------
module full_box() {
    difference() {
        cube([L, W, box_h]);
        // open pocket above the divider tops (room for the lid lip), full width
        translate([end_wall, side_wall, box_h - lip_h - div_gap])
            cube([L - 2*end_wall, W - 2*side_wall, lip_h + div_gap + eps]);
        for (i = [0 : n_chan-1])
            translate([end_wall, chan_y(i), floor_t])
                cube([L - 2*end_wall, chan_w, box_h]);
    }
}
module box_a() {
    union() {
        intersection() { full_box(); cube([half, W, box_h]); }
        tongues(floor_t);
    }
}
module box_b() {
    difference() {
        intersection() {
            full_box();
            translate([half, 0, 0]) cube([half, W, box_h]);
        }
        pockets(floor_t);
    }
}

// ---------- Lid (modelled plate-down, lip up = print orientation) ----------
module full_lid() {
    cube([L, W, lid_t]);
    translate([0, 0, lid_t - eps])
    linear_extrude(lip_h + eps)
    difference() {
        translate([end_wall + lip_tol, side_wall + lip_tol])
            square([L - 2*(end_wall + lip_tol), W - 2*(side_wall + lip_tol)]);
        translate([end_wall + lip_tol + lip_w, side_wall + lip_tol + lip_w])
            square([L - 2*(end_wall + lip_tol + lip_w), W - 2*(side_wall + lip_tol + lip_w)]);
    }
}
module lid_a() {
    union() {
        intersection() { full_lid(); cube([half, W, lid_t + lip_h]); }
        tongues(lid_t);
    }
}
module lid_b() {
    difference() {
        intersection() {
            full_lid();
            translate([half, 0, 0]) cube([half, W, lid_t + lip_h]);
        }
        pockets(lid_t);
    }
}

// Lid flipped onto the box (lip down)
module lid_on_box(m) {
    translate([0, W, box_h + lid_t]) rotate([180, 0, 0]) children();
}

// ---------- Selector ----------
if (part == "box_a") box_a();
else if (part == "box_b") translate([-half, 0, 0]) box_b();   // origin at seam for printing
else if (part == "lid_a") lid_a();
else if (part == "lid_b") translate([-half, 0, 0]) lid_b();
else if (part == "print_plate") {
    box_a();
    translate([0, W + 10, 0]) translate([-half, 0, 0]) box_b();
    translate([half + 20, 0, 0]) lid_a();
    translate([half + 20, W + 10, 0]) translate([-half, 0, 0]) lid_b();
}
else { // assembly
    color("steelblue") { box_a(); box_b(); }
    color("orange") lid_on_box() { lid_a(); lid_b(); }
}
