void updateLocation(int id, int x, int y) {

  Tracker t = (Tracker)locations.get(id);
  if (t == null) {
    t = new Tracker(id, new PVector(x, y));
    locations.put(id, t);
  } else {
    t.setPos(x, y);
  }
}
