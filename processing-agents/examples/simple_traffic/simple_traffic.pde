class Car {
  float x, dx, ddx; // position, velocity, acceleration
  float MAX_SPEED = 25.0; // maximum speed
  float SEPDIST = 200.0; // desired minimum separation from car in front
  float max_ddx; // maximum acceleration
  float ddx_incr = 0.2;
  
  Car(float p) {
    x = p;
    dx = 0.0;
    ddx = 0.0;
    max_ddx = 2.0;
  }
  
  void move(float dt, float road_length) {
    dx = dx + dt*ddx;
    if (dx > MAX_SPEED) { 
      dx = MAX_SPEED;
      ddx = 0.0;
    }
    
    if (dx < 0.0) {
      dx = 0.0;
    }
    
    x = x + dt*dx;
    if (x > road_length) {
      x = x - road_length;
    }
  }
  
  void update_accel(float dfront, float dt) {
//    println(dfront);
    if (dfront < SEPDIST) {
      dx = 0.0;
      ddx = 0.0;
    }
    if (dfront >= SEPDIST) {
      ddx += ddx_incr;
    
      if (ddx > max_ddx) {
        ddx = max_ddx;
      }    
    }
  }
}

Car cars[];
int NUMCARS = 20;
float road_length = 5000.0;

void setup() {
  size(400,400);
  cars = new Car[NUMCARS];
  
  // generate positions first so we can sort them to guarantee
  // that all cars are in order to start.
  float pos[] = new float[NUMCARS];
  for (int i = 0; i < NUMCARS; i++) {
    pos[i] = random(road_length);
  }
  pos = sort(pos);
  
  // create cars with their given positions in order
  for (int i = 0; i < NUMCARS; i++) {
    cars[i] = new Car(pos[i]);
  }
}

void draw() {
  background(0);
  float center_x = width/2.0;
  float center_y = height/2.0;
  float r = width / 3.0;
  float dt = 1.0;
  
  float x,y;
  stroke(color(0,255,0));
  fill(0);
  ellipse(center_x, center_y, 2*r, 2*r);
  noStroke();
  for (int i = 0; i < NUMCARS; i++) {
    x = center_x + r*cos(2*PI*(cars[i].x / road_length));
    y = center_y + r*sin(2*PI*(cars[i].x / road_length));
    fill(color(255,0,0));
    ellipse(x,y,10,10);
    fill(color(255,255,255));
    text(str(i),x,y);
  }
  
  for (int i = 0; i < NUMCARS; i++) {
    int front = i+1;
    if (front >= NUMCARS) front -= NUMCARS;
    float dfront;
    
    if (cars[i].x < cars[front].x) {
      dfront = cars[front].x - cars[i].x;
    } else {
      dfront = (road_length - cars[i].x) + cars[front].x;
    }
    cars[i].update_accel(dfront, dt);
  }
  for (int i = 0; i < NUMCARS; i++) {
    cars[i].move(dt, road_length);
  }

}
