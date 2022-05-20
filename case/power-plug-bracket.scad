// mean well lrs-350-24

outer_y = 115;
inner_y = 105;

height_z = 30;
wall = 2;

mount_z = 17;
mount_x = 27.5;

spacer_x = 50; 
inner_x = 60;

module bottom_ventilation() {
  start_x = 36 + spacer_x;
  start_y = 16;
    
  grill_x = 4;
  grill_y = 35;
}

module bottom() {
  bottom_y = outer_y + wall * 2;
  bottom_x = spacer_x + inner_x;
  cube([bottom_x, outer_y, 1]);
}

bottom();