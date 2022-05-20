// mean well lrs-350-24

outer_y = 115;
inner_y = 105;

height_z = 30;
wall = 2;

spacer_x = 50;
inner_x = 60;

module ventilation_line(start_x, start_y) {
  module dot() { cylinder(h = 3, d = 2.25, $fn=16); }
  line_length = 35;
  y_gap = line_length + 17;

  module line(line_x, line_y) {
    hull() {
      translate([line_x, line_y, -0.1]) dot();
      translate([line_x, line_y + line_length, -0.1]) dot();
    }
  }

  line(start_x, start_y);
  line(start_x, start_y + y_gap);
}

module ventilation(start_x, start_y) {
  ventilation_line(start_x, start_y);
  ventilation_line(start_x + 8, start_y);
  ventilation_line(start_x + 16, start_y);
}

module bottom() {
  bottom_y = outer_y + wall * 2;
  bottom_x = spacer_x + inner_x;

  difference() {
    cube([bottom_x, outer_y, 1]);
    ventilation(36 + spacer_x, 16);
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
  module wall() { cube([spacer_x + inner_x, 2, 30]); }

  wall();
  translate([0, outer_y - wall, 0]) wall();
}

bottom();
difference() {
  walls();
  mount_holes();
}
