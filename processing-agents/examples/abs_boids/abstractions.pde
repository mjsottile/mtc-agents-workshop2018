/*
Processing Agent-Based-Modeling Library
Copyright (C) 2018  Matthew J. Sottile (mjsottile@me.com)

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

import java.util.Map;

interface Drawable {
  void draw();
}

/**
 * The agent set manages the current active agents.  This entails
 * managing the map from agent GUID to the agent itself, as well
 * as the arraylist of agents.  The GUID generation is encapsulated
 * in the agentset too.
 */
class AgentSet {
  HashMap<Integer, Agent> id_map;
  ArrayList<Agent> agents;
  int unique_id;

  AgentSet() {
    agents = new ArrayList<Agent>();
    id_map = new HashMap<Integer, Agent>();
    unique_id = 1;
  }

  int freshID() {
    int id = unique_id;
    unique_id++;
    return id;
  }

  void remove(Agent a) {
    agents.remove(a);
    id_map.remove(a.id);
  }

  void add(Agent a) {
    agents.add(a);
    id_map.put(a.id, a);
  }

  Agent getByID(int id) {
    return id_map.get(id);
  }

  /**
   * The garbage collection phase scans the set of
   * agents and asks them if they should be cleaned up.
   */
  void cleanup() {
    for (int i = agents.size()-1; i >= 0; i--) {
      Agent a = agents.get(i);
      if (a.isGarbage()) {
        agents.remove(i);
        id_map.remove(a.id);
      }
    }
  }
}

/**
 * The agent class defines the default behaviors and common
 * interface that all agents must provide.  Given that no
 * useful functionality is provided by the agent base class,
 * it is necessary to implement a derived class for specific
 * agent behavior and state.
 */
class Agent {
  PVector pos;
  int id;
  Space space;

  Agent(AgentSet agents, Space space) {
    id = agents.freshID();
    this.space = space;
    this.pos = null;
  }
  
  /**
   * Single step for named scheduler.
   */
  void step(String s) {
    step();
  }

  /**
   * Single step for agent.  Default to printing error.
   */
  void step() {
    throw new UnsupportedOperationException("Agent.step");
  }

  /**
   * Commit step for named scheduler.
   */
  void commitStep(String s) {
    commitStep();
  }

  /**
   * For single-step agents where all must make a simultaneous step,
   * we must split a step into two parts: the part that computes the
   * next value of the agent, and the part that commits this next value
   * to be the current value of the agent.
   */
  void commitStep() {
    throw new UnsupportedOperationException("Agent.commitStep");
  }

  /**
   * Staged step for named scheduler.
   */
  void stepStage(String s, int stageNum) {
    stepStage(stageNum);
  }

  /**
   * A single step is broken down into a sequence of stages.
   * This is invoked with the stage number that is to be
   * performed.  Default to printing error.
   */
  void stepStage(int stageNum) {
    throw new UnsupportedOperationException("Agent.stepStage");
  }

  /**
   * If an agent can be cleaned up and disposed of, this returns true.
   * By default, it returns false.
   */
  boolean isGarbage() {
    return false;
  }
}

/**
 * A space defines a coordinate system and topology that agents are
 * embedded within.  It provides the concept of a neighborhood and
 * distance.  Agents may be added and removed from the space, and the
 * space maintains whatever data structure is necessary to provide
 * efficient neighbor lookups.  A space may be finite or infinite, and
 * in the case of finite spaces, may impose wraparound boundaries.
 * Infinite spaces or those without a defined finite extent will report
 * -1 as their width/height.  Finite spaces extend from the origin (0,0)
 * to (w,h).
 */
abstract class Space {
  /**
   * Return the neighbors of the position given (not including
   * those at the position) within some radius r.
   */
  abstract ArrayList neighbors(PVector pos, float r);

