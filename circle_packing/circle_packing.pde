import processing.svg.*;

Pack pack;

String _saveName = "circle_packing_";
int _circles_amt = 200;
float _min_radius = 2;
float _max_radius = 100;
float _border = 5;
boolean _growing = false;

void setup() {
  size(750, 500);
  noFill();
  strokeWeight(1);
  stroke(0);
  noiseDetail(2, 0.1);
  
  pack = new Pack(_circles_amt);
}

void draw() {
  background(255);
  pack.run();

  if (_growing) {
    pack.addCircle(new Circle(width/2, height/2));
  }
}

void keyPressed() {
  if (key == 's' || key == 'S') {
    pack.exportSVG();
  }
}

void mouseClicked() {
  pack.addCircle(new Circle(mouseX, mouseY));
}

class Pack {
  ArrayList<Circle> circles;
  
  float max_speed = 1;
  float max_force = 1;
  float border = _border;
  float min_radius = _min_radius;
  float max_radius = _max_radius;
  
  Pack(int n) {
    init(n);
  }
  
  void init(int n) {
    circles = new ArrayList<Circle>();
    for (int i=0; i<n; i++) {
      int startX = int(random(width));
      int startY = int(random(height));
      addCircle(new Circle(startX, startY));
    }
  }
  
  void addCircle(Circle c) {
    circles.add(c);
  }
  
  void run() {
    PVector[] separate_forces = new PVector[circles.size()];
    int[] near_circles = new int[circles.size()];
    
    for (int i=0; i<circles.size(); i++) {
      checkBorders(i);
      updateCircleRadius(i);
      applySeparationForcesToCircle(i, separate_forces, near_circles);
      displayCircle(i);
    }
  }
  
  void checkBorders(int i) {
    Circle c_i = circles.get(i);
    
    // check x position
    if (c_i.position.x - c_i.radius/2 < border) {
      c_i.position.x = c_i.radius/2 + border; }
    else if (c_i.position.x + c_i.radius/2 > width - border) {
      c_i.position.x = width - c_i.radius/2 - border; }
    
    // check y position
    if (c_i.position.y - c_i.radius/2 < border) {
      c_i.position.y = c_i.radius/2 + border; }
    else if (c_i.position.y + c_i.radius/2 > height - border) {
      c_i.position.y = height - c_i.radius/2 - border; }
  }
  
  void updateCircleRadius(int i) {
    circles.get(i).updateRadius(min_radius, max_radius);
  }
  
  void applySeparationForcesToCircle(int i, PVector[] separate_forces, int[] near_circles) {
    if (separate_forces[i] == null) {
      separate_forces[i] = new PVector();
    }
    
    Circle c_i = circles.get(i);
    
    for (int j = i+1; j<circles.size(); j++) {
      if (separate_forces[j] == null) {
        separate_forces[j] = new PVector();
      }
      
      Circle c_j = circles.get(j);
      
      PVector forceij = getSeparationForce(c_i, c_j);
      
      if (forceij.mag() > 0) {
        separate_forces[i].add(forceij);
        separate_forces[j].sub(forceij);
        near_circles[i]++;
        near_circles[j]++;
      }
    }
    
    if (near_circles[i]>0) {
      separate_forces[i].div((float)near_circles[i]);
    }
    
    if (separate_forces[i].mag() > 0) {
      separate_forces[i].setMag(max_speed);
      separate_forces[i].sub(circles.get(i).velocity);
      separate_forces[i].limit(max_force);
    }
    
    PVector separation = separate_forces[i];
    
    circles.get(i).applyForce(separation);
    circles.get(i).update();
    
    // stop moving if no overlapping neighbors
    c_i.velocity.x = 0.0;
    c_i.velocity.y = 0.0;
  }
  
  PVector getSeparationForce(Circle n1, Circle n2) {
    PVector steer = new PVector(0,0,0);
    float d = PVector.dist(n1.position, n2.position);
    if ((d > 0) && (d < n1.radius/2 + n2.radius/2 + border)) {
      PVector diff = PVector.sub(n1.position, n2.position);
      diff.normalize();
      diff.div(d);
      steer.add(diff);
    }
    
    return steer;
  }
  
  void displayCircle(int i) {
    circles.get(i).display();
  }
  
  void exportSVG() {
    String saveName = _saveName + circles.size() + ".svg";
    PGraphics pg = createGraphics(width, height, SVG, saveName);
    pg.beginDraw();
    for(int i=0; i<circles.size(); i++) {
      Circle c = circles.get(i);
      pg.ellipse(c.position.x, c.position.y, c.radius, c.radius);
    }
    pg.endDraw();
    pg.dispose();
    println("saved " + saveName);
  }
  
}

class Circle {
  PVector position;
  PVector velocity;
  PVector acceleration;
  
  float radius = 1;
  
  Circle(float x, float y) {
    acceleration = new PVector(0, 0);
    velocity = PVector.random2D();
    position = new PVector(x, y);
  }
  
  void applyForce(PVector force) {
    acceleration.add(force);
  }
  
  void update() {
    velocity.add(acceleration);
    position.add(velocity);
    acceleration.mult(0);
  }
  
  void updateRadius(float min, float max) {
    radius = min + noise(position.x*0.01, position.y*0.01) * (max-min);
  }
  
  void display() {
    ellipse(position.x, position.y, radius, radius);
  }
}
