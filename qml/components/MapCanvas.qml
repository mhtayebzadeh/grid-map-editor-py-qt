import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: mapCanvasRoot
    color: "#323842"

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
        return ""; // Fallback disabled to prevent errors, since we use layers now
    }


    function updateScaleIndicator() {
        if (!mapController.resolution) return;
        let pxPerMeter = (1.0 / mapController.resolution) * currentScale;
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
        function onMapLoaded() {
            mapReloadTicker++
            fitMap()
            updateScaleIndicator()
            editCanvas.requestPaint()
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
        if (mapController.mapWidth === 0) return;
        
        let rw = isRotated() ? mapController.mapHeight : mapController.mapWidth;
        let rh = isRotated() ? mapController.mapWidth : mapController.mapHeight;

        let scaleX = viewport.width / rw;
        let scaleY = viewport.height / rh;
        currentScale = Math.min(scaleX, scaleY) * 0.9;
        
        viewport.panX = (viewport.width - (mapController.mapWidth * currentScale)) / 2;
        viewport.panY = (viewport.height - (mapController.mapHeight * currentScale)) / 2;
    }

    function focusRobot() {
        if (mapController.mapWidth === 0) return;

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
            width: mapController.mapWidth > 0 ? mapController.mapWidth : 600
            height: mapController.mapHeight > 0 ? mapController.mapHeight : 400

            Item {
                id: mapSpace
                width: parent.width
                height: parent.height
                anchors.centerIn: parent
                rotation: mapRotation

                
                // The Base Map
                Image {
                    id: mapImage
                    anchors.fill: parent
                    source: "image://map_provider/map?id=" + mapCanvasRoot.mapReloadTicker
                    asynchronous: false
                    fillMode: Image.PreserveAspectFit
                    smooth: false 
                    visible: mapController.mapWidth > 0
                }

                // Layer Canvases
                Repeater {
                    id: layerRepeater
                    model: layersModel
                    Item {
                        anchors.fill: parent
                        visible: model.layerVisible && mapController.mapWidth > 0
                        opacity: model.opacity

                        // Invisible Offscreen Canvas for pure grayscale values (for rendering out accurately)
                        Canvas {
                            id: dataCanvas
                            anchors.fill: parent
                            canvasSize: Qt.size(mapController.mapWidth, mapController.mapHeight)
                            renderStrategy: Canvas.Threaded
                            renderTarget: Canvas.Image
                            antialiasing: false
                            smooth: false
                            visible: false

                            onAvailableChanged: {
                                if (available) {
                                    var ctx = getContext("2d");
                                    ctx.fillStyle = "rgba(0,0,0,0)";
                                    ctx.fillRect(0, 0, width, height);
                                }
                            }
                        }

                        // Visible Display Canvas with color tint
                        Canvas {
                            id: displayCanvas
                            anchors.fill: parent
                            canvasSize: Qt.size(mapController.mapWidth, mapController.mapHeight)
                            renderStrategy: Canvas.Threaded
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
                            target: root
                            function onDoLayerDraw(layerId, points, drawValue, tool, size) {
                                if (model.layerId !== layerId) return;
                                
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
                    canvasSize: Qt.size(mapController.mapWidth > 0 ? mapController.mapWidth : 600,
                                       mapController.mapHeight > 0 ? mapController.mapHeight : 400)
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
                        ctx.setLineDash([Math.max(4, sz * 2), Math.max(4, sz * 2)]);

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
                } else if (mouse.button === Qt.LeftButton && root.activeMode === "layers" && mapController.mapWidth > 0 && root.activeLayerId !== "") {
                    // Start Layer draw
                    let pt = panZoomArea.mapToItem(mapSpace, mouse.x, mouse.y)
                    
                    if (root.currentLayerTool === "pencil" || root.currentLayerTool === "eraser") {
                        isDrawing = true
                        lastDrawPt = pt
                        root.doLayerDraw(root.activeLayerId, [lastDrawPt, pt], root.layerDrawValue, root.currentLayerTool, root.brushSize)
                    } else if (root.currentLayerTool === "line") {
                        isDrawing = true
                        lastDrawPt = pt // start point
                        // Begin preview
                        mapCanvasRoot.previewFromX = pt.x
                        mapCanvasRoot.previewFromY = pt.y
                        mapCanvasRoot.previewToX = pt.x
                        mapCanvasRoot.previewToY = pt.y
                        mapCanvasRoot.showingPreview = true
                    } else if (root.currentLayerTool === "poly") {
                        polyPts.push(pt)
                        mapCanvasRoot.previewPolyPts = polyPts.slice()
                        // Start preview at first point
                        if (polyPts.length === 1) {
                            mapCanvasRoot.previewFromX = pt.x
                            mapCanvasRoot.previewFromY = pt.y
                            mapCanvasRoot.previewToX = pt.x
                            mapCanvasRoot.previewToY = pt.y
                            mapCanvasRoot.showingPreview = true
                        }
                    }
                }
            }
            
            onReleased: (mouse) => {
                if (mouse.button === Qt.LeftButton && isDrawing && root.activeMode === "layers") {
                    let pt = panZoomArea.mapToItem(mapSpace, mouse.x, mouse.y)
                    if (root.currentLayerTool === "line") {
                        root.doLayerDraw(root.activeLayerId, [lastDrawPt, pt], root.layerDrawValue, root.currentLayerTool, root.brushSize)
                        // Clear preview
                        mapCanvasRoot.showingPreview = false
                    }
                    isDrawing = false
                }
            }

            onDoubleClicked: (mouse) => {
                if (mouse.button === Qt.LeftButton && root.activeMode === "layers" && root.currentLayerTool === "poly") {
                    if (polyPts.length > 2) {
                        root.doLayerDraw(root.activeLayerId, polyPts, root.layerDrawValue, "poly", root.brushSize)
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
                } else if (isDrawing && root.activeMode === "layers" && mapController.mapWidth > 0 && (root.currentLayerTool === "pencil" || root.currentLayerTool === "eraser")) {
                    let pt = panZoomArea.mapToItem(mapSpace, mouse.x, mouse.y)
                    root.doLayerDraw(root.activeLayerId, [lastDrawPt, pt], root.layerDrawValue, root.currentLayerTool, root.brushSize)
                    lastDrawPt = pt
                }

                // Update rubber-band preview endpoint
                if (root.activeMode === "layers") {
                    let msPt = panZoomArea.mapToItem(mapSpace, mouse.x, mouse.y)
                    if ((root.currentLayerTool === "line" && isDrawing) ||
                        (root.currentLayerTool === "poly" && polyPts.length > 0)) {
                        mapCanvasRoot.previewToX = msPt.x
                        mapCanvasRoot.previewToY = msPt.y
                        if (!mapCanvasRoot.showingPreview)
                            mapCanvasRoot.showingPreview = true
                    }
                }

                let pt = panZoomArea.mapToItem(mapSpace, mouse.x, mouse.y)
                mouseMapPxX = pt.x
                mouseMapPxY = pt.y
                
                if (mapController.resolution > 0) {
                    mouseMapMeterX = mapController.origin[0] + pt.x * mapController.resolution
                    mouseMapMeterY = mapController.origin[1] + (mapController.mapHeight - pt.y) * mapController.resolution
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
        }
    }



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
            MouseArea { anchors.fill: parent; onClicked: mapCanvasRoot.fitMap() }
        }
        Rectangle { 
            width: 120; height: 36; color: "#cc1e2329"; radius: 4; Layout.alignment: Qt.AlignRight; 
            Text { anchors.centerIn: parent; text: "⌖ Focus Robot"; color: "white" }
            MouseArea { anchors.fill: parent; onClicked: mapCanvasRoot.focusRobot() }
        }
        Rectangle { 
            width: 120; height: 36; color: isFollowingRobot ? "#2e4a66" : "#cc1e2329"; radius: 4; Layout.alignment: Qt.AlignRight; 
            Text { anchors.centerIn: parent; text: "📍 Follow Robot"; color: "white" } 
            MouseArea { anchors.fill: parent; onClicked: { isFollowingRobot = !isFollowingRobot; if (isFollowingRobot) focusRobot(); } }
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

    // Colored drawing cursor overlay – shown only in layers mode
    Rectangle {
        id: layerDrawCursor
        visible: root.activeMode === "layers" && mapController.mapWidth > 0
        width: Math.max(4, root.brushSize * currentScale)
        height: Math.max(4, root.brushSize * currentScale)
        x: mapCanvasRoot._cursorVpX - width / 2
        y: mapCanvasRoot._cursorVpY - height / 2
        color: "transparent"
        border.color: root.activeLayerColor
        border.width: 2
        radius: 2
        z: 200
        // Small center dot for precision
        Rectangle {
            anchors.centerIn: parent
            width: 3; height: 3
            color: root.activeLayerColor
            radius: 2
        }
    }
}
