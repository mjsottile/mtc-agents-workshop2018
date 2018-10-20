// https://pdfs.semanticscholar.org/847f/819a4ea14bd789aca8bc88e85e906cfc657c.pdf

float u[], v[], u_prev[], v_prev[];
float dens[], dens_prev[];
int N = 120;
int sz = (N+2)*(N+2);

void SWAP(float a[], float b[]) {
  float tmp[] = new float[sz];
  arraycopy(a, 0, tmp, 0, sz);
  arraycopy(b, 0, a, 0, sz);
  arraycopy(tmp, 0, b, 0, sz);
}

int index(int i, int j) {
  return (i+(N+2)*j);
}

void add_source(float x[], float s[], float dt) {
  for (int i = 0; i < sz; i++) {
    x[i] += dt * s[i];
  }
}

void diffuse(int b, float x[], float x0[], float diff, float dt) {
  float a = dt*diff*N*N;
  
  for (int k = 0; k < 20; k++) {
    for (int i = 1; i <= N; i++) {
      for (int j = 1; j <= N; j++) {
        x[index(i,j)] = (x0[index(i,j)] + 
                         a * (x[index(i-1,j)] + x[index(i+1,j)] +
                              x[index(i,j-1)] + x[index(i,j+1)]))/(1+4*a);
      }
    }
    set_bnd(b, x);
  }
}

void advect(int b, float d[], float d0[], float u[], float v[], float dt) {
  float x, y, s0, t0, s1, t1, dt0;
  int i0,j0,i1,j1;
  
  dt0 = dt*N;
  
  for (int i = 1; i <= N; i++) {
    for (int j = 1; j <= N; j++) {
      x = i-dt0*u[index(i,j)];
      y = j-dt0*v[index(i,j)];
      if (x<0.5) {
        x = 0.5;
      }
      if (x > N+0.5) {
        x = N+0.5;
      }
      i0 = (int)x;
      i1 = i0+1;      
      if (y<0.5) {
        y = 0.5;
      }
      if (y> N+0.5) {
        y = N+0.5;
      }
      j0 = (int)y;
      j1 = j0+1;
      s1 = x-i0;
      s0 = 1-s1;
      t1 = y-j0;
      t0 = 1-t1;
      d[index(i,j)] = s0*(t0*d0[index(i0,j0)]+t1*d0[index(i0,j1)]) +
                      s1*(t0*d0[index(i1,j0)]+t1*d0[index(i1,j1)]);
    }
  }
  set_bnd(b, d);
}

void dens_step(float x[], float x0[], float u[], float v[], float diff, float dt) {
  add_source(x, x0, dt);
  SWAP(x0,x);
  diffuse(0,x,x0,diff,dt);
  SWAP(x0,x);
  advect(0,x,x0,u,v,dt);
}

void vel_step(float u[], float v[], float u0[], float v0[], float visc, float dt) {
  add_source(u, u0, dt);
  add_source(v, v0, dt);
  SWAP(u0,u);
  diffuse(1, u, u0, visc, dt);
  SWAP(v0,v);
  diffuse(2, v, v0, visc, dt);
  project(u, v, u0, v0);
  SWAP(u0,u);
  SWAP(v0,v);
  advect(1,u,u0,u0,v0,dt);
  advect(2,v,v0,u0,v0,dt);
  project(u,v,u0,v0);
}

void project(float u[], float v[], float p[], float div[]) {
  float h = 1.0 / N;
  
  for (int i = 1; i <= N; i++) {
    for (int j = 1; j <= N; j++) {
      div[index(i,j)] = -0.5 * h * (u[index(i+1,j)]-u[index(i-1,j)]+
                                    v[index(i,j+1)]-v[index(i,j-1)]);
      p[index(i,j)] = 0;
    }
  }
  set_bnd(0, div);
  set_bnd(0, p);
  
  for (int k = 0; k < 20; k++) {
    for (int i = 1; i<= N; i++) {
      for (int j = 1; j<= N; j++) {
        p[index(i,j)] = (div[index(i,j)] + p[index(i-1,j)] + p[index(i+1,j)] +
                                           p[index(i,j-1)] + p[index(i,j+1)])/4;
      }
    }
    set_bnd(0,p);
  }
  
  for (int i = 1; i<=N; i++) {
    for (int j = 1; j<=N; j++) {
      u[index(i,j)] -= 0.5 * (p[index(i+1,j)] - p[index(i-1,j)])/h;
      v[index(i,j)] -= 0.5 * (p[index(i,j+1)] - p[index(i,j-1)])/h;
    }
  }
  set_bnd(1,u);
  set_bnd(2,v);
}

