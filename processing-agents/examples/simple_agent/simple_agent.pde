//
// foundations
//
// using processing to do agent modeling.  use this sketch to establish the basic
// framework.
//
// - representing an agent
// - drawing the world
// - drawing the agent
// - timestepping
// 
// do a vehicle that makes random walk
//

Agent a;

// step 1: setup() - initialize things and set up the size of the view
void setup() {
  size(300, 300);
  a = new Agent();
}


// step 2: define an agent as a class with a position and velocity
class Agent {
  // velocity is a vector
  PVector vel; 
  PVector pos;
  
  Agent() {
    // new agent in the middle of things
    pos = new PVector(150.0, 150.0);
    vel = new PVector(random(2.0) - 1.0, random(2.0) - 1.0);
  }
  
  // step 4: action to take in a step
  void move() {
    pos.add(vel);
    PVector dv = new PVector(random(1.0)-0.5, random(1.0)-0.5);
    vel.add(dv);
    vel.limit(2.0);
    if (pos.x < 0) { pos.x = 300.0; }
    if (pos.x > 300.0) { pos.x = 0.0; }
    if (pos.y < 0) { pos.y = 300.0; }
    if (pos.y > 300.0) { pos.y = 0.0; }
  }
  
  // step 3: drawing the agent
  void draw() {
    ellipse(pos.x, pos.y, 10, 10);
    line(pos.x, pos.y, pos.x + vel.x*10, pos.y + vel.y*10);
  }
}

// step 3: drawing and time stepping
void draw() {
  background(204);
  a.move();
  a.draw();
}
