import processing.svg.*;

float xstart, xnoise, ynoise;
void setup() {
  //width, height in pixels (220mm x 150mm: a5 paper size)
  size(790, 550, SVG, "hello_world.svg");
  smooth();
  strokeWeight(2);
  stroke(0, 0, 0);
  background(255, 255, 255);
  xstart = random(10);
  xnoise = xstart;
  ynoise = random(10);
  for (int y =0; y<=height; y+=10) {
    ynoise += 0.1;
    xnoise = xstart;
    for (int x=0; x<=width; x+=10) {
      xnoise += 0.1;
      drawPoint(x, y, noise(xnoise, ynoise));
    }
  }
  // exit call required for svg
  println("Done");
  exit();
}
void drawPoint(float x, float y, float noiseFactor) {
  pushMatrix();
  translate(x, y);
  rotate(noiseFactor * radians(360));
  line(0, 0, 10, 0);
  popMatrix();
}
