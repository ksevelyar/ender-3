$fn=16;
outer_y = 115;
outer_x = 214;
legs_height = 6;

module bottom_mounts() {
  translate([32, 32, -0.1]) cylinder(d = 4, h = legs_height);
  translate([32, 82, -0.1]) cylinder(d = 4, h = legs_height);

  translate([182, 32, -0.1]) cylinder(d = 4, h = legs_height);
  translate([182, 82, -0.1]) cylinder(d = 4, h = legs_height);
}

module bottom() {
  difference() {
    cube([outer_x, outer_y, 2]);
    bottom_mounts();
  }
}

module bpi_m2_zero_mounts() {
  start_x = 143;
  start_y = 64;
  x_dist = 58;
  y_dist = 23;

  module mount() {
    difference() {
      cylinder(d = 4, h = legs_height);
      cylinder(d = 2, h = legs_height + 1);
    }
  }

  translate([start_x, start_y, 0]) mount();
  translate([start_x + x_dist, start_y, 0]) mount();
  translate([start_x, start_y + y_dist, 0]) mount();
  translate([start_x + x_dist, start_y + y_dist, 0]) mount();
}

module skr_14t_mounts() {
  start_x = 10;
  start_y = 10;
  x_dist = 102;
  y_dist = 77;

  module mount() {
    difference() {
      cylinder(d = 6, h = legs_height);
      cylinder(d = 3, h = legs_height + 1);
    }
  }

  translate([start_x, start_y, 0]) mount();
  translate([start_x + x_dist, start_y, 0]) mount();
  translate([start_x, start_y + y_dist, 0]) mount();
  translate([start_x + x_dist, start_y + y_dist, 0]) mount();
}

module lm2596_mounts() {
  start_x = 146;
  start_y = 40;
  x_dist = 37;
  y_dist = -18;

  module mount() {
    difference() {
      cylinder(d = 6, h = legs_height);
      cylinder(d = 3, h = legs_height + 1);
    }
  }

  translate([start_x, start_y, 0]) mount();
  translate([start_x + x_dist, start_y + y_dist, 0]) mount();
}

bottom();
skr_14t_mounts();
bpi_m2_zero_mounts();
lm2596_mounts();
