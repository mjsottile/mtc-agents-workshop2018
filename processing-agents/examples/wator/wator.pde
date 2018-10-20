//
// base class for any animal
//
class Animal {
  int age;
  boolean is_dead;
  int vx, vy;
  int energy;
  
  Animal() {
    age = 0;
    energy = 0;
    is_dead = false;
  }
    
  void eat(Cell c) {
    println("ERROR: cannot call eat on base class.");
  }
  
  void breed(Cell c) {
    println("ERROR: cannot call breed on base class.");
  }
  
  boolean starve() {
    return (energy <= 0);
  }
  
  boolean can_breed() {
    println("ERROR: cannot call can_breed on base class.");
    return false;
  }
  
  void did_breed() {
    println("ERROR: cannot call did_breed on base class.");
  }
  
  void move(Cell[][] w, int x, int y) {
    w[vx][vy].occupants.add(this);
    energy -= 1;
  }
  
  void compute_gradient(Cell[][] w, int x, int y) {
    println("ERROR: cannot call compute_gradient on base class.");
  }
  
  void draw(int x, int y) {
    println("ERROR: cannot call draw on base class.");
  }
  
  void step() {
    age += 1;
  }
}

class Shark extends Animal {
  int BREED_AGE = 10;
  int BREED_INTERVAL = 30;
  int last_bred;
  int EAT_ENERGY = 3;
  
  Shark() {
    super();
    energy = 20;
  }

  boolean can_breed() {
    return (age > BREED_AGE && age > last_bred + BREED_INTERVAL);
  }
  
  void did_breed() {
    last_bred = age;
  }
  
  void eat(Cell c) {
    for (int i = 0; i < c.occupants.size(); i++) {
      Animal a = c.occupants.get(i);
      if (a instanceof Fish) {
        energy += EAT_ENERGY;
        a.is_dead = true;
        break;
      }
    }
  }
  
  void breed(Cell c) {
    if (can_breed()) {
      for (Animal a : c.occupants) {
        if (a instanceof Shark && a.can_breed()) {
          // TODO: add check to see if the other animal wants to breed with this one.
          a.did_breed();
          did_breed();
          c.new_sharks += 1;
          break;
        }
      }
    }
  }
  
  void compute_gradient(Cell[][] w, int x, int y) {
    // compute directions on torus
    int y_n = (y-1+HEIGHT)%HEIGHT;
    int y_s = (y+1+HEIGHT)%HEIGHT;
    int x_w = (x-1+WIDTH)%WIDTH;
    int x_e = (x+1+WIDTH)%WIDTH;

    // precompute direction indices
    int[] y_dir = {y  , y  , y  , y_n, y_n, y_n, y_s, y_s, y_s};
    int[] x_dir = {x  , x_e, x_w, x_e, x  , x_w, x_e, x  , x_w};
    
    // counts by direction
    int[] count = {0  , 0  , 0  , 0  , 0  , 0  , 0  , 0  , 0  };

    // count each direction
    for (int i = 0; i < 9; i++) {
      for (Animal a : w[x_dir[i]][y_dir[i]].occupants) {
        if (a instanceof Fish) {
          count[i]++;
        }
      }
    }
    
    // find maximum count: move towards fish concentrations
    int i_max = 0;
    for (int i = 1; i < 9; i++) {
      if (count[i] > count[i_max]) {
        i_max = i;
      }
    }
    
    // more than one max may exist.
    IntList candidates = new IntList();
    for (int i = 0; i < 9; i++) {
      if (count[i] == count[i_max]) {
        candidates.append(i);
      }
    }
    
    // pick random from candidate direction
    int idx = candidates.get(floor(random(candidates.size())));
    
    // set gradient based on random valid candidate
    vx = x_dir[idx];
    vy = y_dir[idx];
  }
  
  void draw(int x, int y) {
    fill(color(170.0, 0.0, 0.0));
    rect(x*cell_width, y*cell_height, cell_width, cell_height);
  }
}

class Fish extends Animal {
  int BREED_AGE = 5;
  int BREED_INTERVAL = 20;
  int last_bred;
  int ALGAE_INPUT = 3;
  
  Fish() {
    super();
    last_bred = 0;
    energy = 5;
  }
  
  void eat(Cell c) {
    if (c.algae > ALGAE_INPUT) {
      energy += 1;
      c.algae -= ALGAE_INPUT;
    }
  }
  
  boolean can_breed() {
    return (age > BREED_AGE && age > last_bred + BREED_INTERVAL);
  }
  
  void did_breed() {
    last_bred = age;
  }
  
  void breed(Cell c) {
    if (can_breed()) {
      for (Animal a : c.occupants) {
        if (a instanceof Fish && a.can_breed()) {
          // TODO: add check to see if the other animal wants to breed with this one.
          a.did_breed();
          did_breed();
          c.new_fish += 1;
          break;
        }
      }
    }
  }
    
