import processing.svg.*;
import java.util.Date;
import java.text.SimpleDateFormat;

int cols,rows;
int scale = 7;
float z_scale = random(90); // height displacement
int w = 900;
int h = 700;
float noiseScale = 0.12;
boolean shouldRecord = false;
PShape grid;
int octave;
float noiseFalloff = 0.5;

String generateFilename() {
  String timestamp = new SimpleDateFormat("yyyyMMdd-HHmmss").format(new Date());
  return "drift_" + timestamp + ".svg";
}

public void settings() {
  size(w, h, P3D);
  pixelDensity(1);
}

void setup() {
  hint(ENABLE_DEPTH_SORT); // helper for rendering 3d to svg
  cols = w / scale;
  rows = h / scale;

  octave = round(random(1, 5));
  noiseDetail(octave, noiseFalloff);

  buildGrid();
}

void buildGrid() {
  grid = createShape(GROUP);

  // Define how much of the canvas height should be disintegrating
  float skipPercentage = 80.0;

  // Y coordinate where disintegration should start
  // eg If skipPercentage is 80, it starts 20% from the top.
  float startSkipY = map(100.0 - skipPercentage, 0.0, 100.0, -h/2.0, h/2.0);

  for (int y = 0; y < rows; y++) {
    PShape currentStrip = null;

    for (int x = 0; x < cols; x++) {
      float xPos = x * scale - w/2;
      float yPos = y * scale - h/2;
      float yNextPos = (y + 1) * scale - h/2;
      float baseZ = (x + y) * 0.2;
      float n0 = noise(x * noiseScale, y * noiseScale);
      float n1 = noise(x * noiseScale, (y + 1) * noiseScale);
      float wave = sin((x + y) * 0.12 + n0 * TWO_PI) * z_scale * 0.6;
      float z1 = n0 * z_scale + baseZ + wave;
      float z2 = n1 * z_scale + baseZ + wave;

      boolean shouldDraw = true;

      if (yPos > startSkipY) {
        float skipProbability = constrain(map(yPos, startSkipY, h/2.0, 0.0, 1.0), 0.0, 1.0);

        if (random(1) < skipProbability) {
          shouldDraw = false;
        }
      }

      if (shouldDraw) {
        if (currentStrip == null) {
          currentStrip = createShape();
          currentStrip.beginShape(QUAD_STRIP);
          currentStrip.stroke(0);
          currentStrip.strokeWeight(1);
          currentStrip.noFill();
        }
        currentStrip.vertex(xPos, yPos, z1);
        currentStrip.vertex(xPos, yNextPos, z2);

      } else {
        if (currentStrip != null) {
          currentStrip.endShape();
          grid.addChild(currentStrip);
          currentStrip = null;
        }
      }
    }

    if (currentStrip != null) {
      currentStrip.endShape();
      grid.addChild(currentStrip);
    }
  }
}

void draw() {
  if (shouldRecord) {
    beginRaw(SVG, generateFilename());
  }

  background(255);

  pushMatrix();
  translate(width/2, height/2, 0);
  rotateX(map(mouseY, 0, height, -PI/2, PI/2));
  rotateY(map(mouseX, 0, width, -PI, PI));
  shape(grid);
  popMatrix();

  if (shouldRecord) {
    endRaw();
    shouldRecord = false;
    println("yay SVG exported!");
  }
}

void keyPressed() {
  if (key == 'r' || key == 'R') {
    shouldRecord = true;
  } else if (key == '+' || key == '=') {
    octave = min(12, octave + 1);
    noiseDetail(octave, noiseFalloff);
    println("octave:", octave);
    buildGrid();
  } else if (key == '-') {
    octave = max(1, octave - 1);
    noiseDetail(octave, noiseFalloff);
    println("octave:", octave);
    buildGrid();
  } else if (key == '[') {
    z_scale = max(10, z_scale - 10);
    println("z_scale:", z_scale);
    buildGrid();
  } else if (key == ']') {
    z_scale = min(90, z_scale + 10);
    println("z_scale:", z_scale);
    buildGrid();
  }
}
