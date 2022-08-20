$fn=64;
outer_y = 115;
outer_x = 215;
legs_height = 6;
wall_width = 2;
wall_height = 10;

module bottom() {
  bottom_height = 2;

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
  start_y = 23;
  x_dist = 58;
  y_dist = 23;

  module mount() {
    difference() {
      cylinder(d = 4, h = legs_height);
      cylinder(d = 1.9, h = legs_height + 1);
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

module lm2596_mounts() {
  start_x = 190;
  start_y = 60;
  x_dist = -16;
  y_dist = 30;

  module mount() {
    difference() {
      cylinder(d = 5, h = legs_height);
      cylinder(d = 2.4, h = legs_height + 1);
    }
  }

  translate([start_x, start_y, 0]) mount();
  translate([start_x + x_dist, start_y + y_dist, 0]) mount();
}

module antenna_mount() {
  start_y = outer_y - 20;
  start_x = outer_x - 40;

  module wall() {
    translate([start_x, start_y + 10, 10]) rotate([0, 90, 0]) cylinder(d = 20, h = 2, $fn=64);
    translate([start_x , start_y + 0, 0]) cube([2, 20, 10]);
  }

  module hole() {
    translate([start_x - 0.5, start_y + 10, 10]) rotate([0, 90, 0]) cylinder(d = 6.5, h = 3, $fn=64);
  }

  difference() {
    wall();
    hole();
  }
}

module top_wall() {
  translate([0, outer_y - wall_width, 0]) cube([outer_x, wall_width, wall_height]);
}
module bottom_wall() {
  cube([outer_x, wall_width, wall_height]);
}
module right_wall() {
  translate([0, 0, 0]) cube([wall_width, outer_y, wall_height]);
}
module left_wall() {
  translate([outer_x - wall_width, 0, 0]) cube([wall_width, outer_y, wall_height]);
}

bottom();
skr_14t_mounts();
bpi_m2_zero_mounts();
lm2596_mounts();
antenna_mount();

left_wall();
right_wall();
bottom_wall();
top_wall();
