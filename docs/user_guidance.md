# Occupancy Grid Map Editor - User Manual

Welcome to the **Occupancy Grid Map Editor**! This user manual is designed to guide absolute beginners through all the application's options, pages, panels, and tools. 

Whether you are editing an existing map offline or running a live SLAM (Simultaneous Localization and Mapping) session with a robot in ROS 2, this guide will show you how to navigate the interface, draw manual corrections, manage semantic layers, and place objects like gates.

---

## Table of Contents
1. [Understanding Occupancy Grid Maps](#1-understanding-occupancy-grid-maps)
2. [The Start Screen (App Entry)](#2-the-start-screen-app-entry)
3. [The Main Editor Layout](#3-the-main-editor-layout)
4. [The Interactive Map Canvas](#4-the-interactive-map-canvas)
5. [The System Status & Logs Panel](#5-the-system-status--logs-panel)
6. [Sidebar Control Tabs](#6-sidebar-control-tabs)
   - [Project Tab](#project-tab)
   - [Map Edit Tab](#map-edit-tab)
   - [Layers Tab](#layers-tab)
   - [Gates Tab](#gates-tab)
7. [Step-by-Step Workflows](#7-step-by-step-workflows)
   - [Workflow A: Doing Live SLAM Mapping](#workflow-a-doing-live-slam-mapping)
   - [Workflow B: Making Manual Corrections to the Base Map](#workflow-b-making-manual-corrections-to-the-base-map)
   - [Workflow C: Working with Custom Layers (Keepout Zones)](#workflow-c-working-with-custom-layers-keepout-zones)
   - [Workflow D: Placing and Configuring Gates (Annotation)](#workflow-d-placing-and-configuring-gates-annotation)

---

## 1. Understanding Occupancy Grid Maps

Before diving in, here are a few simple concepts about the maps you will be editing:
* **The Map Format**: Maps are stored as two files: a **PGM image** (the visual map) and a **YAML file** (metadata describing the resolution and starting point).
* **The Colors (Grayscale Semantics)**:
  * ⬛ **Obstacles (Black / Value 100)**: Walls, pillars, furniture, or any area the robot cannot cross.
  * ⬜ **Free Space (White / Value 0)**: Walkways, hallways, and open areas safe for navigation.
  * ░ **Unknown Space (Gray / Value -1 or 255)**: Unexplored areas where the robot has not scanned yet.
* **Resolution**: The size of each pixel in real-world meters (commonly `0.05` which means 5cm per pixel).
* **Origin**: The coordinates (in meters) of the bottom-left corner of the map relative to the robot's coordinate frame.

---

## 2. The Start Screen (App Entry)

When you first open the application, you will be presented with the **Start Screen**. Here, you choose the mode you want to run.

### Top Controls
* **⚙️ Gear Icon (Top-Right)**: Opens the **ROS & Topic Configuration** popup. 
  * If your robot topics are custom, click this to change:
    * *Map Topic* (default `/map`)
    * *Laser Scan Topic* (default `/scan`)
    * *TF Topic* (default `/tf`)
    * *Robot Base Frame* (default `base_link`)
    * *Initial Pose Topic* (default `/initialpose`)
    * *Initial Uncertainty*
    * *Use Simulation Time* (check this if you are running in a simulator like Gazebo).
    * *SLAM Toolbox Services* (Reset Map and Pause Mapping names/types).
  * **Reset to Default**: Click this button inside the popup to restore standard ROS settings.

### Operational Modes
At the top-center, toggle between the two main application modes:

#### A. SLAM Mode (Left Tab)
Use this if you are actively mapping a real environment using a moving robot.
* **Create New Project**: Type a **Project Name**, click **Start SLAM Mapping**, and select a folder on your computer. This creates a `.mepro` project file which will automatically save map updates as the robot explores.
* **Resume SLAM Session**: Click **Open .mepro Project** to resume an unfinished mapping session.

#### B. Map Edit Mode (Right Tab)
Use this if you have a pre-existing map on your computer and want to edit it offline.
* **Create New Project**:
  1. **Project Name**: Enter a name for your editing session.
  2. **Base Map (.pgm)**: Click **Browse** and select your `.pgm` map image.
  3. **Meta Data (.yaml)**: Click **Browse** and select your `.yaml` configuration file.
  4. **Map Resolution**: Automatically populated or editable (default `0.05`).
  5. Click **Create Project** and select a folder to save your project.
* **Open Existing Project**: Click **Open .mepro Project** to open a previously saved `.mepro` project.

---

## 3. The Main Editor Layout

Once your project loads, you enter the **Main Editor**. The screen is divided into two primary sections:

1. **The Sidebar (Left Panel)**: Houses your tools, configurations, and list items. It is divided into four tabs (**Project**, **Map Edit**, **Layers**, **Gates**).
2. **The Interactive Map Canvas (Right Panel)**: Displays your map, the robot, laser scans, coordinates, and allows you to zoom, pan, and draw.

### Bottom Sidebar Buttons
* **Exit (Red Button)**: Prompts you to exit the editor. Unsaved changes will be lost.
* **Save Project (Green Button)**: Saves all manual map edits, custom layers, gates, and updates the project configuration file.

### Log Floating Button
* **📋 Clipboard Icon (Bottom-Right)**: Located at the very bottom right of the screen. Clicking this toggles the **System Status & Logs Panel**.

---

## 4. The Interactive Map Canvas

The Map Canvas displays the map image and live robot coordinates. 

### Visual Overlay Controls (Floating on the Canvas)
* **Scale Indicator (Top-Left)**: A white ruler showing the scale of the map (e.g., `10 m` or `50 cm`). It updates automatically as you zoom.
* **Rotation Controls (Top-Right)**: 
  * `⟲` rotates the map 90 degrees counter-clockwise.
  * `⟳` rotates the map 90 degrees clockwise.
* **⛶ Fit Map Button (Top-Right)**: Instantly resets the view, centering the map and scaling it to fit the screen.
* **🔍 Focus Robot Button (Top-Right)**: Instantly centers the camera view on the robot's current position.
* **⚲ Follow Robot Toggle (Top-Right)**: If enabled (indicated by a blue highlighted background), the camera will automatically pan to keep the robot centered as it moves.
* **⚒️ Tool Icon Button (Top-Right)**: Toggles the visibility of the floating **NavToolsPanel** (details below).
* **Grid Coordinate Display (Bottom-Left)**: Shows the current position of your mouse pointer.
  * **PX**: X and Y coordinates in pixels.
  * **M**: X and Y coordinates in meters.

### Navigation Actions (How to move around)
* **To Pan (Move the map)**:
  * Hold the **Middle Mouse Button** (scroll wheel click) and drag the mouse.
  * *Alternative*: Hold the **Ctrl Key + Left Mouse Button** and drag.
  * *Alternative*: Click the **⚒️** tool icon, select **Enable Touch Pan** (highlighted blue), and drag with the **Left Mouse Button**.
* **To Zoom (In/Out)**:
  * Rotate your **Mouse Scroll Wheel**.
  * *Alternative*: Use the `+` and `-` buttons inside the **NavToolsPanel**.
  * *Alternative*: Use a pinch-to-zoom gesture on a trackpad.

### NavToolsPanel (Floating Panel)
* **Set Initial Pose / Cancel Selection**: Click this, then click on the map to publish the robot's starting coordinate (`/initialpose`) to ROS. Right-click or click cancel to abort.
* **Enable / Disable Touch Pan**: Toggle this to allow panning the map using a standard left-click drag.
* **`-` / `+`**: Zoom out / Zoom in buttons.

---

## 5. The System Status & Logs Panel

Toggle this panel by clicking the **📋** button in the bottom right corner of the window. It slides out from the right side.

* **Terminal Area**: Shows timestamps and colored messages from the application.
  * White/Grey: Standard information logs.
  * Green: Success events.
  * Yellow: Warning messages.
  * Red: Errors.
  * **Copy All**: Copies all terminal logs to your clipboard.
  * **Clear**: Clears the console window.
* **ROS Topics Status**: A quick health check of your robot topics.
  * **Map**, **Laser Scan**, and **TF** status are listed.
  * Flashing **🟢 ACTIVE** indicates topic messages are arriving successfully.
  * **🔴 INACTIVE** indicates no data is being received.

---

## 6. Sidebar Control Tabs

The sidebar on the left lets you control how you interact with the map. Click the tab headers at the top of the sidebar to switch modes:

---

### Project Tab
Displays basic info and settings.
* **Project Info**: View the active project name and the folder directory.
* **Operation Mode (Toggle)**:
  * **Mapping (SLAM)**: (Only selectable in SLAM mode). Indicates live mapping is active.
  * **Map Edit**: Click this to pause live mapping. 
    > [!WARNING]
    > Switching to Edit mode is permanent for the session. A confirmation popup will ask: *“Are you sure? Once you enter Editing mode, you cannot resume mapping.”* Click **Yes** to confirm.
* **SLAM Configuration (Collapsible)**: Click this header to view or edit the active ROS topics and service calls.
* **Checkboxes**:
  * **Auto-save changes (Every 60s)**: Automatically saves your progress.
  * **Show Robot Position**: Toggles the red robot marker arrow on the canvas.
  * **Show Laser Scan**: Toggles the green laser scans on the canvas.
  * **Editing Safety Lock (Red Text)**: If enabled, you cannot draw or edit while live mapping is running. This prevents you from corrupting map data as the robot writes to it. Disable this to allow concurrent editing.

---

### Map Edit Tab
Allows you to correct the base PGM map. Click one of these tools and draw directly on the canvas using your **Left Mouse Button**:
* **⬛ Obstacle**: Paint obstacles (black pixels). Useful for adding missing walls.
* **⬜ Free**: Paint free space (white pixels). Useful for erasing phantom obstacles (sensor noise).
* **░ Unknown**: Paint unknown areas (gray pixels).
* **▧ Revert**: Erase your manual edits and restore the original map pixels.
* **Brush Size Slider**: Drag to change the diameter of your circular paint brush (1 to 50 pixels).
* **Overlay Opacity Slider**: Controls the transparency of your manual edits overlay so you can compare your changes to the original map background.

---

### Layers Tab
Lets you create and edit custom semantic maps (e.g. keepout zones, speed limit zones) on separate layers.
* **Tools**:
  * **✏️ Pencil**: Freehand drawing on the active layer.
  * **⧹ Line**: Draw straight lines. Click once to start, move the mouse to preview, and release to place.
  * **⬡ Poly**: Draw custom polygons. Left-click to place vertices, and **Double-Click** to close the shape and fill it.
  * **▧ Eraser**: Erase drawings from the active layer.
* **Brush Size**: Slider to adjust tool thickness (1 to 50 px).
* **Draw Value**: Slider to adjust the grayscale density value (0 to 255) drawn on the layer.
* **Layers List (+ Button)**:
  * Click the blue **`+`** button next to the LAYERS header to create a new layer.
  * **Layer Items**:
    * **Highlight**: A blue outline indicates the active layer you are currently drawing on.
    * `👁`/`✖` **Visibility Toggle**: Click to show or hide the layer on the map canvas.
    * **Color Square**: Displays the unique color assigned to this layer.
    * **Name Field**: Click inside the text box to rename the layer (e.g., "Keepout Zone").
    * `🗑` **Delete**: Click the trash icon to delete the layer.
    * **OPACITY Slider**: Controls how transparent this layer is on the canvas.

---

### Gates Tab
Manage point-of-interest annotations such as standard gates, home bases, or charging stations.

* **Gate Categories**:
  * ⚲ **Gates** (Standard)
  * 🏠 **Home Gates**
  * ⚡ **Charge Stations**

To place a gate:
1. Locate the category you want and click its blue **`+`** button.
2. A dark overlay will cover the sidebar saying *"Click on the map to place the gate"* (Click the red **Cancel** button if you change your mind).
3. Move your mouse to the Map Canvas (the cursor changes to a crosshair `＋`).
4. Click on the map where the gate is located.
5. The **Add New Gate** dialog will pop up.
6. Complete the details in the dialog:
   * **Name \***: Enter a name (Required).
   * **Description**: Enter an optional description.
   * **Image**: Click the `...` button to pick a local image file associated with this gate (e.g., a photo of the gate).
7. Click **Confirm**. The gate will be created, given a unique ID (e.g., `10001`), and marked on the map with a circular icon.

#### Managing Placed Gates
Click on a gate row in the sidebar list to expand it and access:
* **Coordinates**: View and manually edit the **X (m)** and **Y (m)** coordinates in meters.
* **Description & Image**: Edit descriptions or update the image path using the `...` button.
* **Delete Button (Red)**: Deletes the gate from the list and map, and removes its copied image from your disk.

---

## 7. Step-by-Step Workflows

Here are simple walkthroughs of common tasks to help you get started:

### Workflow A: Doing Live SLAM Mapping
1. Launch the app and select **SLAM Mode**.
2. Click the ⚙️ Gear icon to confirm the robot topics match your system.
3. Type a project name, click **Start SLAM Mapping**, and select a folder.
4. Drive the robot around. You will see the map expanding and updating on the canvas.
5. Toggle **Follow Robot** on the top-right of the canvas if you want the camera to follow the robot automatically.
6. Once mapping is complete, go to the **Project Tab** in the sidebar.
7. Click **Map Edit** in the Operation Mode section.
8. Click **Yes** on the confirmation popup to pause mapping and freeze the map.
9. Click **Save Project** (Green button) at the bottom left.

---

### Workflow B: Making Manual Corrections to the Base Map
1. Open the project in **Map Edit Mode**.
2. Click the **Map Edit** tab in the sidebar.
3. Select the **⬜ Free** tool.
4. Adjust the **Brush Size** slider to your preferred size.
5. Hover over the canvas—a square brush outline will show you where you are drawing.
6. Click and hold the left mouse button to paint over sensor noise (phantom obstacles) to make those areas white (navigable).
7. Select the **⬛ Obstacle** tool to draw missing walls in black.
8. If you make a mistake, select **▧ Revert** and paint over the mistake to restore the original map pixel values.
9. Click the green **Save Project** button to save changes.

---

### Workflow C: Working with Custom Layers (Keepout Zones)
1. Open your project in **Map Edit Mode**.
2. Select the **Layers** tab in the sidebar.
3. Click the blue **`+`** button to create a new layer.
4. Rename it to "No-Go Zone" by typing in its text box.
5. Select the **⬡ Poly** (Polygon) tool.
6. Click points on the map canvas to outline a forbidden area. A colored line will outline your path.
7. **Double-click** to place the final vertex. The shape will close and automatically fill with the layer's color.
8. Adjust the layer's **OPACITY** slider to make it semi-transparent so you can see the background map.
9. If you need to hide the layer temporarily, toggle the `👁` eye icon in the layers list.
10. Click the green **Save Project** button.

---

### Workflow D: Placing and Configuring Gates (Annotation)
1. Open your project and select the **Gates** tab in the sidebar.
2. Under **Charge Stations**, click the **`+`** button.
3. Move your mouse to the canvas and left-click next to where the charging dock is located on the map.
4. In the popup dialog, type "Dock 1" in the **Name \*** field.
5. In the **Description** field, type "Primary charging dock near entrance".
6. Click the `...` button next to the Image field, select a photo of the charging dock, and click open.
7. Click **Confirm**. The charging station is now saved.
8. Click the green **Save Project** button.
