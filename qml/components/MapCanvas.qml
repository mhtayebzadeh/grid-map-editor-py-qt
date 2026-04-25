import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Shapes 1.15

Rectangle {
    id: mapCanvasRoot
    color: "#323842"

    signal doLayerDraw(string layerId, var points, real drawValue, string tool, real size)

    property int mapReloadTicker: 0
    property real currentScale: 1.0
    property real mapRotation: 0.0
    property bool isFollowingRobot: false

    property real mouseMapPxX: 0
    property real mouseMapPxY: 0
    property real mouseMapMeterX: 0
    property real mouseMapMeterY: 0

    property real scaleLineWidth: 100
    property string scaleLineText: "10 m"

    // Cursor overlay position (in viewport coordinates, unscaled)
    property real _cursorVpX: 0
    property real _cursorVpY: 0

    // Preview state for line / polygon rubber-band
    property real previewFromX: 0
    property real previewFromY: 0
    property real previewToX: 0
    property real previewToY: 0
    property bool showingPreview: false
    property var previewPolyPts: []
    property string editLayerPath: ""

    onEditLayerPathChanged: {
        if (editLayerPath && (mapController ? mapController.mapWidth : 0) > 0) {
            editCanvas.loadImage("file://" + editLayerPath);
        }
    }

    
    // Collect layer canvas data as base64 PNG strings
    function getLayerDataUrls() {
        let results = [];
        for (let i = 0; i < layerRepeater.count; i++) {
            let layerItem = layerRepeater.itemAt(i);
            if (!layerItem) continue;
            // Find the invisible dataCanvas among children
            let dataCanvas = null;
            for (let j = 0; j < layerItem.children.length; j++) {
                let child = layerItem.children[j];
                if (child.visible === false && child.canvasSize !== undefined) {
                    dataCanvas = child;
                    break;
                }
            }
            if (dataCanvas) {
                let b64 = dataCanvas.toDataURL("image/png");
                results.push({
                    b64: b64,
                    layerId: layersModel.get(i).layerId,
                    name: layersModel.get(i).name
                });
            }
        }
        return results;
    }

    function saveCanvasOverlay() {
        return editCanvas.toDataURL("image/png");
    }



    function updateScaleIndicator() {
        if (!(mapController ? mapController.resolution : 0)) return;
        let pxPerMeter = (1.0 / (mapController ? mapController.resolution : 0)) * currentScale;
        let units = [0.1, 0.5, 1, 2, 5, 10, 20, 50, 100, 500];
        let chosenUnit = 10;
        for (let i = 0; i < units.length; i++) {
            if (pxPerMeter * units[i] >= 40) {
                chosenUnit = units[i];
                break;
            }
        }
        scaleLineWidth = pxPerMeter * chosenUnit;
        scaleLineText = chosenUnit >= 1 ? chosenUnit + " m" : (chosenUnit * 100) + " cm";
    }

    onCurrentScaleChanged: updateScaleIndicator()

    Connections {
        target: mapController
        
        // Track old values for stability
        property real oldRes: 0
        property var oldOrigin: [0,0,0]
        property real oldHeight: 0
        property bool firstLoad: true

        function onMapLoaded() {
            let newRes = mapController.resolution;
            let newOrigin = mapController.origin;
            
            if (firstLoad) {
                mapReloadTicker++;
                fitMap();
                oldRes = newRes;
                oldOrigin = newOrigin;
                oldHeight = mapController.mapHeight;
                firstLoad = false;
            } else {
                let newHeight = mapController.mapHeight;
                
                // Reference point: the old origin in world coordinates
                // Its old pixel position was (0, oldHeight)
                let oldRefPxX = 0;
                let oldRefPxY = oldHeight;
                
                // Its new pixel position:
                let newRefPxX = (oldOrigin[0] - newOrigin[0]) / newRes;
                let newRefPxY = newHeight - (oldOrigin[1] - newOrigin[1]) / newRes;
                
                // Adjust scale if resolution changed
                let oldScale = currentScale;
                if (oldRes > 0 && newRes !== oldRes) {
                    currentScale = oldScale * (newRes / oldRes);
                }
                
                // Adjust pan to keep the reference point at the same screen position
                // ScreenPos = Pan + Px * Scale
                // NewPan = OldPan + OldPx * OldScale - NewPx * NewScale
                viewport.panX = viewport.panX + (oldRefPxX * oldScale) - (newRefPxX * currentScale);
                viewport.panY = viewport.panY + (oldRefPxY * oldScale) - (newRefPxY * currentScale);
                
                mapReloadTicker++;
                oldRes = newRes;
                oldOrigin = newOrigin;
                oldHeight = newHeight;
            }
            updateScaleIndicator();
            editCanvas.requestPaint();
        }
    }
    
    Connections {
        target: robotHandler
        function onPoseChanged() {
            if (mapCanvasRoot.isFollowingRobot) {
                mapCanvasRoot.focusRobot()
            }
        }
    }

    function isRotated() {
        return Math.abs(mapRotation % 180) === 90;
    }

    function fitMap() {
        if ((mapController ? mapController.mapWidth : 0) === 0) return;
        
        let rw = isRotated() ? (mapController ? mapController.mapHeight : 0) : (mapController ? mapController.mapWidth : 0);
        let rh = isRotated() ? (mapController ? mapController.mapWidth : 0) : (mapController ? mapController.mapHeight : 0);

        let scaleX = viewport.width / rw;
        let scaleY = viewport.height / rh;
        currentScale = Math.min(scaleX, scaleY) * 0.9;
        
        viewport.panX = (viewport.width - ((mapController ? mapController.mapWidth : 0) * currentScale)) / 2;
        viewport.panY = (viewport.height - ((mapController ? mapController.mapHeight : 0) * currentScale)) / 2;
    }

    function focusRobot() {
        if ((mapController ? mapController.mapWidth : 0) === 0) return;

        let pt = robotMarker.mapToItem(mapContainer, robotMarker.width/2, robotMarker.height/2);
        viewport.panX = viewport.width / 2 - pt.x * currentScale;
        viewport.panY = viewport.height / 2 - pt.y * currentScale;
    }

    Item {
        id: viewport
        anchors.fill: parent
        clip: true

        property real panX: 0
        property real panY: 0

        Item {
            id: mapContainer
            x: viewport.panX
            y: viewport.panY
            scale: currentScale
            transformOrigin: Item.TopLeft
            width: (mapController ? mapController.mapWidth : 0) > 0 ? (mapController ? mapController.mapWidth : 0) : 600
            height: (mapController ? mapController.mapHeight : 0) > 0 ? (mapController ? mapController.mapHeight : 0) : 400

            Item {
                id: mapSpace
                anchors.fill: parent
                rotation: mapRotation

                
                // The Base Map
                Image {
                    id: mapImage
                    anchors.fill: parent
                    source: "image://map_provider/map?id=" + mapCanvasRoot.mapReloadTicker
                    asynchronous: false
                    fillMode: Image.Stretch
                    smooth: false 
                    visible: (mapController ? mapController.mapWidth : 0) > 0
                }

                // Layer Canvases
                
                Canvas {
                    id: editCanvas
                    anchors.fill: parent
                    visible: (mapController ? mapController.mapWidth : 0) > 0 && (mapController ? mapController.mapHeight : 0) > 0
                    
                    
                    canvasSize: Qt.size((mapController ? mapController.mapWidth : 0), (mapController ? mapController.mapHeight : 0))
                    
                    renderTarget: Canvas.Image
                    antialiasing: false
                    smooth: false
                    
                    property var pendingDraws: []
                    
                    onPaint: {
                        var ctx = getContext("2d");
                        
                        // Process pending draws
                        for (var idx = 0; idx < pendingDraws.length; idx++) {
                            var draw = pendingDraws[idx];
                            var tool = draw.tool;
                            var size = draw.size;
                            var x1 = draw.x1, y1 = draw.y1, x2 = draw.x2, y2 = draw.y2;
                            
                            if (tool === "obstacle" || tool === "free" || tool === "revert") {
                                ctx.strokeStyle = (tool === "obstacle") ? "black" : (tool === "free") ? "white" : "rgba(0,0,0,0)";
                                if (tool === "revert") {
                                    ctx.globalCompositeOperation = "destination-out";
                                    ctx.strokeStyle = "black"; // alpha matters but dest-out ignores color
                                } else {
                                    ctx.globalCompositeOperation = "source-over";
                                }
                                
                                ctx.lineWidth = size;
                                ctx.lineCap = "square"; // Map editing uses square brush typically
                            
                                ctx.beginPath();
                                ctx.moveTo(x1, y1);
                                ctx.lineTo(x2, y2);
                                ctx.stroke();
                            }
                        }
                        pendingDraws = [];
                    }
                    
                    onImageLoaded: {
                        var ctx = getContext("2d");
                        ctx.drawImage("file://" + mapCanvasRoot.editLayerPath, 0, 0);
                        requestPaint();
                    }

                    onAvailableChanged: {
                        if (available && mapCanvasRoot.editLayerPath) {
                            loadImage("file://" + mapCanvasRoot.editLayerPath);
                        }
                    }

                    function queueDraw(tool, size, x1, y1, x2, y2) {
                        pendingDraws.push({tool: tool, size: size, x1: x1, y1: y1, x2: x2, y2: y2});
                        requestPaint();
                    }
                    
                    function clear() {
                        var ctx = getContext("2d");
                        ctx.clearRect(0, 0, width, height);
                        pendingDraws = [];
                    }
                }

                Repeater {
                    id: layerRepeater
                    model: layersModel
                    Item {
                        anchors.fill: parent
                        visible: model.layerVisible && (mapController ? mapController.mapWidth : 0) > 0
                        opacity: model.opacity

                        Image {
                            id: layerLoader
                            source: model.filePath ? "image://map_provider/layer?path=" + model.filePath : ""
                            visible: false
                            onStatusChanged: {
                                if (status === Image.Ready && dataCanvas.available) {
                                    var ctx = dataCanvas.getContext("2d");
                                    ctx.globalCompositeOperation = "copy";
                                    ctx.drawImage(layerLoader, 0, 0);
                                    ctx.globalCompositeOperation = "source-over";
                                    displayCanvas.requestPaint();
                                }
                            }
                        }

                        // Invisible Offscreen Canvas for pure grayscale values (for rendering out accurately)
                        Canvas {
                            id: dataCanvas
                            anchors.fill: parent
                            canvasSize: Qt.size((mapController ? mapController.mapWidth : 0), (mapController ? mapController.mapHeight : 0))
                            
                            renderTarget: Canvas.Image
                            antialiasing: false
                            smooth: false
                            visible: false
                            
                            onAvailableChanged: {
                                if (available) {
                                    var ctx = getContext("2d");
                                    ctx.fillStyle = "rgba(0,0,0,0)";
                                    ctx.fillRect(0, 0, width, height);
                                    
                                    if (layerLoader.status === Image.Ready) {
                                        ctx.globalCompositeOperation = "copy";
                                        ctx.drawImage(layerLoader, 0, 0);
                                        ctx.globalCompositeOperation = "source-over";
                                        displayCanvas.requestPaint();
                                    }
                                }
                            }
                        }

                        // Visible Display Canvas with color tint
                        Canvas {
                            id: displayCanvas
                            anchors.fill: parent
                            canvasSize: Qt.size((mapController ? mapController.mapWidth : 0), (mapController ? mapController.mapHeight : 0))
                            
                            renderTarget: Canvas.Image
                            antialiasing: false
                            smooth: false
                            
                            // Composite trick: Draw the data canvas, then source-in the color overlay
                            onPaint: {
                                var ctx = getContext("2d");
                                ctx.clearRect(0, 0, width, height);
                                ctx.save();
                                ctx.drawImage(dataCanvas, 0, 0);
                                ctx.globalCompositeOperation = "source-in";
                                ctx.fillStyle = model.colorStr || "green";
                                ctx.fillRect(0, 0, width, height);
                                ctx.restore();
                            }
                        }

                        Connections {
                            target: mapCanvasRoot
                            function onDoLayerDraw(layerId, points, drawValue, tool, size) {
                                console.log("onDoLayerDraw received! model.layerId:", model.layerId, "target:", layerId);
                                if (model.layerId !== layerId) return;
                                console.log("Matched layer! points:", JSON.stringify(points), "tool:", tool);
                                
                                var ctx = dataCanvas.getContext("2d");
                                ctx.imageSmoothingEnabled = false;
                                
                                let thickness = Math.max(1, Math.round(size));
                                
                                if (tool === "eraser") {
                                    ctx.globalCompositeOperation = "destination-out";
                                    ctx.fillStyle = "rgba(0,0,0,1)";
                                } else {
                                    ctx.globalCompositeOperation = "source-over";
                                    let gv = Math.round(drawValue);
                                    let alpha = (gv === 0) ? (50/255) : (gv/255); // Fake slight alpha for pure black (0) so it's not invisible, or just use RGB
                                    ctx.fillStyle = `rgba(${gv},${gv},${gv},1)`;
                                }

                                if (tool === "pencil" || tool === "line" || tool === "eraser") {
                                    // Plot exact map cells
                                    let x0 = Math.floor(points[0].x);
                                    let y0 = Math.floor(points[0].y);
                                    let x1 = Math.floor(points[1].x);
                                    let y1 = Math.floor(points[1].y);
                                    
                                    let dx = Math.abs(x1 - x0);
                                    let dy = Math.abs(y1 - y0);
                                    let sx = (x0 < x1) ? 1 : -1;
                                    let sy = (y0 < y1) ? 1 : -1;
                                    let err = dx - dy;
                                    let halfThin = Math.floor(thickness / 2);
                                    
                                    while(true) {
                                        ctx.fillRect(x0 - halfThin, y0 - halfThin, thickness, thickness);
                                        if (x0 === x1 && y0 === y1) break;
                                        let e2 = 2 * err;
                                        if (e2 > -dy) { err -= dy; x0 += sx; }
                                        if (e2 < dx) { err += dx; y0 += sy; }
                                    }
                                } else if (tool === "poly") {
                                    ctx.beginPath();
                                    ctx.moveTo(points[0].x, points[0].y);
                                    for(let i = 1; i < points.length; i++) {
                                        ctx.lineTo(points[i].x, points[i].y);
                                    }
                                    ctx.closePath();
                                    ctx.fill();
                                }
                                
                                dataCanvas.requestPaint();
                                displayCanvas.requestPaint();
                            }
                        }
                    }
                }

                // Preview Canvas: rubber-band line/polygon shown before the draw is committed
                Canvas {
                    id: previewCanvas
                    anchors.fill: parent
                    canvasSize: Qt.size((mapController ? mapController.mapWidth : 0) > 0 ? mapController.mapWidth : 600,
                                       (mapController ? mapController.mapHeight : 0) > 0 ? mapController.mapHeight : 400)
                    renderStrategy: Canvas.Cooperative
                    antialiasing: false
                    smooth: false
                    visible: mapCanvasRoot.showingPreview && mapController.mapWidth > 0
                    z: 50

                    onPaint: {
                        var ctx = getContext("2d");
                        ctx.clearRect(0, 0, width, height);
                        if (!mapCanvasRoot.showingPreview) return;

                        var color = root.activeLayerColor || "#ef4444";
                        var sz = Math.max(1, root.brushSize);

                        ctx.strokeStyle = color;
                        ctx.lineWidth = sz;

                        if (root.currentLayerTool === "line") {
                            ctx.beginPath();
                            ctx.moveTo(mapCanvasRoot.previewFromX, mapCanvasRoot.previewFromY);
                            ctx.lineTo(mapCanvasRoot.previewToX, mapCanvasRoot.previewToY);
                            ctx.stroke();
                        } else if (root.currentLayerTool === "poly") {
                            var pts = mapCanvasRoot.previewPolyPts;
                            if (pts.length > 0) {
                                ctx.beginPath();
                                ctx.moveTo(pts[0].x, pts[0].y);
                                for (var i = 1; i < pts.length; i++) {
                                    ctx.lineTo(pts[i].x, pts[i].y);
                                }
                                ctx.lineTo(mapCanvasRoot.previewToX, mapCanvasRoot.previewToY);
                                ctx.stroke();
                            }
                        }
                    }

                    // Re-paint whenever any preview state changes
                    Connections {
                        target: mapCanvasRoot
                        function onPreviewToXChanged() { previewCanvas.requestPaint(); }
                        function onPreviewToYChanged() { previewCanvas.requestPaint(); }
                        function onShowingPreviewChanged() { previewCanvas.requestPaint(); }
                        function onPreviewPolyPtsChanged() { previewCanvas.requestPaint(); }
                    }
                }


        
        
        
                Text {
                    anchors.centerIn: parent
                    text: "[No Map Loaded]"
                    color: "white"
                    visible: (mapController ? mapController.mapWidth : 0) === 0
                    rotation: -mapRotation
                }
                
                Item {
                    id: robotMarker
                    // Use a fixed size for the container to maintain high resolution
                    width: 24; height: 24
                    
                    property real _res: (mapController && mapController.resolution > 0) ? mapController.resolution : 0.05
                    property var _origin: (mapController && mapController.origin) ? mapController.origin : [0,0,0]
                    
                    // Position it using logical map coordinates
                    x: px - (width / 2)
                    y: py - (height / 2)
                    // Use scale to keep the marker visually the same size on screen while zooming
                    scale: 1.0 / currentScale
                    
                    property real px: (mapController ? mapController.mapWidth : 0) > 0 ? ((robotHandler ? robotHandler.x : 0) - _origin[0]) / _res : 0
                    property real py: (mapController ? mapController.mapHeight : 0) > 0 ? (mapController ? mapController.mapHeight : 0) - (((robotHandler ? robotHandler.y : 0) - _origin[1]) / _res) : 0

                    rotation: 90 - (robotHandler ? robotHandler.theta : 0) * (180 / Math.PI) + mapRotation
                    visible: ((mapController ? mapController.mapWidth : 0) > 0) && root.showRobot

                    // Laser Scan Canvas has been moved to viewport overlay

                    // Robot Marker (Arrow) - Now using a high-res Shape for crisp edges
                    Shape {
                        anchors.fill: parent
                        layer.enabled: true
                        layer.samples: 4
                        
                        ShapePath {
                            strokeColor: "white"
                            strokeWidth: 2
                            fillColor: "#ef4444"
                            startX: 12; startY: 0
                            PathLine { x: 24; y: 24 }
                            PathLine { x: 12; y: 18 }
                            PathLine { x: 0; y: 24 }
                            PathLine { x: 12; y: 0 }
                        }
                    }
                }

                Rectangle {
                    id: brushPreview
                    property real logicalSize: Math.max(1, Math.round(root.brushSize))
                    width: logicalSize
                    height: logicalSize
                    radius: 0
                    color: {
                        if (root.activeMode === "layers" && root.currentLayerTool !== "eraser") {
                            return root.activeLayerColor || "#ef4444"
                        }
                        return (root.currentMapEditTool === "obstacle" || root.currentLayerTool === "eraser") ? "black" : 
                               (root.currentMapEditTool === "free") ? "white" : "#3b82f6"
                    }
                    border.color: {
                        if (root.activeMode === "layers" && root.currentLayerTool !== "eraser") {
                            return root.activeLayerColor || "#ef4444"
                        }
                        return "#3b82f6"
                    }
                    opacity: 0.5
                    border.width: 2 / currentScale
                    visible: panZoomArea.containsMouse && (mapController ? mapController.mapWidth : 0) > 0 && !panZoomArea.pressed && (root.activeMode === "map-edit" || root.activeMode === "layers")
                    // Note editCanvas.previewX doesn't exist anymore, so we just use mouseMapPxX
                    x: Math.floor(mouseMapPxX) - Math.floor(logicalSize / 2)
                    y: Math.floor(mouseMapPxY) - Math.floor(logicalSize / 2)
                    z: 999
                }

                // Render Gates
                Repeater {
                    model: root.gateCategories
                    Item {
                        anchors.fill: parent
                        property string catIcon: modelData.icon
                        
                        Repeater {
                            model: modelData.model
                            Item {
                                property real px: (mapController ? mapController.mapWidth : 0) > 0 && (mapController ? mapController.resolution : 0) > 0 ? (model.xPos - (mapController ? mapController.origin : [0,0,0])[0]) / (mapController ? mapController.resolution : 0) : 0
                                property real py: (mapController ? mapController.mapHeight : 0) > 0 && (mapController ? mapController.resolution : 0) > 0 ? (mapController ? mapController.mapHeight : 0) - ((model.yPos - (mapController ? mapController.origin : [0,0,0])[1]) / (mapController ? mapController.resolution : 0)) : 0
                                
                                x: px - (width / 2)
                                y: py - (height / 2)
                                width: 24
                                height: 24
                                scale: 1.0 / currentScale
                                rotation: -mapRotation
                                z: 200
                                
                                Rectangle {
                                    anchors.fill: parent
                                    color: root.activeGateId === model.gateId ? "#ef4444" : "#2563eb"
                                    radius: 12
                                    border.color: "white"
                                    border.width: 2
                                    
                                    // Make the icon slightly bigger if selected
                                    scale: root.activeGateId === model.gateId ? 1.2 : 1.0
                                    Behavior on scale { NumberAnimation { duration: 150 } }
                                    Behavior on color { ColorAnimation { duration: 150 } }

                                    Text {
                                        anchors.centerIn: parent
                                        text: catIcon
                                        color: "white"
                                        font.pixelSize: 12
                                    }
                                }
                            }
                        }
                    }
                }
        
        } // mapSpace
        } // mapContainer

        // Laser Canvas OVERLAY in viewport coordinates (crisp resolution, native zooming)
        Canvas {
            id: laserCanvas
            anchors.fill: parent
            z: 90
            visible: ((mapController ? mapController.mapWidth : 0) > 0) && root.showLaserScan

            Connections {
                target: robotHandler
                function onScanChanged() { laserCanvas.requestPaint() }
                function onPoseChanged() { laserCanvas.requestPaint() }
            }
            
            Connections {
                target: mapCanvasRoot
                function onCurrentScaleChanged() { laserCanvas.requestPaint() }
                function onMapRotationChanged() { laserCanvas.requestPaint() }
            }
            
            Connections {
                target: viewport
                function onPanXChanged() { laserCanvas.requestPaint() }
                function onPanYChanged() { laserCanvas.requestPaint() }
            }

            onPaint: {
                var ctx = getContext("2d");
                ctx.clearRect(0, 0, width, height);
                let scan = robotHandler ? robotHandler.scanData : null;
                if (!scan || scan.length === 0) return;
                
                let res = mapController ? mapController.resolution : 0.05;
                if (res <= 0) return;
                
                // Get robot pos in viewport
                let robotPos = robotMarker.mapToItem(viewport, robotMarker.width/2, robotMarker.height/2);
                let cx = robotPos.x;
                let cy = robotPos.y;
                
                ctx.beginPath();
                ctx.strokeStyle = "rgba(0, 255, 128, 0.6)";
                ctx.lineWidth = 2;
                
                let step = robotHandler ? robotHandler.scanAngleIncrement : (Math.PI * 2 / 360);
                let angle_min = robotHandler ? robotHandler.scanAngleMin : -Math.PI;
                let first = true;
                
                // Calculate the global rotation angle for the rays
                // In JS Canvas: 0 is Right, positive is Clockwise.
                // In ROS: 0 is Right, positive is Counter-Clockwise.
                // mapRotation is clockwise.
                let robotTheta = robotHandler ? robotHandler.theta : 0;
                let mapRotRad = (mapRotation * Math.PI / 180);
                
                for (let i = 0; i < scan.length; i++) {
                    let dist = scan[i];
                    if (dist <= 0.1 || dist > 30.0) continue; 
                    
                    // Angle of the ray relative to the map (in JS Canvas coordinates)
                    let globalAngle = -(robotTheta + angle_min + i * step) + mapRotRad;
                    
                    let distPx = (dist / res) * currentScale;
                    
                    let lx = cx + distPx * Math.cos(globalAngle);
                    let ly = cy + distPx * Math.sin(globalAngle);
                    
                    if (first) { ctx.moveTo(lx, ly); first = false; }
                    else ctx.lineTo(lx, ly);
                }
                ctx.stroke();

                ctx.fillStyle = "#00ff80";
                for (let i = 0; i < scan.length; i += 2) { 
                    let dist = scan[i];
                    if (dist <= 0.1 || dist > 30.0) continue;
                    
                    // Angle of the ray relative to the map (in JS Canvas coordinates)
                    let globalAngle = -(robotTheta + angle_min + i * step) + mapRotRad;
                    
                    let distPx = (dist / res) * currentScale;
                    
                    let lx = cx + distPx * Math.cos(globalAngle);
                    let ly = cy + distPx * Math.sin(globalAngle);
                    
                    ctx.beginPath();
                    ctx.arc(lx, ly, 2, 0, Math.PI * 2);
                    ctx.fill();
                }
            }
        }

        MouseArea {
            id: panZoomArea
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.MiddleButton
            hoverEnabled: true
            
            property real lastPanX: 0
            property real lastPanY: 0
            property bool isDrawing: false
            property var lastDrawPt: null
            property var polyPts: []
            
            onPressed: (mouse) => {
                if (mouse.button === Qt.MiddleButton || (mouse.button === Qt.LeftButton && (mouse.modifiers & Qt.ControlModifier))) {
                    isFollowingRobot = false
                    lastPanX = mouse.x
                    lastPanY = mouse.y
                } else if (mouse.button === Qt.LeftButton && (mapController ? mapController.mapWidth : 0) > 0) {
                    let pt_raw = panZoomArea.mapToItem(mapSpace, mouse.x, mouse.y)
                    let pt = Qt.point(Math.floor(pt_raw.x), Math.floor(pt_raw.y))
                    
                    if (root.pendingGateModel !== null) {
                        if ((mapController ? mapController.resolution : 0) > 0) {
                            let mapX = (mapController ? mapController.origin : [0,0,0])[0] + pt.x * (mapController ? mapController.resolution : 0);
                            let mapY = (mapController ? mapController.origin : [0,0,0])[1] + ((mapController ? mapController.mapHeight : 0) - pt.y) * (mapController ? mapController.resolution : 0);
                            root.openAddGateDialog(mapX, mapY);
                        }
                        return;
                    }
                    
                    if (root.activeMode === "layers" && root.activeLayerId !== "") {
                        if (root.currentLayerTool === "pencil" || root.currentLayerTool === "eraser") {
                            isDrawing = true
                            lastDrawPt = pt
                            mapCanvasRoot.doLayerDraw(root.activeLayerId, [lastDrawPt, pt], root.layerDrawValue, root.currentLayerTool, root.brushSize)
                        } else if (root.currentLayerTool === "line") {
                            isDrawing = true
                            lastDrawPt = pt // start point
                            mapCanvasRoot.previewFromX = pt.x
                            mapCanvasRoot.previewFromY = pt.y
                            mapCanvasRoot.previewToX = pt.x
                            mapCanvasRoot.previewToY = pt.y
                            mapCanvasRoot.showingPreview = true
                        } else if (root.currentLayerTool === "poly") {
                            polyPts.push(pt)
                            mapCanvasRoot.previewPolyPts = polyPts
                            mapCanvasRoot.previewToX = pt.x
                            mapCanvasRoot.previewToY = pt.y
                            mapCanvasRoot.showingPreview = true
                        }
                    } else if (root.activeMode === "map-edit") {
                        if (root.currentMapEditTool === "obstacle" || root.currentMapEditTool === "free" || root.currentMapEditTool === "revert") {
                            isDrawing = true
                            lastDrawPt = pt
                            editCanvas.queueDraw(root.currentMapEditTool, root.brushSize, lastDrawPt.x, lastDrawPt.y, pt.x, pt.y)
                        }
                    }
                }
            }
            
            onReleased: (mouse) => {
                if (mouse.button === Qt.LeftButton && isDrawing) {
                    let pt_raw = panZoomArea.mapToItem(mapSpace, mouse.x, mouse.y)
                    let pt = Qt.point(Math.floor(pt_raw.x), Math.floor(pt_raw.y))
                    if (root.activeMode === "layers" && root.currentLayerTool === "line") {
                        mapCanvasRoot.doLayerDraw(root.activeLayerId, [lastDrawPt, pt], root.layerDrawValue, root.currentLayerTool, root.brushSize)
                        mapCanvasRoot.showingPreview = false
                    }
                    isDrawing = false
                }
            }

            onDoubleClicked: (mouse) => {
                if (mouse.button === Qt.LeftButton && root.activeMode === "layers" && root.currentLayerTool === "poly") {
                    if (polyPts.length > 2) {
                        mapCanvasRoot.doLayerDraw(root.activeLayerId, polyPts, root.layerDrawValue, "poly", root.brushSize)
                    }
                    polyPts = []
                    mapCanvasRoot.previewPolyPts = []
                    mapCanvasRoot.showingPreview = false
                }
            }

            onPositionChanged: (mouse) => {
                if (pressedButtons & Qt.MiddleButton || (pressedButtons & Qt.LeftButton && (mouse.modifiers & Qt.ControlModifier))) {
                    viewport.panX += (mouse.x - lastPanX)
                    viewport.panY += (mouse.y - lastPanY)
                    lastPanX = mouse.x
                    lastPanY = mouse.y
                } else if (isDrawing && (mapController ? mapController.mapWidth : 0) > 0) {
                    let pt_raw = panZoomArea.mapToItem(mapSpace, mouse.x, mouse.y)
                    let pt = Qt.point(Math.floor(pt_raw.x), Math.floor(pt_raw.y))
                    if (root.activeMode === "layers" && root.activeLayerId !== "" && (root.currentLayerTool === "pencil" || root.currentLayerTool === "eraser")) {
                        mapCanvasRoot.doLayerDraw(root.activeLayerId, [lastDrawPt, pt], root.layerDrawValue, root.currentLayerTool, root.brushSize)
                        lastDrawPt = pt
                    } else if (root.activeMode === "layers" && root.currentLayerTool === "line") {
                        mapCanvasRoot.previewToX = pt.x
                        mapCanvasRoot.previewToY = pt.y
                    } else if (root.activeMode === "map-edit" && (root.currentMapEditTool === "obstacle" || root.currentMapEditTool === "free" || root.currentMapEditTool === "revert")) {
                        editCanvas.queueDraw(root.currentMapEditTool, root.brushSize, lastDrawPt.x, lastDrawPt.y, pt.x, pt.y)
                        lastDrawPt = pt
                    }
                }

                let pt_raw = panZoomArea.mapToItem(mapSpace, mouse.x, mouse.y)
                let pt = Qt.point(Math.floor(pt_raw.x), Math.floor(pt_raw.y))
                
                if (root.activeMode === "layers" && root.currentLayerTool === "poly" && polyPts.length > 0) {
                    mapCanvasRoot.previewToX = pt.x
                    mapCanvasRoot.previewToY = pt.y
                }
                
                mouseMapPxX = pt.x
                mouseMapPxY = pt.y
                
                if ((mapController ? mapController.resolution : 0) > 0) {
                    let _m_res = mapController.resolution
                    let _m_org = mapController.origin || [0,0,0]
                    mouseMapMeterX = _m_org[0] + pt.x * _m_res
                    mouseMapMeterY = _m_org[1] + ((mapController.mapHeight) - pt.y) * _m_res
                }

                // Track cursor position in viewport space for the colored cursor overlay
                let vpPt = panZoomArea.mapToItem(viewport, mouse.x, mouse.y)
                mapCanvasRoot._cursorVpX = vpPt.x
                mapCanvasRoot._cursorVpY = vpPt.y
            }
            
            onWheel: (wheel) => {
                let zoomRatio = wheel.angleDelta.y > 0 ? 1.1 : 1 / 1.1;
                let newScale = currentScale * zoomRatio
                if(newScale > 0.05 && newScale < 50.0) {
                    let relX = wheel.x - viewport.panX
                    let relY = wheel.y - viewport.panY

                    viewport.panX = wheel.x - relX * zoomRatio
                    viewport.panY = wheel.y - relY * zoomRatio
                    currentScale = newScale
                }
            }
            cursorShape: {
                if (root.pendingGateModel !== null) return Qt.CrossCursor;
                if (isDrawing) return Qt.CrossCursor;
                if (panZoomArea.pressedButtons & Qt.MiddleButton || (panZoomArea.pressedButtons & Qt.LeftButton && (Qt.keyboardModifiers & Qt.ControlModifier))) return Qt.SizeAllCursor;
                return Qt.ArrowCursor;
            }
        }
    } // viewport


    Rectangle {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.margins: 16
        width: scaleLineWidth + 20
        height: 40
        color: "#cc1e2329"
        radius: 4
        
        ColumnLayout {
            anchors.centerIn: parent
            spacing: 2
            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                Rectangle { width: 1; height: 6; color: "white" }
                Rectangle { Layout.preferredWidth: scaleLineWidth; height: 2; color: "white" }
                Rectangle { width: 1; height: 6; color: "white" }
            }
            Text { text: scaleLineText; color: "white"; font.pixelSize: 12; Layout.alignment: Qt.AlignHCenter }
        }
    }

    ColumnLayout {
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: 16
        spacing: 8

        RowLayout {
            Layout.alignment: Qt.AlignRight
            spacing: 8
            Rectangle { 
                width: 36; height: 36; color: "#cc1e2329"; radius: 4; 
                Text { anchors.centerIn: parent; text: "⟲"; color: "white" }
                MouseArea { 
                    anchors.fill: parent; 
                    cursorShape: Qt.PointingHandCursor
                    onClicked: { 
                        mapRotation = (mapRotation - 90) % 360; 
                        if (isFollowingRobot) focusRobot(); else fitMap();
                    }
                }
            }
            Rectangle { 
                width: 36; height: 36; color: "#cc1e2329"; radius: 4; 
                Text { anchors.centerIn: parent; text: "⟳"; color: "white" } 
                MouseArea { 
                    anchors.fill: parent; 
                    cursorShape: Qt.PointingHandCursor
                    onClicked: { 
                        mapRotation = (mapRotation + 90) % 360; 
                        if (isFollowingRobot) focusRobot(); else fitMap();
                    }
                }
            }
        }
        Rectangle { 
            width: 100; height: 36; color: "#cc1e2329"; radius: 4; Layout.alignment: Qt.AlignRight; 
            Text { anchors.centerIn: parent; text: "⛶ Fit Map"; color: "white" }
            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: mapCanvasRoot.fitMap() }
        }
        Rectangle { 
            width: 120; height: 36; color: "#cc1e2329"; radius: 4; Layout.alignment: Qt.AlignRight; 
            Text { anchors.centerIn: parent; text: "🔍 Focus Robot"; color: "white" }
            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: mapCanvasRoot.focusRobot() }
        }
        Rectangle { 
            width: 120; height: 36; color: isFollowingRobot ? "#2e4a66" : "#cc1e2329"; radius: 4; Layout.alignment: Qt.AlignRight; 
            Text { anchors.centerIn: parent; text: "⚲ Follow Robot"; color: "white" } 
            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { isFollowingRobot = !isFollowingRobot; if (isFollowingRobot) focusRobot(); } }
        }
    }

    Rectangle {
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.margins: 16
        width: 160
        height: 50
        color: "#cc1e2329"
        radius: 4
        
        ColumnLayout {
            anchors.centerIn: parent
            spacing: 2
            Text { text: "PX: " + Math.round(mouseMapPxX) + ", " + Math.round(mouseMapPxY); color: "white"; font.pixelSize: 12; font.family: "monospace" }
            Text { text: "M: " + mouseMapMeterX.toFixed(2) + ", " + mouseMapMeterY.toFixed(2); color: "white"; font.pixelSize: 12; font.family: "monospace" }
        }
    }
}
