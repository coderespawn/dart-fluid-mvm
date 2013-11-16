part of fluid_mvm;

/** 
 * MVM Fluid simulator based on Grant Kot's work:
 * https://github.com/kotsoft/FluidCinder
 */
class FluidSimulator {
  int gSizeX, gSizeY, gSizeY_3;
  List<Node> grid = new List<Node>();
  List<Node> active = new List<Node>();
  Material mat = new Material();
  var random = new Random();
  FluidRenderer renderer;
  num _fluidToWorldScale;
  num _worldToFluidScale; 
  
  num uscip(num p00, num x00, num y00, num p01, num x01, num y01, num p10, num x10, num y10, num p11, num x11, num y11, num u, num v)
  {
    num dx = x00 - x01;
    num dy = y00 - y10;
    num a = p01 - p00;
    num b = p11 - p10 - a;
    num c = p10 - p00;
    num d = y11 - y01;
    return ((((d - 2 * b - dy) * u - 2 * a + y00 + y01) * v +
        ((3 * b + 2 * dy - d) * u + 3 * a - 2 * y00 - y01)) * v +
        ((((2 * c - x00 - x10) * u + (3 * b + 2 * dx + x10 - x11)) * u - b - dy - dx) * u + y00)) * v +
        (((x11 - 2 * (p11 - p01 + c) + x10 + x00 + x01) * u +
            (3 * c - 2 * x00 - x10)) * u +
            x00) * u + p00;
  }
  
  List<Particle> particles = new List<Particle>();
  Simulator() {}
  void initializeGrid(int sizeX, int sizeY, [num fluidToWorldScale = 4.0]) {
    _fluidToWorldScale = fluidToWorldScale;
    _worldToFluidScale = 1.0 / fluidToWorldScale; 
    
    sizeX = (sizeX * _worldToFluidScale).toInt();
    sizeY = (sizeY * _worldToFluidScale).toInt();
    gSizeX = sizeX;
    gSizeY = sizeY;
    gSizeY_3 = sizeY - 3;
    grid = new List<Node>(gSizeX * gSizeY);
    for (int i = 0; i < gSizeX*gSizeY; i++) {
      grid[i] = new Node();
    }
  }
  
  void addParticle(num x, num y, [num u = 0, num v = 0]) {
    Particle p = new Particle(x, y, u, v);
    p.initializeWeights(gSizeY);
    particles.add(p);
  }
  
  void draw() {
    if (renderer == null) return;
    renderer.drawBegin(gSizeX, gSizeY);
    int numParticles = particles.length;

    num x, y, u, v;
    for (int i = 0; i < numParticles; i++) {
      Particle p = particles[i];
      renderer.drawParticle(p.x, p.y, p.u, p.v);
    }
    renderer.drawEnd();
  }
  
