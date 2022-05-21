// mean well lrs-350-24

outer_y = 115;

height_z = 30;
wall = 2;

spacer_x = 50;
inner_x = 60;

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


module bottom() {
  bottom_y = outer_y + wall * 2;
  bottom_x = spacer_x + inner_x;

module socket_cutout() {
  cutout_y = 47;
  cutout_x = 27;

  start_x = 10;
  start_y = (bottom_y - 47) / 2;

  translate([start_x, start_y, -0.1]) cube([cutout_x, cutout_y, 5]);

  translate([start_x - 5, bottom_y / 2, -0.1]) cylinder(d=4, h=5, $fn=16);
  translate([start_x + 5 + cutout_x, bottom_y / 2, -0.1]) cylinder(d=4, h=5, $fn=16);
}

  difference() {
    cube([bottom_x, outer_y, 1]);
    ventilation(36 + spacer_x);

    socket_cutout();
  }
}

module mount_holes() {
  mount_z = 17;
  mount_x = spacer_x + 32;

  translate([mount_x,-10,mount_z]) {
    rotate([-90,0,0]) cylinder(h = 200, d = 3, $fn=16);
  }
}
module walls() {
  module wall() { cube([spacer_x + inner_x, 2, height_z]); }

  wall();
  translate([0, outer_y - wall, 0]) wall();

  cube([2, outer_y, height_z]);
}

module ports_cover() {
  width_x = 15;
  height = 10;

  translate([spacer_x, wall, 0]) cube([width_x, outer_y - wall * 2, height]);
}

bottom();
ports_cover();
difference() {
  walls();
  mount_holes();
}
