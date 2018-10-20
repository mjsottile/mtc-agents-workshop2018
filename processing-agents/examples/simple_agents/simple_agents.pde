//
// foundations
//
// using processing to do agent modeling.  use this sketch to establish the basic
// framework.
//
// - scaling up a to 
// 
// do a vehicle that makes random walk
//

Agent a[];
int WIDTH, HEIGHT;

// step 1: setup() - initialize things and set up the size of the view
void setup() {
  int NUMAGENTS = 1000;
  HEIGHT = 500;
  WIDTH = 500;
  
  size(500, 500);
  
  a = new Agent[NUMAGENTS];
  
  for (int i = 0; i < a.length; i++) {
    a[i] = new Agent();
  }
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
    if (pos.x < 0) { pos.x = WIDTH; }
    if (pos.x > WIDTH) { pos.x = 0.0; }
    if (pos.y < 0) { pos.y = HEIGHT; }
    if (pos.y > HEIGHT) { pos.y = 0.0; }
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
  for (int i = 0; i < a.length; i++) {
    a[i].move();
    a[i].draw();
  }
}
