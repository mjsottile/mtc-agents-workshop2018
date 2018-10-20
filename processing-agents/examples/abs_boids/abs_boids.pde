//
// three rules:
//
// - separation : steer to avoid overcrowding local flockmates
// - alignment : steer towards average heading of local flockmates
// - cohesion : steer towards the center of mass of local flockmates
//

final int WIDTH = 300;
final int HEIGHT = 300;
float max_vel = 15.0;
float cohesion_strength = 0.00075;
float separation_strength = 0.3;
float alignment_strength = 1.0/1.8;
float noise_strength = 0.5;
int NUMBOIDS = 1000;
float radius = WIDTH / 40.0;

class Boid extends Agent implements Drawable {
  PVector v, a;

  Boid(AgentSet agents, Space space) {
    super(agents, space);
    pos = new PVector(floor(random(space.width())), floor(random(space.height())));
    v = new PVector(random(-5,5), random(-5,5));
    a = new PVector(0.0, 0.0);
  }

  void stepStage(int stageNum) {
    switch (stageNum) {
      case 0:
        // reset acceleration
        a = new PVector(0.0, 0.0);

        // center of mass
        PVector com = pos.copy();
        // average heading
        PVector avg_heading = v.copy();
        // separation
        PVector sep = new PVector(0.0, 0.0);

        // get neighbors within radius r
        ArrayList<Agent> ns = space.neighbors_of(this, radius);
        int numn = 0;
        for (Agent b: ns) {
          numn++;
          // position of b relative to this, adjusted given the
          // topology of the space.
          PVector bpos = space.relative_to(pos, ((Boid)b).pos);

          // add location of neighbor to center of mass
          com.add(bpos);

          // add velocity of neighbor to average heading
          avg_heading.add(((Boid)b).v);

          if (PVector.dist(b.pos, pos) < radius*0.2) {
            // add separation between self and neighbor
            sep.add(PVector.sub(pos,bpos));
          }
        }
        float scale_factor = 1.0 / (numn + 1);

        // scale center of mass and avg heading to compute averages
        com.mult(scale_factor);
        avg_heading.mult(scale_factor);

        // scale by parameters
        PVector com_acc = PVector.sub(com, pos);
        com_acc.mult(cohesion_strength);
        PVector head_acc = PVector.sub(avg_heading, v);
        head_acc.mult(alignment_strength);
        sep.mult(separation_strength);

        a.add(com_acc);
        a.add(head_acc);
        a.add(sep);

        break;
      case 1:
        float dt = 1.0;
        v.add(a.mult(dt));
        v.add(new PVector(random(-noise_strength, noise_strength),
                          random(-noise_strength, noise_strength)));
        v.limit(max_vel);
        PVector newpos = PVector.add(pos, v.copy().mult(dt));
        space.moveAgent(this, newpos);
        break;
      default:
        break;
    }
  }

  void draw() {
    float xscale = width / (float)space.width();
    float yscale = height / (float)space.height();
    PVector x = new PVector(pos.x * xscale, pos.y * yscale);
    fill(color(250,250,0));
    ellipse(x.x, x.y, 5, 5);
    fill(color(250,0,250));
    line(x.x, x.y, x.x+v.x*5, x.y+v.y*5);
  }
}

Model m;

void setup() {
  size(800,800);
  AgentSet agents = new AgentSet();
  KDTreeContinuousSpace s = new KDTreeContinuousSpace(WIDTH,HEIGHT,agents);
  StagedScheduler sched = new StagedScheduler(2);
  m = new Model(agents, s, sched);

  for (int i = 0; i < NUMBOIDS; i++) {
    Boid b = new Boid(agents, s);
    m.add(b);
  }
}

void draw() {
  background(204);
  for (Agent a : m.agents.agents) {
    if (a instanceof Drawable) {
      Drawable da = (Drawable)a;
      da.draw();
    }
  }
  m.step(); 
}
