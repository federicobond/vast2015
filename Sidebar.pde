class Sidebar extends Component {

  Sidebar(int x, int y, int width, int height) {
    super(x, y, width, height);
  }

  void addItem(Component item) {
    children.add(item);
  }

  void removeItem(Component item) {
    children.remove(item);
  }

  List<Component> getItems() {
    return children;
  }

  void removeAllItems() {
    Iterator<Component> it = children.iterator();
    while (it.hasNext()) {
      if (it.next() instanceof DataFileItem) {
        it.remove();
      }
    }
  }

  void drawTitle(int dy, String title) {
    fill(255);
    textFont(fontBold);
    text(title, x + 20, y + dy);
    textFont(fontRegular);

    strokeWeight(1);
    stroke(50);
    fill(255);
    line(x, y + dy + 10, x + width - 1, y + dy + 10);

    line(x -1 + SIDEBAR, 0, x -1 + SIDEBAR, HEIGHT);
  }

  void display() {
    noStroke();

    image(BG, x, 0, width, HEIGHT);
  }
}

public class DataFileItem extends Component {
  String name;
  String timestamp;

  /*
  class CloseButton extends Component {
    CloseButton() {
      super(0, 0, 10, 10);
    }

    void mousePressed(int mx, int my) {
      println("dleete");
    }

    void display() {
      fill(100);
      if (mouseOver) {
        fill(150);
      }
      rect(SIDEBAR - 20, 5, 14, 14);
    }
  }
  */

  DataFileItem(int i, String name) {
    super(0 + (SIDEBAR / 2) * (i%2), 40 + i/2 * 26, SIDEBAR / 2 - 1, 25);
    this.name = name;
    timestamp = name.substring(5, name.length()).replace("_", " ");
    timestamp = timestamp.replace("2014-6-06", "Fri");
    timestamp = timestamp.replace("2014-6-07", "Sat");
    timestamp = timestamp.replace("2014-6-08", "Sun");
    //add(new CloseButton());
  }

  void mousePressed(int mx, int my) {
    if (shifted) {
      deleteData(name);
      reloadDataFiles = true;
    } else {
      loadData(name);
    }
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
    text(timestamp, x + 20, y + 17);
  }
}

class MainSidebar extends Sidebar {
  MainSidebar(int x, int y, int w, int h) {
    super(x, y, w, h);
  }

  void display() {
    super.display();

    drawTitle(28, "Snapshots");
  }
}

class ExtraSidebar extends Sidebar {
  ExtraSidebar(int x, int y, int w, int h) {
    super(x, y, w, h);
  }

  void display() {
    super.display();

    drawTitle(28, "Tracking: (" + trackSet.size() + ")");

    Iterator<Integer> it = trackSet.iterator();
    for (int i = 0; it.hasNext(); i++) {
      Integer id = it.next();
      text(id, x + 20 + (80 * (i%3)), y + 28 + 36 + (i/3) * 25);
    }
  }
}
