boolean insideSelection(PVector v) {
  // matrix holds the current transformation matrix
  PVector pos = new PVector();
  matrix.mult(v, pos);

  return pos.x > min(firstMouseX, mouseX) && pos.x < max(firstMouseX, mouseX)
      && pos.y > min(firstMouseY, mouseY) && pos.y < max(firstMouseY, mouseY);
}

void removeTracked() {
  Iterator<Integer> it = trackList.iterator();
  while (it.hasNext()) {
    Tracker t = locations.get(it.next());
    if (insideSelection(t.pos)) {
      it.remove();
      t.tracking = false;
    }
  }
  return;
}

void clearTracked() {
  // remove previous tracked items
  for (Integer id : trackList) {
    Tracker t = locations.get(id);
    if (t != null) t.tracking = false;
  }
  trackList.clear();
}

void addTracked() {
  for (Map.Entry e : locations.entrySet()) {
    int id = (Integer)e.getKey();
    Tracker t = (Tracker) e.getValue();
    if (insideSelection(t.pos)) {
      trackList.add(id);
      t.tracking = true;
    }
  }
}
