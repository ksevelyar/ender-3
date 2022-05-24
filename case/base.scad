$fn=16;
outer_y = 115;
outer_x = 214;

module bottom_mounts() {
  translate([32, 32, -0.1]) cylinder(d = 4, h = 4);
  translate([32, 82, -0.1]) cylinder(d = 4, h = 4);

  translate([182, 32, -0.1]) cylinder(d = 4, h = 4);
  translate([182, 82, -0.1]) cylinder(d = 4, h = 4);
}

module bottom() {
  difference() {
    cube([outer_x, outer_y, 2]);
    bottom_mounts();
  }
}

module bpi_m2_zero_mounts() {
  start_x = 143;
  start_y = 72;
  x_dist = 58;
  y_dist = 23;

  module bpi_m2_zero_mount() {
    difference() {
      cylinder(d = 4, h = 4);
      cylinder(d = 2, h = 5);
    }
  }

  translate([start_x, start_y, 0]) bpi_m2_zero_mount();
  translate([start_x + x_dist, start_y, 0]) bpi_m2_zero_mount();
  translate([start_x, start_y + y_dist, 0]) bpi_m2_zero_mount();
  translate([start_x + x_dist, start_y + y_dist, 0]) bpi_m2_zero_mount();
}

module skr_14t_mounts() {
  start_x = 10;
  start_y = 10;
  x_dist = 102;
  y_dist = 77;

  module skr_14t_mount() {
    difference() {
      cylinder(d = 7, h = 4);
      cylinder(d = 4, h = 5);
    }
  }

  translate([start_x, start_y, 0]) skr_14t_mount();
  translate([start_x + x_dist, start_y, 0]) skr_14t_mount();
  translate([start_x, start_y + y_dist, 0]) skr_14t_mount();
  translate([start_x + x_dist, start_y + y_dist, 0]) skr_14t_mount();
}

bottom();
skr_14t_mounts();
bpi_m2_zero_mounts();
