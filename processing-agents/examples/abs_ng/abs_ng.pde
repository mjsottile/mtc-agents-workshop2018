int BULK_UPDATE = 100;
int wHeight = 15;
int wWidth = 15;
boolean torus = false;
float eps = 1e-9;
//
// noise settings:
// 
// interesting values: 0.2/0.8/100.0
//
float noiseThresh = 0.01;
float perturbationThresh = 0.01;
float perturbationAmount = 10.0;

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

class NGAgent extends Agent implements Drawable {
  ArrayList<Word> vocab;

  NGAgent(AgentSet agents, Space space) {
    super(agents, space);
    vocab = new ArrayList<Word>();
  }

  void step(String sched) {
    if (sched == "speak") {
      ArrayList<Agent> ns = space.neighbors(pos, 1);
      int i = floor(random(ns.size()));
      NGAgent other = (NGAgent)ns.get(i);
      NGAgent speaker, hearer;
      if (random(1.0) < 0.5) {
        speaker = this;
        hearer = other;
      } else {
        speaker = other;
        hearer = this;
      }
      Word w = speaker.randomWord();
      if (hearer.knowsWord(w)) {
        hearer.clearOthers(w);
        speaker.clearOthers(w);
      } else {
        hearer.learnWord(w);
      }
    }
    if (sched == "noise") {
      if (random(1.0) < noiseThresh) {
        this.perturb();
      }
    }
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
  
  void draw() {
    float h = height / wHeight;
    float w = width / wWidth;
    float x = pos.x * w + (w/2);
    float y = pos.y * h + (h/2);

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

MultiSchedulerModel m;

void setup() {
  size(500,500);
  AgentSet agents = new AgentSet();
  GridSpace s = new GridSpace(wWidth, wHeight, agents, true);
  s.torus = false;

  // word interaction scheduler
  RandomSingleAgentScheduler sched = new RandomSingleAgentScheduler("speak");

  // noise scheduler
  ArbitraryScheduler nsched =  new ArbitraryScheduler("noise");

  m = new MultiSchedulerModel(agents, s);
  m.addScheduler(sched);
  m.addScheduler(nsched);

  for (int i = 0; i < wWidth; i++) {
    for (int j = 0; j < wHeight; j++) {
      NGAgent a = new NGAgent(agents, s);
      a.pos = new PVector(i,j);
      m.add(a);
      // add to each scheduler
      sched.add(a);
      nsched.add(a);
    }
  }
}

void draw() {
  background(0);
  for (Agent a : m.agents.agents) {
    if (a instanceof Drawable) {
      Drawable da = (Drawable)a;
      da.draw();
    }
  }
  
  for (int i = 0; i < BULK_UPDATE; i++) {
    m.step(); 
  }
}
