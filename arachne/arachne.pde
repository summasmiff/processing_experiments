import processing.svg.*;
import java.util.Date;
import java.text.SimpleDateFormat;
import java.util.HashMap;

int w = 700;
int h = 900;
float curveSmoothness = 0.4;

// Globals for keyPressed editing
int webSpacing = 15;
float droopFactor = 0.25;
int numSpokes = 20;
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
  noLoop();
}

void draw() {
  if (!shouldRecord) {
    background(255);
  }

  if (shouldRecord) {
    beginRecord(SVG, generateFilename());
  }

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

// SVG export-friendly cubic bezier with two distinct control points for gradual droop
void drawBezierCurve(float x1, float y1, float midDroopX, float midDroopY, float x2, float y2) {
  // Control point 1: between start and midpoint, biased toward start
  float cx1 = lerp(x1, midDroopX, curveSmoothness);
  float cy1 = lerp(y1, midDroopY, curveSmoothness);

  // Control point 2: between end and midpoint, biased toward end
  float cx2 = lerp(x2, midDroopX, curveSmoothness);
  float cy2 = lerp(y2, midDroopY, curveSmoothness);

  beginShape();
  vertex(x1, y1);
  bezierVertex(cx1, cy1, cx2, cy2, x2, y2);
  endShape();
}

void spinWeb() {
  PVector hub = new PVector(w / 2.0, h / 2.0);
  float hubRadius = 20;
  float minRadius = hubRadius + webSpacing;

  float baseAngle = TWO_PI / numSpokes;
  float[] angles = new float[numSpokes];
  float[] radii = new float[numSpokes];
  PVector[] spokeEnds = new PVector[numSpokes];

  // Draw spokes
  for (int i = 0; i < numSpokes; i++) {
    float angle = i * baseAngle + radians(random(-2, 2));
    angles[i] = angle;

    PVector perimeterPoint = getPerimeterIntersection(hub, angle);
    spokeEnds[i] = perimeterPoint;
    radii[i] = dist(hub.x, hub.y, perimeterPoint.x, perimeterPoint.y);

    float hubVertexX = hub.x + cos(angle) * hubRadius;
    float hubVertexY = hub.y + sin(angle) * hubRadius;

    float segDx = perimeterPoint.x - hubVertexX;
    float segDy = perimeterPoint.y - hubVertexY;
    float segAngle = atan2(segDy, segDx);
    float horizontalness = abs(cos(segAngle));
    float segLength = dist(hubVertexX, hubVertexY, perimeterPoint.x, perimeterPoint.y);

    float midX = (hubVertexX + perimeterPoint.x) / 2.0;
    float midY = (hubVertexY + perimeterPoint.y) / 2.0;

    float droopAmount = segLength * horizontalness * droopFactor;
    float cx = midX;
    float cy = midY + droopAmount;
    drawBezierCurve(hubVertexX, hubVertexY, cx, cy, perimeterPoint.x, perimeterPoint.y);
  }

  // Draw the hub polygon
  beginShape();
  for (int i = 0; i < numSpokes; i++) {
    float hubVertexX = hub.x + cos(angles[i]) * hubRadius;
    float hubVertexY = hub.y + sin(angles[i]) * hubRadius;
    vertex(hubVertexX, hubVertexY);
  }
  endShape(CLOSE);

  float spiralStep = webSpacing;
  float maxRadius = 0;
  for (float r : radii) {
    if (r > maxRadius) maxRadius = r;
  }
  // Collect connection points to ensure only 2 spiral segments connects to each spoke
  HashMap<String, Integer> connections = new HashMap<String, Integer>();

  // Draw spiral segments
  for (float currentRadius = maxRadius; currentRadius > minRadius; currentRadius -= spiralStep) {
    for (int i = 0; i < numSpokes; i++) {
      int next = (i + 1) % numSpokes;

      if (radii[i] >= currentRadius) {
        PVector p1 = getDroopedSpokePoint(hub, angles[i], hubRadius, currentRadius, radii[i], droopFactor);
        float r2 = min(radii[next], currentRadius);
        PVector p2 = getDroopedSpokePoint(hub, angles[next], hubRadius, r2, radii[next], droopFactor);

        String key1 = i + "_" + round(currentRadius);
        String key2 = next + "_" + round(r2);

        int count1 = connections.getOrDefault(key1, 0);
        int count2 = connections.getOrDefault(key2, 0);

        if (count1 < 2 && count2 < 2) {
          float segDx = p2.x - p1.x;
          float segDy = p2.y - p1.y;
          float segAngle = atan2(segDy, segDx);
          float horizontalness = abs(cos(segAngle));
          float segLength = dist(p1.x, p1.y, p2.x, p2.y);

          float midX = (p1.x + p2.x) / 2.0;
          float midY = (p1.y + p2.y) / 2.0;
          float droopAmount = segLength * horizontalness * droopFactor;

          float cx = midX;
          float cy = midY + droopAmount;
          drawBezierCurve(p1.x, p1.y, cx, cy, p2.x, p2.y);

          connections.put(key1, count1 + 1);
          connections.put(key2, count2 + 1);
        }
      }
    }
  }
}

PVector getDroopedSpokePoint(PVector hub, float angle, float hubRadius, float targetRadius, float spokeLength, float droopFactor) {
  float hubVertexX = hub.x + cos(angle) * hubRadius;
  float hubVertexY = hub.y + sin(angle) * hubRadius;
  float perimeterX = hub.x + cos(angle) * spokeLength;
  float perimeterY = hub.y + sin(angle) * spokeLength;

  float segLength = spokeLength - hubRadius;
  float horizontalness = abs(cos(angle));
  float droopAmount = segLength * horizontalness * droopFactor;

  float midDroopX = (hubVertexX + perimeterX) / 2.0;
  float midDroopY = (hubVertexY + perimeterY) / 2.0 + droopAmount;

  // Calculate two control points matching the drawBezierCurve function
  float cx1 = lerp(hubVertexX, midDroopX, curveSmoothness);
  float cy1 = lerp(hubVertexY, midDroopY, curveSmoothness);
  float cx2 = lerp(perimeterX, midDroopX, curveSmoothness);
  float cy2 = lerp(perimeterY, midDroopY, curveSmoothness);

  float t = (targetRadius - hubRadius) / segLength;
  t = constrain(t, 0, 1);

  float x = bezierPoint(hubVertexX, cx1, cx2, perimeterX, t);
  float y = bezierPoint(hubVertexY, cy1, cy2, perimeterY, t);

  return new PVector(x, y);
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
    redraw();
  }

  if (keyCode == DOWN) {
    droopFactor += 0.05;
    println("droopFactor: " + droopFactor);
    redraw();
  }

  if (keyCode == UP) {
    droopFactor = max(0, droopFactor - 0.05);
    println("droopFactor: " + droopFactor);
    redraw();
  }
}