  /**
   * Return the neighbors of the agent given within some radius r.
   * Note: agents are not neighbors of themselves.
   */
  ArrayList neighbors_of(Agent a, float r) {
    ArrayList<Agent> ns = neighbors(a.pos, r);
    for (int i = ns.size()-1; i >= 0; i--) {
      Agent na = ns.get(i);
      if (na.id == a.id) {
        ns.remove(i);
      }
    }
    return ns;
  }

  /**
   * Remove an agent from the space.
   */
  abstract void removeAgent(Agent a);

  /**
   * Place an agent in the space at the position.
   */
  abstract void placeAgent(Agent a, PVector pos);

  /**
   * Move an agent that is already present in the space to
   * a new location in the space.
   */
  abstract void moveAgent(Agent a, PVector pos);

  /**
   * Return the width of the space.  Return -1 if the
   * width is undefined.
   */
  abstract int width();

  /**
   * Return the height of the space.  Return -1 if the
   * height is undefined.
   */
  abstract int height();

  /**
   * Given a coordinate vector, adjust it so that it falls
   * within the space.  A runtime exception is raised if the
   * coordinates cannot be fixed in the given space (e.g., out of bounds
   * on a non-torus).
   */ 
  abstract PVector fixCoordinates(PVector x) throws RuntimeException;

  /**
   * Given a vantage point position x, and a subject position y, return
   * a relative position of y to x such that the relative position of y
   * is the closest it can be in the space.
   */
  abstract PVector relative_to(PVector x, PVector y);

  /**
   * Return the shortest distance in the space from x to y.
   */
  abstract float dist(PVector x, PVector y);

  /**
   * Update the space.  This is called after one or more agents may have moved
   * in order to keep any auxiliary data structures coherent.  By default it
   * does nothing.
   */
  void update() {
    // empty
  }
}

class ContinuousSpace extends Space {
  AgentSet agents;
  boolean finite;
  int w, h;
  boolean torus;

  ContinuousSpace(int w, int h, AgentSet agents) {
    finite = true;
    this.w = w;
    this.h = h;
    this.agents = agents;
    torus = true;
  }

  ContinuousSpace(AgentSet agents) {
    finite = false;
    w = -1;
    h = -1;
    torus = false;
    this.agents = agents;
  }

  PVector fixCoordinates(PVector x) {
    if (!finite) {
      return x;
    } else {
      if (torus) {
        return new PVector((x.x + w) % w, (x.y + h) % h);
      } else {
        if (x.x > w || x.x < 0 || x.y > h || x.y < 0) {
          throw new RuntimeException("Coordinates out of bounds: "+x);
        } else {
          return x;
        }
      }
    }
  }

  PVector relative_to(PVector x, PVector y) {
    if (torus) {
        // try wraparounds
        PVector y_up = new PVector(y.x, y.y-h);
        PVector y_down = new PVector(y.x, y.y+h);
        PVector y_left = new PVector(y.x-w, y.y);
        PVector y_right = new PVector(y.x+w, y.y);

        PVector min_y = y;
        if (PVector.dist(x, min_y) > PVector.dist(x, y_up)) {
          min_y = y_up;
        }
        if (PVector.dist(x, min_y) > PVector.dist(x, y_down)) {
          min_y = y_down;
        }
        if (PVector.dist(x, min_y) > PVector.dist(x, y_left)) {
          min_y = y_left;
        }
        if (PVector.dist(x, min_y) > PVector.dist(x, y_right)) {
          min_y = y_right;
        }
        return min_y;
    } else {
      return y;
    }
  }

  float dist(PVector x, PVector y) {
    if (torus) {
      PVector rel_y = relative_to(x, y);
      return PVector.dist(x, rel_y);
    } else {
      return PVector.dist(x,y);
    }
  }

  void removeAgent(Agent a) {
    // do nothing: this continuous space doesn't hold agents in
    // a secondary data structure beyond the agentset: removal must
    // occur there since the set owns the agent objects.
  }

