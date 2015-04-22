import java.util.Map;
import java.util.List;
import java.util.Arrays;
import java.util.Iterator;
import java.io.FileReader;
import java.io.BufferedReader;
import java.io.FileNotFoundException;

// TODO:
// * Add tooltip for people
// * Add ability to record events and alert of upcoming events
// * Remove non-tracking people
// * When hovering over tracking id in list, highlight track point, 
//   maybe draw a line between id and point
// * Save tracking data into file
// * Read many more points per draw cicle. Maybe buffer 30 secs of new data on each cycle
// * Select ids and compute statistics: how much time do they spend in the park? average distance travelled? how many rides? time moving vs time stopped, average messages sent

String LOCATION_DATA = "/Users/federicobond/Downloads/MC1 2015 Data/park-movement-Fri.csv";
String COMM_DATA = "/Users/federicobond/Downloads/MC2 2015 Data/comm-data-Fri.csv";

ArrayList<Communication> comms = new ArrayList<Communication>();

int WIDTH = 750;
int HEIGHT = 744;
int SIDEBAR = 270;

float ZOOM_STEP = 0.1;
float MAX_ZOOM = 3.0;
float PAN_STEP = 15;

PMatrix matrix;

PImage map = loadImage("/Users/federicobond/Downloads/Auxiliary Files/Park Map.png");;
BufferedReader locReader;
BufferedReader comReader;

HashMap<Integer, Tracker> locations = new HashMap<Integer, Tracker>();
List<Integer> trackList = new ArrayList<Integer>(Arrays.asList(1116329, 1045021, 1749109, 918738, 1250941, 970490, 128533, 1508923, 839736, 1278894));

String line;
String[] fields, comFields;
String timestamp, newTimestamp, comTimestamp;

boolean paused = false;
boolean step = false;

boolean showCommunications = true;

PFont fontBold, fontRegular;

void setup() {
  randomSeed(0); // make colors repeatable
  size(WIDTH + SIDEBAR, HEIGHT);
  
  fontBold = loadFont("Menlo.vlw");
  fontRegular = loadFont("Menlo-Regular.vlw");

  textFont(fontRegular);
  textSize(14);
  
  locReader = openData(LOCATION_DATA);
  comReader = openData(COMM_DATA);
  
  fields = getData(locReader);
  timestamp = fields[0];
  
  comFields = getData(comReader);
  comTimestamp = comFields[0];
  
  Interactive.make(this);
  Interactive.add(sidebar);
  
  updateDataFiles();

}

void updateData() {
  do {
    timestamp = fields[0];
    
    int id = Integer.parseInt(fields[1]);
    int x = (int)map(Integer.parseInt(fields[3]), 0.0, 99.0, 0.0, 750.0);
    int y = (int)map(Integer.parseInt(fields[4]), 0.0, 99.0, 744.0, 0.0);

    updateLocation(id, x, y);

    fields = getData(locReader);
    newTimestamp = fields[0];
    
  } while (timestamp.equals(newTimestamp));
  
  while (comTimestamp.compareTo(timestamp) < 1) {
    int to = comFields[2].equals("external") ? -1 : Integer.parseInt(comFields[2]);
    int from = Integer.parseInt(comFields[1]);
    
    Tracker tfrom = locations.get(from);
    Tracker tto = locations.get(to);
    
    if (tfrom != null && tto != null) {
      comms.add(new Communication(tfrom, tto));
    }
    
    comFields = getData(comReader);
    comTimestamp = comFields[0];
  }
}

float zoom = 1.0;
PVector pan = new PVector(0, 0);

void draw() {
  noStroke();
  image(map, pan.x, pan.y, WIDTH * zoom, HEIGHT * zoom);

  if (!paused || step) {
    updateData();
  }

  pushMatrix();
  translate(pan.x, pan.y);
  scale(zoom);
  
  // store the map transformation matrix for later
  matrix = getMatrix();

  drawCommunications();
  
  drawTrackers();
  popMatrix();

  drawSelection();

  drawMapControls();
  
  step = false;
}

void drawMapControls() {
  noStroke();
  fill(255);
  text(timestamp, 8, 18);
  text((int)frameRate + " fps", 8, HEIGHT - 10);
  
  fill(255, 0, 0);
  rect(160, -3, textWidth("Play") + 10, 28, 3);
  rect(205, -3, textWidth("Pause") + 10, 28, 3);
  rect(258, -3, textWidth("Save") + 10, 28, 3);

  fill(255);
  text("Play", 165, 18);
  text("Pause", 210, 18);
  text("Save", 263, 18);
  
  
  if (mouseX <= WIDTH && zoom == 1.0) { 
    String label = (int)map(mouseX, 0, WIDTH, 0, 100) + "," + (int)map(mouseY, 0, HEIGHT, 0, 100);
    
    fill(255);
    textAlign(RIGHT);
    text(label, WIDTH - 10, HEIGHT - 10);
    textAlign(LEFT);
  }
}

