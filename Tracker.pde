class Tracker {
  public PVector pos;
  public boolean tracking = false;
  private PVector dis = new PVector(random(-4, 4), random(-4, 4));
  private color _color = color(random(125, 255), random(125, 255), random(125, 255));

  private List<PVector> trail;

  Tracker(int id, PVector _pos) {
    pos = _pos;

    if (trackSet.contains(id)) {
      setTracking(true);
    }
  }

  void setTracking(boolean val) {
    tracking = val;
    if (!tracking) {
      trail = null;
    }
  }

  void setPos(int x, int y) {
    // avoid creating trails for stationary trackers
    if (tracking && showTrails && (pos.x != x || pos.y != y)) {
      if (trail == null) {
        trail = new ArrayList<PVector>();
      }
      trail.add(new PVector(x, y));
    }
    pos.set(x, y);
  }

  void displayTrail() {
    if (tracking && showTrails && trail != null) {
      stroke(255, 150);
      strokeWeight(3);
      noFill();
      Iterator<PVector> it = trail.iterator();
      PVector from = it.next();
      while (it.hasNext()) {
        PVector to = it.next();
        line(from.x, from.y, to.x, to.y);
        from = to;
      }
    }
  }

  void display() {
    displayTrail();

    int size = 4;
    if (tracking) {
      strokeWeight(3);
      stroke(255, 255, 255);
      fill(255, 0, 0);
      size = 10;
    } else if (dimUntracked) {
      noStroke();
      fill(_color & 0xFF, 50);
    } else {
      noStroke();
      fill(_color);
    }

    ellipse(pos.x + dis.x, pos.y + dis.y, size, size);
  }
}
