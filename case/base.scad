$fn=64;
outer_y = 115;
outer_x = 215;
legs_height = 6;
wall_width = 2;
wall_height = 15;
bottom_height = 1.4;

module bottom() {
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
  module wall() translate([0, outer_y - wall_width, 0]) cube([outer_x, wall_width, wall_height]);

  module skr_sd_cutout() {
    translate([57, outer_y - 10, legs_height]) cube([20, 20, 100]);
  }

  difference() {
    wall();
    skr_sd_cutout();
  }
}
module bottom_wall() {
  usb_width = 15.2;
  module wall() {
    cube([outer_x, wall_width, wall_height]);
  }

  module usb_cutout() {
    start_x = 198 - 13 - usb_width;
    start_z = 4;
    height = 80;
    translate([start_x, -15, start_z]) cube([usb_width, 30, height]);
  }

  module sleeve_cutout(start_x) {
    width = 6;
    start_z = 6;
    height = 80;

    hull() {
      translate([start_x, 15, start_z]) rotate([90,0,0]) cylinder(d=width,h=30);
      translate([start_x, 15, 80]) rotate([90,0,0]) cylinder(d=width,h=30);
    }
  }

  module ribbon_cutout(start_x) {
    width = 1.2;
    start_z = 4;
    height = 80;
    translate([start_x, -15, start_z]) cube([width, 30, height]);
  }

  difference() {
    wall();
    usb_cutout();

    sleeve_cutout(outer_x / 2 + 5);
    sleeve_cutout(outer_x / 2 - 5);

    ribbon_cutout(30);
    ribbon_cutout(30 + usb_width / 2);
    ribbon_cutout(30 + usb_width);
  }
}
module right_wall() {
  translate([0, 0, 0]) cube([wall_width, outer_y, wall_height]);
}
module left_wall() {
  module wall() {
    translate([outer_x - wall_width, 0, 0]) cube([wall_width, outer_y, wall_height]);
  }

  module avg16_cutout(y) {
    hull() {
      translate([outer_x - 15, y, bottom_height * 2]) rotate([0,90,0]) cylinder(d=4,h=30);
      translate([outer_x - 15, y, 100]) rotate([0,90,0]) cylinder(d=4,h=30);
    }
  }

  difference() {
    wall();
    avg16_cutout(9);
    avg16_cutout(18);
    avg16_cutout(27);

    avg16_cutout(49);
    avg16_cutout(58);
    avg16_cutout(67);
    avg16_cutout(76);
  }
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
