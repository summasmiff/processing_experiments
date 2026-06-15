import processing.svg.*;
import java.util.Date;
import java.text.SimpleDateFormat;

PShape fernSVG;
boolean shouldRecord = false; // Used to control svg render

// Frond Deformation -
float radius = 350;
float svgWidth = 409;  // needed for correct aspect ratio
float svgHeight = 785; // can this be derived from loading the shape?

// 3D Fern Render
int frondNum = 8;     // Number of SVGs arranged in the circle
float circleRadius = 200;  // How far from the center the SVGs are placed

String generateFilename() {
  String timestamp = new SimpleDateFormat("yyyyMMdd-HHmmss").format(new Date());
  return "fern-3d-" + timestamp + ".svg";
}

void setup() {
  size(800, 800, P3D);
  fernSVG = loadShape("fern.svg"); // lives in "./data"
}

void draw() {
  if (shouldRecord) {
    beginRaw(SVG, generateFilename());
  }

  background(255);

  // Position camera
  translate(width / 2, height / 2, -1200);

  // camera controlled by mouse
  rotateX(map(mouseY, 0, height, -PI, PI));
  rotateY(map(mouseX, 0, width, -PI, PI));

  // axidraw style
  noFill();
  stroke(0);
  strokeWeight(1);

  for (int i = 0; i < frondNum; i++) {
    pushMatrix();
    float ringAngle = map(i, 0, frondNum, 0, TWO_PI);

    // rotate and move the local grid
    rotateY(ringAngle);
    translate(0, 0, circleRadius);

    // render the frond at this position
    deformAndDrawShape(fernSVG);

    popMatrix(); // restore local grid transforms
  }

  if (shouldRecord) {
    endRaw();
    shouldRecord = false;
    println("Vector SVG exported successfully!");
  }
}

void deformAndDrawShape(PShape shp) {
  int childCount = shp.getChildCount(); // get svg groups

  if (childCount > 0) {
    for (int i = 0; i < childCount; i++) {
      deformAndDrawShape(shp.getChild(i));
    }
  } else {
    int vertexCount = shp.getVertexCount();
    if (vertexCount > 0) {
      beginShape();
      for (int j = 0; j < vertexCount; j++) {
        PVector v = shp.getVertex(j);

        // main deform: arc along y axis
        float flippedY = svgHeight - v.y; // flip Y so bottom is at origin (0)
        float normalizedY = flippedY / svgHeight; // y as percentage from bottom
        float angle = normalizedY * PI;

        // this too i guess
        float centeredX = v.x - (svgWidth / 2);
        float xFlare = 0.80; // increase to push tips further outward

        float bentX = centeredX * (1 + xFlare * normalizedY);
        float bentY = radius * sin(angle);
        float bentZ = radius - radius * cos(angle); // flip the Z so the frond curves out
        vertex(bentX, bentY, bentZ);
      }
      endShape();
    }
  }
}

void keyPressed() {
  if (key == 'r' || key == 'R') {
    shouldRecord = true;
  }
}
