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

    // Global UI State
    property string activeMode: "project" // "project", "map-edit", "layers", "gates"
    
    // Map Edit State
    property string currentMapEditTool: "obstacle" // "obstacle", "free", "revert"
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
    signal doLayerDraw(string layerId, var points, real drawValue, string tool, int size)

    ListModel {
        id: layersModel
        Component.onCompleted: {
            layersModel.append({ "layerId": "layer_" + Date.now(), "name": "Keepout", "colorStr": "#ef4444", "opacity": 0.70, "layerVisible": true });
            root.activeLayerId = layersModel.get(0).layerId;
        }
    }

    function requestSaveMapEdits() {
        let b64 = mapCanvas.saveCanvasOverlay();
        mapController.saveMergedMap(b64);
    }

    // Collect all layer canvas data and send to Python to persist
    function saveProject() {
        let layerDataList = mapCanvas.getLayerDataUrls();
        let layerMetaList = [];
        for (let i = 0; i < layersModel.count; i++) {
            let layer = layersModel.get(i);
            layerMetaList.push({
                "layerId": layer.layerId,
                "name": layer.name,
                "colorStr": layer.colorStr,
                "opacity": layer.opacity,
                "visible": layer.layerVisible,
                "b64": (i < layerDataList.length) ? layerDataList[i].b64 : ""
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
        }
    }
}