  void moveAgent(Agent a, PVector pos) {
    // fix the coordinate
    PVector p = fixCoordinates(pos);
    a.pos = p;
  }

  void placeAgent(Agent a, PVector pos) {
    //
    a.pos = pos;
  }

  int width() {
    return w;
  }

  int height() {
    return h;
  }

  ArrayList<Agent> neighbors(PVector c, float r) {
    ArrayList<Agent> ns = new ArrayList<Agent>();

    for (Agent a : agents.agents) {
      if (dist(c, a.pos) < r) {
        ns.add(a);
      }
    }

    return ns;
  }
}

// dimension of space that KDTree is partitioning
int KDT_DIM = 2;

class KDTreeNode<T> {
  PVector loc;
  T contents;
  KDTreeNode left, right;

  KDTreeNode() {
    loc = null;
    left = null;
    right = null;
    contents = null;
  }

  private void insert_with_depth(PVector x, T value, int depth) {
    // node has no position, so associate the position and done.
    if (loc == null) {
      loc = x;
      contents = value;
      return;
    }

    // node has a position, so figure out which dimension we are splitting
    // on based on depth.
    int axis = depth % KDT_DIM;

    // get array view on both location of current node and x
    float[] loc_a = loc.array();
    float[] x_a = x.array();

    // if x greater than loc on axis, go down right side
    if (loc_a[axis] < x_a[axis]) {
      if (right == null) {
        right = new KDTreeNode();
      }
      right.insert_with_depth(x, value, depth+1);
    
    // otherwise go down left side
    } else {
      if (left == null) {
        left = new KDTreeNode();
      }
      left.insert_with_depth(x, value, depth+1);
    }
  }

  void insert(PVector x, T value) {
    insert_with_depth(x, value, 0);
  }

  private boolean inbounds(PVector x, PVector pmin, PVector pmax) {
    float[] x_a = x.array();
    float[] pmin_a = pmin.array();
    float[] pmax_a = pmax.array();

    for (int i = 0; i < KDT_DIM; i++) {
      if (x_a[i] < pmin_a[i] || x_a[i] > pmax_a[i]) {
        return false;
      }
    }
    return true;
  }

  private void range_search_with_list(PVector pmin, PVector pmax, ArrayList<T> l, int depth) {
    if (loc == null) {
      return;
    }

    int axis = depth % KDT_DIM;
    float[] loc_a = loc.array();
    float[] pmin_a = pmin.array();
    float[] pmax_a = pmax.array();

    if (loc_a[axis] < pmin_a[axis] && right != null) {
      right.range_search_with_list(pmin, pmax, l, depth+1);
    } else if (loc_a[axis] > pmax_a[axis] && left != null) {
      left.range_search_with_list(pmin, pmax, l, depth+1);
    } else {
      if (inbounds(loc, pmin, pmax)) {
        l.add(contents);
      }
      if (right != null) {
        right.range_search_with_list(pmin, pmax, l, depth+1);
      }
      if (left != null) {
        left.range_search_with_list(pmin, pmax, l, depth+1);
      }
    }
  }

  ArrayList<T> range_search(PVector min, PVector max) {
    ArrayList<T> l = new ArrayList<T>();
    range_search_with_list(min, max, l, 0);
    return l;
  }

  void range_search(PVector min, PVector max, ArrayList<T> l) {
    range_search_with_list(min, max, l, 0);
  }
}

class KDTreeContinuousSpace extends ContinuousSpace {
  KDTreeNode<Agent> t;
  boolean updated;

  KDTreeContinuousSpace(int w, int h, AgentSet agents) {
    super(w, h, agents);
    t = null;
    updated = false;
  }

  void removeAgent(Agent a) {
    // agent was removed, so make sure we update the tree
    updated = false;
  }

  void moveAgent(Agent a, PVector pos) {
    super.moveAgent(a, pos);
    updated = false;
  }

