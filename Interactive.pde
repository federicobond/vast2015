public static class Interactive {
  ArrayList<Component> components = new ArrayList<Component>();
  
  private static Interactive instance; 
  
  private PApplet app;

  private Interactive(PApplet app) {
    this.app = app;
  }
  
  static void add(Component c) {
    instance.components.add(c);
  }
  
  static void remove(Component c) {
    instance.components.remove(c);
  }
  
  synchronized static Interactive make(PApplet parent) {
    if (instance == null) {
      instance = new Interactive(parent);
    }
    
    parent.registerMethod("draw", instance);
    parent.registerMethod("mouseEvent", instance);
    return instance;
  }
  
  public void draw() {
    for (Component c : components) {
      c.draw();
    }
  }
  
  private boolean insideComponent(int x, int y, Component c) {
    return x >= c.x && y >= c.y && x <= c.x + c.width && y <= c.y + c.height;
  }
  
  public void mouseEvent(MouseEvent event) {
    int x = event.getX();
    int y = event.getY();

    switch (event.getAction()) {
      case MouseEvent.PRESS:
        mousePressed(x, y);
        break;
      case MouseEvent.RELEASE:
        mouseReleased(x, y);
        break;
      case MouseEvent.CLICK:
        mouseClicked(x, y);
        break;
      case MouseEvent.DRAG:
        mouseDragged(x, y);
        break;
      case MouseEvent.MOVE:
        mouseMoved(x, y);
        break;
    }
  }
  
  void mousePressed(int x, int y) {
    for (Component c : components) {
      if (!insideComponent(x, y, c)) continue;
      c.mousePressed();
    }
  }
  
  void mouseClicked(int x, int y) {
    for (Component c : components) {
      if (!insideComponent(x, y, c)) continue;
      c.mouseClicked();
    }
  }

  void mouseReleased(int x, int y) {
    for (Component c : components) {
      if (!insideComponent(x, y, c)) continue;
      c.mouseReleased();
    }
  }
  
  void mouseMoved(int x, int y) {
    for (Component c : components) {
      if (!insideComponent(x, y, c)) continue;
      c.mouseMoved();
    }
  }
  
  void mouseDragged(int x, int y) {
    for (Component c : components) {
      if (!insideComponent(x, y, c)) continue;
      c.mouseDragged();
    }
  }
}
