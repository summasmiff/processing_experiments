import processing.svg.*;
import com.jogamp.opengl.GL;
import com.jogamp.opengl.GL2ES2;
 
PJOGL pgl;
GL2ES2 gl;
float x,y,z, hMax, alpha1, alpha2, alpha3;

void setup() {
  // width, height in pixels
  // slightly smaller than a5
  size(750, 500, P3D);
  // backface culling not working with default sphere => need to build own primitives?
  //pgl = (PJOGL) beginPGL();  
  //gl = pgl.gl.getGL2ES2();
  //gl.glEnable(GL.GL_CULL_FACE);
  //gl.glFrontFace(GL.GL_CCW);
  //gl.glCullFace(GL.GL_BACK);
  x = width/2;
  y = height/2;
  z = 0;
  hMax = 3;
  alpha1 = 0;
  alpha2 = 0;
  alpha3 = 0;
  smooth();
  strokeWeight(1);
  stroke(0,0,0);
  noFill();
  
  beginRaw(SVG, "sphere.svg");
  translate(x, y, z);
  sphereDetail(12);
  sphere(200);
  endRaw();
  println("done");
}