  void placeAgent(Agent a, PVector pos) {
    super.placeAgent(a, pos);
    updated = false;
  }

  ArrayList<Agent> neighbors(PVector c, float r) {
    if (!updated) {
      update();
    }

    // TODO: this does not work for torus!
    ArrayList<Agent> ns = new ArrayList<Agent>();

    if (r*2 >= this.width() || r*2 >= this.height()) {
      throw new UnsupportedOperationException("Cannot handle neighborhood radii larger than world.");
    }

    if (torus) {
      int boxes = 1;
      float[] minx = new float[4];
      float[] miny = new float[4];
      float[] maxx = new float[4];
      float[] maxy = new float[4];
      minx[0] = c.x - r;
      miny[0] = c.y - r;
      maxx[0] = c.x + r;
      maxy[0] = c.y + r;

      if (c.x - r < 0) {
        // x from 0 to c.x + r, and width-(r-c.x) to width
        minx[0] = 0;
        maxx[0] = c.x + r;
        minx[1] = this.width()-(r-c.x);
        maxx[1] = this.width();

        // carry over y values from 0.
        miny[1] = miny[0];
        maxy[1] = maxy[0];
        boxes = 2;
      } else {
        if (c.x + r >= this.width()) {
          // x from c.x - r to width, and 0 to r-c.x
          minx[0] = c.x - r;
          maxx[0] = this.width();
          minx[1] = 0;
          maxx[1] = r - c.x;

          // carry over y values from 0.
          miny[1] = miny[0];
          maxy[1] = maxy[0];
          boxes = 2;
        }
      }

      if (c.y - r < 0) {
        // y from 0 to c.y + r, and height-(r-c.y) to height
        for (int i = 0; i < boxes; i++) {
          minx[i+boxes] = minx[i];
          maxx[i+boxes] = maxx[i];

          miny[i] = 0;
          maxy[i] = c.y + r;
          miny[i+boxes] = this.height() - (r - c.y);
          maxy[i+boxes] = this.height();          
        }
        boxes = boxes * 2;
      } else {
        if (c.y + r >= this.height()) {
          // y from c.y - r to height, and 0 to r-c.y
          for (int i = 0; i < boxes; i++) {
            minx[i+boxes] = minx[i];
            maxx[i+boxes] = maxx[i];

            miny[i] = c.y - r;
            maxy[i] = this.height();
            miny[i+boxes] = 0;
            maxy[i+boxes] = r - c.y;          
          }
          boxes = boxes * 2;
        }
      }
      
      // spin through all boxes to check
      for (int i = 0; i < boxes; i++) {
        t.range_search(new PVector(minx[i], miny[i]), new PVector(maxx[i], maxy[i]), ns);
      }
    } else {
      t.range_search(new PVector(c.x-r, c.y-r), new PVector(c.x+r, c.y+r), ns);
    }

    for (int i = ns.size()-1; i >= 0; i--) {
      Agent a = ns.get(i);
      if (PVector.dist(a.pos, c) > r) {
        ns.remove(i);
      }
    }

    return ns;
  }

  void update() {
    // spin through agent set to create a new instance of t
    t = new KDTreeNode<Agent>();

    for (Agent a : agents.agents) {
      t.insert(a.pos, a);
    }

    updated = true;
  }
}

class GridSpace extends Space {
  boolean moore;
  boolean torus;
  IntList a[][];
  AgentSet agents;
  
  GridSpace(int w, int h, AgentSet agents) {
    this(w, h, agents, true);
  }
  
  GridSpace(int w, int h, AgentSet agents, boolean moore) {
    a = new IntList[w][h];
    for (int i = 0; i < w; i++) {
      for (int j = 0; j < h; j++) {
        a[i][j] = new IntList();
      }
    }
    this.moore = moore;
    this.torus = true;
    this.agents = agents;
  }
  
