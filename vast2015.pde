import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.List;
import java.util.Arrays;
import java.util.Set;
import java.util.HashSet;
import java.util.Iterator;
import java.io.FileReader;
import java.io.BufferedReader;
import java.io.FileNotFoundException;
import java.awt.datatransfer.StringSelection;
import java.awt.datatransfer.Clipboard;
import java.awt.Toolkit;
import javax.swing.SwingUtilities;

// TODO:
// * Add ability to record events and alert of upcoming events
//   maybe draw a line between id and point
// * Save tracking data into file
// * Turn data files into "snapshots"
// * Select ids and compute statistics: how much time do they spend in the park? average distance travelled? how many rides? time moving vs time stopped, average messages sent
// * Save tracked ID groups, possibly assigning colors to them
// * Jump to specific point in time (j key -> open dialog)
// * Try to fast forward data if possible, to avoid reopening file
// * Save and load tracking groups from a file. Use categorical colors
// * Check to see if someone is spoofing his location in the message data. Regions are already defined
// * Map checkins against ride capacity (see method for determining ride capacity via selections)

// constants
final PImage MAP = loadImage("/Users/federicobond/Downloads/Auxiliary Files/Park Map.png");;
final PImage BG = loadImage("/Users/federicobond/bg.png");

final String LOCATION_DATA = "/Users/federicobond/Downloads/MC1 2015 Data/park-movement-%s.csv";
final String COMM_DATA = "/Users/federicobond/Downloads/MC2 2015 Data/comm-data-%s.csv";
final String DEFAULT_DAY = "Fri";

final String SAVEDATA_DIR = "/Users/federicobond/data";

final int WIDTH = 750;
final int HEIGHT = 744;
final int SIDEBAR = 265;

final float ZOOM_STEP = 0.1;
final float MAX_ZOOM = 3.0;
final float PAN_STEP = 15;
final int TIME_STEP = 5;

PFont fontBold, fontRegular;

// working data
ArrayList<Communication> comms = new ArrayList<Communication>();
PMatrix matrix;

volatile BufferedReader locReader;
volatile BufferedReader comReader;

volatile Map<Integer, Tracker> locations = new HashMap<Integer, Tracker>();
//volatile List<Integer> trackList = new ArrayList<Integer>(Arrays.asList(1116329, 1045021, 1749109, 918738, 1250941, 970490, 128533, 1508923, 839736, 1278894));
volatile Set<Integer> trackSet = new HashSet<Integer>();

{
  trackSet.addAll(Arrays.asList(1080969, 1629516, 1781070, 644885, 1935406, 521750, 1787551, 1600469));
}

volatile String line;
volatile String[] fields, comFields;
volatile String timestamp, newTimestamp, comTimestamp;

final List<DataFileItem> dataFilesList = new ArrayList<DataFileItem>();
final Sidebar sidebar = new MainSidebar(0, 0, SIDEBAR, HEIGHT);
final Sidebar sidebar2 = new ExtraSidebar(WIDTH + SIDEBAR, 0, SIDEBAR, HEIGHT);

// animation status
boolean paused = false;
boolean step = false;
boolean reloadDataFiles = false;

// position
float zoom = 1.0;
PVector pan = new PVector(0, 0);

// options
boolean showCommunications = true;
boolean dimUntracked = false;
boolean showTrails = false;

// selection status
boolean shifted, alted;

// drag vars
int firstMouseX, firstMouseY;

// data status
volatile boolean loading = false;

void setup() {
  fontBold = loadFont("Menlo.vlw");
  fontRegular = loadFont("Menlo-Regular.vlw");

  randomSeed(0); // make colors repeatable
  size(WIDTH + 2* SIDEBAR, HEIGHT);

  textFont(fontRegular);
  textSize(14);

  locReader = openData(locationData(DEFAULT_DAY));
  comReader = openData(commData(DEFAULT_DAY));

  fields = getData(locReader);
  timestamp = fields[0];

  comFields = getData(comReader);
  comTimestamp = comFields[0];

  Interactive.make(this);
  Interactive.add(sidebar);
  Interactive.add(sidebar2);

  updateDataFiles();
}

void updateData() {
  int timestep = (int) constrain(50.0 / frameRate, 3, 10);
  do {
    timestamp = fields[0];

    int id = Integer.parseInt(fields[1]);
    int x = Integer.parseInt(fields[3]);
    int y = Integer.parseInt(fields[4]);

    x = (int)map(x, 0.0, 100.0, 0.0, 750.0);
    y = (int)map(y, 0.0, 100.0, 744.0, 0.0);

    updateLocation(id, x, y);

    /*
    if (type.equals("check-in")) {
      handleCheckin(id, x, y);
    } else {
      handleCheckout(id, x, y);
    }
    */

    fields = getData(locReader);
    if (fields == null) {
      paused = true;
      return;
    }
    newTimestamp = fields[0];

    if (!timestamp.equals(newTimestamp)) {
      timestep--;
      if (timestamp.contains(":00:00")) {
        saveData();
      }
    }

  } while (timestep > 0);

  while (comTimestamp.compareTo(timestamp) < 1) {
    int to = comFields[2].equals("external") ? -1 : Integer.parseInt(comFields[2]);
    int from = Integer.parseInt(comFields[1]);

    Tracker tfrom = locations.get(from);
    Tracker tto = locations.get(to);

    if (tfrom != null && tto != null) {
      synchronized(comms) {
      comms.add(new Communication(tfrom, tto));
      }
    }

    comFields = getData(comReader);
    if (comFields == null) {
      return;
    }
    comTimestamp = comFields[0];
  }
}

