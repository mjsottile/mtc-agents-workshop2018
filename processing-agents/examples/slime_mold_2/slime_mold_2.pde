//
// slime mold (see "turtles, termintes, and traffic jams" book)
//
float world[][];
Agent agents[];

int NAGENTS = 800;
int WIDTH = 200;
int HEIGHT = 200;
int cell_width, cell_height;
float pVelocityNoise = 0.95;
float evaporation_rate = 0.99;
float diffusion_rate = 8;
float cell_capacity = 250;

int neighbor(int x, int offset, int w) {
  return (x + offset + w) % w;
}

class Agent {
  int x, y;
  int vx, vy;
  
  Agent(int W, int H) {
    x = (int)random(W);
    y = (int)random(H);
    vx = round(random(-1,1));
    vy = round(random(-1,1));
  }
  
  void randomize_velocity() {
    if (random(1.0) > pVelocityNoise) {
      vx = round(random(-1,1));
    }
    if (random(1.0) > pVelocityNoise) {
      vy = round(random(-1,1));
    }
  }
  
  PVector compute_gradient() {
    int nleft = neighbor(x, -1, WIDTH);
    int nright = neighbor(x, 1, WIDTH);
    int nup = neighbor(y, -1, HEIGHT);
    int ndown = neighbor(y, 1, HEIGHT);
    
    float fvx = (world[nleft][y] - world[x][y]) + (world[x][y] - world[nright][y]);
    float fvy = (world[x][nup] - world[x][y]) + (world[x][y] - world[x][ndown]);
    
    return new PVector(fvx,fvy);
  }

  void make_move() {
    x = (x + vx + WIDTH) % WIDTH;
    y = (y + vy + HEIGHT) % HEIGHT;
  }
  
  void leave_pheremone() {
    world[x][y] += 1.8;
  }
  
  void sniff_and_turn() {
    PVector v = compute_gradient();
    if (abs(v.x) > 0) {
      vx -= round(v.x/abs(v.x));
    }
    if (abs(v.y) > 0) {
      vy -= round(v.y/abs(v.y));
    }
  }
  
  void step() {
    make_move();
    randomize_velocity();
    leave_pheremone();
    if (world[x][y] > 2) {
      sniff_and_turn();
    }
  }
  
  void draw() {
    ellipse(x*cell_width + cell_width/2, y*cell_height + cell_height/2, cell_width, cell_height);
  }
}

void setup() {
  size(800,800);
  
  cell_width = 800 / WIDTH;
  cell_height = 800 / HEIGHT;
  
  world = new float[WIDTH][HEIGHT];
  for (int i = 0; i < WIDTH; i++) {
    for(int j = 0; j < HEIGHT; j++) {
      world[i][j] = 0.0;
    }
  }
  
  agents = new Agent[NAGENTS];
  for (int i = 0; i < NAGENTS; i++) {
    agents[i] = new Agent(WIDTH, HEIGHT);
  }
}

void world_step() {
  
  for (int i = 0; i < WIDTH; i++) {
    for (int j = 0; j < HEIGHT; j++) {
      world[i][j] = world[i][j] > cell_capacity ? cell_capacity : world[i][j];
    }
  }
  
  // diffusion
  float new_world[][] = new float[WIDTH][HEIGHT];
  for (int i = 0; i < WIDTH; i++) {
    for (int j = 0; j < HEIGHT; j++) {
      new_world[i][j] = 0.0;
    }
  }
  
  for (int i = 0; i < WIDTH; i++) {
    for (int j = 0; j < HEIGHT; j++) {
      int nleft = neighbor(i, -1, WIDTH);
      int nright = neighbor(i, 1, WIDTH);
      int nup = neighbor(j, -1, HEIGHT);
      int ndown = neighbor(j, 1, HEIGHT);

      float out = world[i][j] > diffusion_rate ? diffusion_rate : world[i][j];
      new_world[i][j] += world[i][j] - out;
      new_world[nleft][nup] += out/8.0;
      new_world[nleft][ndown] += out/8.0;
      new_world[nleft][j] += out/8.0;
      new_world[nright][nup] += out/8.0;
      new_world[nright][ndown] += out/8.0;
      new_world[nright][j] += out/8.0;
      new_world[i][nup] += out/8.0;
      new_world[i][ndown] += out/8.0;
    }
  }
  
  for (int i = 0; i < WIDTH; i++) {
    for (int j = 0; j < HEIGHT; j++) {
      world[i][j] = new_world[i][j];
    }
  }
  
   
  // evaporation
  for (int i = 0; i < WIDTH; i++) {
    for (int j = 0; j < HEIGHT; j++) {
      world[i][j] *= evaporation_rate;
    }
  }
 
}

void draw() {
  background(204);
  
  world_step();
  
  float max_conc = 1.0;
  for (int i = 0; i < WIDTH; i++) {
    for (int j = 0; j < HEIGHT; j++) {
      if (world[i][j] > max_conc) {
        max_conc = world[i][j];
      }
    }
  }
  
  for (int i = 0; i < WIDTH; i++) {
    for (int j = 0; j < HEIGHT; j++) {
      fill(color(255.0 * world[i][j]/max_conc,0,0));
      rect(i*cell_width, j*cell_height, cell_width, cell_height);
    }
  }
  
  fill(color(127,127,127));
  
  for (Agent a : agents) {
    a.step();
    a.draw();
  }
}
