import processing.svg.*;
import java.util.Date;
import java.text.SimpleDateFormat;
import java.util.HashMap;

// --- base config ---
int w = 700;
int h = 900;
int webSpacing = 15;
int numSpokes = 20;

// --- keyPressed state ---
float droopFactor = 0.25;
boolean shouldRecord = false;

// --- constants ---
final float CURVE_SMOOTHNESS = 0.4;
final float HUB_RADIUS = 20;
final float DROOP_ADJUSTMENT_STEP = 0.05;
final float MAX_SPOKE_JITTER = 2.0; // degrees
final int MAX_SPIRAL_CONNECTIONS = 2;

class Spoke {
  float angle;
  PVector start; // Hub vertex
  PVector end;   // Perimeter intersection
  float length;

  Spoke(PVector hub, float angle) {
    this.angle = angle;
    this.start = new PVector(
      hub.x + cos(angle) * HUB_RADIUS,
      hub.y + sin(angle) * HUB_RADIUS
    );
    this.end = getPerimeterIntersection(hub, angle);
    this.length = PVector.dist(this.start, this.end);
  }
}

String generateFilename() {
  String timestamp = new SimpleDateFormat("yyyyMMdd-HHmmss").format(new Date());
  return "arachne_" + timestamp + ".svg";
}

public void settings() {
  size(w, h);
  pixelDensity(1);
}

void setup() {
  noLoop();
}

void draw() {
  if (!shouldRecord) background(255);
  if (shouldRecord) beginRecord(SVG, generateFilename());

  stroke(0);
  strokeWeight(1);
  noFill();

  spinWeb();

  if (shouldRecord) {
    endRecord();
    shouldRecord = false;
    println("yay SVG exported!");
  }
}

void keyPressed() {
  if (key == 'r' || key == 'R') {
    shouldRecord = true;
    redraw();
  } else if (keyCode == DOWN) {
    droopFactor += DROOP_ADJUSTMENT_STEP;
    println("droopFactor: " + droopFactor);
    redraw();
  } else if (keyCode == UP) {
    droopFactor = max(0, droopFactor - DROOP_ADJUSTMENT_STEP);
    println("droopFactor: " + droopFactor);
    redraw();
  }
}

void spinWeb() {
  PVector hub = new PVector(w / 2.0, h / 2.0);
  Spoke[] spokes = generateSpokes(hub);

  drawSpokes(spokes);
  drawHub(spokes);
  drawSpiral(spokes);
}

Spoke[] generateSpokes(PVector hub) {
  Spoke[] spokes = new Spoke[numSpokes];
  float baseAngle = TWO_PI / numSpokes;

  for (int i = 0; i < numSpokes; i++) {
    float jitteredAngle = i * baseAngle + radians(random(-MAX_SPOKE_JITTER, MAX_SPOKE_JITTER));
    spokes[i] = new Spoke(hub, jitteredAngle);
  }
  return spokes;
}

void drawSpokes(Spoke[] spokes) {
  for (Spoke spoke : spokes) {
    drawDroopedCurve(spoke.start, spoke.end, droopFactor);
  }
}

void drawHub(Spoke[] spokes) {
  beginShape();
  for (Spoke spoke : spokes) {
    vertex(spoke.start.x, spoke.start.y);
  }
  endShape(CLOSE);
}

void drawSpiral(Spoke[] spokes) {
  float maxSpiralRadius = getMaxSpokeLength(spokes);
  float minSpiralRadius = webSpacing; // Distance from hub vertex

  HashMap<String, Integer> connections = new HashMap<>();

  // Draw spiral from the outside in
  for (float currentRadius = maxSpiralRadius; currentRadius > minSpiralRadius; currentRadius -= webSpacing) {
    for (int i = 0; i < spokes.length; i++) {
      Spoke current = spokes[i];
      Spoke next = spokes[(i + 1) % spokes.length];

      if (current.length >= currentRadius) {
        PVector p1 = getPointOnDroopedSpoke(current, currentRadius);
        float nextRadius = min(next.length, currentRadius);
        PVector p2 = getPointOnDroopedSpoke(next, nextRadius);

        String key1 = i + "_" + round(currentRadius);
        String key2 = ((i + 1) % spokes.length) + "_" + round(nextRadius);

        if (connections.getOrDefault(key1, 0) < MAX_SPIRAL_CONNECTIONS &&
            connections.getOrDefault(key2, 0) < MAX_SPIRAL_CONNECTIONS) {

          drawDroopedCurve(p1, p2, droopFactor);

          connections.put(key1, connections.getOrDefault(key1, 0) + 1);
          connections.put(key2, connections.getOrDefault(key2, 0) + 1);
        }
      }
    }
  }
}

// --- geometry helpers ---
void drawDroopedCurve(PVector p1, PVector p2, float factor) {
  PVector midDroop = calculateDroopControlPoint(p1, p2, factor);

  float cx1 = lerp(p1.x, midDroop.x, CURVE_SMOOTHNESS);
  float cy1 = lerp(p1.y, midDroop.y, CURVE_SMOOTHNESS);
  float cx2 = lerp(p2.x, midDroop.x, CURVE_SMOOTHNESS);
  float cy2 = lerp(p2.y, midDroop.y, CURVE_SMOOTHNESS);

  beginShape();
  vertex(p1.x, p1.y);
  bezierVertex(cx1, cy1, cx2, cy2, p2.x, p2.y);
  endShape();
}

PVector calculateDroopControlPoint(PVector p1, PVector p2, float factor) {
  float segLength = PVector.dist(p1, p2);
  float segAngle = atan2(p2.y - p1.y, p2.x - p1.x);
  float horizontalness = abs(cos(segAngle));
  float droopAmount = segLength * horizontalness * factor;

  return new PVector(
    (p1.x + p2.x) / 2.0,
    (p1.y + p2.y) / 2.0 + droopAmount
  );
}

PVector getPointOnDroopedSpoke(Spoke spoke, float distFromStart) {
  PVector midDroop = calculateDroopControlPoint(spoke.start, spoke.end, droopFactor);

  float cx1 = lerp(spoke.start.x, midDroop.x, CURVE_SMOOTHNESS);
  float cy1 = lerp(spoke.start.y, midDroop.y, CURVE_SMOOTHNESS);
  float cx2 = lerp(spoke.end.x, midDroop.x, CURVE_SMOOTHNESS);
  float cy2 = lerp(spoke.end.y, midDroop.y, CURVE_SMOOTHNESS);

  float t = constrain(distFromStart / spoke.length, 0, 1);

  float x = bezierPoint(spoke.start.x, cx1, cx2, spoke.end.x, t);
  float y = bezierPoint(spoke.start.y, cy1, cy2, spoke.end.y, t);

  return new PVector(x, y);
}

PVector getPerimeterIntersection(PVector origin, float angle) {
  float dx = cos(angle);
  float dy = sin(angle);
  float tMin = Float.MAX_VALUE;

  if (dx > 0) tMin = min(tMin, (w - origin.x) / dx);
  else if (dx < 0) tMin = min(tMin, -origin.x / dx);

  if (dy > 0) tMin = min(tMin, (h - origin.y) / dy);
  else if (dy < 0) tMin = min(tMin, -origin.y / dy);

  return new PVector(origin.x + dx * tMin, origin.y + dy * tMin);
}

float getMaxSpokeLength(Spoke[] spokes) {
  float maxLen = 0;
  for (Spoke s : spokes) {
    if (s.length > maxLen) maxLen = s.length;
  }
  return maxLen;
}
