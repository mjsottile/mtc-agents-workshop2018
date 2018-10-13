class Agent {
  PVector pos, vel;
  
  Agent() {
    pos = new PVector(0.0, 0.0);
    vel = new PVector(1.0, 1.0);
  }
  
  void step() {
    pos = pos.add(vel);
    
    if (pos.x < 0 || pos.x > width || pos.y < 0 || pos.y > height) {
      pos = pos.sub(vel);
    }
    
    //vel = vel.add(new PVector(random(1.0)-0.5, random(1.0)-0.5));
    vel = new PVector(random(3.0)-1.5, random(3.0)-1.5);
  }
  
  void draw() {
    fill(color(255,0,0));
    ellipse(pos.x, pos.y, 40.0, 40.0);
  }
}

//

Agent a;

void setup() {
  size(300, 300);
  a = new Agent();
}

void draw() {
  background(204);  
  
  a.draw();
  
  a.step();
}