  int width() {
    return a.length;
  }
  
  int height() {
    return a[0].length;
  }

  PVector relative_to(PVector x, PVector y) {
    if (torus) {
        int h = this.height();
        int w = this.width();

        // try wraparounds
        PVector y_up = new PVector(y.x, y.y-h);
        PVector y_down = new PVector(y.x, y.y+h);
        PVector y_left = new PVector(y.x-w, y.y);
        PVector y_right = new PVector(y.x+w, y.y);

        PVector min_y = y;
        if (PVector.dist(x, min_y) > PVector.dist(x, y_up)) {
          min_y = y_up;
        }
        if (PVector.dist(x, min_y) > PVector.dist(x, y_down)) {
          min_y = y_down;
        }
        if (PVector.dist(x, min_y) > PVector.dist(x, y_left)) {
          min_y = y_left;
        }
        if (PVector.dist(x, min_y) > PVector.dist(x, y_right)) {
          min_y = y_right;
        }
        return min_y;
    } else {
      return y;
    }
  }

  float dist(PVector x, PVector y) {
    PVector rel_y = relative_to(x, y);

    // 2D Manhattan distance
    return abs(x.x-rel_y.x) + abs(x.y-rel_y.y);
  }
  
  ArrayList<Agent> neighbors(PVector c, float r) {
    ArrayList<Agent> ns = new ArrayList<Agent>();
    int ir = round(r);
    
    int cx = round(c.x);
    int cy = round(c.y);
    
    for (int i = cx-ir; i <= cx+ir; i++) {
      for (int j = cy-ir; j <= cy+ir; j++) {
        // skip center
        if  (i == cx && j == cy) {
          continue;
        }
        
        // if not torus, skip off-grid elements
        if (!torus) {
          if (i < 0 || i >= a.length) {
            continue;
          }
          if (j < 0 || j >= a[0].length) {
            continue;
          }
        }
        
        int ix = i;
        int jx = j;
        
        if (torus) {
          ix = (i + a.length) % a.length;
          jx = (j + a[0].length) % a[0].length;
        }
        float dx = abs(float(cx-i));
        float dy = abs(float(cy-j));
        float d;
        
        if (moore) {
          // l-infinity norm
          d = max(dx, dy);
        } else {
          // l-1 norm
          d = dx + dy;
        }
        
        // inside radius and not the central element
        if (d <= r) {
          IntList contents = a[ix][jx];
          for (int a : contents) {
            ns.add(agents.getByID(a));
          }
        }
      }
    }
    
    return ns;
  }

  void removeAgent(Agent agent) {
    IntList ids = a[round(agent.pos.x)][round(agent.pos.y)];
    for (int i = 0; i < ids.size(); i++) {
      if (ids.get(i) == agent.id) {
        ids.remove(i);
        break;
      }
    }
  }

  void placeAgent(Agent agent, PVector pos) {
    agent.pos = pos;
    int x = round(pos.x);
    int y = round(pos.y);
    a[x][y].append(agent.id);
  }
  
  void moveAgent(Agent agent, PVector pos) {
    removeAgent(agent);
    PVector p = fixCoordinates(pos);
    placeAgent(agent, p);
  }

  PVector fixCoordinates(PVector x) {
    int w = this.width();
    int h = this.height();
    
    if (torus) {
      return new PVector((round(x.x)+w) % w, (round(x.y)+h) % h);
    } else {
      if (x.x > w || x.x < 0 || x.y > h || x.y < 0) {
        throw new RuntimeException("Coordinates out of bounds: "+x);
      } else {
        return x;
      }
    }
  }
}

//class SingleGridSpace extends GridSpace {
//}

class NetworkSpace extends Space {
  IntList adj[]; // adjacency list
  IntList residents[]; // agents residing at each vertex
  boolean directed;
  AgentSet agents;

  NetworkSpace(int numvert) {
    this(numvert, false);
  }

