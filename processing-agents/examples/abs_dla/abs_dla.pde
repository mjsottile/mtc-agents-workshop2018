float radius = 4.0;
float stepsize = 2.0;
float birth_rad = 30.0;
float reset_rad = birth_rad*1.5;
PVector birth_center;

PVector random_on_circle(float r) {
  float theta = random(TWO_PI);
  float x = r * cos(theta);
  float y = r * sin(theta);
  return new PVector(x+birth_center.x, y+birth_center.y);
}

void update_radii(PVector p) {
  float d_center = PVector.dist(birth_center, p);
  
  if (d_center > birth_rad/2) {
    birth_rad = birth_rad * 1.5;
    reset_rad = birth_rad + 30.0;
  }
}

class Particle extends Agent implements Drawable {
  boolean stuck, spawned;
  Model m;

  Particle(Model m) {
    super(m.agents, m.space);
    this.m = m;
    pos = random_on_circle(birth_rad);
    stuck = false;
    spawned = false;
  }

  void step() {
      if (stuck) {
          if (!spawned) {
              // generate new particle
              Particle kid = new Particle(m);
              m.add(kid);
              spawned = true;
          }
      } else {
          ArrayList<Agent> ns = space.neighbors_of(this, radius);
          if (ns.size() > 0) {
            for (Agent n : ns) {
              if (((Particle)n).stuck == true) {
                stuck = true;
                
                update_radii(n.pos);
                
                return;
              }
            }
          }

          // move
          PVector npos = PVector.add(pos, new PVector(random(stepsize)-stepsize/2,
                                                      random(stepsize)-stepsize/2));
          if (PVector.dist(birth_center, npos) > reset_rad) {
            npos = random_on_circle(birth_rad);
          }
          space.moveAgent(this, npos);
      }
  }

  void draw() {
    float xscale = width / (float)space.width();
    float yscale = height / (float)space.height();
    PVector x = new PVector(pos.x * xscale, pos.y * yscale);
    if (stuck) {
      fill(color(0,250,250));
    } else {
      if (show_all) {
        fill(color(250,250,0));
      } else {
        return;
      }
    }
    ellipse(x.x, x.y, 10, 10);
  }
}

Model m;

void setup() {
//  size(1000,1000);
  fullScreen();
  AgentSet agents = new AgentSet();
  KDTreeContinuousSpace s = new KDTreeContinuousSpace(width/2,height/2,agents);
  s.torus = false;
  
  ArbitraryScheduler sched = new ArbitraryScheduler("");
  m = new Model(agents, s, sched);

  birth_center = new PVector(s.width()/2, s.height()/2);

  Particle p = new Particle(m);
  p.pos = birth_center.copy();
  p.stuck = true;
  p.spawned = true;
  
  m.add(p);

  for (int i = 0; i < 100; i++) {
    Particle freep = new Particle(m);
    m.add(freep);
  }

}

int cur = 0;
int DRAW_STEPS = 1;
boolean show_all = true;

void draw() {
  if (cur == DRAW_STEPS) {
    background(0);
    float xscale = width / (float)m.space.width();
    float yscale = height / (float)m.space.height();

    if (show_all) {
      fill(color(120,0,0));
      ellipse(birth_center.x*xscale, birth_center.y*yscale, reset_rad*2*xscale, reset_rad*2*yscale);
      fill(color(120,120,0));
      ellipse(birth_center.x*xscale, birth_center.y*yscale, birth_rad*2*xscale, birth_rad*2*yscale);
    }
    for (Agent a : m.agents.agents) {
      if (a instanceof Drawable) {
        Drawable da = (Drawable)a;
        da.draw();
      }
    }
    cur = 0;
  } else {
    cur++;
  }
  
  
  m.step(); 
}
