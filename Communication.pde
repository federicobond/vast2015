class Communication {
  Tracker from;
  Tracker to;
  public int life = (int) constrain(frameRate / 2.5, 3, 10);

  Communication(Tracker _from, Tracker _to) {
    from = _from;
    to = _to;
  }

  void display() {
    // highlight communications from tracked devices
    if (from.tracking || to.tracking) {
      strokeWeight(4);
      stroke(255, 50, 50, map(life, 0, 10, 0, 200));
    } else if (dimUntracked) {
      return;
    } else {
      strokeWeight(1);
      stroke(from._color, map(life, 0, 10, 0, 150));
    }
    line(from.pos.x, from.pos.y, to.pos.x, to.pos.y);
  }
}
