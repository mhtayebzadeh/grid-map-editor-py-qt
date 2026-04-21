# QML Architecture Plan (Based on app_details.md)

## 1. Screens
- **StartScreen.qml**: Initial launcher. Mode selection (SLAM vs Edit). File pickers for `.pgm` and `.yaml`. Resolution input.
- **MainEditor.qml**: The primary workspace loaded after StartScreen.

## 2. Main Editor Layout
- **SplitView**: To handle the resizable Left Panel and Map Canvas.
- **LeftPanel.qml**: Contains a `TabBar` and `StackLayout` or `SwipeView` for 4 tabs:
  1. `ProjectTab.qml`: Mode toggle, auto-save, save project.
  2. `MapEditTab.qml`: Brush tools (Obstacle, Free, Revert), Brush size.
  3. `LayersTab.qml`: Layer list (add/rename/vis/opacity), Drawing tools (Pencil, Line, Polygon, Eraser).
  4. `GatesTab.qml`: Categories (Gates, Home, Charge), List view of placed gates.
- **MapCanvas.qml**: Main interactive area. Needs to support Pan, Zoom, Rotate, Drawing overlays, and Gate icons.
- **GateEditDialog.qml**: Modal popup for editing ID, Name, Description, Image, Position.

## 3. Theming
- Dark mode by default (`Material.Dark` or custom palette).

### 4. UI Details Extract from Images
- **Colors**:
  - Main App Background: `#1a1e24`
  - Side Panel Background: `#1e2329`
  - Canvas Background: `#323842` (approximate)
  - Active Blue / Accents: `#2e6bf0`
  - Success Green (Save buttons): `#22c55e` or `#1fbd58`
  - Inactive Panel / Input Background: `#252b32` or `#2a3038`
- **Layout Split**: SplitView with a resizable Side Panel on the left (min ~250px) and a Map Canvas taking up the remaining space on the right.
- **Top Right Canvas Controls**: Rotate CCW, Rotate CW, Fit Map, Focus Robot, Follow Robot.
- **Bottom Right Canvas Indicator**: Coordinate display `PX: x, y | M: x, y`.
