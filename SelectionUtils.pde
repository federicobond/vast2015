void handleSelection() {
  if (firstMouseX == -1) {
    // selection started outside map area
    return;
  }
  if (abs(firstMouseX - mouseX) < 2 || abs(firstMouseY - mouseY) < 2) {
    // selection too small, ignoring...
    return;
  }

  if (alted) {
    removeTracked();
    return;
  }

  if (!shifted) clearTracked();

  addTracked();
}

boolean insideSelection(PVector v) {
  // matrix holds the current transformation matrix
  PVector pos = new PVector();
  matrix.mult(v, pos);

  return pos.x > min(firstMouseX, mouseX) && pos.x < max(firstMouseX, mouseX)
      && pos.y > min(firstMouseY, mouseY) && pos.y < max(firstMouseY, mouseY);
}

void removeTracked() {
  Iterator<Integer> it = trackSet.iterator();
  while (it.hasNext()) {
    Tracker t = locations.get(it.next());
    if (insideSelection(t.pos)) {
      it.remove();
      t.setTracking(false);
    }
  }
  return;
}

void clearTracked() {
  // remove previous tracked items
  for (Integer id : trackSet) {
    Tracker t = locations.get(id);
    if (t != null) t.setTracking(false);
  }
  trackSet.clear();
  sidebar2.y = 0;
}

void addTracked() {
  for (Map.Entry e : locations.entrySet()) {
    int id = (Integer)e.getKey();
    Tracker t = (Tracker) e.getValue();
    if (insideSelection(t.pos)) {
      trackSet.add(id);
      t.setTracking(true);
    }
  }
}
