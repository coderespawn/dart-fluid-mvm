import 'dart:html';
import 'package:fluid_mvm/fluid_mvm.dart';
import 'package:fluid_mvm/fluid_mvm_renderer2d.dart';

FluidSimulator simulator;
CanvasRenderingContext2D context;

void main() {
  CanvasElement canvas = querySelector("#fluid_canvas");
  context = canvas.context2D;
  
  // Create the fluid simulator
  simulator = new FluidSimulator();
  simulator.initializeGrid(canvas.width, canvas.height);
  
  // Add some initial particles
  for (int i = 0; i < 50; i++) {
    for (int j = 0; j < 50; j++) {
      simulator.addParticle(i * 2 + 10, j * 2 + 10, 0.5, 0);
    }
  }
  
  // Create a 2d renderer to draw the fluid
  simulator.renderer = new FluidRenderer2D(context);
  
  window.animationFrame.then(draw);
}

void draw(num elapsedTime) {
  // Clear out the background
  context.strokeStyle = "black";
  context.fillStyle = "white";
  context.fillRect(0, 0, context.canvas.width, context.canvas.height);

  // Update the simulation
  simulator.update();
  
  // Draw the fluid particles
  simulator.draw();
  
  window.animationFrame.then(draw);
}
