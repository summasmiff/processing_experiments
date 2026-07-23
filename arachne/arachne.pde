import processing.svg.*;
import java.util.Date;
import java.text.SimpleDateFormat;
import java.util.HashMap;

// --- base config ---
int width = 600;
int height = 800;
int webSpacing = 15;
int numSpokes = 20;

// --- keyPressed state ---
float droopFactor = 0.35;
boolean shouldRecord = false;

// --- constants ---
final float CURVE_SMOOTHNESS = 0.4;
final float HUB_RADIUS = 20;
final float DROOP_ADJUSTMENT_STEP = 0.05;
final float MAX_SPOKE_JITTER = 2.0; // degrees
final int MAX_SPIRAL_CONNECTIONS = 2;
final float MAX_STICK_ANGLE_DEGREES = 10.0;
final int SPACING_ADJUSTMENT = 1;

// --- stick perimeter state ---
PVector stick1Base, stick1Top;
PVector stick2Base, stick2Top;

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
  size(width, height);
  pixelDensity(1);
}

void setup() {
  noLoop();
  generateSticks();
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
  } else if (key == '[') {
    webSpacing = max(0, webSpacing - SPACING_ADJUSTMENT);
    println("webSpacing: " + webSpacing);
    redraw();
  } else if (key == ']') {
    webSpacing += SPACING_ADJUSTMENT;
    println("webSpacing: " + webSpacing);
    redraw();
  }
}

// --- stick generation ---
void generateSticks() {
  // stick 1: originates in first 20% of width
  float x1 = random(0, width * 0.2);
  stick1Base = new PVector(x1, height);
  // lean LEFT
  float angleOffset1 = random(-MAX_STICK_ANGLE_DEGREES, -1);
  float angle1 = radians(angleOffset1);

  // come to between 20% and 30% from the top
  float targetY1 = height * random(0.2, 0.3);
  float verticalDist1 = height - targetY1;
  float xOffset1 = verticalDist1 * tan(angle1);

  stick1Top = new PVector(max(0, x1 + xOffset1), targetY1);

  // stick 2: originates in last 20% of width
  float x2 = random(width * 0.8, width);
  stick2Base = new PVector(x2, height);
  // lean RIGHT
  float angleOffset2 = random(1, MAX_STICK_ANGLE_DEGREES);
  float angle2 = radians(angleOffset2);

  // Come to within between 1% and 5% from the top
  float targetY2 = height * random(0.01, 0.05);
  float verticalDist2 = height - targetY2;
  float xOffset2 = verticalDist2 * tan(angle2);

  stick2Top = new PVector(min(width, x2 + xOffset2), targetY2);
}

void spinWeb() {
  PVector stick1Center = PVector.add(stick1Base, stick1Top).div(2);
  PVector stick2Center = PVector.add(stick2Base, stick2Top).div(2);
  PVector hubCenter = PVector.add(stick1Center, stick2Center).div(2);
  Spoke[] spokes = generateSpokes(hubCenter);

  drawPerimeter();
  drawSpokes(spokes);
  drawHub(spokes);
  drawSpiral(spokes);
}

