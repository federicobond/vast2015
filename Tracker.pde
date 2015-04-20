class Tracker {
  public PVector pos;
  public boolean tracking = false;
  public PVector dis = new PVector(random(-4, 4), random(-4, 4));
  color _color = color(random(125, 255), random(125, 255), random(125, 255));
  
  Tracker(int id, PVector _pos) {
    pos = _pos;
    
    if (trackList.contains(id)) {
      tracking = true;
    }
  }
  
  void display() {
    int size = 4;
    if (tracking) {
      strokeWeight(3);
      stroke(255, 255, 255);
      fill(255, 0, 0);
      size = 10;
    } else {
      noStroke();
      fill(_color);
    }
    ellipse(pos.x + dis.x, pos.y + dis.y, size, size);
  }
}
