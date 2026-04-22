import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "./components"

Rectangle {
    id: root
    color: "#1a1e24"

    signal doLayerDraw(string layerId, var points, real drawValue, string tool, real size) // Matches the main app background dark color

    property bool isSlamMode: false
    property string projectName: ""
    property string projectPath: ""

    // SLAM Topics (Persisted via Settings)
    property string slamRobotTopic: ""
    property string slamMapTopic: ""
    property string slamMappingEnabledParam: ""

    // Global UI State
    property string activeMode: "project" // "project", "map-edit", "layers", "gates"
    
    // Map Edit State
    property string currentMapEditTool: "obstacle" // "obstacle", "free", "revert"
    property string editLayerPath: ""
    property int brushSize: 10

    // Layer State
    property string currentLayerTool: "pencil" // pencil, line, poly, eraser
    property string activeLayerId: ""
    property int layerDrawValue: 0

    // Derived: color of the currently active layer (used for cursor tint)
    property string activeLayerColor: {
        for (var i = 0; i < layersModel.count; i++) {
            if (layersModel.get(i).layerId === activeLayerId)
                return layersModel.get(i).colorStr;
        }
        return "#ef4444";
    }

    // Signal emitted to layer canvases to commit a draw operation

    ListModel {
        id: layersModel
        Component.onCompleted: {
            if (!root.isSlamMode && projectManager.isLoaded) {
                let layers = projectManager.getLayers();
                if (layers && layers.length > 0) {
                    layersModel.clear();
                    for (let i = 0; i < layers.length; i++) {
                        layersModel.append({
                            "layerId": layers[i].layerId,
                            "name": layers[i].name,
                            "colorStr": layers[i].colorStr,
                            "opacity": layers[i].opacity,
                            "layerVisible": layers[i].visible,
                            "filePath": layers[i].file || ""
                        });
                    }
                } else {
                    layersModel.append({ "layerId": "layer_" + Date.now(), "name": "Keepout", "colorStr": "#ef4444", "opacity": 0.70, "layerVisible": true, "filePath": "" });
                }
            } else {
                layersModel.append({ "layerId": "layer_" + Date.now(), "name": "Keepout", "colorStr": "#ef4444", "opacity": 0.70, "layerVisible": true, "filePath": "" });
            }
            root.activeLayerId = layersModel.get(0).layerId;
            root.editLayerPath = projectManager.getEditedOverlay();
        }
    }

    function requestSaveMapEdits() {
        let b64 = mapCanvas.saveCanvasOverlay();
        mapController.saveMergedMap(b64);
    }

    // Collect all layer canvas data and send to Python to persist
    function saveProject() {
        // Also save merged map so everything is fully persisted
        requestSaveMapEdits()
        
        let layerDataList = mapCanvas.getLayerDataUrls();
        let layerMetaList = [];
        for (let i = 0; i < layersModel.count; i++) {
            let layer = layersModel.get(i);
            let b64 = "";
            for (let j = 0; j < layerDataList.length; j++) {
                if (layerDataList[j].layerId === layer.layerId) {
                    b64 = layerDataList[j].b64;
                    break;
                }
            }
            layerMetaList.push({
                "layerId": layer.layerId,
                "name": layer.name,
                "colorStr": layer.colorStr,
                "opacity": layer.opacity,
                "visible": layer.layerVisible,
                "b64": b64
            });
        }
        mapController.saveProjectFull(layerMetaList);
    }

    SplitView {
        anchors.fill: parent
        orientation: Qt.Horizontal

        SidePanel {
            id: sidePanel
            SplitView.preferredWidth: 320
            SplitView.minimumWidth: 250
            SplitView.maximumWidth: 500
        }

        MapCanvas {
            id: mapCanvas
            SplitView.fillWidth: true
            editLayerPath: root.editLayerPath
        }
    }

    Timer {
        id: autoSaveTimer
        interval: 20000
        running: sidePanel.autoSaveEnabled
        repeat: true
        onTriggered: {
            console.log("Auto-saving project...")
            root.saveProject()
        }
    }
}

