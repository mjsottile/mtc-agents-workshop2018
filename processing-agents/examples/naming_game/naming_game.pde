int BULK_UPDATE = 100;
int wHeight = 100;
int wWidth = 100;
boolean torus = false;
float eps = 1e-9;
//
// noise settings:
// 
// interesting values: 0.2/0.8/100.0
//
float noiseThresh = 0.01;
float perturbationThresh = 0.8;
float perturbationAmount = 100.0;

class Word {
  color c;
  
  Word() {
    c = color(random(255), random(255), random(255));
  }
  
  Word(color c) {
    this.c = c;
  }
  
  void perturb() {
    float rpert = random(perturbationAmount) - (perturbationAmount/2.0);
    float gpert = random(perturbationAmount) - (perturbationAmount/2.0);
    float bpert = random(perturbationAmount) - (perturbationAmount/2.0);
    c = color(constrain(red(c)+rpert,0,255),
              constrain(green(c)+gpert,0,255),
              constrain(blue(c)+bpert,0,255));
  }
  
  boolean equivalent(Word w) {
    return (abs(red(c)-red(w.c)) < eps &&
            abs(green(c)-green(w.c)) < eps &&
            abs(blue(c)-blue(w.c)) < eps);
  }
  
  Word combineWith(Word w) {
    color wc = w.c;
    
    color cnew = color((red(c)+red(wc))/2.0,
                       (green(c)+green(wc))/2.0,
                       (blue(c)+blue(wc))/2.0);
    
    return new Word(cnew);
  }
}

class Agent {
  ArrayList<Word> vocab;
  boolean interacted;

  Agent() {
    interacted = false;
    vocab = new ArrayList<Word>();
  }
  
  void perturb() {
    for (int i = 0; i < vocab.size(); i++) {
      Word w = vocab.get(i);
      if (random(1.0) < perturbationThresh) {
        Word wnew = new Word(w.c);
        wnew.perturb();
        vocab.set(i,wnew);
      }
    }
  }
  
  void reset() {
    interacted = false;
  }
  
  boolean knowsWord(Word kw) {
    for (Word w : vocab) {
      if (w.equivalent(kw)) {
        return true;
      }
    }
    return false;
  }
  
  void clearOthers(Word w) {
    vocab = new ArrayList<Word>();
    vocab.add(w);
  }
  
  void learnWord(Word w) {
    vocab.add(w);
  }
  
  Word randomWord() {
    if (vocab.size() > 0) {
      return vocab.get(int(random(vocab.size())));
    } else {
      Word w = new Word();
      vocab.add(w);
      return w;
    }
  }
  
  void draw(float x, float y) {
    float h = height / wHeight;
    float w = width / wWidth;

    noStroke();
    
    if (vocab.size() == 0) {
      fill(color(0,0,0));
      ellipse(x, y, w, h);
      return;
    }
    
    float pieSize = TWO_PI / vocab.size();
    float start = 0.0;
    for (Word word : vocab) {
      fill(word.c);
      arc(x, y, w, h, start, start+pieSize);
      start += pieSize;
    }
  }
}

Agent a[][];

int neighbor(int coord, int extent) {
  int offset = int(random(3))-1;
  if (torus) {
    return (coord + extent + offset) % extent;
  } else {
    int cnew = coord + offset;
    while (cnew < 0 || cnew >= extent) {
       offset = int(random(3))-1;
       cnew = coord + offset;
    }
    return cnew;
  }
}

void noise(int i, int j) {
  if (random(1.0) < noiseThresh) {
    Agent x = a[i][j];
    x.perturb();
  }
}

void oneStep() {
  int i = int(random(wWidth));
  int j = int(random(wHeight));
  Agent speaker = a[i][j];
  int ni = neighbor(i, wWidth);
  int nj = neighbor(j, wHeight);
  Agent hearer = a[ni][nj];
  
  Word w = speaker.randomWord();
  if (hearer.knowsWord(w)) {
    hearer.clearOthers(w);
    speaker.clearOthers(w);
  } else {
    hearer.learnWord(w);
  }
}

void setup() {
  size(500,500);
  
  a = new Agent[wWidth][wHeight];
  for (int i = 0; i < wWidth; i++) {
    for (int j = 0; j < wHeight; j++) {
      a[i][j] = new Agent();
    }
  }
}

void draw() {
  for (int i = 0; i < BULK_UPDATE; i++) {
    oneStep();
  }
  
  for (int i = 0; i < wWidth; i++) {
    for (int j = 0; j < wHeight; j++) {
      noise(i,j);
    }
  }
  
  background(0);
  float w = width/wWidth;
  float h = height/wHeight;
  
  for (int i = 0; i < wWidth; i++) {
    for (int j = 0; j < wHeight; j++) {
      a[i][j].draw(i * w + (w/2), j * h + (h/2));
    }
  }
}
