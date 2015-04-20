String SAVEDATA_DIR = "/Users/federicobond/data";
ArrayList<String> dataFiles = new ArrayList<String>();

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
    
  return line.split(",");
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
  saveJSONObject(obj, SAVEDATA_DIR + "/data-" + timestamp.replace(" ", "_") + ".json");
  updateDataFiles();
  println("Data snapshot saved");
}

void loadData(String file) {
  // load and update locations
  JSONObject obj = loadJSONObject(SAVEDATA_DIR + "/" + file);
  trackList.clear();
  locations.clear();
  comms.clear();

  JSONArray savedLocs = obj.getJSONArray("locations");
  int size = savedLocs.size();

  // reset the seed so we get the same colors
  // each time we load the file
  randomSeed(0); 
  for (int i = 0; i < size; i++) {
    JSONObject savedLoc = savedLocs.getJSONObject(i);
    updateLocation(savedLoc.getInt("id"), savedLoc.getInt("x"), savedLoc.getInt("y"));
  }

  // close current reader
  closeData(locReader);
  closeData(comReader);
  
  // open new reader and forward to saved timestamp
  locReader = openData(LOCATION_DATA);
  comReader = openData(COMM_DATA);

  String savedTimestamp = obj.getString("timestamp");
  do {
    fields = getData(locReader);
    timestamp = fields[0];
  } while (!timestamp.equals(savedTimestamp));
  
  do {
    comFields = getData(comReader);
    comTimestamp = comFields[0];
  } while (comTimestamp.compareTo(savedTimestamp) < 1);
  
  newTimestamp = timestamp;
  
  println("Data snapshot loaded");
}

ArrayList<DataFileItem> dataFilesList = new ArrayList<DataFileItem>();

void updateDataFiles() {
  File folder = new File(SAVEDATA_DIR);
  File[] listOfFiles = folder.listFiles();

  dataFiles.clear();
  for (int i = 0; i < listOfFiles.length; i++) {
    if (listOfFiles[i].isFile()) {
      dataFiles.add(listOfFiles[i].getName());
    }
  }

  for (int i = 0; i < dataFiles.size(); i++) {
    DataFileItem item = new DataFileItem(dataFiles.get(i), WIDTH, 40 + i * 26, 270, 25);
    item.init();
  }
}
