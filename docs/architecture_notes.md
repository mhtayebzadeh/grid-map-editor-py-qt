# Grid Map Editor Architecture Notes

## 1) Application Screens

- **StartScreen.qml**
  - Mode selection: `SLAM` vs `Edit Existing Map`.
  - Existing map inputs: `.yaml`, `.pgm`, resolution fallback.
  - **SLAM creation fields (required)**:
    - `robot position topic`
    - `map topic`
    - `mapping enabled parameter`
  - Output of StartScreen is a normalized startup config object passed to `MainEditor.qml`.

- **MainEditor.qml**
  - Main workspace host for tabs + map canvas.
  - Owns app-level state: active mode, active tab, layer model, active layer/tool, brush size, project path/id.

---

## 2) Main Editor Layout

- **SplitView**
  - Left: control panel (tabs).
  - Right: `MapCanvas.qml` (interactive map viewport).

- **Left panel tabs**
  1. **ProjectTab.qml**
     - Save project action.
     - Project mode/config and save metadata display.
  2. **MapEditTab.qml**
     - Base-map editing tools: `Obstacle`, `Free`, `Revert`, brush size.
  3. **LayersTab.qml**
     - Layer CRUD: add/rename/visibility/opacity.
     - Drawing tools: `Pencil`, `Line`, `Polygon`, `Eraser`.
  4. **GatesTab.qml**
     - Gate/category management and placement metadata.

---

## 3) Map Rendering + Layering Model

### 3.1 Canonical stack order

Rendering stack is always present (unless individually hidden by user visibility toggles):

1. `original_map` (from map provider)
2. `edit_layer` (map-edit strokes, same dimensions as map)
3. `merged_map` semantic result (`original_map + edit_layer`)
4. user layers (`keepout`, `speed`, `direction`, ...), each with color + opacity

> Important rule: switching tabs must **not** hide `edit_layer` or other layers.

### 3.2 Pixel and resolution contract

- `edit_layer` and all user layers must have:
  - exact same width/height as map
  - one logical cell per map pixel
  - no smoothing/antialiasing (`pixel-accurate`, hard edges)
- All drawing operations use integer map coordinates.

### 3.3 Canvas structure (per layer)

- Offscreen `dataCanvas` holds grayscale/semantic values.
- Visible `displayCanvas` tints by layer color and applies opacity.
- `edit_layer` follows same size/resolution contract, displayed in grayscale (black/white/gray semantics).

---

## 4) Interaction Model

- **Pan/zoom/rotate** are viewport-level interactions.
- **Mouse coordinate projection** always maps screen position into map pixel space.
- **Brush preview**:
  - square shape aligned to pixel grid
  - **in Layers tab, preview color = active layer color**
  - in map-edit mode, grayscale preview based on tool semantics

### 4.1 Layer drawing UX

- `Pencil`/`Eraser`: continuous stroke updates while dragging.
- `Line`:
  - first click sets start point
  - moving mouse shows live line preview
  - release commits line to layer
- `Polygon`:
  - clicks append vertices
  - live preview shows pending segment(s)
  - finalize action commits polygon fill/shape according to tool behavior

---

## 5) Save/Project Persistence Contract

### 5.1 Save action scope (ProjectTab Save button)

Single save action must persist **all project artifacts**:

- base map files (`.pgm` + `.yaml` as applicable)
- `edit_layer` artifact
- `merged_map` artifact
- all custom layers (one file per layer + metadata)
- gates/entities metadata (if present)
- `.mepro` project manifest

### 5.2 `.mepro` required metadata

`.mepro` should include at minimum:

- project id/name
- project directory paths
- map config (dimensions, resolution, origin, map files)
- layer list (id/name/type/color/opacity/visibility/file path)
- edit layer + merged map references
- last updated/save timestamps
  - e.g. `updatedAt`, `lastSavedAt` (ISO-8601)

---

## 6) Controllers and Responsibilities

- **map_provider.py**
  - load map, expose map image provider
  - persist merged/edit/layer outputs
  - guarantee output dimensions match map dimensions

- **project_manager.py**
  - own `.mepro` schema read/write
  - save/load full project state (including timestamps)

- **robot_handler.py**
  - robot pose stream and map coordinate transforms for robot marker/follow mode

---

## 7) Reliability Rules

- QML bindings must tolerate startup ordering (`null` guards for controllers/handlers).
- No UI overlay controls should be parented into transformed map-space containers.
- Drawing operations must avoid non-existent backend calls; command flow should be explicit QML signal -> layer/edit canvas update -> persistence stage.

---

## 8) Theme / UI tokens

- Main background: `#1a1e24`
- Side panel: `#1e2329`
- Canvas bg: `#323842`
- Accent blue: `#2e6bf0`
- Success green: `#22c55e` / `#1fbd58`
- Input/secondary bg: `#252b32` / `#2a3038`

Top-right canvas controls: rotate CCW/CW, fit map, focus robot, follow robot.
Bottom-left indicator: `PX: x,y` and `M: x,y`.
