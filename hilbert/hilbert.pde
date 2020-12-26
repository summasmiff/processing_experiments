import processing.svg.*;

String _saveName = "hilbert_";
int order = 6;
int N = int(pow(2, order));
int total = N * N;

PVector[] path = new PVector[total];

void setup() {
  size(512, 512);

  for (int i = 0; i < total; i ++) {
    path[i] = hilbert(i);
    float len = width / N;
    path[i].mult(len);
    path[i].add(len/2, len/2);
  }
}

void draw() {
  background(255);
  stroke(0);
  strokeWeight(2);
  noFill();
  beginShape();
  for (int i = 0; i < path.length; i++ ) {
    vertex(path[i].x, path[i].y);
  }
  endShape();
}

void keyPressed() {
  if (key == 's' || key == 'S') {
    exportSVG();
  }
}

void exportSVG() {
  String exportName = _saveName + order + ".svg";
  PGraphics pg = createGraphics(width, height, SVG, exportName);
  pg.beginDraw();
  pg.noFill();
  pg.strokeWeight(1);
  pg.stroke(0);
  pg.smooth();

  pg.beginShape();
  for (int i = 0; i < path.length; i++ ) {
    pg.vertex(path[i].x, path[i].y);
  }
  pg.endShape();
  pg.endDraw();
  pg.dispose();
  println("saved " + exportName);
}

PVector hilbert(int i) {
  PVector[] points = {
    new PVector(0, 0), 
    new PVector(0, 1), 
    new PVector(1, 1), 
    new PVector(1, 0)
  };

  int index = i & 3;
  PVector v = points[index];

  for (int j=1; j < order; j++) {
    i = i >>> 2;
    index = i & 3;
    float len = pow(2, j);

    if (index == 0) {
      float temp = v.x;
      v.x = v.y;
      v.y = temp;
    } else if (index == 1) {
      v.y+=len;
    } else if (index == 2) {
      v.x+=len;
      v.y+=len;
    } else if (index == 3) {
      float temp = len-1-v.x;
      v.x = len-1-v.y;
      v.y = temp;
      v.x+=len;
    }
  }

  return v;
}
