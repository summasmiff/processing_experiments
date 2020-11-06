import processing.svg.*;

int _numPoints = 450;
float _angle = 137.5;
float _scale = 10;
float _seedSize = 20;


void setup() {
  size(750, 500);
  strokeWeight(1);
  stroke(0);
  noFill();
  background(255);
}

void draw() {
  for(int n=0; n<_numPoints; n++) {
      float theta = n * radians(_angle);
      float radius = sqrt(n) * _scale;
      float translateX = radius * cos(theta) + width/2;
      float translateY = radius * sin(theta) + height/2;
      
      float x = 0;
      float y = 0;
      
      float size = (n / 42) + _seedSize;

      pushMatrix();      
      translate(translateX, translateY);
      rotate(theta);
      quad(x, y+size/4, x+size/2, y, x+size, y+size/4, x+size/2, y+ size/2);
      popMatrix();
    }
}
