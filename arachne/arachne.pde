import processing.svg.*;
import java.util.Date;
import java.text.SimpleDateFormat;
import java.util.HashMap;

int w = 900;
int h = 700;
int webSpacing = 15;
boolean shouldRecord = false;

String generateFilename() {
  String timestamp = new SimpleDateFormat("yyyyMMdd-HHmmss").format(new Date());
  return "arachne_" + timestamp + ".svg";
}

public void settings() {
  size(w, h);
  pixelDensity(1);
}

void setup() {
  stroke(0);
  strokeWeight(1);
  noFill();
}

void draw() {
  if (shouldRecord) {
    beginRaw(SVG, generateFilename());
  }

  background(255);
  spinWeb();
  noLoop();

  if (shouldRecord) {
    endRaw();
    shouldRecord = false;
    println("yay SVG exported!");
  }
}

void spinWeb() {
  PVector hub = new PVector(w / 2.0, h / 2.0);
  float hubRadius = 20;
  float minRadius = hubRadius + webSpacing;

  // Spokes
  int numSpokes = floor(random(20, 36));
  float baseAngle = TWO_PI / numSpokes;
  float[] angles = new float[numSpokes];
  float[] radii = new float[numSpokes];
  PVector[] spokeEnds = new PVector[numSpokes];

  for (int i = 0; i < numSpokes; i++) {
    float angle = i * baseAngle + radians(random(-2, 2));
    angles[i] = angle;

    PVector perimeterPoint = getPerimeterIntersection(hub, angle);
    spokeEnds[i] = perimeterPoint;

    radii[i] = dist(hub.x, hub.y, perimeterPoint.x, perimeterPoint.y);

    float hubVertexX = hub.x + cos(angle) * hubRadius;
    float hubVertexY = hub.y + sin(angle) * hubRadius;

    line(hubVertexX, hubVertexY, perimeterPoint.x, perimeterPoint.y);
  }

  // Draw the hub polygon
  beginShape();
  for (int i = 0; i < numSpokes; i++) {
    float hubVertexX = hub.x + cos(angles[i]) * hubRadius;
    float hubVertexY = hub.y + sin(angles[i]) * hubRadius;
    vertex(hubVertexX, hubVertexY);
  }
  endShape(CLOSE);

  // Draw the spiral from outside in
  float spiralStep = webSpacing;
  float maxRadius = 0;
  for (float r : radii) {
    if (r > maxRadius) maxRadius = r;
  }

  // Track web connections at each point to prevent more than 2 segments per point
  HashMap<String, Integer> connections = new HashMap<String, Integer>();

  for (float currentRadius = maxRadius; currentRadius > minRadius; currentRadius -= spiralStep) {
    for (int i = 0; i < numSpokes; i++) {
      int next = (i + 1) % numSpokes;

      if (radii[i] >= currentRadius) {
        float r1 = currentRadius;
        float x1 = hub.x + cos(angles[i]) * r1;
        float y1 = hub.y + sin(angles[i]) * r1;

        float r2 = min(radii[next], currentRadius);
        float x2 = hub.x + cos(angles[next]) * r2;
        float y2 = hub.y + sin(angles[next]) * r2;

        String key1 = i + "_" + round(r1);
        String key2 = next + "_" + round(r2);

        int count1 = connections.getOrDefault(key1, 0);
        int count2 = connections.getOrDefault(key2, 0);

        if (count1 < 2 && count2 < 2) {
          line(x1, y1, x2, y2);
          connections.put(key1, count1 + 1);
          connections.put(key2, count2 + 1);
        }
      }
    }
  }
}

PVector getPerimeterIntersection(PVector origin, float angle) {
  float dx = cos(angle);
  float dy = sin(angle);
  float cx = origin.x;
  float cy = origin.y;

  float tMin = Float.MAX_VALUE;

  if (dx > 0) tMin = min(tMin, (w - cx) / dx);
  else if (dx < 0) tMin = min(tMin, -cx / dx);

  if (dy > 0) tMin = min(tMin, (h - cy) / dy);
  else if (dy < 0) tMin = min(tMin, -cy / dy);

  return new PVector(cx + dx * tMin, cy + dy * tMin);
}

void keyPressed() {
  if (key == 'r' || key == 'R') {
    shouldRecord = true;
  }
}
