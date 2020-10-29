class Turtle {
  String todo;
  float len;
  float theta;

  Turtle(String sentence, float length, float angle) {
    todo = sentence;
    len = length;
    theta = angle;
  }

  void render() {
    stroke(0);
    for (int i=0; i < todo.length(); i++) {
      switch(todo.charAt(i)) {
      case 'F':
        line(0, 0, len, 0);
        translate(len, 0);
        break;
      case '+':
        rotate(theta);
        break;
      case '-': 
        rotate(-theta);
        break;
      case '[': 
        pushMatrix();
        break;
      case ']': 
        popMatrix();
        break;
      default: 
        break;
      }
    }
  }

  void renderSVG(int w, int h, String saveName) {
    PGraphics pg = createGraphics(w, h, SVG, saveName);
    pg.beginDraw();
    pg.stroke(0);
    pg.strokeWeight(1);
    pg.translate(width/2, height);
    pg.rotate(-PI/2);
    for (int i=0; i < todo.length(); i++) {
      switch(todo.charAt(i)) {
      case 'F':
        pg.line(0, 0, len, 0);
        pg.translate(len, 0);
        break;
      case '+':
        pg.rotate(theta);
        break;
      case '-': 
        pg.rotate(-theta);
        break;
      case '[': 
        pg.pushMatrix();
        break;
      case ']': 
        pg.popMatrix();
        break;
      default: 
        break;
      }
    }
    pg.endDraw();
    pg.dispose();
  }

  void setLen(float l) {
    len = l;
  }

  void changeLen(float percent) {
    len *= percent;
  }

  void setToDo(String s) {
    todo = s;
  }
}
