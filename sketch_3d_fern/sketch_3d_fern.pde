import processing.svg.*;
import java.util.Date;
import java.text.SimpleDateFormat;

String fernFilename = "simple-fern-3";

PShape fernSVG;
PShape[] bentFronds; // frond cache

//consts
float svgWidth; // needed for correct aspect ratio
float svgHeight;
float PHI = 1.61803398875f;

// state
boolean shouldRecord = false;
boolean needsRebuild = true; // flag to rebuild cache

float frondBendRadius;
float spiralAngleDeg;
int frondNum = 11;
float maxFernDistance = 500;

String generateFilename() {
  String timestamp = new SimpleDateFormat("yyyyMMdd-HHmmss").format(new Date());
  return "fern-3d-" + timestamp + ".svg";
}

void randomizeState() {
  frondBendRadius = random(500, 700);
  spiralAngleDeg = random(120, 150);
  frondNum = 11;
  maxFernDistance = 500;
}

void rebuildFrondCache() {
  // frondBendRadius must be at least svg height to not warp the shape
  frondBendRadius = max(svgHeight, frondBendRadius);

  bentFronds = new PShape[frondNum];
  for (int i = 0; i < frondNum; i++) {
    bentFronds[i] = createShape(GROUP);
    buildBentFrondCache(fernSVG, bentFronds[i]);
  }
  println("Rebuilt Cache -> BendRadius: " + nf(frondBendRadius,0,1) +
          " | Spiral: " + nf(spiralAngleDeg,0,1) +
          " | Fronds: " + frondNum +
          " | Distance: " + nf(maxFernDistance,0,1));
}

void setup() {
  size(800, 800, P3D);
  hint(ENABLE_DEPTH_SORT); // helper for rendering 3d to svg
  pixelDensity(1);

  fernSVG = loadShape(fernFilename + ".svg"); // lives in "./data"
  if (fernSVG == null) {
    println("WHOA no svg found :(");
    exit();
    return;
  }
  svgWidth = fernSVG.width;
  svgHeight = fernSVG.height;

  // Initialize state and build cache for the first time
  randomizeState();
  rebuildFrondCache();
}

void draw() {
  if (needsRebuild) {
    rebuildFrondCache();
    needsRebuild = false;
  }

  if (shouldRecord) {
    beginRaw(SVG, generateFilename());
  }
  background(255);

  // camera position with mouse control
  translate(width / 2, (height - (height/3)), -200);
  rotateX(map(mouseY, 0, height, -TWO_PI, TWO_PI));
  rotateY(map(mouseX, 0, width, -TWO_PI, TWO_PI));
  scale(0.4); // make fern smaller to fit on screen

  // axidraw styles
  noFill();
  stroke(0);
  strokeWeight(1);

  // render loop using cache
  randomSeed(1234);
  for (int i = 0; i < frondNum; i++) {
    pushMatrix();

    float ringAngle = map(i, 0, frondNum, 0, TWO_PI);
    rotateY(ringAngle);
    translate(0, 0, random(maxFernDistance));
    shape(bentFronds[i]);

    popMatrix();
  }

  if (shouldRecord) {
    endRaw();
    shouldRecord = false;
    println("yay SVG exported!");
  }

  drawHUD();
}

void drawHUD() {
  // 2D HUD for key command hints
  // Save 3D drawing styles and 3D matrix transformations for later
  pushStyle();
  pushMatrix();

  // turn off depth testing so text draws on top of everything
  hint(DISABLE_DEPTH_TEST);
  // switch to a flat 2D camera
  ortho(-width/2, width/2, -height/2, height/2, -1000, 1000);
  // clear out the 3D scene's rotateX, rotateY, and scale(0.4)
  resetMatrix();
  // move the origin (0,0) to the top-left corner
  translate(-width/2, -height/2, 0);

  noStroke();
  fill(0, 0, 0, 200); // Semi-transparent black background
  rect(10, 10, 270, 155, 5);

  fill(255);
  textSize(14);
  textLeading(18);
  textAlign(LEFT, TOP);

  String hudText = "--- FERN CONTROLS ---\n";
  hudText += "[Q / A] Bend Radius: " + nf(frondBendRadius, 0, 1) + "\n";
  hudText += "[W / S] Spiral Angle: " + nf(spiralAngleDeg, 0, 1) + " deg\n";
  hudText += "[E / D] Frond Count:  " + frondNum + "\n";
  hudText += "[T / G] Max Distance: " + nf(maxFernDistance, 0, 1) + "\n";
  hudText += "[SPACE] Randomize All\n";
  hudText += "[R] Record SVG";

  text(hudText, 20, 15);

  // switch back to 3D perspective
  perspective();
  hint(ENABLE_DEPTH_TEST);
  popMatrix();
  popStyle();
}

