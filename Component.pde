class Component {
  int x, y, width, height;
  boolean mouseOver;
  
  ArrayList<Component> children = new ArrayList<Component>();
  
  Component(int x, int y, int width, int height) {
    this.x = x;
    this.y = y;
    this.width = width;
    this.height = height;
  }
  
  void add(Component c) {
    children.add(c);
  }
  
  void remove(Component c) {
    children.remove(c);
  }
  
  void removeAll() {
    children.clear();
  }
  
  void mouseEvent(int action, int mx, int my) {
    boolean catched = false;
    for (Component c : children) {
      if (Interactive.insideComponent(mx - x, my - y, c)) {
        c.mouseOver = true;
        c.mouseEvent(action, mx - x, my - y);
        catched = true;
      } else {
        c.mouseOver = false;
      }
    }
    if (!catched) {
      switch (action) {
        case MouseEvent.PRESS:
          mousePressed(mx, my);
          return;
        case MouseEvent.RELEASE:
          mouseReleased(mx, my);
          return;
        case MouseEvent.CLICK:
          mouseClicked(mx, my);
          return;
        case MouseEvent.DRAG:
          mouseDragged(mx, my);
          return;
        case MouseEvent.MOVE:
          mouseMoved(mx, my);
          return;
      }
    };
  }
  
  void mousePressed(int mx, int my) {}
  void mouseReleased(int mx, int my) {}
  void mouseDragged(int mx, int my) {}
  void mouseClicked(int mx, int my) {}
  void mouseMoved(int mx, int my) {}
 
  void draw() {
    display();
    pushMatrix();
    translate(x, y);
    for (Component c : children) {
      c.draw();
    }
    popMatrix();
  }
  
  void display() {}
  
  String toString() {
    return getClass().getSimpleName() + "[x=" + x + ", y=" + y + ", width=" + width + ", height=" + height + "]"; 
  }
}
