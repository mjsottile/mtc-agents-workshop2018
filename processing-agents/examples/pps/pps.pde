//
// quick implementation of paper:
//   "How a life-like system emerges from a simple particle motion law"
//
// mjsottile@me.com
//

// ============================================================================
// single agent
// ============================================================================
class Agent
{
  float xpos;
  float ypos;
  float theta;
  int nval;

  float newx, newy, newtheta;

  Agent(float xlo, float xhi, float ylo, float yhi) {
    xpos = random(xhi-xlo)+xlo;
    ypos = random(yhi-ylo)+ylo;

    theta = random(TWO_PI);

    nval = 0;
  }

  void move(float dx, float dy) {
    newx = xpos + dx;
    newy = ypos + dy;
  }

  void rotate(float dtheta) {
    newtheta = (theta + dtheta) % TWO_PI;
  }

  void commit() {
    xpos = newx;
    ypos = newy;
    theta = newtheta;
  }

  float separation(Agent a) {
    return sqrt(pow((a.xpos - xpos), 2) + pow((a.ypos - ypos), 2));
  }
}

// ============================================================================
// parameters
// ============================================================================
class Parameters {
  float step;
  float a;
  float b;
  float r;
  float world_w, world_h;

  Parameters() {
    step = 0.67;
    r = 5.0;
    a = PI;
    b = (17.0/180.0) * PI;
  }

  Parameters(float _step, float _a, float _b, float _r) {
    step = _step;
    a = _a;
    b = _b;
    r = _r;
  }
}

// ============================================================================
// helpers
// ============================================================================
int sign(int x) {
  if (x < 0) {
    return -1;
  } else {
    if (x > 0) {
      return 1;
    } else {
      return 0;
    }
  }
}

// ============================================================================
// time stepping
// ============================================================================
void processPoint(Agent a, Agent[] others, int nagents, Parameters p) {
  float a_line_x, a_line_y;
  int side_a, side_b;

  a_line_x = cos(a.theta);
  a_line_y = sin(a.theta);

  side_a = 0;
  side_b = 0;

  // naive O(n^2) algorithm for processing all agents within neighborhood.
  // ideally should replace with proper space partitioning structure to
  // reduce it to an O(n log n) or similar algorithm.
  for (int i = 0; i < nagents; i++) {
    // consider only agents within some distance of the current agent
    if (a.separation(others[i]) <= p.r) {
      // determine which side of the agent they are on by looking at the
      // sign of the following.
      float side_sign = a_line_x * others[i].ypos - a_line_y * others[i].xpos;
      if (side_sign >= 0) {
        side_a++;
      } else {
        side_b++;
      }
    }
  }

  // update rule from paper
  a.nval = side_a + side_b;
  float dtheta = (p.a + p.b * (side_a + side_b) * sign(side_a - side_b)) % TWO_PI;
  float lx, ly;

  lx = cos(a.theta + dtheta);
  ly = sin(a.theta + dtheta);
  a.rotate(dtheta);
  a.move(lx*p.step, ly*p.step);
}

// ============================================================================
// population timestepping
// ============================================================================
void singleStep(Agent[] agents, int nagents, Parameters p) {
  for (int i = 0; i < nagents; i++) {
    processPoint(agents[i], agents, nagents, p);
  }
  for (int i = 0; i < nagents; i++) {
    agents[i].commit();
  }
}

// ============================================================================
// setup
// ============================================================================
Parameters p;
int nagents;
Agent[] agents;

void setup() {  
  size(1200, 800);
  p = new Parameters();
  nagents = 600;

  agents = new Agent[nagents];
  for (int i = 0; i < nagents; i++) {
    agents[i] = new Agent(-10, 10, -10, 10);
  }
}

int interval = 5;
int lastRecordedTime = 0;

int iter = 0;

int lifetime = 50;

class Drawable {
  float x, y;
  color c;
  int age;

  Drawable(float _x, float _y, color _c) {
    x = _x;
    y = _y;
    c = _c;
    age = 1;
  }

  void draw() {
    age++;
    int a = (c >> 24) & 0xFF;
    int r = (c >> 16) & 0xFF;  // Faster way of getting red(argb)
    int g = (c >> 8) & 0xFF;   // Faster way of getting green(argb)
    int b = c & 0xFF;          // Faster way of getting blue(argb)
    fill(r, g, b, a*(lifetime-age)/lifetime);
    noStroke();
    rect(x, y, 2, 2);
  }
}

ArrayList<Drawable> drawables = new ArrayList<Drawable>();

void draw() {
  background(32);
  for (int i = 0; i < nagents; i++) {
    float dx = (agents[i].xpos + 60)*(1200/120);
    float dy = (agents[i].ypos + 60)*(800/120);
    int nv = agents[i].nval;
    color c = color(0, 0, 0);
    if (nv < 13) {
      c = color(0, 255, 0);
    } else {
      if (nv >= 13 && nv <= 15) {
        c = color(128, 128, 0);
      } else {  
        if (nv > 15 && nv <= 35) {
          c = color(0, 192, 192);
        } else {
          c = color(192, 192, 0);
        }
      }
    }

    //         fill(c);
    //         noStroke();
    //         rect(dx,dy,3,3);
    drawables.add(new Drawable(dx, dy, c));
  }
  for (int i = drawables.size()-1; i >= 0; i--) {
    Drawable d = drawables.get(i);
    d.draw();
    if (d.age > lifetime) {
      drawables.remove(i);
    }
  }
  if (millis()-lastRecordedTime>interval) {
    iteration();
    lastRecordedTime = millis();
  }
}

void iteration() {
  singleStep(agents, nagents, p);
}
