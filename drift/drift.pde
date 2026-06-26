import processing.svg.*;
import java.util.Date;
import java.text.SimpleDateFormat;

int cols,rows;
int scale = 10;
float z_scale = random(90); // height displacement
int w = 900;
int h = 700;
float small = 0.4;
boolean shouldRecord = false;
PShape grid;

String generateFilename() {
  String timestamp = new SimpleDateFormat("yyyyMMdd-HHmmss").format(new Date());
  return "drift_" + timestamp + ".svg";
}

public void settings() {
  size(w, h, P3D);
}

void setup() {
  hint(ENABLE_DEPTH_SORT); // helper for rendering 3d to svg
  println("z_scale: ", z_scale);
  cols = w / scale;
  rows = h / scale;

  grid = createShape(GROUP);
  int octave = round(random(1, 4));
  noiseDetail(octave, 0.5);

  for (int y = 0; y < rows; y++) {
    PShape row = createShape();
    row.beginShape(QUAD_STRIP);
    row.stroke(0);
    row.strokeWeight(1);
    row.noFill();
    for (int x = 0; x < cols; x++) {
      // Scale grid coordinates to noise space
      float scaled_x = x * small;
      float scaled_y = y * small;
      float scaled_yplus = (y + 1) * small;
      // Add linear ramp to create diagonal wave pattern
      float z = x*1.2 + y*1.2;

      // Convert grid coordinates to screen space, centered at origin
      float xPos = x * scale - w/2;
      float yPos = y * scale - h/2;
      float yNextPos = (y + 1) * scale - h/2;

      // Sample Perlin noise at current and next row, scaled by height factor
      float z1 = noise(scaled_x, scaled_y) * z_scale + z;
      float z2 = noise(scaled_x, scaled_yplus) * z_scale + z;

      row.vertex(xPos, yPos, z1);
      row.vertex(xPos, yNextPos, z2);
    }
    row.endShape();
    grid.addChild(row);
  }

}

void draw() {
  if (shouldRecord) {
    beginRaw(SVG, generateFilename());
  }

  background(255);

  pushMatrix();
  translate(width/2, height/2, 0);
  rotateX(map(mouseY, 0, height, -PI/2, PI/2));
  rotateY(map(mouseX, 0, width, -PI, PI));
  shape(grid);
  popMatrix();

  if (shouldRecord) {
    endRaw();
    shouldRecord = false;
    println("yay SVG exported!");
  }
}

void keyPressed() {
  if (key == 'r' || key == 'R') {
    shouldRecord = true;
  }
}
