import processing.svg.*;
import java.io.File;
import java.util.Arrays;
import java.util.Date;
import java.text.SimpleDateFormat;

String fernFilename = "bracken2";
String[] fernFilenames = {};
int fernFilenameIndex;

PShape fernSVG;
PShape[] bentFronds; // frond cache

//consts
float svgWidth; // needed for correct aspect ratio
float svgHeight;
float PHI = 1.61803398875f; // feels like this should be a const in Processing ??

// state
boolean recordSVG = false;
boolean savePreview = false;
boolean needsRebuild = true; // flag to rebuild frond cache

// editable parameters
float frondBendRadius;
float spiralAngleDeg;
int frondNum = 11;
float maxFernDistance = 500;
float maxRingAngle = 360;

String generateFilename() {
  String timestamp = new SimpleDateFormat("yyyyMMdd-HHmmss").format(new Date());
  return "fern-3d-" + timestamp + ".svg";
}

void randomizeState() {
  frondBendRadius = random(500, 700);
  spiralAngleDeg = random(50, 90);
  frondNum = frondNum;
  maxFernDistance = 500;
}

void rebuildFrondCache() {
  bentFronds = new PShape[frondNum];
  for (int i = 0; i < frondNum; i++) {
    bentFronds[i] = createShape(GROUP);
    buildBentFrondCache(fernSVG, bentFronds[i]);
  }
  println("Rebuilt Cache -> BendRadius: " + nf(frondBendRadius,0,1) +
          " | Spiral: " + nf(spiralAngleDeg,0,1) +
          " | Fronds: " + frondNum +
          " | maxRingAngle: " + maxRingAngle +
          " | Distance: " + nf(maxFernDistance,0,1));
}

void setup() {
  size(800, 800, P3D);
  pixelDensity(1);

  File[] dataFiles = new File(dataPath("")).listFiles();
  if (dataFiles == null) {
    println("Could not read the data folder.");
    exit();
    return;
  }
  for (File file : dataFiles) {
    if (file.isFile() && file.getName().toLowerCase().endsWith(".svg")) {
      fernFilenames = append(fernFilenames, file.getName());
    }
  }
  if (fernFilenames == null || fernFilenames.length == 0) {
    println("No SVG files found in the data folder.");
    exit();
    return;
  }
  Arrays.sort(fernFilenames);
  fernFilenameIndex = 0;
  for (int i = 0; i < fernFilenames.length; i++) {
    if (fernFilenames[i].equals(fernFilename + ".svg")) {
      fernFilenameIndex = i;
      break;
    }
  }

  fernSVG = loadShape(fernFilenames[fernFilenameIndex]);
  if (fernSVG == null) {
    println("OOPS! no svg found :(");
    exit();
    return;
  }
  fernFilename = fernFilenames[fernFilenameIndex].substring(
    0, fernFilenames[fernFilenameIndex].length() - 4
  );
  svgWidth = fernSVG.width;
  svgHeight = fernSVG.height;

  // Initialize frond cache
  randomizeState();
  rebuildFrondCache();
}

void draw() {
  if (needsRebuild) {
    rebuildFrondCache();
    needsRebuild = false;
  }

  if (recordSVG) {
    beginRaw(SVG, generateFilename());
  }
  background(255);

  // camera; mouse controls the view direction.
  translate(width * 0.5, height * 0.7, -300);
  rotateX(map(mouseY, 0, height, -TWO_PI, TWO_PI));
  rotateY(map(mouseX, 0, width, -TWO_PI, TWO_PI));
  scale(0.5); // resize fern on screen

  // axidraw styles
  noFill();
  stroke(0);
  strokeWeight(1);

  // render using cache
  randomSeed(1234);
  for (int i = 0; i < frondNum; i++) {
    pushMatrix();

    float ringAngle = map(i, 0, frondNum, 0, radians(maxRingAngle));
    rotateY(ringAngle);
    rotateX(random(radians(30)));
    translate(0, 0, random(maxFernDistance));
    shape(bentFronds[i]);

    popMatrix();
  }

  if (recordSVG) {
    endRaw();
    recordSVG = false;
    println("yay SVG exported!");
  }

  drawHUD();

  if (savePreview) {
    saveFrame("preview.png");
    savePreview = false;
    println("Saved preview.png");
  }
}

void drawHUD() {
  // 2D HUD for key commands and state display
  // Save 3D drawing styles and 3D matrix transformations for next fern draw frame
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

  // render HUD
  noStroke();
  fill(0, 0, 0, 200); // Semi-transparent black background
  rect(10, 10, 350, 195, 5);

  fill(255);
  textSize(14);
  textLeading(18);
  textAlign(LEFT, TOP);

  String hudText = "--- FERN CONTROLS ---\n";
  hudText += "[Q / A] Bend Radius: " + nf(frondBendRadius, 0, 1) + "\n";
  hudText += "[W / S] Spiral Angle: " + nf(spiralAngleDeg, 0, 1) + "\n";
  hudText += "[E / D] Frond Count:  " + frondNum + "\n";
  hudText += "[T / G] Max Distance: " + nf(maxFernDistance, 0, 1) + "\n";
  hudText += "[<- / ->] Max Ring Angle: " + nf(maxRingAngle, 0, 1) + "\n";
  hudText += "[SPACE] Randomize All\n";
  hudText += "[F] Fern: " + fernFilename + "\n";
  hudText += "[R] Record SVG\n";
  hudText += "[P] Save preview PNG";

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
    recordSVG = true;
  }
  // [P] Save a preview image
  else if (key == 'p' || key == 'P') {
    savePreview = true;
  }
  // [F] Cycle to the next fern SVG
  else if (key == 'f' || key == 'F') {
    fernFilenameIndex = (fernFilenameIndex + 1) % fernFilenames.length;
    String nextFilename = fernFilenames[fernFilenameIndex];
    PShape nextFern = loadShape(nextFilename);
    if (nextFern == null) {
      println("Could not load " + nextFilename + ".");
      fernFilenameIndex = (fernFilenameIndex - 1 + fernFilenames.length) % fernFilenames.length;
    } else {
      fernSVG = nextFern;
      fernFilename = nextFilename.substring(0, nextFilename.length() - 4);
      svgWidth = fernSVG.width;
      svgHeight = fernSVG.height;
      needsRebuild = true;
      println("Loaded fern: " + fernFilename);
    }
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
  // [left / right] Adjust maxRingAngle
  if (key == CODED) {
    if (keyCode == LEFT) {
      maxRingAngle += 20;
      changed = true;
    } else if (keyCode == RIGHT) {
      maxRingAngle -= 20;
      changed = true;
    }}

  if (changed) {
    needsRebuild = true;
  }
}
