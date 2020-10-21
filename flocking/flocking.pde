import processing.svg.*;

Flock flock;
String saveName = "flocking_";
int _flock_size = 350;
float _separationFactor = 1.5;
float _alignmentFactor = 1.0;
float _cohesionFactor = 1.0;
float _neighbordist = 50;
float _targetSeekingFactor = 0.5;
//PShape leaf = new PShape();

void setup() {
  size(750, 500);
  flock = new Flock();
  //leaf = loadShape("leaf.svg");

  //Add initial flock members
  for (int i=0; i < _flock_size; i++) {
    flock.addMember(new Member(width/2, height/2));
  }
}

void draw() {
  background(255);
  flock.run();
}

void mousePressed() {
  flock.addMember(new Member(mouseX, mouseY));
}

void keyPressed() {
  if (key == 's' || key == 'S') {
    flock.exportSVG();
  }
}

class Flock {
  ArrayList<Member> members;

  Flock() {
    members = new ArrayList<Member>();
  }

  void run() {
    for (Member m : members) {
      m.run(members); // Each member gets the entire list of members
    }
  }

  void addMember(Member m) {
    members.add(m);
  }
  
  void exportSVG() {
    String exportName = saveName + members.size() + ".svg";
    PGraphics pg = createGraphics(width, height, SVG, exportName);
    pg.beginDraw();
    pg.noFill();
    pg.strokeWeight(1);
    pg.stroke(0);
    
    for (int i=0; i<members.size(); i++) {
      Member m = members.get(i);
      pg.pushMatrix();
      float theta = m.velocity.heading() + radians(90);
      pg.translate(m.position.x, m.position.y);
      pg.rotate(theta); // rotate being applied globally?
      pg.ellipse(0, 0, m.r*4, m.r*8);
      pg.popMatrix();
    }
    
    pg.endDraw();
    pg.dispose();
    println("saved " + exportName);
  }
}

class Member {
  PVector position;
  PVector velocity;
  PVector acceleration; 
  float r;
  float maxForce;
  float maxSpeed;

  Member(float x, float y) {
    acceleration = new PVector(0, 0);
    velocity = PVector.random2D();
    position = new PVector(x, y);
    r = 2.0;
    maxSpeed = 2;
    maxForce = 0.03;
  }

  void run(ArrayList<Member> members) {
    flock(members);
    update();
    borders();
    render();
  }

  void applyForce(PVector force) {
    acceleration.add(force);
  }

  void flock(ArrayList<Member> members) {
    PVector separation = separate(members);
    PVector alignment = align(members);
    PVector cohesion = cohesion(members);
    PVector target = new PVector(mouseX, mouseY);
    PVector seeking_target = seek(target);

    separation.mult(_separationFactor);
    alignment.mult(_alignmentFactor);
    cohesion.mult(_cohesionFactor);
    seeking_target.mult(_targetSeekingFactor);

    applyForce(separation);
    applyForce(alignment);
    applyForce(cohesion);
    applyForce(seeking_target);
  }

  void update() {
    velocity.add(acceleration);
    velocity.limit(maxSpeed);
    position.add(velocity);
    // reset acceleration after each update
    acceleration.mult(0);
  }

  // returns desired minus velocity
  PVector seek(PVector target) {
    PVector desired = PVector.sub(target, position); // create a vector pointing from current position towards target
    desired.setMag(maxSpeed);
    PVector steer = PVector.sub(desired, velocity);
    steer.limit(maxForce);
    return steer;
  }

  PVector separate(ArrayList<Member> members) {
    float desiredSeparation = 25.0f;
    PVector steer = new PVector(0, 0, 0);
    int count = 0;
    // Check each member for being too close
    for (Member other : members) {
      float d = PVector.dist(position, other.position);
      // if NOT YOU and TOO CLOSE
      if ((d>0) && (d < desiredSeparation)) {
        PVector diff = PVector.sub(position, other.position);
        diff.normalize();
        diff.div(d); //weight by how close: move more if too close / less if further away
        steer.add(diff);
        count++;
      }
    }

    if (count > 0) {
      steer.div((float)count);
    }

    if (steer.mag() > 0) {
      steer.setMag(maxSpeed);

      // Reynolds flocking algo: steering = desired - velocity
      steer.normalize();
      steer.mult(maxSpeed);
      steer.sub(velocity);
      steer.limit(maxForce);
    }
    
    return steer;
  }
  
  PVector align(ArrayList<Member> members) {
    float neighbordist = _neighbordist;
    PVector sum = new PVector(0,0);
    int count = 0;
    for (Member other : members) {
      float d = PVector.dist(position, other.position);
      if ((d > 0) && (d < neighbordist)) {
        sum.add(other.velocity);
        count++;
      }
    }
    
    if (count < 0) {
      sum.div((float)count);
      sum.setMag(maxSpeed);
      sum.normalize();
      sum.mult(maxSpeed);
      PVector steer = PVector.sub(sum, velocity);
      steer.limit(maxForce);
      return steer;
    } else {
      return new PVector(0,0);
    }
  }
  
  PVector cohesion(ArrayList<Member> members) {
    float neighbordist = _neighbordist;
    PVector sum = new PVector(0,0);
    int count = 0;
    for (Member other : members) {
      float d = PVector.dist(position, other.position);
      if ((d > 0) && (d < neighbordist)) {
        sum.add(other.position);
        count++;
      }
    }
    if (count > 0) {
      sum.div(count);
      return seek(sum);
    } else {
      return new PVector(0,0);
    }
  }

  void render() {
    float theta = velocity.heading() + radians(90);
    stroke(0);
    noFill();
    pushMatrix();
    translate(position.x, position.y);
    rotate(theta);
    //shape(leaf, 0, 0, r, r);
    beginShape(TRIANGLES);
    vertex(0, -r*2);
    vertex(-r, r*2);
    vertex(r, r*2);
    endShape();
    popMatrix();
  }

  // wraparound
  void borders() {
    if (position.x < -r) position.x = width+r;
    if (position.y < -r) position.y = height+r;
    if (position.x > width + r) position.x = -r;
    if (position.y > height + r) position.y = -r;
  }
}
