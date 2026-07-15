import processing.svg.*;
import java.util.Date;
import java.text.SimpleDateFormat;

String fernFilename = "fern-6";

PShape fernSVG;
PShape[] bentFronds; // frond cache
boolean shouldRecord = false;

// bent frond
float frondBendRadius = 700; // Needs to be larger than the svgHeight
float angleDeg = random(50, 75);
float svgWidth; // needed for correct aspect ratio
float svgHeight;
// how much of the spiral to use
float spiralAngleDeg = random(20, 150); // good values: 82 92
float PHI = 1.61803398875f;

// 3D Fern render
int frondNum = 11;
float maxFernDistance = 500;

String generateFilename() {
  String timestamp = new SimpleDateFormat("yyyyMMdd-HHmmss").format(new Date());
  return "fern-3d-" + timestamp + ".svg";
}

void setup() {
  size(800, 800, P3D);
  hint(ENABLE_DEPTH_SORT); // helper for rendering 3d to svg
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
  translate(width / 2, (height - (height/3)), 0);
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
      // use pen plotting styles
      PShape pathSection = createShape();
      pathSection.beginShape();
      pathSection.noFill();
      pathSection.stroke(0);
      pathSection.strokeWeight(1);

      for (int j = 0; j < vertexCount; j++) {
        PVector v = source.getVertex(j);

        float flippedY = svgHeight - v.y; // flip upside down so ferns grow up
        float normalizedY = flippedY / svgHeight; // y as percentage of height

        float theta = normalizedY * radians(spiralAngleDeg);
        float centeredX = v.x - (svgWidth / 2);
        float xFlare = 0.10;

        // Golden spiral radius.
        // Radius changes by PHI every quarter turn.
        // Negative exponent = inward curl toward the frond tip.
        float r = frondBendRadius * pow(PHI, -theta / HALF_PI);
        float bentX = centeredX * (1 + xFlare * normalizedY);
        float bentY = r * sin(theta);
        float bentZ = frondBendRadius - r * cos(theta);

        pathSection.vertex(bentX, bentY, bentZ);

      }
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
