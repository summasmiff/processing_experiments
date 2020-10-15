import processing.svg.*;

String saveName = "differential_growth_";
// params
float _maxForce = 0.2;
float _maxForceNoise = Float.NaN; //disable: set to Float.NaN;
float _maxSpeed = 2;
float _separationCohesionRation = 1.5;

// make the next two similar to make tightly packed lines
float _desiredSeparation = 9;
float _maxEdgeLen = 9;

long _randomSeed;

DifferentialLine _diff_line;

void setup() {
  size(750, 500, FX2D);
  startNewLine();
}

void draw() {
  background(255);
  _diff_line.run();
  _diff_line.renderAsShape();
}

void startNewLine() {
  _randomSeed = (long)random(-1000000, 1000000);
  println("Random seed: " + _randomSeed);
  randomSeed(_randomSeed);
  
  _diff_line = new DifferentialLine(_maxForce, _maxForceNoise, _maxSpeed, _desiredSeparation, _separationCohesionRation, _maxEdgeLen);
  
  float nodesStart = 20;
  float angInc = TWO_PI/nodesStart;
  float rayStart = 10;
  
  for (float a=0; a<TWO_PI; a+= angInc) {
    float x = width/2 + cos(a) * rayStart;
    float y = height/2 + sin(a) * rayStart;
    _diff_line.addNode(new Node(x, y, _diff_line.maxForce, _diff_line.maxSpeed));
  }
}

class DifferentialLine {
  ArrayList<Node> nodes;
  float maxForce;
  float maxForceNoise;
  float maxSpeed;
  float desiredSeparation;
  float sq_desiredSeparation;
  float separationCohesionRation;
  float maxEdgeLen;
  
  DifferentialLine(float mF, float mFn, float mS, float dS, float sCr, float eL) {
    nodes = new ArrayList<Node>();
    maxForce = mF;
    maxForceNoise = mFn;
    maxSpeed = mS;
    desiredSeparation = dS;
    sq_desiredSeparation = sq(desiredSeparation);
    separationCohesionRation = sCr;
    maxEdgeLen = eL;
  }
  
  void addNode(Node n) {
    nodes.add(n);
  }
  
  void addNodeAt(Node n, int index) {
    nodes.add(index, n);
  }
  
  void run() {
    differentiate();
    growth();
  }
  
  void differentiate() {
    int n = nodes.size();
    PVector[] separateForces = getSeparationForces();
    PVector[] cohesionForces = getEdgeCohesionForces();
    
    for (int i=0; i<nodes.size(); i++) {
      PVector separation = separateForces[i];
      PVector cohesion = cohesionForces[i];
      
      separation.mult(separationCohesionRation);
      
      nodes.get(i).applyForce(separation);
      nodes.get(i).applyForce(cohesion);
      nodes.get(i).update();
    }
  }
  
  void growth() {
    for (int i=0; i<nodes.size()-1; i++) {
      Node n1 = nodes.get(i);
      Node n2 = nodes.get(i+1);
      float d = PVector.dist(n1.position, n2.position);
      if (d>maxEdgeLen) {
        int index = nodes.indexOf(n2);
        PVector middleNode = PVector.add(n1.position, n2.position).div(2);
        addNodeAt(new Node(middleNode.x, middleNode.y, maxForce, maxSpeed), index);
      }
    }
  }
  
  void updateMaxForceByPosition(int i) {
    if (!Float.isNaN(maxForceNoise)) {
      float new_max_force = noise(nodes.get(i).position.x * 0.01, nodes.get(i).position.y * 0.01) * maxForceNoise;
      nodes.get(i).maxForce = new_max_force;
    }
  }
  
  void checkBorders(Node n, float border) {
    if (n.position.x < border || n.position.x > width - border) {
      n.velocity.x *= -1;
    }
    if (n.position.y < border || n.position.y > height - border) {
      n.velocity.y *= -1;
    } 
  }
  
