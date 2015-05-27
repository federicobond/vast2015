String locationData(String day) {
  return String.format(LOCATION_DATA, day);
}

String commData(String day) {
  return String.format(COMM_DATA, day);
}

String saveDataDir() {
  return sketchPath(SAVEDATA_DIR);
}

BufferedReader openData(String file) {
  BufferedReader reader = null;

  try {
    reader = new BufferedReader(new FileReader(new File(file)));
  } catch (FileNotFoundException ignore) {
    println("File not fonud: " + file);
    exit();
  }
  try {
    reader.readLine(); // skip headers
  } catch (IOException ignore) {
    println("Error reading file headers");
    exit();
  }
  return reader;
}

String[] getData(BufferedReader reader) {
  try {
    line = reader.readLine();
  } catch (IOException ignore) {
    println("Cannot read line");
    exit();
  }

  if (line != null) {
    return line.split(",");
  }
  return null;
}

void closeData(BufferedReader reader) {
  try {
    reader.close();
  } catch (IOException ignore) {}
}

void saveData() {
  JSONObject obj = new JSONObject();
  obj.setString("timestamp", timestamp);
  JSONArray locs = new JSONArray();
  for (Map.Entry e : locations.entrySet()) {
    Tracker t = (Tracker) e.getValue();
    JSONObject loc = new JSONObject();
    loc.setInt("id", (Integer)e.getKey());
    loc.setInt("x", (int)t.pos.x);
    loc.setInt("y", (int)t.pos.y);
    locs.append(loc);
  }
  obj.setJSONArray("locations", locs);
  saveJSONObject(obj, saveDataDir() + "/data-" + timestamp.replace(" ", "_") + ".json", "compact");
  updateDataFiles();
  println("Data snapshot saved");
}

volatile String saveFile;

void loadData(String _file) {
  loading = true;
  saveFile = _file;
  thread("_loadData");
}

void _seekDataPoint(String savedTimestamp) {
  String dayNumber = savedTimestamp.substring(7, 9);
  String day;

  if (dayNumber.equals("06")) day = "Fri";
  else if (dayNumber.equals("07")) day = "Sat";
  else if (dayNumber.equals("08")) day = "Sun";
  else throw new RuntimeException("unrecognized day");

  if (!timestamp.substring(7, 9).equals(dayNumber)
      || timestamp.compareTo(savedTimestamp) >= 0) {

    // close current reader
    closeData(locReader);
    closeData(comReader);

    // open new reader and forward to saved timestamp
    locReader = openData(locationData(day));
    comReader = openData(commData(day));
  }

  do {
    fields = getData(locReader);
    timestamp = fields[0];
  } while (timestamp.compareTo(savedTimestamp) < 1);

  do {
    comFields = getData(comReader);
    comTimestamp = comFields[0];
  } while (comTimestamp.compareTo(savedTimestamp) < 1);

  newTimestamp = timestamp;
}

void _loadData() {
  // load and update locations

  JSONObject obj = loadJSONObject(SAVEDATA_DIR + "/" + saveFile);

  JSONArray savedLocs = obj.getJSONArray("locations");
  int size = savedLocs.size();

  locations.clear();
  comms.clear();

  // reset the seed so we get the same colors
  // each time we load the file
  randomSeed(0); 

  for (int i = 0; i < size; i++) {
    JSONObject savedLoc = savedLocs.getJSONObject(i);
    updateLocation(savedLoc.getInt("id"), savedLoc.getInt("x"), savedLoc.getInt("y"));
  }

  _seekDataPoint(obj.getString("timestamp"));
  println("Data snapshot loaded");

  loading = false;
}

void updateDataFiles() {
  File folder = new File(saveDataDir());
  File[] listOfFiles = folder.listFiles();
  sidebar.removeAllItems();
  for (int i = 0; i < listOfFiles.length; i++) {
    if (listOfFiles[i].isFile()) {
      DataFileItem item = new DataFileItem(i, listOfFiles[i].getName());
      sidebar.addItem(item);
    }
  }
}

void deleteData(String filename) {
  new File(saveDataDir() + "/" + filename).delete();
}
