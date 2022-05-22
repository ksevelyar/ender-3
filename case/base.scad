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

bottom();
