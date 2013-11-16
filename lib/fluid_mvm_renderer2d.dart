library fluid_mvm_renderer2d;
import 'package:fluid_mvm/fluid_mvm.dart';
import 'dart:html';

class FluidRenderer2D extends FluidRenderer {
  CanvasRenderingContext2D context;
  FluidRenderer2D(this.context);
  num scaleX;
  num scaleY;
  
  /**
   *  Called once per frame before the first geometry is drawn
   *  [gridWidth] is the width of the fluid simulation's world
   *  [gridHeight] is the height of the fluid simulation's world 
   */
  void drawBegin(int gridWidth, int gridHeight) {
    scaleX = context.canvas.width / gridWidth; 
    scaleY = context.canvas.height / gridHeight;
    context.beginPath();
  }
  
  /** Draw the actual particle */
  void drawParticle(num x, num y, num u, num v) {
    x *= scaleX; 
    u *= scaleX; 
    y *= scaleY; 
    v *= scaleY;
    context.moveTo(x, y);
    context.lineTo(x - u, y - v);
  }

  /** Called after all the geometry has been drawn */
  void drawEnd() {
    context.closePath();
    context.stroke();
  }
}