void drawCommunications() {
  Iterator<Communication> it = comms.iterator();
  while (it.hasNext()) {
    Communication c = it.next();
    if (showCommunications) c.display();
    // do not consume life when paused
    if (!paused | step) {
      c.life--;
    }
    if (c.life == 0) {
      it.remove();
    }
  }
}

void drawSelection() {
  if (!mousePressed) return;
  fill(0, 0, 150, 50);
  strokeWeight(1);
  stroke(255);
  
  int x = constrain(min(firstMouseX, mouseX), 0, WIDTH);
  int y = constrain(min(firstMouseY, mouseY), 0, HEIGHT);
  int w = constrain(max(firstMouseX, mouseX), 0, WIDTH) - x;
  int h = constrain(max(firstMouseY, mouseY), 0, HEIGHT) - y;
  rect(x, y, w, h);
}

void drawTrackers() {
  noStroke();
  ArrayList<Tracker> trackingPoints = new ArrayList<Tracker>();

  for (Map.Entry e : locations.entrySet()) {
    Tracker t = (Tracker) e.getValue();
    if (t.tracking) {
      // add tracking points to a list for later draw
      trackingPoints.add(t);
    } else {
      t.display();
    }
  }
  
  // draw all tracker points on top
  for (Tracker t : trackingPoints) {
    t.display();
  }
}

void mouseClicked() {
  if (playOver()) {
    paused = false;
  } else if (pauseOver()) {
    paused = true;
  } else if (saveOver()) {
    saveData();
  } else if (mouseX <= WIDTH) {
    clearTracked();
  }
}

int firstMouseX, firstMouseY;

void mousePressed() {
  firstMouseX = mouseX;
  firstMouseY = mouseY;
}

boolean addSelection, removeSelection;

void mouseReleased() {
  if (abs(firstMouseX - mouseX) < 2 || abs(firstMouseY - mouseY) < 2) {
    // selection too small, ignoring...
    return;
  }
  
  if (removeSelection) {
    removeTracked();
    return;
  }
  
  if (!addSelection) clearTracked();

  addTracked();
}

void keyPressed() {
  if (key == 'p' || key == ' ') {
    paused = !paused;
  } else if (key == 'n') {
    step = true;
  } else if (key == 's') {
    saveData();
  } else if (key == 'c') {
    showCommunications = !showCommunications;
  } else if (keyCode == ALT) {
    removeSelection = true;
  } else if (keyCode == SHIFT) {
    addSelection = true;
  } else if (key == '+') {
    float newZoom = constrain(zoom + ZOOM_STEP, 1, MAX_ZOOM);
    if (zoom != newZoom) {
      pan.x -= ((newZoom - zoom) * WIDTH) / 2.0;
      pan.y -= ((newZoom - zoom) * HEIGHT) / 2.0;
    }
    zoom = newZoom;
  } else if (key == '-') {
    zoom = constrain(zoom - ZOOM_STEP, 1, MAX_ZOOM);
    pan.x = constrain(pan.x + (ZOOM_STEP * WIDTH) / 2.0, WIDTH * (1 - zoom), 0);
    pan.y = constrain(pan.y + (ZOOM_STEP * HEIGHT) / 2.0, HEIGHT * (1 - zoom), 0);
  } else if (keyCode == UP) {
    pan.y = min(pan.y + PAN_STEP, 0);
  } else if (keyCode == DOWN) {
    pan.y = max(pan.y - PAN_STEP, HEIGHT * (1 - zoom));
  } else if (keyCode == LEFT) {
    pan.x = min(pan.x + PAN_STEP, 0);
  } else if (keyCode == RIGHT) {
    pan.x = max(pan.x - PAN_STEP, WIDTH * (1 - zoom));
  }
}
void keyReleased() {
  if (keyCode == ALT) {
    removeSelection = false;
  } else if (keyCode == SHIFT) {
    addSelection = false;
  }
}

boolean playOver() {
  return mouseX > 160 && mouseY > 0 && mouseX < 160 + textWidth("Play") + 10 && mouseY < 25;
}

boolean pauseOver() {
  return mouseX > 205 && mouseY > 0 && mouseX < 205 + textWidth("Pause") + 10 && mouseY < 25;
}

boolean saveOver() {
  return mouseX > 258 && mouseY > 0 && mouseX < 258 + textWidth("Save") + 10 && mouseY < 25;
}