void draw() {
  if (loading) {
    drawMessage("Loading...");
    return;
  }
  if (reloadDataFiles) {
    updateDataFiles();
    reloadDataFiles = false;
  }

  noStroke();
  image(MAP, SIDEBAR + pan.x, pan.y, WIDTH * zoom, HEIGHT * zoom);

  if (!paused || step) {
    updateData();
  }

  pushMatrix();
  translate(SIDEBAR + pan.x, pan.y);
  scale(zoom);

  // store the map transformation matrix for later
  matrix = getMatrix();

  drawCommunications();

  drawTrackers();
  popMatrix();

  drawSelection();

  pushMatrix();
  translate(SIDEBAR, 0);
  drawMapHUD();
  popMatrix();

  step = false;
}

void drawMessage(String message) {
  fill(100);
  rect(width / 2 - 102, height / 2 - 32, 204, 64, 5);
  fill(30);
  rect(width / 2 - 100, height / 2 - 30, 200, 60, 3);
  textAlign(CENTER);
  fill(200);
  text(message, width / 2, height / 2 + 5);
  textAlign(LEFT);
}

void drawMapHUD() {
  noStroke();
  fill(255);
  text(timestamp, 8, 18);
  text((int)frameRate + " fps", 8, HEIGHT - 10);

  if (mouseX > SIDEBAR && mouseX <= WIDTH + SIDEBAR && zoom == 1.0) {
    String label = (int)map(mouseX, SIDEBAR, WIDTH + SIDEBAR, 0, 100) + "," + (int)map(mouseY, 0, HEIGHT, 100, 0);

    fill(255);
    textAlign(RIGHT);
    text(label, WIDTH - 10, HEIGHT - 10);
    textAlign(LEFT);
  }
}

void drawCommunications() {
  Iterator<Communication> it = comms.iterator();
  synchronized(comms) {
  while (it.hasNext()) {
    Communication c = it.next();
    if (showCommunications) c.display();
    // do not consume life when paused
    if (!paused || step) {
      c.life--;
    }
    if (c.life == 0) {
      it.remove();
    }
  }
  }
}

void drawSelection() {
  if (!mousePressed || firstMouseX == -1) return;
  fill(0, 0, 150, 50);
  strokeWeight(1);
  stroke(255);

  int x = constrain(min(firstMouseX, mouseX), SIDEBAR, WIDTH + SIDEBAR);
  int y = constrain(min(firstMouseY, mouseY), 0, HEIGHT);
  int w = constrain(max(firstMouseX, mouseX), SIDEBAR, WIDTH + SIDEBAR) - x;
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
  if (mouseX > SIDEBAR && mouseX <= SIDEBAR + WIDTH) {
    clearTracked();
  }
}

void mousePressed() {
  if (mouseX < SIDEBAR || mouseX > SIDEBAR + WIDTH) {
    firstMouseX = firstMouseY = -1;
    return;
  }
  firstMouseX = mouseX;
  firstMouseY = mouseY;
}

void mouseReleased() {
  handleSelection();
}

void keyPressed() {
  if (key == 'p' || key == ' ') {
    paused = !paused;
  } else if (key == 'n') {
    step = true;
  } else if (key == 's') {
    saveData();
  } else if (key == 'm') {
    showCommunications = !showCommunications;
  } else if (key == 'd') {
    dimUntracked = !dimUntracked;
  } else if (key == 'c') {
    copyTrackedIds();
  } else if (key == 't') {
    showTrails = !showTrails;
  } else if (key == 'q') {
    // printQueues();
  } else if (keyCode == ALT) {
    alted = true;
  } else if (keyCode == SHIFT) {
    shifted = true;
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
    alted = false;
  } else if (keyCode == SHIFT) {
    shifted = false;
  }
}

void mouseWheel(MouseEvent event) {
  if (mouseX <= SIDEBAR) {
    float e = event.getCount();
    sidebar.y = constrain(sidebar.y - (int)e, -MAX_INT, 0);
  } else if (mouseX > WIDTH + SIDEBAR) {
    float e = event.getCount();
    sidebar2.y = constrain(sidebar2.y - (int)e, -MAX_INT, 0);
  }
}

void copyTrackedIds() {
  String copy = trackSet.toString();
  StringSelection selection = new StringSelection(copy.substring(1, copy.length() - 1));
  Clipboard clipboard = Toolkit.getDefaultToolkit().getSystemClipboard();
  clipboard.setContents(selection, null);
}
