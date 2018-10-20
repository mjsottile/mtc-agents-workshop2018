//
// Cell State
//
class CellState {
  float[] subs;
  float maxc;
  
  CellState(int n) {
    subs = new float[n];
    for (int i = 0; i < n; i++) {
      subs[i] = 0.0;
    }
  }
  
  void clamp() {
    for (int i = 0; i < subs.length; i++) {
      if (subs[i] > maxc) {
        subs[i] = maxc;
      }
    }
  }
  
  void randomize(float max_concentration) {
    maxc = max_concentration;
    for (int i = 0; i < subs.length; i++) {
      subs[i] = random(max_concentration);
    }
  }
  
  void draw(float x, float y, float rx, float ry) {
    float arcangle = TWO_PI / subs.length;
    color from = color(204, 102, 0);
    color to = color(0, 102, 153);
    
    for (int i = 0; i < subs.length; i++) {
      fill(lerpColor(from, to, (float)i / (float)subs.length));
      arc(x, y, rx, ry, arcangle*i, arcangle*i + arcangle*(subs[i]/maxc));
    }
  }
}

//
// Organism
//
class Organism {
  float energy;
  int age;
  int x, y;
  
  /*
   metabolism: in a single timestep t, consuming one unit of substance i will
               result in an energy change of metabolism[i] (positive or negative).
               if less than one unit is available of that substance, it will take whatever
               concentration is there * metabolism to yield slightly less energy/loss.
               
   byproduct:  consuming one (or <1) unit of substance i will cause other substances to increase
               by some amount.  constraint: all elements of byproduct must be positive, ith entry must
               be zero (if you consume it, you can't produce it). TODO: this should really come from some
               consistent reaction mechanism versus being organism specific...
   */
  float metabolism[];
  float byproduct[][];
  
  Organism(float energy_init, int x_init, int y_init, int nsubs) {
    energy = energy_init;
    age = 0;
    x = x_init;
    y = y_init;
    metabolism = new float[nsubs];
    byproduct = new float[nsubs][nsubs];
    randomize();
  }
  
  void randomize() {
    for (int i = 0; i < metabolism.length; i++) {
      metabolism[i] = random(2)-1.0;
    }
    for (int i = 0; i < byproduct.length; i++) {
      for (int j = 0; j < byproduct[i].length; j++) {
        if (i==j) {
          byproduct[i][j] = 0.0;
        } else {
          byproduct[i][j] = random(1);
        }
      }
    }
  }
  
  Organism reproduce(float energy_init) {
    // TODO: where to place child?
    Organism child = new Organism(energy_init, x, y, metabolism.length);
    child.metabolism = metabolism;
    child.byproduct = byproduct;
    return child;
  }
  
  float[] eat(float nutrients[]) {
    int n = nutrients.length;
    float newnutrients[] = new float[n];
    float eps = 0.01;
    
    float energy_change = 0;
    
    for (int i = 0; i < n; i++) {
      if (nutrients[i] > 0.0 && abs(metabolism[i]) > eps) {
        float consumed = (nutrients[i] > 1.0) ? 1.0 : nutrients[i];
        newnutrients[i] = nutrients[i] - consumed;
        energy_change = metabolism[i] * consumed;
        for (int j = 0; j < n; j++) {
          newnutrients[j] += byproduct[i][j] * consumed;
        }
      }
    }
    
    energy += energy_change;
    
    return newnutrients;
  }
  
  void movement() {
    energy -= 1.0; // Movement cost
  }
  
  boolean die() {
    if (energy <= 0.0) {
      return true;
    } else {
      return false;
    }
  }
  
  color get_color() {
    return color(energy);
  }
}

//
//
//

CellState[][] world;
ArrayList<Organism> pop;
int NSUBSTANCES = 5;
float MAX_CONCENTRATION = 100.0;
int WIDTH = 20;
int HEIGHT = 20;
int VIEW_WIDTH = 1600;
int VIEW_HEIGHT = 1600;
int INIT_POP = 200;
float INIT_ENERGY = 200.0;

void setup() {
  world = new CellState[HEIGHT][WIDTH];
  for (int i = 0; i < HEIGHT; i++) {
    for (int j = 0; j < WIDTH; j++) {
      world[i][j] = new CellState(NSUBSTANCES);
      world[i][j].randomize(MAX_CONCENTRATION);
    }
  }
  pop = new ArrayList<Organism>();
  
  for (int i = 0; i < INIT_POP; i++ ) {
    pop.add(new Organism(INIT_ENERGY, (int)random(WIDTH), (int)random(HEIGHT), NSUBSTANCES));
  }
  
  size(1600, 1600);
  stroke(48);
  noSmooth();
  background(0);
}

void one_step() {
  //
  // eat
  //
  for (int i = 0; i < pop.size(); i++) {
    Organism cur = pop.get(i);
    
    float[] newnutrients = cur.eat(world[cur.y][cur.x].subs);
    
    world[cur.y][cur.x].subs = newnutrients;
    world[cur.y][cur.x].clamp();
  }
  
  //
  // starve
  //
  for (int i = pop.size()-1; i >= 0; i--) {
    Organism cur = pop.get(i);
    if (cur.die()) {
      pop.remove(i);
    }
  }
  
  //
  // move
  //
  for (int i = 0; i < pop.size(); i++) {
    int dirx = (int)random(3) - 1;
    int diry = (int)random(3) - 1;
    Organism cur = pop.get(i);
    int newx = cur.x + dirx;
    int newy = cur.y + diry;
    if (newx >= WIDTH) {
      newx -= WIDTH;
    }
    if (newx < 0) {
      newx += WIDTH;
    }
    if (newy >= HEIGHT) {
      newy -= HEIGHT;
    }
    if (newy < 0) {
      newy += HEIGHT;
    }
    cur.x = newx;
    cur.y = newy;
    cur.movement();
  }
}

// Variables for timer
int interval = 5;
int lastRecordedTime = 0;
int stepnum = 0;

void draw() {
  // Iterate if timer ticks
  if (millis()-lastRecordedTime>interval) {
    if (pop.size() > 0) {
      one_step();
      stepnum++;
      print(pop.size());
      print(" // ");
      println(stepnum);
    }
    lastRecordedTime = millis();
  }
  background(0);
  int w = VIEW_WIDTH/WIDTH;
  int h = VIEW_HEIGHT/HEIGHT;
  
  float ow = w/5.0;
  float oh = h/5.0;
  float oow = (w-ow)/2.0;
  float ooh = (w-oh)/2.0;

  for (int i = 0; i < HEIGHT; i++) {
    for (int j = 0; j < WIDTH; j++) {
      world[j][i].draw(j*w,i*h,w,h);
    }
  }
  
  for (int i = 0; i < pop.size(); i++) {
    Organism cur = pop.get(i);
    
    color c = cur.get_color();
    fill(c);
    rect(cur.x*w+oow, cur.y*h+ooh, ow, oh);
  }

}
