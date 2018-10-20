int WWIDTH = 200;
int WHEIGHT = 200;
boolean world[][][];
int cur,next;

void onestep() {
  for (int i = 0; i < WWIDTH; i++) {
    for (int j = 0; j < WHEIGHT; j++) {
      int up = (j-1+WHEIGHT) % WHEIGHT;
      int down = (j+1+WHEIGHT) % WHEIGHT;
      int left = (i-1+WWIDTH) % WWIDTH;
      int right = (i+1+WWIDTH) % WWIDTH;
      
      int count = 0;
      count += world[cur][i][up] ? 1 : 0;
      count += world[cur][i][down] ? 1 : 0;
      count += world[cur][left][up] ? 1 : 0;
      count += world[cur][left][down] ? 1 : 0;
      count += world[cur][right][up] ? 1 : 0;
      count += world[cur][right][down] ? 1 : 0;
      count += world[cur][left][j] ? 1 : 0;
      count += world[cur][right][j] ? 1 : 0;
      if (count == 3) {
        world[next][i][j] = true;
      } else {
        if (count < 2 || count > 5) {
          world[next][i][j] = false;
        } else {
          world[next][i][j] = world[cur][i][j];
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
  world = new boolean[2][WWIDTH][WHEIGHT];
  for (int i = 0; i < WWIDTH; i++) {
    for (int j = 0; j < WHEIGHT; j++) {
      if (random(1.0) < 0.05) {
        world[cur][i][j] = true;
      } else {
        world[cur][i][j] = false;
      }
      world[next][i][j] = false;
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
      if (world[cur][i][j]) { 
        fill(color(255,0,255)); 
      } else { 
        fill(color(0,0,0)); 
      }
      rect(i*CW, j*CH, CW, CH);
    }
  }
}
