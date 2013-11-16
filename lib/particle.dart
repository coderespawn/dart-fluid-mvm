part of fluid_mvm;

class Particle {

  num x, y, u, v;
  int cx, cy, gi;
  List<num> px = [0, 0, 0];
  List<num> py = [0, 0, 0];
  List<num> gx = [0, 0, 0];
  List<num> gy = [0, 0, 0];
  
  Particle([this.x = 0, this.y = 0, this.u = 0, this.v= 0]);
  
  void initializeWeights(int gSizeY) {
    cx = (x - .5).toInt();
    cy = (y - .5).toInt();
    gi = cx * gSizeY + cy;
    
    num cx_x = cx - x;
    num cy_y = cy - y;
    
    // Quadratic interpolation kernel weights - Not meant to be changed
    px[0] = .5 * cx_x * cx_x + 1.5 * cx_x + 1.125;
    gx[0] = cx_x + 1.5;
    cx_x++;
    px[1] = -cx_x * cx_x + .75;
    gx[1] = -2 * cx_x;
    cx_x++;
    px[2] = .5 * cx_x * cx_x - 1.5 * cx_x + 1.125;
    gx[2] = cx_x - 1.5;
    
    py[0] = .5 * cy_y * cy_y + 1.5 * cy_y + 1.125;
    gy[0] = cy_y + 1.5;
    cy_y++;
    py[1] = -cy_y * cy_y + .75;
    gy[1] = -2 * cy_y;
    cy_y++;
    py[2] = .5 * cy_y * cy_y - 1.5 * cy_y + 1.125;
    gy[2] = cy_y - 1.5;
  }
}
