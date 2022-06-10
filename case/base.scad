$fn=32;
outer_y = 115;
outer_x = 220;
legs_height = 6;

module bottom() {
  bottom_height = 0.4;

  module bottom_mounts() {
    translate([32, 32, -0.1]) cylinder(d = 4, h = bottom_height + 1);
    translate([32, 82, -0.1]) cylinder(d = 4, h = bottom_height + 1);

    translate([182, 32, -0.1]) cylinder(d = 4, h = bottom_height + 1);
    translate([182, 82, -0.1]) cylinder(d = 4, h = bottom_height + 1);
  }

  difference() {
    cube([outer_x, outer_y, bottom_height]);
    bottom_mounts();
  }
}

module bpi_m2_zero_mounts() {
  start_x = 140;
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
  x_dist = 102;
  y_dist = 77;
  start_x = 10;
  start_y = (outer_y - y_dist) / 2;

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


module display_mounts() {
  x_dist = 87;
  y_dist = 65;
  start_x = 121;
  start_y = (outer_y - y_dist) / 2;
  display_legs_height = 20;

  module mount(height) {
    difference() {
      cylinder(d = 6, h = height);
      cylinder(d = 3, h = height + 1);
    }
  }

  module mounts() {
    translate([start_x, start_y, 0]) mount(display_legs_height);
    translate([start_x + x_dist, start_y, 0]) mount(display_legs_height);
    translate([start_x, start_y + y_dist, 0]) mount(display_legs_height * 1.5);
    translate([start_x + x_dist, start_y + y_dist, 0]) mount(display_legs_height * 1.5);
  }

  difference() {
    mounts();
    translate([start_x - 10, start_y - 10, display_legs_height - 4]) rotate([10,0,0]) cube([x_dist + 20, y_dist + 20, 10]);
  }
}

module lm2596_mounts() {
  start_x = 160;
  start_y = 45;
  x_dist = 30;
  y_dist = -18;

  module mount() {
    difference() {
      cylinder(d = 5, h = legs_height);
      cylinder(d = 2.5, h = legs_height + 1);
    }
  }

  translate([start_x, start_y, 0]) mount();
  translate([start_x + x_dist, start_y + y_dist, 0]) mount();
}

module antenna_mount() {
  module wall() {
    intersection() {
      translate([outer_x - 10, 2, 2]) rotate([90, 0, 0]) cylinder(d = 20, h = 2, $fn=64);
      translate([outer_x - 30, 0, 0]) cube([30, 2, 20]);
    }
  }

  module hole() {
    translate([outer_x - 9.6, 2.1, 6.8]) rotate([90, 0, 0]) cylinder(d = 6.3, h = 3, $fn=64);
  }

  difference() {
    wall();
    hole();
  }
}

bottom();
skr_14t_mounts();
bpi_m2_zero_mounts();
lm2596_mounts();
display_mounts();
antenna_mount();
