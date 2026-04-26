import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import QtCore
import "./components"

Rectangle {
    id: root
    color: "#1a1e24"

    Settings {
        id: folderSettings
        category: "LastFolders"
        property string lastGateImageFolder: ""
    }

    signal doLayerDraw(string layerId, var points, real drawValue, string tool, real size) // Matches the main app background dark color

    property bool isSlamMode: false
    property string projectName: ""
    property string projectPath: ""

    // SLAM Topics (Persisted via Settings)
    property string slamMapTopic: ""
    property string slamScanTopic: ""
    property string slamMappingEnabledParam: ""
    property string slamTfTopic: ""
    property string slamRobotFrame: ""
    property bool slamUseSimTime: false

    // Global properties used by sub-tabs
    property string mapTopic: (projectManager && projectManager.isLoaded) ? projectManager.mapTopic : slamMapTopic
    property string scanTopic: (projectManager && projectManager.isLoaded) ? projectManager.scanTopic : slamScanTopic
    property string tfTopic: (projectManager && projectManager.isLoaded) ? projectManager.tfTopic : slamTfTopic
    property string robotFrame: (projectManager && projectManager.isLoaded) ? projectManager.robotFrame : slamRobotFrame

    // Global UI State
    property string activeMode: "project" // "project", "map-edit", "layers", "gates"
    property bool showRobot: true
    property bool showLaserScan: true
    property bool safetyLockEnabled: true
    property bool mappingActive: isSlamMode
    property bool editingDisabled: safetyLockEnabled && mappingActive

    
    // Map Edit State
    property string currentMapEditTool: "obstacle" // "obstacle", "free", "revert"
    property string editLayerPath: ""
    property int brushSize: 10

    // Gates State
    property var pendingGateModel: null
    property string pendingGateCategoryId: ""
    property string activeGateId: ""
    ListModel { id: standardGatesModel }
    ListModel { id: homeGatesModel }
    ListModel { id: chargeStationsModel }

    property var gateCategories: [
        { id: "standard", name: "Gates", icon: "⚲", model: standardGatesModel },
        { id: "home", name: "Home Gates", icon: "🏠", model: homeGatesModel },
        { id: "charge", name: "Charge Stations", icon: "⚡", model: chargeStationsModel }
    ]

    function openAddGateDialog(mapX, mapY) {
        addGateDialog.mapX = mapX
        addGateDialog.mapY = mapY
        addGateDialog.gateName = "New Gate"
        addGateDialog.gateDesc = ""
        addGateDialog.gateImage = ""
        addGateDialog.open()
    }
    
    function getNextIncrementalGateId(categoryId) {
        let baseId = 10000;
        let targetModel = null;
        if (categoryId === "standard") {
            baseId = 10000;
            targetModel = standardGatesModel;
        } else if (categoryId === "home") {
            baseId = 20000;
            targetModel = homeGatesModel;
        } else if (categoryId === "charge") {
            baseId = 30000;
            targetModel = chargeStationsModel;
        } else {
            // Fallback for any other categories
            baseId = 40000;
            targetModel = standardGatesModel;
        }
        
        let maxId = baseId;
        if (targetModel) {
            for (let i = 0; i < targetModel.count; i++) {
                let idNum = parseInt(targetModel.get(i).gateId);
                if (!isNaN(idNum) && idNum > maxId) {
                    maxId = idNum;
                }
            }
        }
        return (maxId + 1).toString();
    }


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
            mapController.isSlamMode = root.mappingActive;
            
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
            root.activeLayerId = layersModel.count > 0 ? layersModel.get(0).layerId : "";
            root.editLayerPath = projectManager ? projectManager.getEditedOverlay() : "";
            
            if (projectManager.isLoaded) {
                // Global Config takes priority over project-saved topics
                if (root.slamMapTopic !== "") projectManager.mapTopic = root.slamMapTopic;
                if (root.slamScanTopic !== "") projectManager.scanTopic = root.slamScanTopic;
                if (root.slamTfTopic !== "") projectManager.tfTopic = root.slamTfTopic;
                if (root.slamRobotFrame !== "") projectManager.robotFrame = root.slamRobotFrame;
                if (root.slamMappingEnabledParam !== "") projectManager.mappingEnabledParam = root.slamMappingEnabledParam;
                projectManager.useSimTime = root.slamUseSimTime;

                robotHandler.start_ros(projectManager.scanTopic, projectManager.mapTopic, projectManager.tfTopic, projectManager.robotFrame, projectManager.initialPoseTopic, projectManager.useSimTime);
                root.loadProjectGates();
            } else if (root.isSlamMode) {
                robotHandler.start_ros(root.slamScanTopic, root.slamMapTopic, root.slamTfTopic, root.slamRobotFrame, "/initialpose", root.slamUseSimTime);
            }
        }
    }

    function loadProjectGates() {
        standardGatesModel.clear();
        homeGatesModel.clear();
        chargeStationsModel.clear();

        let gatesData = projectManager.loadGates();
        if (!gatesData) return;
        
        let standard = gatesData.standard_gates || [];
        for (let i = 0; i < standard.length; i++) standardGatesModel.append(standard[i]);
        
        let home = gatesData.home_gates || [];
        for (let i = 0; i < home.length; i++) homeGatesModel.append(home[i]);
        
        let charge = gatesData.charge_stations || [];
        for (let i = 0; i < charge.length; i++) chargeStationsModel.append(charge[i]);
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

        // Also save gates to YAML
        function modelToList(model) {
            let list = [];
            for (let i = 0; i < model.count; i++) {
                let item = model.get(i);
                list.push({
                    "gateId": item.gateId,
                    "name": item.name,
                    "description": item.description,
                    "imageFile": item.imageFile,
                    "xPos": item.xPos,
                    "yPos": item.yPos
                });
            }
            return list;
        }
        
        projectManager.saveGates(
            modelToList(standardGatesModel),
            modelToList(homeGatesModel),
            modelToList(chargeStationsModel)
        );
    }

    onMappingActiveChanged: {
        mapController.isSlamMode = mappingActive;
        statusPanel.addLog("Operation Mode changed: " + (mappingActive ? "Mapping (SLAM)" : "Map Editing"), "info");
    }

    SplitView {
        anchors.fill: parent
        orientation: Qt.Horizontal

        SidePanel {
            id: sidePanel
            SplitView.preferredWidth: 340
            SplitView.minimumWidth: 300
            SplitView.maximumWidth: 500
            onSaveRequested: root.saveProject()
            onExitRequested: exitConfirmDialog.open()
        }

        MapCanvas {
            id: mapCanvas
            SplitView.fillWidth: true
            editLayerPath: root.editLayerPath
        }
    }

    MessageDialog {
        id: exitConfirmDialog
        title: "Confirm Exit"
        text: "Are you sure you want to exit the editor? Any unsaved changes will be lost."
        buttons: MessageDialog.Yes | MessageDialog.No
        onAccepted: {
            robotHandler.stop_ros();
            stackView.pop();
        }
    }

    Connections {
        target: projectManager
        function onRosConfigChanged() {
            if (projectManager.isLoaded) {
                console.log("ROS topics updated: Map=" + projectManager.mapTopic + " Scan=" + projectManager.scanTopic)
                robotHandler.start_ros(projectManager.scanTopic, projectManager.mapTopic, projectManager.tfTopic, projectManager.robotFrame);
            }
        }
    }

    Timer {
        id: autoSaveTimer
        interval: 60000
        running: sidePanel.autoSaveEnabled
        repeat: true
        onTriggered: {
            statusPanel.addLog("Auto-saving project...", "info")
            root.saveProject()
        }
    }

    FileDialog {
        id: imageFileDialog
        title: "Select Gate Image"
        nameFilters: ["Image files (*.png *.jpg *.jpeg)", "All files (*)"]
        currentFolder: folderSettings.lastGateImageFolder !== "" ? folderSettings.lastGateImageFolder : StandardPaths.writableLocation(StandardPaths.PicturesLocation)
        onAccepted: {
            folderSettings.lastGateImageFolder = currentFolder
            if (addGateDialog.visible) {
                addGateDialog.gateImage = selectedFile.toString().replace("file://", "");
            }
        }
    }

    Dialog {
        id: addGateDialog
        anchors.centerIn: parent
        width: 350
        height: 380
        modal: true
        title: "Add New Gate"
        
        property real mapX: 0.0
        property real mapY: 0.0
        property string gateName: ""
        property string gateDesc: ""
        property string gateImage: ""

        background: Rectangle { color: "#1f2937"; radius: 8; border.color: "#374151" }
        
        header: Rectangle {
            color: "#111827"; height: 40; radius: 8
            Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 8; color: "#111827" } // hide bottom radius
            Text { anchors.centerIn: parent; text: addGateDialog.title; color: "white"; font.pixelSize: 14; font.bold: true }
        }

        contentItem: ColumnLayout {
            spacing: 12
            
            Text { text: "Location: " + addGateDialog.mapX.toFixed(2) + ", " + addGateDialog.mapY.toFixed(2) + " (meters)"; color: "#9ca3af"; font.pixelSize: 12 }
            
            ColumnLayout {
                spacing: 4
                Layout.fillWidth: true
                Text { text: "Name *"; color: addGateDialog.gateName.trim() === "" ? "#ef4444" : "#d1d5db"; font.pixelSize: 12 }
                Rectangle {
                    Layout.fillWidth: true; height: 32; color: "#111827"; radius: 4; border.color: addGateDialog.gateName.trim() === "" ? "#ef4444" : "#374151"
                    TextInput { anchors.fill: parent; anchors.margins: 8; color: "white"; font.pixelSize: 13; text: addGateDialog.gateName; onTextChanged: addGateDialog.gateName = text }
                }
            }
            
            ColumnLayout {
                spacing: 4
                Layout.fillWidth: true
                Text { text: "Description"; color: "#d1d5db"; font.pixelSize: 12 }
                Rectangle {
                    id: descriptionRect
                    Layout.fillWidth: true; height: 60; color: "#111827"; radius: 4; border.color: "#374151"; clip: true
                    ScrollView {
                        anchors.fill: descriptionRect
                        clip: true
                        TextEdit { 
                            width: descriptionRect.width - 12
                            anchors.centerIn: descriptionRect
                            padding: 8
                            color: "white"; font.pixelSize: 13; 
                            text: addGateDialog.gateDesc; 
                            onTextChanged: addGateDialog.gateDesc = text
                            wrapMode: Text.Wrap
                            selectByMouse: true
                        }
                    }
                }
            }
            
            ColumnLayout {
                spacing: 4
                Layout.fillWidth: true
                Text { text: "Image Path/URL"; color: "#d1d5db"; font.pixelSize: 12 }
                RowLayout {
                    Layout.fillWidth: true
                    Rectangle {
                        Layout.fillWidth: true; height: 32; color: "#111827"; radius: 4; border.color: "#374151"
                        TextInput { 
                            anchors.fill: parent; anchors.margins: 8; color: "white"; font.pixelSize: 13; 
                            text: addGateDialog.gateImage; 
                            readOnly: true; clip: true; 
                        }
                    }
                    Rectangle {
                        width: 32; height: 32; color: "#374151"; radius: 4
                        Text { anchors.centerIn: parent; text: "..."; color: "white" }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: imageFileDialog.open()
                        }
                    }
                }
            }
            
            RowLayout {
                Layout.fillWidth: true; Layout.alignment: Qt.AlignRight; spacing: 8; Layout.topMargin: 12
                Rectangle {
                    width: 80; height: 32; color: "transparent"; border.color: "#6b7280"; radius: 4
                    Text { anchors.centerIn: parent; text: "Cancel"; color: "white"; font.pixelSize: 13 }
                    MouseArea { anchors.fill: parent; onClicked: { root.pendingGateModel = null; addGateDialog.close() } }
                }
                Rectangle {
                    width: 80; height: 32; color: addGateDialog.gateName.trim() === "" ? "#4b5563" : "#2563eb"; radius: 4
                    opacity: addGateDialog.gateName.trim() === "" ? 0.5 : 1.0
                    Text { anchors.centerIn: parent; text: "Confirm"; color: "white"; font.pixelSize: 13; font.bold: true }
                    MouseArea { 
                        anchors.fill: parent
                        enabled: addGateDialog.gateName.trim() !== ""
                        onClicked: {
                            if (root.pendingGateModel) {
                                let newGid = getNextIncrementalGateId(root.pendingGateCategoryId);
                                let finalImagePath = addGateDialog.gateImage;
                                if (finalImagePath) {
                                    finalImagePath = projectManager.copyGateImage(finalImagePath, root.pendingGateCategoryId, addGateDialog.gateName, newGid, "");
                                }
                                root.pendingGateModel.append({
                                    gateId: newGid,
                                    name: addGateDialog.gateName,
                                    xPos: addGateDialog.mapX,
                                    yPos: addGateDialog.mapY,
                                    description: addGateDialog.gateDesc,
                                    imageFile: finalImagePath
                                });
                                root.activeGateId = newGid;
                            }
                            root.pendingGateModel = null;
                            root.pendingGateCategoryId = "";
                            addGateDialog.close();
                        }
                    }
                }
            }
        }
    }
}