void set_bnd(int b, float x[]) {
  for (int i = 1; i <= N; i++) {
    x[index(0  ,i  )]   = b==1 ? -x[index(1,i)] : x[index(1,i)];
    x[index(N+1,i  )]   = b==1 ? -x[index(N,i)] : x[index(N,i)];
    x[index(i  ,0  )]   = b==2 ? -x[index(i,1)] : x[index(i,1)];
    x[index(i  ,N+1)]   = b==2 ? -x[index(i,N)] : x[index(i,N)];
  }
  x[index(0  ,0  )] = 0.5 * (x[index(1,0  )] + x[index(0  ,1)]);
  x[index(0  ,N+1)] = 0.5 * (x[index(1,N+1)] + x[index(0  ,N)]);
  x[index(N+1,0  )] = 0.5 * (x[index(N,0  )] + x[index(N+1,1)]);
  x[index(N+1,N+1)] = 0.5 * (x[index(N,N+1)] + x[index(N+1,N)]);
}

//
// processing boilerplate
//

void setup() {
  size(600,600);
  u = new float[sz];
  v = new float[sz];
  u_prev = new float[sz];
  v_prev = new float[sz];
  dens = new float[sz];
  dens_prev = new float[sz];
  
  for (int i = 0; i < sz; i++) {
    dens[i] = 1.0;
  }
}


float visc = 0.00001;
float diff = 0.00;
float dt = 0.05;

int step = 1;

float dens_max = 0.0;

void draw() {
  background(0);
  
  //float dens_max = 0.0;
  
  for (int i = 0; i < sz; i++) {
    dens_prev[i] = 0.0;
    if (dens[i]>dens_max) { dens_max = dens[i]; }
    u_prev[i] = 0.0;
    v_prev[i] = 0.0;
  }
  //if (step <= 1000) {
  //  for (int i = 0; i < 2; i++) {
  //    for (int j = 0; j < 2; j++) {
  //      dens_prev[index(N/2+i,N/2+j)] = 1.0;
  //    }
  //  }
  //  step++;
  //}
  u_prev[index(10,N/2)] = 15.0;
  u_prev[index(590,N/2-2)] = -15.0;
  if (random(100.0) > 20.0) {
    dens_prev[index(N/2,N/2)] = 30.0;
  }
  //v_prev[index(N/2 + 4, N/2)] = (5 - random(10.0));
  //u_prev[index(N/2 - 4,N/2)] = (5 - random(10.0));
  //v_prev[index(N/2, N/2 + 4)] = (5 - random(10.0));  
  float cw = 600.0/(float)N;
  float ch = 600.0/(float)N;
  float mx = 0.0;
  //for (int i=0;i<sz;i++) {
  //  dens[i] *= 0.95;
  //}
  
  for (int i = 1; i<= N; i++) {
    for (int j = 1; j<= N; j++) {
      noStroke();
      fill(color((log(dens[index(i,j)])/log(dens_max))*455.0,0,0));
      rect(cw*(float)(i-1), ch*(float)(j-1), cw, ch);
      stroke(color(0,abs(u[index(i,j)]*1000),abs(v[index(i,j)]*1000)));
      line(cw*(float)(i-1), ch*(float)(j-1), cw*(float)(i-1) + u[index(i,j)]*10.0, ch*(float)(j-1) + v[index(i,j)]*10.0);
    }
  }
  vel_step(u,v,u_prev,v_prev,visc,dt);
  dens_step(dens, dens_prev, u, v, diff, dt);
  //normalize_dens();
}