  void compute_gradient(Cell[][] w, int x, int y) {
        // compute directions on torus
    int y_n = (y-1+HEIGHT)%HEIGHT;
    int y_s = (y+1+HEIGHT)%HEIGHT;
    int x_w = (x-1+WIDTH)%WIDTH;
    int x_e = (x+1+WIDTH)%WIDTH;

    // precompute direction indices
    int[] y_dir = {y  , y  , y  , y_n, y_n, y_n, y_s, y_s, y_s};
    int[] x_dir = {x  , x_e, x_w, x_e, x  , x_w, x_e, x  , x_w};
    
    // counts by direction
    int[] count = {0  , 0  , 0  , 0  , 0  , 0  , 0  , 0  , 0  };

    // count each direction
    for (int i = 0; i < 9; i++) {
      for (Animal a : w[x_dir[i]][y_dir[i]].occupants) {
        if (a instanceof Shark) {
          count[i]++;
        }
      }
    }
    
    // find minimum count: move away from shark concentrations
    int i_min = 0;
    for (int i = 1; i < 9; i++) {
      if (count[i] < count[i_min]) {
        i_min = i;
      }
    }
    
    // more than one min may exist.
    IntList candidates = new IntList();
    for (int i = 0; i < 9; i++) {
      if (count[i] == count[i_min]) {
        candidates.append(i);
      }
    }
    
    // pick random from candidate direction
    int idx = candidates.get(floor(random(candidates.size())));
    
    // set gradient based on random valid candidate
    vx = x_dir[idx];
    vy = y_dir[idx];
  }

  void draw(int x, int y) {
    fill(color(0.0, 0.0, 170.0));
    rect(x*cell_width, y*cell_height, cell_width, cell_height);
  }

}

class Cell {
  ArrayList<Animal> occupants;
  int algae;
  int ALGAE_RATE = 1;
  int MAX_ALGAE = 200;
  int new_fish, new_sharks;
  
  Cell() {
    algae = 10;
    occupants = new ArrayList<Animal>();
    new_fish = 0;
    new_sharks = 0;
  }
  
  void reset_breed() {
    new_fish = 0;
    new_sharks = 0;
  }
  
  void grow() {
    if (algae < 0) {
      algae = 0;
    }
    algae += ALGAE_RATE;
    if (algae > MAX_ALGAE) {
      algae = MAX_ALGAE;
    }
  }
  
  void draw(int x, int y) {
    fill(color(0.0, algae, 0.0));
    rect(x*cell_width, y*cell_height, cell_width, cell_height);
    for (Animal a: occupants) {
      a.draw(x, y);
    }
  }
}

Cell[][] world;
int WIDTH = 200;
int HEIGHT = 200;
int INITIAL_SHARKS = 300;
int INITIAL_FISH = 1000;
float cell_width, cell_height;

void setup() {
  size(600,600);
  
  cell_width = 600 / WIDTH;
  cell_height = 600 / HEIGHT;
  
  world = new Cell[WIDTH][HEIGHT];
  for (int i = 0; i < WIDTH; i++) {
    for (int j = 0; j < HEIGHT; j++) {
      world[i][j] = new Cell();
    }
  }
  
  for (int i = 0; i < INITIAL_SHARKS; i++) {
    int x = floor(random(WIDTH));
    int y = floor(random(HEIGHT));
    
    world[x][y].occupants.add(new Shark());
  }

  for (int i = 0; i < INITIAL_FISH; i++) {
    int x = floor(random(WIDTH));
    int y = floor(random(HEIGHT));
    
    world[x][y].occupants.add(new Fish());
  }

}

void step() {
  // =-=-=-=-=-=-=-=-=-=--=-=
  // animals:
  for (int i = 0; i < WIDTH; i++) {
    for (int j = 0; j < HEIGHT; j++) {
      for (Animal a : world[i][j].occupants) {
        // eat
        if (!a.is_dead) {
          a.eat(world[i][j]);
        }
        
        // starve
        if (a.starve()) { 
          a.is_dead = true; 
        }
  
        // breed
        if (!a.is_dead) {
          a.breed(world[i][j]);
        }
      }
      
      // garbage collect - get rid of dead animals
      for (int k = world[i][j].occupants.size()-1; k >= 0; k--) {
        Animal a = world[i][j].occupants.get(k);
        if (a.is_dead) {
          world[i][j].occupants.remove(k);
        }
      }
    }
  }  

  // spawn
  for (int i = 0; i < WIDTH; i++) {
    for (int j = 0; j < HEIGHT; j++) {
      for (int k = 0; k < world[i][j].new_fish; k++) {
        world[i][j].occupants.add(new Fish());
      }
      for (int k = 0; k < world[i][j].new_sharks; k++) {
        world[i][j].occupants.add(new Shark());
      }
      world[i][j].reset_breed();
    }
  }
  
  // move
  for (int i = 0; i < WIDTH; i++) {
    for (int j = 0; j < HEIGHT; j++) {
      for (Animal a : world[i][j].occupants) {
        a.compute_gradient(world, i, j);
      }
    }
  }
  Cell[][] newWorld = new Cell[WIDTH][HEIGHT];
  for (int i = 0; i < WIDTH; i++) {
    for (int j = 0; j < HEIGHT; j++) {
      newWorld[i][j] = new Cell();
    }
  }

  for (int i = 0; i < WIDTH; i++) {
    for (int j = 0; j < HEIGHT; j++) {
      for (int k = world[i][j].occupants.size()-1; k >= 0; k--) {
        Animal a = world[i][j].occupants.get(k);
        a.move(newWorld, i, j);
        a.step();
      }
    }
  }

  for (int i = 0; i < WIDTH; i++) {
    for (int j = 0; j < HEIGHT; j++) {
      world[i][j].occupants = newWorld[i][j].occupants;
    }
  }
  
  // =-=-=-=-=-=-=-=-=-=--=-=
  // cells:
  
  // grow algae
  for (int i = 0; i < WIDTH; i++) {
    for (int j = 0; j < HEIGHT; j++) {
      world[i][j].grow();
    }
  }
}

void draw() {
  background(204);
  step();
  
  for (int i = 0; i < WIDTH; i++) {
    for (int j = 0; j < HEIGHT; j++) {
      world[i][j].draw(i,j);
    }
  }  
}