  void update() {
    // Reset grid nodes
    int nActive = active.length;
    for (int i = 0; i < nActive; i++) {
      active[i].active = false;
    }
    active.clear();
    
    // Add particle mass, velocity and density gradient to grid
    var nodeIndex;
    int nParticles = particles.length;
    for (int pi = 0; pi < nParticles; pi++) {
      Particle p = particles[pi];
      var px = p.px;
      var gx = p.gx;
      var py = p.py;
      var gy = p.gy;
      nodeIndex = p.gi;
      Node n;
      for (int i = 0; i < 3; i++, nodeIndex += gSizeY_3) {
        num pxi = px[i];
        num gxi = gx[i];
        for (int j = 0; j < 3; j++, nodeIndex++) {
          Node n = grid[nodeIndex];
          num pyj = py[j];
          num gyj = gy[j];
          num phi = pxi * pyj;
          if (n.active) {
            n.mass += phi;
            n.gx += gxi * pyj;
            n.gy += pxi * gyj;
          } else {
            n.active = true;
            active.add(n);
            n.mass = phi;
            n.gx = gxi * pyj;
            n.gy = pxi * gyj;
            n.ax = 0;
            n.ay = 0;
          }
        }
      }
    }
    
    nActive = active.length;
    
    // Calculate pressure and add forces to grid
    for (int pi = 0; pi < nParticles; pi++) {
      Particle p = particles[pi];
      
      num fx = 0, fy = 0;
      Node n = grid[p.gi];
      var ppx = p.px;
      var pgx = p.gx;
      var ppy = p.py;
      var pgy = p.gy;
      
      int cx = p.x.toInt();
      int cy = p.y.toInt();
      int gi = cx * gSizeY + cy;
      
      Node n1 = grid[gi];
      Node n2 = grid[gi+1];
      Node n3 = grid[gi+gSizeY];
      Node n4 = grid[gi+gSizeY+1];
      
      num density = uscip(n1.mass, n1.gx, n1.gy, n2.mass, n2.gx, n2.gy, n3.mass, n3.gx, n3.gy, n4.mass, n4.gx, n4.gy, p.x - cx, p.y - cy);
      
      num pressure = mat.stiffness / mat.restDensity * (density - mat.restDensity);
      if (pressure > 2) {
        pressure = 2;
      }
      
      // Wall force
      if (p.x < 4) {
        fx += (4 - p.x);
      } else if (p.x > gSizeX - 5) {
        fx += (gSizeX - 5 - p.x);
      }
      if (p.y < 4) {
        fy += (4 - p.y);
      } else if (p.y > gSizeY - 5) {
        fy += (gSizeY - 5 - p.y);
      }
      
      // Add forces to grid
      nodeIndex = p.gi;
      for (int i = 0; i < 3; i++, nodeIndex += gSizeY_3) {
        num pxi = ppx[i];
        num gxi = pgx[i];
        for (int j = 0; j < 3; j++, nodeIndex++) {
          n = grid[nodeIndex];
          num pyj = ppy[j];
          num gyj = pgy[j];
          num phi = pxi * pyj;
          
          num gx = gxi * pyj;
          num gy = pxi * gyj;
          n.ax += -(gx * pressure) + fx * phi;
          n.ay += -(gy * pressure) + fy * phi;
        }
      }
    }
    
    // Update acceleration of nodes
    for (int i = 0; i < nActive; i++) {
      Node n = active[i];
      n.u = 0;
      n.v = 0;
      if (n.mass > 0) {
        n.ax /= n.mass;
        n.ay /= n.mass;
      }
    }
    
    for (int pi = 0; pi < nParticles; pi++) {
      Particle p = particles[pi];
      
      // Update particle velocities
      nodeIndex = p.gi;
      Node n;
      var px = p.px;
      var py = p.py; 
      for (int i = 0; i < 3; i++, nodeIndex += gSizeY_3) {
        num pxi = px[i];
        for (int j = 0; j < 3; j++, nodeIndex++) {
          n = grid[nodeIndex];
          num pyj = py[j];
          num phi = pxi * pyj;
          p.u += phi * n.ax;
          p.v += phi * n.ay;
        }
      }
      
      p.v += mat.gravity;
      
      // Add particle velocities back to the grid
      nodeIndex = p.gi;
      for (int i = 0; i < 3; i++, nodeIndex += gSizeY_3) {
        num pxi = px[i];
        for (int j = 0; j < 3; j++, nodeIndex++) {
          n = grid[nodeIndex];
          num pyj = py[j];
          num phi = pxi * pyj;
          n.u += phi * p.u;
          n.v += phi * p.v;
        }
      }
    }
    
    // Update node velocities
    for (int i = 0; i < nActive; i++) {
      Node n = active[i];
      if (n.mass > 0) {
        n.u /= n.mass;
        n.v /= n.mass;
      }
    }
    
    // Advect particles
    for (int pi = 0; pi < nParticles; pi++) {
      Particle p = particles[pi];
      
      num gu = 0, gv = 0;
      nodeIndex = p.gi;
      Node n;
      var ppx = p.px;
      var ppy = p.py;
      var pgx = p.gx;
      var pgy = p.gy;
      for (int i = 0; i < 3; i++, nodeIndex += gSizeY_3) {
        num pxi = ppx[i];
        for (int j = 0; j < 3; j++, nodeIndex++) {
          n = grid[nodeIndex];
          num pyj = ppy[j];
          num phi = pxi * pyj;
          gu += phi * n.u;
          gv += phi * n.v;
        }
      }
      
      p.x += gu;
      p.y += gv;
      
      p.u += mat.smoothing*(gu-p.u);
      p.v += mat.smoothing*(gv-p.v);
      
      // Hard boundary correction (Random numbers keep it from clustering)
      if (p.x < 1) {
        p.x = 1 + .01 * random.nextDouble();
      } 
      else if (p.x > gSizeX - 2) {
        p.x = gSizeX - 2 - .01 * random.nextDouble();
      }
      if (p.y < 1) {
        p.y = 1 + .01 * random.nextDouble();
      } 
      else if (p.y > gSizeY - 2) {
        p.y = gSizeY - 2 - .01 * random.nextDouble();
      }
      
      // Update grid cell index and kernel weights
      int cx = p.cx = (p.x - .5).toInt();
      int cy = p.cy = (p.y - .5).toInt();
      p.gi = cx * gSizeY + cy;
      
      num x = cx - p.x;
      num y = cy - p.y;
      
      // Quadratic interpolation kernel weights - Not meant to be changed
      ppx[0] = .5 * x * x + 1.5 * x + 1.125;
      pgx[0] = x + 1.5;
      x++;
      ppx[1] = -x * x + .75;
      pgx[1] = -2 * x;
      x++;
      ppx[2] = .5 * x * x - 1.5 * x + 1.125;
      pgx[2] = x - 1.5;
      
      ppy[0] = .5 * y * y + 1.5 * y + 1.125;
      pgy[0] = y + 1.5;
      y++;
      ppy[1] = -y * y + .75;
      pgy[1] = -2 * y;
      y++;
      ppy[2] = .5 * y * y - 1.5 * y + 1.125;
      pgy[2] = y - 1.5;
    }
  }
}
