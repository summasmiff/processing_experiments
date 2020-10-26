import processing.svg.*;

String _saveName = "barnsley_fern_";
float x = 0;
float y = 0;
int transforms;

void setup() {
  size(500, 750);
  background(255);
}

void draw() {
  for (int i = 0; i < 100; i++ ) {
    drawDot();
    nextPoint();
  }
}

void keyPressed() {
  if (key == 's' || key == 'S') {
    exportSVG();
  }
}

// yuck - would rather have some form of edge detection than point-based rendering
void exportSVG() {
  String saveName = _saveName + transforms + ".svg";
  PGraphics pg = createGraphics(width, height, SVG, saveName);
  pg.beginDraw();
  pg.stroke(0);
  pg.strokeWeight(1);
  for (int i=0; i<transforms; i++) {
    float px = map(x, -2.1820, 2.6558, 0, width);
    float py = map(y, 0, 9.9983, height, 0);
    pg.ellipse(px, py, 2, 2);
  }
  pg.endDraw();
  pg.dispose();
  println("saved " + saveName);
}

void nextPoint() {
  float nextX;
  float nextY;

  float r = random(1);
  
  // TODO: Parameterize probabilities
  // TODO: Parameterize values
  if (r < 0.02) { 
    nextX = 0;
    nextY = 0.16 * y;
  } else if (r < 0.86) {
    nextX = 0.85 * x + 0.04 * y;
    nextY = -0.04 * x + 0.85 * y + 1.6;
  } else if (r < 0.93) {
    nextX = 0.2 * x + -0.26 * y;
    nextY = 0.23 * x + 0.22 * y + 1.6;
  } else {
    nextX = -0.15 * x + 0.28 * y;
    nextY = 0.26 * x + 0.24 * y + 0.44;
  }

  x = nextX;
  y = nextY;
}

void drawDot() {
  stroke(0);
  strokeWeight(1);
  float px = map(x, -2.1820, 2.6558, 0, width);
  float py = map(y, 0, 9.9983, height, 0);
  ellipse(px, py, 2, 2);
  transforms += 1;
}
