int world[][];

void setup() {
  size(600,600);
  world = new int[300][300];
  
  // one central cell
  world[1][150] = 1;
  // random
  //for (int i = 0; i < 300; i++) {
  //  if (random(1.0) < 0.2) {
  //    world[1][i] = 1;
  //  } else {
  //    world[1][i] = 0;
  //  }
  //}
  
  for (int i = 2; i < 300; i++) {
    for (int j = 2; j < 299; j++) {
      int l = world[i-1][j-1];
      int c = world[i-1][j];
      int r = world[i-1][j+1];
      // 000 001 010 011 100 101 110 111
      // 1   2   4   8   16  32  64  128
      // rule 30 ==  2+4+8+16
      if ((l==0 && c==0 && r==1) ||
          (l==0 && c==1 && r==0) ||
          (l==0 && c==1 && r==1) ||
          (l==1 && c==0 && r==0)) {
        world[i][j] = 1;
      } else {
        world[i][j] = 0;
      }
    }
  }
}

void draw() {
  background(204);
  noStroke();
  for (int i = 0; i < 300; i++) {
    for (int j = 0; j < 300; j++) {
      if (world[i][j] == 1) {
        fill(color(255,255,255));
      } else {
        fill(color(0,0,0));
      }
      rect(i*2,j*2,2,2);
    }
  }
}
