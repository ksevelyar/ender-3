height_z = 70;
wall = 2;
outer_y = 115 + wall * 2;
spacer_x = 20;
inner_x = 60;

module bottom() {
  bottom_y = outer_y + wall * 2;
  bottom_x = spacer_x + inner_x;

  module ventilation_line(start_x) {
    module dot() { cylinder(h = 3, d = 2.25, $fn=16); }
    line_length = 40;
    y_gap = (outer_y - line_length * 2) / 3;

    module line(line_x, line_y) {
      hull() {
        translate([line_x, line_y, -0.1]) dot();
        translate([line_x, line_y + line_length, -0.1]) dot();
      }
    }

    line(start_x, y_gap);
    line(start_x, y_gap * 2 + line_length);
  }

  module ventilation(start_x) {
    ventilation_line(start_x);
    ventilation_line(start_x + 8);
    ventilation_line(start_x + 16);
  }

  module socket_cutout() {
    cutout_y = 47.5;
    cutout_x = 27.5;
    start_x = 15;
    start_y = (bottom_y - 47 - wall * 2) / 2;

    translate([start_x, start_y, -0.1]) cube([cutout_x, cutout_y, 5]);

    translate([start_x - 7, bottom_y / 2 - wall, -0.1]) cylinder(d=2.5, h=5, $fn=16);
    translate([start_x + 7 + cutout_x, bottom_y / 2 - wall, -0.1]) cylinder(d=2.5, h=5, $fn=16);
  }

  difference() {
    cube([bottom_x, outer_y, wall]);
    ventilation(36 + spacer_x);

    socket_cutout();
  }
}

module mount_holes() {
  mount_z = height_z - 13;
  mount_x = spacer_x + 32;

  translate([mount_x,-10,mount_z]) {
    rotate([-90,0,0]) cylinder(h = 200, d = 3.5, $fn=16);
  }
}

module walls() {
  bottom_x = spacer_x + inner_x - wall;
  socket_box_height = 40;

  module wall_with_support() {
    cube([spacer_x + inner_x, 2, height_z]);
    translate([0, 0, socket_box_height - 2]) cube([spacer_x + inner_x, wall * 2, wall]);
    translate([0, 1, socket_box_height - 4.8]) rotate([45,0,0]) cube([spacer_x + inner_x, wall * 2, 1]);
  }

  wall_with_support();
  translate([0, outer_y, 0]) mirror([0,180,0]) wall_with_support();

  cube([wall, outer_y, height_z]);
  translate([bottom_x,0,0]) cube([wall, outer_y, socket_box_height]);
}

bottom();
difference() {
  walls();
  mount_holes();
}
