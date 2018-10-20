int[][] cells;
int[][] cellsBuffer;
int[][] cellType;

int cellSize = 3;

int interval = 10;
int lastRecordedTime = 0;

int HORIZ_DOT      = 0;
int VERT_DOT       = 1;
int CORNER_DOT     = 2;
int CENTRAL_CIRCLE = 3;

float k = 0.55;
float kc = 0.52;
float s = 0.02;
float sc = 0.03;

int nx, ny;

void setup() {
  size(1000, 700);

  nx = width/cellSize;
  ny = height/cellSize;

  cells = new int[nx][ny];
  cellsBuffer = new int[nx][ny];
  cellType = new int[nx][ny];

  stroke(48);
  noSmooth();

  for (int x=0; x<nx; x++) {
    for (int y=0; y<ny; y++) {
      float state = random(500);
      cells[x][y] = int(state-250);
      // which cell type am I?
      if (x % 2 == 1 && y % 2 == 0) {
        cellType[x][y] = HORIZ_DOT;
      }
      if (x % 2 == 0 && y % 2 == 1) {
        cellType[x][y] = VERT_DOT;
      }
      if (x % 2 == 0 && y % 2 == 0) {
        cellType[x][y] = CORNER_DOT;
      }
      if (x % 2 == 1 && y % 2 == 1) {
        cellType[x][y] = CENTRAL_CIRCLE;
      }
    }
  }

  background(0);
}

int clamp(int i) {
  if (i < -255) {
    return -255;
  }
  if (i > 255) {
    return 255;
  }
  return i;
}

color cellToColor(int i, int t) {
  color c;

  if (t==CENTRAL_CIRCLE) {
    c = color(i%255, 0, i%255);
  } else {
    c = color(i%255, i%255, 0);
  }

  return c;
}

void draw() {
  for (int x = 0; x < nx; x++) {
    for (int y = 0; y < ny; y++) {
      color c = cellToColor(cells[x][y], cellType[x][y]);
      fill(c);
      rect(x*cellSize, y*cellSize, cellSize, cellSize);
    }
  }

  if (millis()-lastRecordedTime>interval) {
    iteration();
    lastRecordedTime = millis();
  }
}

void applyForcesCrossClass(int x, int y) {
  if (cellType[x][y] == CENTRAL_CIRCLE) {
    int xs[] = { x-1, x  , x+1, x+1, x+1, x  , x-1, x-1 };
    int ys[] = { y-1, y-1, y-1, y  , y+1, y+1, y+1, y   };
    int tot = 0;
    int neighbors = 0;
    for (int i = 0; i < 8; i++) {
      if (xs[i] >= 0 && xs[i] < nx && ys[i] >= 0 && ys[i] < ny) {
        tot += cellsBuffer[xs[i]][ys[i]];
        neighbors++;
      }
    }
    cells[x][y] += int(sc * (float(cellsBuffer[x][y]) - float(tot)/float(neighbors)));
  } else {
    int tot = 0;
    int neighbors = 0;
    if (cellType[x][y] == HORIZ_DOT) {
      int xs[] = { x,   x   };
      int ys[] = { y-1, y+1 };
      for (int i = 0; i < 2; i++) {
        if (xs[i] >= 0 && xs[i] < nx && ys[i] >= 0 && ys[i] < ny) {
          tot += cellsBuffer[xs[i]][ys[i]];
          neighbors++;
        }
      }
    } else if (cellType[x][y] == VERT_DOT) {
      int xs[] = { x-1, x+1 };
      int ys[] = { y  , y   };
      for (int i = 0; i < 2; i++) {
        if (xs[i] >= 0 && xs[i] < nx && ys[i] >= 0 && ys[i] < ny) {
          tot += cellsBuffer[xs[i]][ys[i]];
          neighbors++;
        }
      }
    } else {
      int xs[] = { x-1, x+1, x-1, x+1 };
      int ys[] = { y-1, y-1, y+1, y+1 };
      for (int i = 0; i < 4; i++) {
        if (xs[i] >= 0 && xs[i] < nx && ys[i] >= 0 && ys[i] < ny) {
          tot += cellsBuffer[xs[i]][ys[i]];
          neighbors++;
        }
      }
    }
    cells[x][y] += s * (float(cellsBuffer[x][y]) - float(tot)/float(neighbors));    
  }
}

