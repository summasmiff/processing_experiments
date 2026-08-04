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
float frondBendRadius = random(500, 700); // Needs to be larger than the svgHeight
float angleDeg = random(50, 75);
float spiralAngleDeg = random(120, 150); // how much of the spiral to use
int frondNum = 11;
float maxFernDistance = 500;

String generateFilename() {
  String timestamp = new SimpleDateFormat("yyyyMMdd-HHmmss").format(new Date());
  return "fern-3d-" + timestamp + ".svg";
}

void setup() {
  size(800, 800, P3D);
  hint(ENABLE_DEPTH_SORT); // helper for rendering 3d to svg
  pixelDensity(1);
  println("frondBendRadius: ", frondBendRadius);
  println("spiralAngleDeg: ", spiralAngleDeg);

  fernSVG = loadShape(fernFilename + ".svg"); // lives in "./data"
  if (fernSVG == null) {
    println("WHOA no svg found :(");
    exit();
    return;
  }
  svgWidth = fernSVG.width;
  svgHeight = fernSVG.height;

  // bent fern cache
  bentFronds = new PShape[frondNum];
  for (int i = 0; i < frondNum; i++) {
    bentFronds[i] = createShape(GROUP);
    buildBentFrondCache(fernSVG, bentFronds[i]);
  }
}

void draw() {
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
    // rotateZ(HALF_PI);
    translate(0, 0, random(maxFernDistance));
    shape(bentFronds[i]);

    popMatrix();
  }

  if (shouldRecord) {
    endRaw();
    shouldRecord = false;
    println("yay SVG exported!");
  }
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
  if (key == 'r' || key == 'R') {
    shouldRecord = true;
  }
}
