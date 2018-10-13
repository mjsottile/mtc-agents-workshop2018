class Agent {
  int state, next_state;
  
  Agent() {
    if (random(1.0) < 0.1) {
      state = 1;
    } else {
      state = 0;
    }
  }
  
  void step(int ns) {
    next_state = state;
    if (state == 0 && ns == 3) {
      next_state = 1;
    } else {
      if (state == 1 && (ns < 2 || ns > 3)) {
        next_state = 0;
      }
    }
  }
  
  void advance() {
    state = next_state;
  }
  
  void draw(int i, int j) {
    if (state == 0) {
      fill(color(0,0,0));
    } else {
      fill(color(255,255,0));
    }
    
    rect(i * width/20, j * height/20, width/20, height/20);
  }
}



Agent a[][];

void setup() {
  size(300,300);
  
  a = new Agent[20][20];
  
  for (int i = 0; i < 20; i++) {
    for (int j = 0; j < 20; j++) {
      a[i][j] = new Agent();
    }
  }
  
}

void draw() {
  background(204);
  
  for (int i = 0; i < 20; i++) {
    for (int j = 0; j < 20; j++) {
      int ns = 0;
      
      // count neighbors in Moore neighborhood
      for (int k = -1;k <= 1; k++) {
        for (int l = -1; l <= 1; l++) {
          // check that we are in bounds
          if (i+k >= 0 && i+k < 20 && j+l >= 0 && j+l < 20) {
            
            // count neighbors that are on
            if (a[i+k][j+l].state == 1 && !(k==0 && l == 0)) {
              ns = ns + 1;
            }
          }
        }
      }
      
      a[i][j].step(ns);
    }
  }
  
  for (int i = 0; i < 20; i++) {
    for (int j = 0; j < 20; j++) {
      a[i][j].advance();
    }
  }
  
  for (int i = 0; i < 20; i++) {
    for (int j = 0; j < 20; j++) {
      a[i][j].draw(i,j);
    }
  }
}
