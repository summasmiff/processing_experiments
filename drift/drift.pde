import processing.svg.*;
int cols,rows;
int scale = 10;
int z_scale = 20;
int w = 900;
int h = 700;
float small = 0.5;

void setup() {
  size(750, 500, P3D);
  cols = w / scale;
  rows = h / scale;
  smooth();
  strokeWeight(1);
  stroke(0,0,0);
  noFill();
  
  beginRaw(SVG, "drift.svg");
  
  // Move origin to rotate "camera"
  translate(width/2, height/2);
  rotateX(PI/5);
  // Move origin for placement of mesh
  translate(-w/2, -h/1.5);
  
  for (int y = 0; y < rows; y++) {
    beginShape(TRIANGLE_STRIP);
    for (int x = 0; x < cols; x++) {
      float scaled_x = x * small;
      float scaled_y = y * small;
      float scaled_yplus = (y + 1) * small;
      //noiseDetail(2,0.5);
      vertex(x*scale, y*scale, noise(scaled_x,scaled_y)*z_scale);
      vertex(x*scale, (y+1)*scale, noise(scaled_x, scaled_yplus)*z_scale);
    }
    endShape();
  }
  
  endRaw();
  println("done");
}