void buildBentFrondCache(PShape source, PShape targetGroup) {
  int childCount = source.getChildCount();

  if (childCount > 0) {
    for (int i = 0; i < childCount; i++) {
      buildBentFrondCache(source.getChild(i), targetGroup);
    }
  } else {
    int vertexCount = source.getVertexCount();
    if (vertexCount > 0) {

      PShape pathSection = createShape();
      pathSection.beginShape();
      pathSection.noFill();
      pathSection.stroke(0);
      pathSection.strokeWeight(1);

      PVector prevBent = null;
      // Prevent random lines being added due to svg point ordering
      // if a gap in the fernSVG is larger than this value, start a new shape.
      // modify value HERE if necessary (svg missing chunks: reduce threshold, random lines: increase threshold)
      float gapThreshold = 200.0f;

      for (int j = 0; j < vertexCount; j++) {
        PVector v = source.getVertex(j);

        float flippedY = svgHeight - v.y;
        // guard: prevent math explosions if a vertex falls slightly outside the SVG bounds
        float normalizedY = constrain(flippedY / svgHeight, 0.0, 1.0);

        float theta = normalizedY * radians(spiralAngleDeg);
        float centeredX = v.x - (svgWidth / 2);
        float xFlare = 0.10;

        float r = frondBendRadius * pow(PHI, -theta / HALF_PI);
        float bentX = centeredX * (1 + xFlare * normalizedY);
        float bentY = r * sin(theta);
        float bentZ = frondBendRadius - r * cos(theta);

        PVector currentBent = new PVector(bentX, bentY, bentZ);

        // GAP DETECTION: If the distance from the last point is too large,
        // fernSVG path jumped to a new sub-shape.
        if (prevBent != null && PVector.dist(prevBent, currentBent) > gapThreshold) {

          // Finish the current shape and add it to the group
          pathSection.endShape();
          targetGroup.addChild(pathSection);

          // Start a brand new shape for this disconnected line
          pathSection = createShape();
          pathSection.beginShape();
          pathSection.noFill();
          pathSection.stroke(0);
          pathSection.strokeWeight(1);
        }

        pathSection.vertex(bentX, bentY, bentZ);
        prevBent = currentBent;
      }

      // Add the final shape
      pathSection.endShape();
      targetGroup.addChild(pathSection);
    }
  }
}

void keyPressed() {
  boolean changed = false;

  // [R] Record
  if (key == 'r' || key == 'R') {
    shouldRecord = true;
  }
  // [SPACE] Randomize
  else if (key == ' ') {
    randomizeState();
    changed = true;
  }
  // [Q / A] Adjust frondBendRadius
  else if (key == 'q' || key == 'Q') {
    frondBendRadius += 20;
    changed = true;
  } else if (key == 'a' || key == 'A') {
    frondBendRadius -= 20;
    changed = true;
  }
  // [W / S] Adjust spiralAngleDeg
  else if (key == 'w' || key == 'W') {
    spiralAngleDeg += 5;
    changed = true;
  } else if (key == 's' || key == 'S') {
    spiralAngleDeg -= 5;
    changed = true;
  }
  // [E / D] Adjust frondNum
  else if (key == 'e' || key == 'E') {
    frondNum++;
    changed = true;
  } else if (key == 'd' || key == 'D') {
    frondNum = max(1, frondNum - 1); // prevent going below 1
    changed = true;
  }
  // [T / G] Adjust maxFernDistance
  else if (key == 't' || key == 'T') {
    maxFernDistance += 20;
    changed = true;
  } else if (key == 'g' || key == 'G') {
    maxFernDistance -= 20;
    changed = true;
  }

  if (changed) {
    needsRebuild = true;
  }
}
