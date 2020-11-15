import processing.svg.*;
int cols,rows;
int scale = 20;
int z_scale = 90;
int w = 900;
int h = 700;
float small = 0.4;

void setup() {
  size(750, 500, P3D);
  cols = w / scale;
  rows = h / scale;
  smooth();
  strokeWeight(1);
  stroke(0,0,0);
  noFill();
  int x_rot = round(random(3, 5));
  int y_rot = round(random(5, 8));
  int octave = round(random(1, 4));
  println(x_rot);
  String saveName = "drift_" + x_rot + "_" + y_rot + "_" + octave + ".svg";
  beginRaw(SVG, saveName);
  
  // Move origin to rotate "camera"
  translate(width/2, height/3 * 2);
  
  rotateX(PI/x_rot);
  rotateY(PI/y_rot);
  
  // Move origin for placement of mesh
  translate(-w/2, -h/1.2, -h/8);
  
  for (int y = 0; y < rows; y++) {
    beginShape(TRIANGLE_STRIP);
    for (int x = 0; x < cols; x++) {
      float scaled_x = x * small;
      float scaled_y = y * small;
      float scaled_yplus = (y + 1) * small;
      float z = x*1.2 + y*1.2;
      
      noiseDetail(octave, 0.5);
      vertex(x*scale, y*scale, noise(scaled_x,scaled_y)*z_scale + z);
      vertex(x*scale, (y+1)*scale, noise(scaled_x, scaled_yplus)*z_scale + z);
    }
    endShape();
  }
  
  endRaw();
  println("done");
}
