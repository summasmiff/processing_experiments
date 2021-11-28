import processing.svg.*;

String saveName = "lorenz_attractor_";
float x = random(0.01, 0.09); 
float y = random(0.01, 0.09); 
float z = random(0.01, 0.09); 

float a = 0.5; //spacing between points
float b = int(random(150,200)); 
float c = 1.1618; // spiral tightness

ArrayList<PVector> points = new ArrayList<PVector>();

void setup() {
  size(500, 750);
  background(255);
  println(b);
  println(c);
}

void draw() {
  rect(0, 0, 500, 750);
  float center_x = width/4;
  float center_y = height/2;
  
  float dt = 0.01;
  //calculate differential for each frame
  float delta_x = (a * (y - x)) * dt;
  x = x + delta_x;
  
  float delta_y = (x * (b - z) - y) * dt;
  y = y + delta_y;
  
  //only rendering in 2d but can try different projections
  float delta_z = (x * y - c * z)*dt;
  z = z + delta_z;
  
  points.add(new PVector(x + center_x, y + center_y));

  stroke(0);
  noFill();
  
  beginShape();
  for (PVector v : points) {
    vertex(v.x, v.y);
  }
  endShape();
  
  rect(center_x, center_y, 10, 10);
}

void exportSVG() {
    String exportName = saveName + b + ".svg";
    PGraphics pg = createGraphics(width, height, SVG, exportName);
    pg.beginDraw();
    pg.beginShape();
    for (PVector v : points) {
      pg.vertex(v.x, v.y);
    }
    pg.endShape();
    pg.endDraw();
    pg.dispose();
    
    println("Saved as " + exportName);
  }

void keyPressed() {
  if (key == 's' || key == 'S') {
    exportSVG();
  } 
}