  NetworkSpace(int numvert, boolean directed) {
    this.directed = directed;
    adj = new IntList[numvert];
    residents = new IntList[numvert];
    for (int i = 0; i < numvert; i++) {
      adj[i] = new IntList();
      residents[i] = new IntList();
    }
  }

  PVector relative_to(PVector x, PVector y) {
    return y;
  }

  float dist(PVector x, PVector y) {
    throw new UnsupportedOperationException("dist");
  }

  void addEdge(int a, int b) {
    adj[a].append(b);
    if (!directed) {
      adj[b].append(a);
    }
  }

  void removeAgent(Agent a) {
    int vertex = round(a.pos.x);
    for (int i = residents[vertex].size()-1; i >= 0; i--) {
      int ra_id = residents[vertex].get(i);
      if (a.id == ra_id) {
        residents[vertex].remove(i);
        break;
      }
    }
  }
  
  void placeAgent(Agent a, PVector pos) {
    int vertex = round(pos.x);
    a.pos = pos;
    residents[vertex].append(a.id);
  }
  
  int width() {
    return -1;
  }
  
  int height() {
    return -1;
  }
  
  void moveAgent(Agent a, PVector pos) {
    removeAgent(a);
    placeAgent(a, pos);
  }

  PVector fixCoordinates(PVector x) {
    // no useful fixCoordinates for networks, so just return fresh x
    return x.copy();
  }
  
  /**
   * NOTE: radius r is ignored for network neighborhoods for now.
   */
  ArrayList<Agent> neighbors(PVector c, float r) {
    ArrayList<Agent> ns = new ArrayList<Agent>();

    for (int n_node: adj[round(c.x)]) {
      for (int n_id: residents[n_node]) {
        ns.add(agents.getByID(n_id));
      }
    }

    return ns;
  }
}

/**
 * A scheduler handles stepping a set of agents.  A scheduler can be
 * optionally named.  Agents added and removed to the scheduler are added
 * to an ArrayList maintained by the scheduler.  Schedulers do not own
 * agent objects, so adding and removing them only affects the agent set
 * that the scheduler instance manages (i.e., removing an agent from one
 * scheduler has no effect on other schedulers with references to the same
 * agent).  The scheduler must provide a cleanup phase so that it can remove
 * agents that are garbage such that they can be removed from the
 * scheduler agent set.  The scheduler abstract class provides default behavior
 * for maintaining the agent set, but defers implementation of the step() method
 * to specific scheduler instances.
 */
abstract class Scheduler {
  ArrayList<Agent> agents;
  String name;

  Scheduler(String s) {
    this();
    name = s;
  }

  Scheduler() {
    agents = new ArrayList<Agent>();
    name = "DefaultScheduler";
  }

  void add(Agent a) {
    agents.add(a);
  }
  
  void remove(Agent a) {
    for (int i = 0; i < agents.size(); i++) {
      Agent x = agents.get(i);
      if (a.id == x.id) {
        agents.remove(i);
        return;
      }
    }
  }

  void cleanup() {
    for (int i = agents.size()-1; i >= 0; i--) {
      if (agents.get(i).isGarbage()) {
        agents.remove(i);
      }
    }
  }

  abstract void step();
}

/**
 * This scheduler invokes the stepStage function for a fixed number
 * of stages during a step.  All agents are stepped for step i, and
 * then all agents are stepped for step i+1, and so on.
 */
class StagedScheduler extends Scheduler {
  int numStages;

  StagedScheduler(String name) {
    super(name);
  }

  StagedScheduler(int numStages) {
    super();
    if (numStages < 1) {
      throw new IllegalArgumentException("StagedScheduler requires numStages >= 1.");
    }
    this.numStages = numStages;
  }

  void step() {
    int nagents = agents.size();

    for (int i = 0; i < numStages; i++) {

      for (int j = 0; j < nagents; j++) {
        Agent a = agents.get(j);
        a.stepStage(name, i);
      }
    }
  }  
}

