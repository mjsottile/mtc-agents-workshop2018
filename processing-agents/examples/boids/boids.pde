//
// three rules:
//
// - separation : steer to avoid overcrowding local flockmates
// - alignment : steer towards average heading of local flockmates
// - cohesion : steer towards the center of mass of local flockmates
//

final int WIDTH = 400;
final int HEIGHT = 400;
float max_vel = 2.0;
float cohesion_strength = 0.8;
float separation_strength = 0.15;
float alignment_strength = 1.5;
float noise_strength = 0.05;

class Boid {
  PVector x;
  PVector v;
  
  Boid() {
    x = new PVector(floor(random(WIDTH)), floor(random(HEIGHT)));
    v = new PVector(random(-1,1), random(-1,1));
  }
  
  PVector step_vec(ArrayList<Boid> ns) {
    PVector com = x.copy();
    for (Boid b: ns) {
      com.add(b.x);
    }
    com.mult(1.0 / (ns.size() + 1));
    com.sub(x);
    com.mult(cohesion_strength);
    
    PVector avg_heading = v.copy();
    for (Boid b: ns) {
      avg_heading.add(b.v);
    }
    avg_heading.mult(1.0 / (ns.size() + 1));
    avg_heading.sub(v);
    avg_heading.mult(alignment_strength);
    
    PVector sep = new PVector(0.0, 0.0);
    for (Boid b: ns) {
      sep.add(x.copy().sub(b.x));
    }
    sep.mult(separation_strength);
    
    PVector noise = new PVector(random(-noise_strength, noise_strength),
                                random(-noise_strength, noise_strength));
    
    PVector sv = new PVector(0.0, 0.0);
    sv.add(com);
    sv.add(avg_heading);
    sv.add(sep);
    sv.add(noise);
    return sv;
  }
  
  void move() {
    x.add(v);
    if (x.x > WIDTH) { x.x -= WIDTH; }
    if (x.x < 0) {x.x += WIDTH; }
    if (x.y > HEIGHT) {x.y -= HEIGHT; }
    if (x.y < 0) {x.y += HEIGHT; }
  }
}

ArrayList<Boid> boids;

int nboids = 100;
float radius = 10.0;

ArrayList<Boid> neighbors(Boid b, float r) {
  ArrayList<Boid> ns = new ArrayList<Boid>();
  for (Boid b2 : boids) {
    PVector x = b2.x.copy();
    if (x.dist(b.x) <= r) {
      ns.add(b2);
    }
  }
  
  return ns;
}

void onestep() {
  for (Boid b: boids) {
    PVector bv = b.step_vec(neighbors(b, radius));
    b.v.add(bv);
    b.v.limit(max_vel);                          
  }
  for (Boid b: boids) {
    b.move();
  }
}

void setup() {
  size(400,400);
  boids = new ArrayList<Boid>();
  for (int i = 0; i < nboids; i++) {
    boids.add(new Boid());
  }
}

void draw() {
  background(204);
  onestep();
  for (Boid b: boids) {
    fill(color(250,250,0));
    ellipse(b.x.x, b.x.y, 5, 5);
    fill(color(250,0,250));
    line(b.x.x, b.x.y, b.x.x+b.v.x*10, b.x.y+b.v.y*10);
  }
}
