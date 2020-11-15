import processing.svg.*;

int _numPoints = 450;
float _angle = 137.5;
float _scale = 10;
float _seedSize = random(8, 15);
float _growScale = random(15, 30);
String _saveName = "fermat_spiral_";


void setup() {
  size(750, 500);
  strokeWeight(1);
  stroke(0);
  noFill();
  background(255);
}

void draw() {
  for (int n=0; n<_numPoints; n++) {
    float theta = n * radians(_angle);
    float radius = sqrt(n) * _scale;
    float translateX = radius * cos(theta) + width/2;
    float translateY = radius * sin(theta) + height/2;

    float x = 0;
    float y = 0;

    float size = (n / _growScale) + _seedSize;

    pushMatrix();      
    translate(translateX, translateY);
    rotate(theta);
    quad(x, y+size/4, x+size/2, y, x+size, y+size/4, x+size/2, y+ size/2);
    popMatrix();
  }
}

void keyPressed() {
  if (key == 's' || key == 'S') {
    exportSVG();
  }
}

void exportSVG() {
  String exportName = _saveName + round(_seedSize) + "_"+ round(_growScale) + ".svg";
  PGraphics pg = createGraphics(width, height, SVG, exportName);
  pg.beginDraw();
  pg.noFill();
  pg.strokeWeight(1);
  pg.stroke(0);

  for (int n=0; n<_numPoints; n++) {
    float theta = n * radians(_angle);
    float radius = sqrt(n) * _scale;
    float translateX = radius * cos(theta) + width/2;
    float translateY = radius * sin(theta) + height/2;

    float x = 0;
    float y = 0;

    float size = (n / _growScale) + _seedSize;

    pg.pushMatrix();      
    pg.translate(translateX, translateY);
    pg.rotate(theta);
    pg.quad(x, y+size/4, x+size/2, y, x+size, y+size/4, x+size/2, y+ size/2);
    pg.popMatrix();
  }

  pg.endDraw();
  pg.dispose();
  println("saved " + exportName);
}