/**
 * This scheduler is similar to the arbitrary scheduler, but the
 * agent may cache the results of its step and only commit them
 * when its commitStep() method is called.  This is an alternative
 * to using a staged scheduler with two stages.
 */
class SimultaneousArbitraryScheduler extends Scheduler {
  SimultaneousArbitraryScheduler(String name) {
    super(name);
  }

  void step() {
    //
    // NOTE: this assumes that the iterator over the agent set will
    //       visit agents in the same order during each of the following
    //       loops.
    //

    int nagents = agents.size();

    /* step phase */
    for (int i = 0; i < nagents; i++) {
      Agent a = agents.get(i);
      a.step(name);
    }

    /* commit phase */
    for (int i = 0; i < nagents; i++) {
      Agent a = agents.get(i);
      a.commitStep(name);
    }
  }
}

/**
 * This scheduler steps all agents once in a step in an arbitrary
 * order.  No guarantees are made regarding the order that agents
 * are visited, and it may vary between invocations.
 */
class ArbitraryScheduler extends Scheduler {
  ArbitraryScheduler(String name) {
    super(name);
  }

  void step() {
    int nagents = agents.size(); // capture this before the loop in case new agents
                                 // get appended during the step
    for (int i = 0; i < nagents; i++) {
      Agent a = agents.get(i);
      a.step(name);
    }
  }
}

/**
 * This scheduler steps only one agent during a single step.  The
 * agent selected is randomly drawn from the agent set.
 */
class RandomSingleAgentScheduler extends Scheduler {
  RandomSingleAgentScheduler(String name) {
    super(name);
  }

  void step() {
    int i = floor(random(agents.size()));
    Agent a = agents.get(i);
    a.step(name);
  }
}

/**
 * A model combines a set of agents, a space, and a single scheduler.
 * Agents are added to a model, which handles adding them to the
 * appropriate model structures.  The model provides a model step
 * method that advances the scheduler and then handles cleanup to
 * deal with agents that have become garbage during the step.
 */
class Model {
  AgentSet agents;
  Space space;
  Scheduler scheduler;

  Model(AgentSet agents, Space space, Scheduler scheduler) {
    this.agents = agents;
    this.space = space;
    this.scheduler = scheduler;
  }
  
  void add(Agent a) {
    agents.add(a);
    space.placeAgent(a, a.pos);
    scheduler.add(a);
  }

  void step() {
    scheduler.step();

    // cleanup any dead agents
    scheduler.cleanup();
    agents.cleanup();
  }
}

/**
 * A multischeduler model implements a model that has a single set of agents
 * but more than one scheduler.  An agent can be managed by one or more
 * schedulers.  Schedulers are invoked in the order that they are added to
 * the model.  Each scheduler takes a full step before the next.  Scheduler
 * cleanup occurs in the same order.
 */
class MultiSchedulerModel {
  AgentSet agents;
  Space space;
  ArrayList<Scheduler> schedulers;

  MultiSchedulerModel(AgentSet agents, Space space) {
    this.agents = agents;
    this.space = space;
    this.schedulers = new ArrayList<Scheduler>();
  }

  void addScheduler(Scheduler s) {
    schedulers.add(s);
  }

  void add(Agent a) {
    agents.add(a);
    space.placeAgent(a, a.pos);
  }

  void schedule(Agent a, String scheduler_name) {
    for (Scheduler s : schedulers) {
      if (s.name == scheduler_name) {
        s.add(a);
      }
    }
  }

  void step() {
    for (int i = 0; i < schedulers.size(); i++) {
      Scheduler s = schedulers.get(i);
      s.step();
    }

    for (int i = 0; i < schedulers.size(); i++) {
      Scheduler s = schedulers.get(i);
      s.cleanup();
    }

    agents.cleanup();
  }
}
