class GOLAgent extends Agent implements Drawable {
  boolean value, nextValue;

  GOLAgent(AgentSet agents, Space space) {
    super(agents, space);
    value = false;
  }

  void draw() {
    float w = (float)width / (float)space.width();
    float h = (float)height / (float)space.height();
    noStroke();
    if (value) {
      fill(color(29,255,176));
    } else {
      fill(color(120,14,88));
    }
    rect(pos.x*w,pos.y*h,w,h);
  }

  void stepStage(int stageNum) {
    switch (stageNum) {
      case 0:
        ArrayList<Agent> ns = space.neighbors(pos, 1);
        int nn = 0;
        for (Agent na : ns) {
          GOLAgent a = (GOLAgent)na;
          if (a.value) {
            nn++;
          }
        }
        nextValue = value;
        if (value==false) {
          if (nn==3) {
            nextValue = true;
          }
        } else {
          if (nn < 2 || nn > 3) {
            nextValue = false;
          }
        }
        break;
      case 1:
        value = nextValue;
        break;
      default:
        println("Invalid stage number : "+stageNum);
        break;
    }
  }
}

Model m;

void setup() {
  size(300,300);
  AgentSet agents = new AgentSet();
  GridSpace s = new GridSpace(100,100,agents,true);
  s.torus = true;
  StagedScheduler sched = new StagedScheduler(2);
  m = new Model(agents, s, sched);

  for (int i = 0; i < 100; i++) {
    for (int j = 0; j < 100; j++)  {
      GOLAgent a = new GOLAgent(agents, s);
      a.value = random(1.0) < 0.5 ? true : false;
      a.pos = new PVector(i,j);
      m.add(a);
    }
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
