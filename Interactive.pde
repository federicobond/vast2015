public static class Interactive {
  List<Component> components = new ArrayList<Component>();

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

  static boolean insideComponent(int x, int y, Component c) {
    return x >= c.x && y >= c.y && x <= c.x + c.width && y <= c.y + c.height;
  }

  public void mouseEvent(MouseEvent event) {
    int x = event.getX();
    int y = event.getY();
    for (Component c : components) {
      if (insideComponent(x, y, c)) {
        c.mouseOver = true;
        c.mouseEvent(event.getAction(), x, y);
      } else {
        c.mouseOver = false;
      }
    }
  }

}
