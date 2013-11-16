part of fluid_mvm;

/** Fluid renderer interface.  Create an implementation to draw with a specific graphic library */
abstract class FluidRenderer {
  /** Called once per frame before the first geometry is drawn */
  void drawBegin(int gridWidth, int gridHeight);
  
  /** Draw the actual particle */
  void drawParticle(num x, num y, num u, num v);

  /** Called after all the geometry has been drawn */
  void drawEnd();
}
