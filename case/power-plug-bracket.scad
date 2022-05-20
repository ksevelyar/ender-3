// mean well lrs-350-24

outer_y = 115;
inner_y = 105;

height_z = 30;
wall = 2;

mount_z = 17;
mount_x = 27.5;

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

module ventilation() {
  ventilation_line(36 + spacer_x, 16);
  ventilation_line(36 + 8 + spacer_x, 16);
  ventilation_line(36 + 16 + spacer_x, 16);
}

module bottom() {
  bottom_y = outer_y + wall * 2;
  bottom_x = spacer_x + inner_x;

  difference() {
    cube([bottom_x, outer_y, 1]);
    ventilation();
  }
}

bottom();
