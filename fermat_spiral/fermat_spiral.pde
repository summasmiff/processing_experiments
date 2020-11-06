import processing.svg.*;

int _numPoints = 450;
float _angle = 137.5;
float _scale = 10;
float _seedSize = 10;


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
      float x = radius * cos(theta) + width/2;
      float y = radius * sin(theta) + height/2;
      
      float size = (n / 60) + _seedSize * 1.5;
      //float size = _seedSize;

      ellipse(x, y, size, size);
    }
}
