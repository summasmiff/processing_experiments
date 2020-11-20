import processing.svg.*; //<>//

String _saveName = "flow_field_";
float[][] grid;
float[][] starting_points;
float resolution;
float num_columns, num_rows, angle, x, y;
int left_x, right_x, top_y, bottom_y;
int column_index, row_index;
float grid_angle, x_step, y_step;
float position_noise;

float step_length = 10;

int _octave = round(random(4, 6));
float falloff = random(0.75, 0.8);
int num_steps = round(random(100, 150));
int num_lines = round(random(50, 70));

void setup() {
  // width, height in pixels
  // slightly smaller than a5
  size(750, 500);
  smooth();
  strokeWeight(2);
  stroke(0, 0, 0);
  noFill();

  println("octave: " + _octave);
  println("falloff: " + falloff);
  println("num_steps: " + num_steps);
  println("num_lines: " + num_lines);

  // make grid larger than paper so lines can flow off
  left_x = int(width * -4);
  right_x = int(width * 4);
  top_y = int(height * -4);
  bottom_y = int(height * 4);
  resolution = int(width * 0.01);
  num_columns = (right_x - left_x) / resolution;
  num_rows = (bottom_y - top_y) / resolution;

  grid = new float[int(num_columns)][int(num_rows)];
  starting_points = new float[num_lines][2];

  for (int column = 0; column < num_columns -1; column +=1) {
    for (int row = 0; row < num_rows - 1; row +=1) {
      float scaled_x = column * 0.005;
      float scaled_y = row * 0.005;
      noiseDetail(_octave, falloff);
      float noise_value = noise(scaled_x, scaled_y);
      angle = map(noise_value, 0.0, 1.0, 0.0, PI * 2.0);
      grid[column][row] = angle;
    }
  }

  for (int j = 1; j < num_lines; j = j+1) {
    float x = random(width/11, (width/7)*6);
    float y = random(0, height);
    float[] point = new float[2];
    point[0] = x;
    point[1] = y;
    starting_points[j] = point;
  }
};

void draw() {
  for (int k = 1; k < num_lines; k = k+1) {
    float[] starting_point = new float[2];
    starting_point = starting_points[k];

    drawCurves(starting_point[0], starting_point[1], left_x, top_y, resolution, grid);
  }
}

void keyPressed() {
  if (key == 's' || key == 'S') {
    exportSVG();
  }

  if (key == CODED) {
    if (keyCode == UP) {
      num_steps = num_steps + 10;
    } else if (keyCode == DOWN) {
      num_steps = num_steps -10;
    } 
  }
}


void drawCurves(float x, float y, int left_x, int top_y, float resolution, float[][] grid) {
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

void exportSVG() {
  int name_falloff = round(falloff * 10);
  String exportName = _saveName + num_steps + "_" + name_falloff + ".svg";
  PGraphics pg = createGraphics(width, height, SVG, exportName);
  pg.beginDraw();
  pg.noFill();
  pg.strokeWeight(1);
  pg.stroke(0);
  pg.smooth();

  for (int k = 1; k < num_lines; k = k+1) {
    float[] starting_point = new float[2];
    starting_point = starting_points[k];
    x = starting_point[0];
    y = starting_point[1];
    
    pg.beginShape();
    
    // drawCurves
    for (int i = 0; i < num_steps; i = i+1) {
      int c_size = round(random(4, 9) * (y / 150));
      pg.ellipse(x, y, c_size, c_size);

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

    pg.endShape();
  }

  pg.endDraw();
  pg.dispose();
  println("saved " + exportName);
}
