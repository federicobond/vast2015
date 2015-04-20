void updateLocation(int id, int x, int y) {
  Tracker t = (Tracker)locations.get(id);
  if (t == null) {
    locations.put(id, new Tracker(id, new PVector(x, y)));
  } else {
    t.pos.set(x, y);
  }
}
