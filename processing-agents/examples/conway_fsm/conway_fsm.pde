int WWIDTH = 200;
int WHEIGHT = 200;
int NUMSTATES = 50;
int NUMVALUES = 2;
int world[][][];
int cur,next;
int state[][];
int state_transition[][];
int state_update[][];

void apply_statemachine(int i, int j) {
  int newstate = state_transition[state[i][j]][world[cur][i][j]];
  int newvalue = state_update[state[i][j]][world[cur][i][j]];
  state[i][j] = newstate;
  world[cur][i][j] = (world[cur][i][j] + newvalue) % 2;
}

void onestep() {
  for (int i = 0; i < WWIDTH; i++) {
    for (int j = 0; j < WHEIGHT; j++) {
      int up = (j-1+WHEIGHT) % WHEIGHT;
      int down = (j+1+WHEIGHT) % WHEIGHT;
      int left = (i-1+WWIDTH) % WWIDTH;
      int right = (i+1+WWIDTH) % WWIDTH;
      
      int count = 0;
      count += world[cur][i][up];
      count += world[cur][i][down];
      count += world[cur][left][up];
      count += world[cur][left][down];
      count += world[cur][right][up];
      count += world[cur][right][down];
      count += world[cur][left][j];
      count += world[cur][right][j];
      
      world[next][i][j] = world[cur][i][j];
      if (world[cur][i][j] == 0) {
        if (count == 3) {
          world[next][i][j] = 1;
        }
      }
      if (world[cur][i][j] == 1) {
        if (count < 2 || count > 3) {
          world[next][i][j] = 0;
        }
      }
    }
  }
  
  cur = (cur + 1) % 2;
  next = (next + 1) % 2;
  
  for (int i = 0; i < WWIDTH; i++) {
    for (int j = 0; j < WHEIGHT; j++) {
      apply_statemachine(i,j);
    }
  }
}

void setup() {
  size(600,600);
  cur = 0;
  next = 1;
  state = new int[WWIDTH][WHEIGHT];
  state_transition = new int[NUMSTATES][NUMVALUES];
  state_update = new int[NUMSTATES][NUMVALUES];

  for (int s = 0; s < NUMSTATES; s++) {
    for (int v = 0; v < NUMVALUES; v++) {
      state_transition[s][v] = int(random(NUMSTATES));;
      state_update[s][v] = int(random(NUMVALUES+1));
    }
  }

  println("STATE_TRANSITION:");
  for (int s = 0; s < NUMSTATES; s++) {
    for (int v = 0; v < NUMVALUES; v++) {
      println(str(s)+" "+str(v)+" :: "+state_transition[s][v]+", "+state_update[s][v]);
    }
  }

  world = new int[2][WWIDTH][WHEIGHT];
  for (int i = 0; i < WWIDTH; i++) {
    for (int j = 0; j < WHEIGHT; j++) {
      state[i][j] = 0;
      if (random(1.0) < 0.1) {
        world[cur][i][j] = 1;
      } else {
        world[cur][i][j] = 0;
      }
      world[next][i][j] = 0;
    }
  }
}

void draw() {
  onestep();
  
  int CH = height / WHEIGHT;
  int CW = width / WWIDTH;
  background(204);
  noStroke();
  
  for (int i = 0; i < WWIDTH; i++) {
    for (int j = 0; j < WHEIGHT; j++) {
      if (world[cur][i][j] == 1) { 
        fill(color(0,0,255)); 
      } else { 
        fill(color(0,0,0)); 
      }
      rect(i*CW, j*CH, CW, CH);
    }
  }
}