void applyForcesSameClass(int x, int y) {
  int neighbors = 0;
  float accum = 0.0;

  // TODO: add feedback mechanism to feed O's back to dots as pressure.
  if (cellType[x][y] == HORIZ_DOT) {
    int x1 = x-1; 
    int y1 = y;
    int x2 = x+1; 
    int y2 = y;
    if (x1 >= 0) {
      accum += k*(cellsBuffer[x][y]-cellsBuffer[x1][y1]);
      neighbors++;
    }
    if (x2 < nx) {
      accum += k*(cellsBuffer[x][y]-cellsBuffer[x2][y2]);
      neighbors++;
    }
  }
  if (cellType[x][y] == VERT_DOT) {
    int y1 = y-1; 
    int x1 = x;
    int y2 = y+1; 
    int x2 = x;
    if (y1 >= 0) {
      accum += k*(cellsBuffer[x][y]-cellsBuffer[x1][y1]);
      neighbors++;
    }
    if (y2 < ny) {
      accum += k*(cellsBuffer[x][y]-cellsBuffer[x2][y2]);
      neighbors++;
    }
  }
  if (cellType[x][y] == CORNER_DOT) {
    int y1 = y-1; 
    int x1 = x;
    int y2 = y+1; 
    int x2 = x;
    int y3 = y; 
    int x3 = x-1;
    int y4 = y; 
    int x4 = x+1;
    if (y1 >= 0) {
      accum += k*(cellsBuffer[x][y]-cellsBuffer[x1][y1]);
      neighbors++;
    }
    if (y2 < ny) {
      accum += k*(cellsBuffer[x][y]-cellsBuffer[x2][y2]);
      neighbors++;
    }
    if (x3 >= 0) {
      accum += k*(cellsBuffer[x][y]-cellsBuffer[x3][y3]);
      neighbors++;
    }
    if (x4 < nx) {
      accum += k*(cellsBuffer[x][y]-cellsBuffer[x4][y4]);
      neighbors++;
    }
  }

  if (cellType[x][y] == CENTRAL_CIRCLE) {
    int y1 = y-2; 
    int x1 = x;
    int y2 = y+2; 
    int x2 = x;
    int y3 = y;   
    int x3 = x-2;
    int y4 = y;   
    int x4 = x+2;

    if (y1 >= 0) {
      accum += kc*(cellsBuffer[x][y]-cellsBuffer[x1][y1]);
      neighbors++;
    }
    if (y2 < ny) {
      accum += kc*(cellsBuffer[x][y]-cellsBuffer[x2][y2]);
      neighbors++;
    }
    if (x3 >= 0) {
      accum += kc*(cellsBuffer[x][y]-cellsBuffer[x3][y3]);
      neighbors++;
    }
    if (x4 < nx) {
      accum += kc*(cellsBuffer[x][y]-cellsBuffer[x4][y4]);
      neighbors++;
    }
  }

  cells[x][y] = clamp(int(accum / float(neighbors)));
}

void iteration() {
  for (int x = 0; x < nx; x++) {
    for (int y = 0; y < ny; y++) {
      cellsBuffer[x][y] = cells[x][y];
    }
  }

  for (int x = 0; x < nx; x++) {
    for (int y = 0; y < ny; y++) {
      applyForcesSameClass(x,y);
    }
  }
  
  for (int x = 0; x < nx; x++) {
    for (int y = 0; y < ny; y++) {
      applyForcesCrossClass(x,y);
      cells[x][y] = clamp(cells[x][y]);
    }
  }
}