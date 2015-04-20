class Component {
  int x, y, width, height;
  
  Component(int x, int y, int width, int height) {
    this.x = x;
    this.y = y;
    this.width = width;
    this.height = height;
  }
  
  void mousePressed() {}
  void mouseReleased() {}
  void mouseDragged() {}
  void mouseClicked() { println("Hello"); }
  void mouseMoved() {}
  
  void draw() {}
}
