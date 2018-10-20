float cohesion_scale = 0.075;
float separation_scale = 2.125;
float separation_eps = 0.1;
float alignment_scale = 1.0/1.8;

// history parameters
int history_length = 15;
int curstep = 0;

// timing parameters
int interval = 25;
int lastRecordedTime = 0;

// optional plotting flags
boolean fade_colors = true;
boolean show_history = true;

int numBouncyAgents = 1600;




class BouncyAgent {
  PVector pos, vel;
  PVector[] history;
  
  BouncyAgent(float x, float y, float vx, float vy) {
    pos = new PVector(x,y);
    vel = new PVector(vx,vy);
    history = new PVector[history_length];
  }
  
  PVector cohesion(BouncyAgent[] BouncyAgents) {
    PVector tot = pos.copy();
    int n = 1;
  
    for (int i = 0; i < numBouncyAgents; i++) {
      if (pos.dist(BouncyAgents[i].pos) < eps) {
        n += 1;
        tot.add(BouncyAgents[i].pos);
      }
    }
  
    tot.mult(cohesion_scale / float(n));
    tot.sub(pos);
    return tot;
  }
  
  PVector separation(BouncyAgent[] BouncyAgents) {
    PVector v = new PVector(0.0, 0.0);
    
    for (int i = 0; i < numBouncyAgents; i++) {
      if (pos.dist(BouncyAgents[i].pos) < separation_eps) {
        PVector t = BouncyAgents[i].pos.copy();
        t.sub(pos);
        v.sub(t);
      }
    }
    
    v.mult(separation_scale);
    return v;
  }

  PVector alignment(BouncyAgent[] BouncyAgents) {
    PVector v = new PVector(0.0, 0.0);
    int n = 1;
    
    for (int i = 0; i < numBouncyAgents; i++) {
      if (pos.dist(BouncyAgents[i].pos) < eps) {
        v.add(BouncyAgents[i].vel);
        n += 1;
      }
    }
    
    v.mult(1.0 / float(n));
    v.sub(vel);
    v.mult(separation_scale);
    return v;
  }


  void step(float dt, BouncyAgent[] others) {
    PVector v_cohesion = cohesion(others);
    PVector v_separation = separation(others);
    PVector v_alignment = alignment(others);
    history[curstep] = pos.copy();
    
    // update velocity
    PVector t = v_cohesion;
    t.add(v_separation);
    t.add(v_alignment);
    t.mult(0.1);
    vel.add(t);
    
    // scale velocity and add to self.
    PVector v = vel.copy();
    v.mult(dt);
    pos.add(v);
    
    // keep inside the bounding box
    if (abs(pos.x) > 1.0) {
      pos.x *= -1.0;
    }
    if (abs(pos.y) > 1.0) {
      pos.y *= -1.0;
    }
  }
}

BouncyAgent[] BouncyAgents = new BouncyAgent[numBouncyAgents];
float eps = 0.1;

void init() {
  for (int i = 0; i < numBouncyAgents; i++) {
    BouncyAgents[i] = new BouncyAgent(random(-1,1),random(-1,1),random(-0.2,0.2),random(-0.2,0.2));
  }
}

void iteration() {
  for (int i = 0; i < numBouncyAgents; i++) {
    BouncyAgents[i].step(0.1, BouncyAgents);
  }
  curstep = (curstep + 1) % history_length;
}

void setup() {
  size(800,800);
  init();
}

void draw() {
  background(51);
  for (int i = 0; i < numBouncyAgents; i++) {
    if (show_history) {
      for (int j = 0; j < history_length; j++) {
        int hpos = (curstep + j) % history_length;
        if (BouncyAgents[i].history[hpos] != null) {
          if (fade_colors) {
            fill(color(255/(history_length-j),0,0));
          }
          ellipse(BouncyAgents[i].history[hpos].x*(width/2-20) + width/2, 
                  BouncyAgents[i].history[hpos].y*(height/2-20) + height/2, 5, 5);
        }
      }
    }
    
    ellipse(BouncyAgents[i].pos.x*(width/2-20) + width/2, BouncyAgents[i].pos.y*(height/2-20)+height/2, 5, 5);
  }
  if (millis()-lastRecordedTime > interval) {
    iteration();
    lastRecordedTime = millis();
  }
}
