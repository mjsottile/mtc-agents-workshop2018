int WWIDTH = 100;
int WHEIGHT = 100;
int world[][][];
int cur,next;

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
}

void setup() {
  size(600,600);
  cur = 0;
  next = 1;
  world = new int[2][WWIDTH][WHEIGHT];
  for (int i = 0; i < WWIDTH; i++) {
    for (int j = 0; j < WHEIGHT; j++) {
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