  PVector[] getSeparationForces() {
    int n = nodes.size();
    PVector[] separateForces = new PVector[n];
    int[] nearNodes = new int[n];
    
    Node nodei;
    Node nodej;
    
    for (int i=0; i<n; i++) {
      separateForces[i] = new PVector();
    }
    
    for (int i=0; i<n; i++) {
      nodei = nodes.get(i);
      for (int j=i+1; j<n; j++) {
        nodej = nodes.get(j);
        PVector forceij = getSeparationForce(nodei, nodej);
        if (forceij.mag()>0) {
          separateForces[i].add(forceij);
          separateForces[j].sub(forceij);
          nearNodes[i]++;
          nearNodes[j]++;
        }
      }
      if (nearNodes[i]>0) {
        separateForces[i].div((float)nearNodes[i]);
      }
      
      if (separateForces[i].mag() >0) {
        separateForces[i].setMag(maxSpeed);
        separateForces[i].sub(nodes.get(i).velocity);
        separateForces[i].limit(maxForce);
      }
    }
    
    return separateForces;
  }
  
  PVector getSeparationForce(Node n1, Node n2) {
    PVector steer = new PVector(0,0);
    float sq_d = sq(n2.position.x-n1.position.x)+sq(n2.position.y-n1.position.y);
    if (sq_d>0 && sq_d<sq_desiredSeparation) {
      PVector diff = PVector.sub(n1.position, n2.position);
      diff.normalize();
      diff.div(sqrt(sq_d));
      steer.add(diff);
    }
    return steer;
  }
  
  PVector[] getEdgeCohesionForces() {
    int n = nodes.size();
    PVector[] cohesionForces = new PVector[n];
    
    for (int i=0; i<n; i++) {
      PVector sum = new PVector(0,0);
      if (i!=0 && i!=n-1) {
        sum.add(nodes.get(i-1).position).add(nodes.get(i+1).position);
      } else if (i == 0) {
        sum.add(nodes.get(n-1).position).add(nodes.get(1).position);
      } else if (i == n-1) {
        sum.add(nodes.get(i-1).position).add(nodes.get(0).position);
      }
      sum.div(2);
      cohesionForces[i] = nodes.get(i).seek(sum);
    }
    
    return cohesionForces;
  }
  
  PVector getEdgeCohesionForce(int i) {
    PVector sum = new PVector(0,0);
    if (i!=0 && i!=nodes.size()-1) {
      sum.add(nodes.get(i-1).position).add(nodes.get(i+1).position);
    } else if (i == 0) {
      sum.add(nodes.get(nodes.size()-1).position).add(nodes.get(1).position);
    } else if (i == nodes.size()-1) {
      sum.add(nodes.get(i-1).position).add(nodes.get(0).position);
    }
    sum.div(2);
    return nodes.get(i).seek(sum);
  }
  
  void renderAsShape() {
    smooth();
    stroke(0,0,0);
    strokeWeight(1);
    noFill();
    beginShape();
    for (int i=0; i<nodes.size(); i++) {
      vertex(nodes.get(i).position.x, nodes.get(i).position.y);
    }
    endShape(CLOSE);
  }
  
  void exportSVG() {
    String exportName = saveName + nodes.size() + ".svg";
    PGraphics pg = createGraphics(width, height, SVG, exportName);
    pg.beginDraw();
    pg.beginShape();
    for (int i=0; i<nodes.size(); i++) {
      pg.vertex(nodes.get(i).position.x, nodes.get(i).position.y);
    }
    pg.endShape(CLOSE);
    pg.endDraw();
    pg.dispose();
    
    println("Saved as " + exportName);
  }
}

class Node {
  PVector position;
  PVector velocity;
  PVector acceleration;
  
  float maxForce;
  float maxSpeed;
  
  Node(float x, float y, float mS, float mF) {
    acceleration = new PVector(0,0);
    velocity = PVector.random2D();
    position = new PVector(x, y);
    maxSpeed = mS;
    maxForce = mF;
  }
  
  void applyForce(PVector force) {
    acceleration.add(force);
  }
  
  void update() {
    velocity.add(acceleration);
    velocity.limit(maxSpeed);
    position.add(velocity);
    acceleration.mult(0);
  }
  
  PVector seek(PVector target) {
    PVector desired = PVector.sub(target, position);
    desired.setMag(maxSpeed);
    PVector steer = PVector.sub(desired, velocity);
    steer.limit(maxForce);
    return steer;
  }
  
  void render() {
    fill(0);
    ellipse(position.x, position.y, 2, 2);
  }
}

void displayFrameRate() {
  fill(255);
  text((int)_randomSeed, 20, 20);
  text((int)frameRate, 20, 35);
}

void keyPressed() {
  if (key == 's' || key == 'S') {
    _diff_line.exportSVG();
  } else if (key == 'r' || key == 'R') {
    startNewLine();
  }
}