void drawPerimeter() {
  stroke(255, 0, 0); // RED for debug
  strokeWeight(3);
  line(stick1Base.x, stick1Base.y, stick1Top.x, stick1Top.y);
  line(stick2Base.x, stick2Base.y, stick2Top.x, stick2Top.y);

  // web frame strand
  stroke(0);
  strokeWeight(1);
  PVector t1 = new PVector(stick1Top.x, stick1Top.y);
  PVector t2 = new PVector(stick2Top.x, stick2Top.y);
  drawDroopedCurve(t1, t2, droopFactor);
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
  float maxSpiralRadius = (0.55 * getMaxSpokeLength(spokes));
  float minSpiralRadius = (4.5 * webSpacing); // Distance from hub vertex

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
  PVector dir = new PVector(cos(angle), sin(angle));
  float tMin = Float.MAX_VALUE;
  PVector closestIntersect = null;

  PVector t1 = new PVector(stick1Top.x, stick1Top.y);
  PVector t2 = new PVector(stick2Top.x, stick2Top.y);

  // Stick 1
  PVector intersect = raySegmentIntersect(origin, dir, stick1Base, stick1Top);
  if (intersect != null) {
    float t = PVector.dist(origin, intersect);
    if (t > 0.1 && t < tMin) { tMin = t; closestIntersect = intersect; }
  }

  // Web frame strand
  intersect = rayBezierIntersect(origin, dir, t1, t2, droopFactor, 20);
  if (intersect != null) {
    float t = PVector.dist(origin, intersect);
    if (t > 0.1 && t < tMin) { tMin = t; closestIntersect = intersect; }
  }

  // Stick 2
  intersect = raySegmentIntersect(origin, dir, stick2Top, stick2Base);
  if (intersect != null) {
    float t = PVector.dist(origin, intersect);
    if (t > 0.1 && t < tMin) { tMin = t; closestIntersect = intersect; }
  }

  // Bottom edge of sketch
  intersect = raySegmentIntersect(origin, dir, stick2Base, stick1Base);
  if (intersect != null) {
    float t = PVector.dist(origin, intersect);
    if (t > 0.1 && t < tMin) { tMin = t; closestIntersect = intersect; }
  }

  // Fallback to prevent null pointers
  if (closestIntersect == null) {
    closestIntersect = PVector.add(origin, PVector.mult(dir, 100));
  }

  return closestIntersect;
}

PVector rayBezierIntersect(PVector origin, PVector dir, PVector p1, PVector p2, float factor, int numSegments) {
  PVector midDroop = calculateDroopControlPoint(p1, p2, factor);

  float cx1 = lerp(p1.x, midDroop.x, CURVE_SMOOTHNESS);
  float cy1 = lerp(p1.y, midDroop.y, CURVE_SMOOTHNESS);
  float cx2 = lerp(p2.x, midDroop.x, CURVE_SMOOTHNESS);
  float cy2 = lerp(p2.y, midDroop.y, CURVE_SMOOTHNESS);

  float tMin = Float.MAX_VALUE;
  PVector closestIntersect = null;

  PVector prevPoint = p1.copy();
  for (int i = 1; i <= numSegments; i++) {
    float t = (float) i / numSegments;
    float x = bezierPoint(p1.x, cx1, cx2, p2.x, t);
    float y = bezierPoint(p1.y, cy1, cy2, p2.y, t);
    PVector currPoint = new PVector(x, y);

    PVector intersect = raySegmentIntersect(origin, dir, prevPoint, currPoint);
    if (intersect != null) {
      float dist = PVector.dist(origin, intersect);
      if (dist > 0.1 && dist < tMin) {
        tMin = dist;
        closestIntersect = intersect;
      }
    }

    prevPoint = currPoint;
  }

  return closestIntersect;
}

// Helper method for precise 2D ray-to-line-segment intersection
PVector raySegmentIntersect(PVector origin, PVector dir, PVector a, PVector b) {
  PVector v1 = PVector.sub(origin, a);
  PVector v2 = PVector.sub(b, a);
  PVector v3 = new PVector(-dir.y, dir.x);

  float dot = PVector.dot(v2, v3);
  if (abs(dot) < 0.000001) return null; // Parallel lines

  float t1 = (v2.x * v1.y - v2.y * v1.x) / dot;
  float t2 = PVector.dot(v1, v3) / dot;

  // t1 is distance along ray, t2 is distance along segment (0.0 to 1.0)
  if (t1 > 0 && t2 >= 0.0 && t2 <= 1.0) {
    return PVector.add(origin, PVector.mult(dir, t1));
  }
  return null;
}

float getMaxSpokeLength(Spoke[] spokes) {
  float maxLen = 0;
  for (Spoke s : spokes) {
    if (s.length > maxLen) maxLen = s.length;
  }
  return maxLen;
}
