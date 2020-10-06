import processing.svg.*;

void setup() {
  // width, height in pixels
  size(790, 550, SVG, "flow_field.svg");
  smooth();
  strokeWeight(2);
  stroke(0,0,0);
  noFill();
  
  // declare var
  float[][] grid;
  float resolution;
  float num_columns, num_rows, angle, x, y;
  int left_x, right_x, top_y, bottom_y;
  
  // assign var
  left_x = int(width * -0.5);
  right_x = int(width * 1.5);
  top_y = int(height * -0.5);
  bottom_y = int(height * 1.5);
  resolution = int(width * 0.01);
  num_columns = (right_x - left_x) / resolution;
  num_rows = (bottom_y - top_y) / resolution;
  
  grid = new float[int(num_columns)][int(num_rows)];
  
  for (int column = 0; column < num_columns -1; column +=1) {
    for (int row = 0; row < num_rows - 1; row +=1) {
      float scaled_x = column * 0.005;
      float scaled_y = row * 0.005;
      float noise_value = noise(scaled_x, scaled_y);
      angle = map(noise_value, 0.0, 1.0, 0.0, PI * 2.0);
      grid[column][row] = angle;
    }
  }
  
  y = 1;
  
  for (x = -200; x < 800; x = x+10) { //<>//
    drawCurve(x, y, left_x, top_y, resolution, grid);
  }
  
  //exit() required for SVG generation
  println("Done");
  exit();
};

void drawCurve(float x, float y, int left_x, int top_y, float resolution, float[][] grid) {
  int num_steps, column_index, row_index;
  float step_length, grid_angle, x_step, y_step;
  num_steps = 160;
  step_length = 4;
  beginShape();
  for (int i = 0; i < num_steps; i = i+1) {
    vertex(x, y);
    int x_offset = int(x) - left_x;
    int y_offset = int(y) - top_y;
    
    column_index = int(x_offset / resolution);
    row_index = int(y_offset / resolution);
    
    grid_angle = grid[column_index][row_index];
    
    x_step = step_length * cos(grid_angle); 
    y_step = step_length * sin(grid_angle);
    
    x = x + x_step;
    y = y + y_step;
  }
  endShape();
};
