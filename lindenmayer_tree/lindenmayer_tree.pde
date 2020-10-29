import processing.svg.*;

Turtle turtle;
LSystem lsys;
String _saveName = "l_system_";
int transforms = 0;
float theta;

void setup() {
  size(500, 750);
  noFill();
  strokeWeight(2);
  stroke(0);

  Rule[] ruleset = new Rule[1];
  ruleset[0] = new Rule('F', "FF+[+F-F-F]-[-F+F+F]");
  lsys = new LSystem("F", ruleset);

  float start_len = width/4;
  turtle = new Turtle(lsys.getSentence(), start_len, radians(25));
}

void draw () {
  translate(width/2, height);
  rotate(-PI/2);
  turtle.render();
  noLoop();
}

void mousePressed() {
  if (transforms < 5) {
    pushMatrix();
    lsys.generate();
    turtle.setToDo(lsys.getSentence());
    turtle.changeLen(0.5);
    popMatrix();
    redraw();
    transforms++;
  }
}

void keyPressed() {
  if (key == 's' || key == 'S') {
    exportSVG();
  }
}

void exportSVG() {
  String saveName = _saveName + transforms + ".svg";
  turtle.renderSVG(width, height, saveName);
  
  println("saved " + saveName);
}
