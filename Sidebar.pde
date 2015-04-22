class Sidebar extends Component {

  Sidebar(int x, int y, int width, int height) {
    super(x, y, width, height);
  }
  
  void addItem(Component item) {
    children.add(item);
  }
  
  void removeAllItems() {
    Iterator<Component> it = children.iterator();
    while (it.hasNext()) {
      if (it.next() instanceof DataFileItem) {
        it.remove();
      }
    }
  }
  
  void display() {
    noStroke();
    
    fill(30);
    rect(WIDTH, 0, WIDTH + SIDEBAR, HEIGHT);
    
    strokeWeight(1);
    stroke(50);
    fill(255);
  
    textFont(fontBold);
    text("Data files:", WIDTH + 20, 25);
    textFont(fontRegular);
    line(WIDTH, 38, WIDTH + SIDEBAR, 38);
    
    textFont(fontBold);
    text("Tracking: (" + trackList.size() + ")", WIDTH + 20, 375);
    textFont(fontRegular);
    line(WIDTH, 388, WIDTH + SIDEBAR, 388);
    for (int i = 0; i < trackList.size(); i++) {
      text(trackList.get(i), WIDTH + 20 + (80 * (i%3)), 412 + (i/3) * 25);
    }
  } 
}

public class DataFileItem extends Component {
  String name;

  DataFileItem(String name, int x, int y, int w, int h) {
    super(x, y, w, h);
    this.name = name;
  }
  
  void mousePressed(int mx, int my) {
    loadData(name);
  }
  
  void display() {
    noStroke();
    if (mouseOver) {
      fill(65);
    } else {
      fill(45);
    }
    rect(x, y, width, height);
    fill(230);
    text(name, x + 15, y + 17);
  }
  
}
