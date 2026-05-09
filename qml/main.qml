import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtCore
import "./components"

ApplicationWindow {
    id: window
    visible: true
    width: 1024
    height: 768
    title: qsTr("Occupancy Grid Map Editor")
    color: "#1a1e24"

    Settings {
        id: slamSettings
        category: "SlamTopics"
        property string mapTopic: "/map"
        property string scanTopic: "/scan"
        property string tfTopic: "/tf"
        property string robotFrame: "base_link"
        property string initialPoseTopic: "/initialpose"
        property bool useSimTime: false
        property real initialUncertainty: 1.5
        property string resetMapServiceName: "/slam_toolbox/reset"
        property string resetMapServiceType: "slam_toolbox/srv/Reset"
        property string pauseMappingServiceName: "/slam_toolbox/pause_new_measurements"
        property string pauseMappingServiceType: "slam_toolbox/srv/Pause"
    }

    StackView {
        id: stackView
        anchors.fill: parent
        initialItem: StartScreen {
            onStartEditor: (isSlamMode, projectName, projectPath, mapFile, yamlFile, resolution, mapTopic, scanTopic, tfTopic, robotFrame, useSimTime, resetMapServiceName, resetMapServiceType, pauseMappingServiceName, pauseMappingServiceType) => {
                
                // If in edit mode, tell python to load the map!
                if (!isSlamMode && (mapFile !== "" || yamlFile !== "")) {
                     mapController.loadMap(yamlFile, mapFile, parseFloat(resolution) || 0.05)
                }

                stackView.push("MainEditor.qml", {
                    "isSlamMode": isSlamMode,
                    "projectName": projectName,
                    "projectPath": projectPath,
                    "slamMapTopic": mapTopic,
                    "slamScanTopic": scanTopic,
                    "slamTfTopic": tfTopic,
                    "slamRobotFrame": robotFrame,
                    "slamUseSimTime": useSimTime,
                    "slamResetMapServiceName": resetMapServiceName,
                    "slamResetMapServiceType": resetMapServiceType,
                    "slamPauseMappingServiceName": pauseMappingServiceName,
                    "slamPauseMappingServiceType": pauseMappingServiceType
                })
            }
        }
    }

    // Toggle Button (Floating at bottom)
    Rectangle {
        id: logToggleButton
        width: 40; height: 40
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        anchors.margins: 15
        color: statusPanel.isOpen ? "#3b82f6" : "#374151"
        radius: 4
        z: 999 // Below panel but above stackView
        
        Text {
            anchors.centerIn: parent
            text: "📋"
            font.pixelSize: 20
            color: "white"
        }
        
        MouseArea {
            id: logToggleMouseArea
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            hoverEnabled: true
            onClicked: statusPanel.isOpen = !statusPanel.isOpen
        }
        
        ToolTip.visible: logToggleMouseArea.containsMouse
        ToolTip.text: "Show Logs & Status"
    }

    StatusPanel {
        id: statusPanel
        isOpen: false
    }

    // Logic to update topics in the status panel
    function refreshTopics() {
        if (!projectManager) return;
        
        let topics = [];
        // Map Topic
        let mapTopic = projectManager.mapTopic || "/map";
        topics.push({ name: "Map", topic: mapTopic, isActive: robotHandler.isMapActive });
        
        // Scan Topic
        let scanTopic = projectManager.scanTopic || "/scan";
        topics.push({ name: "Laser Scan", topic: scanTopic, isActive: robotHandler.isScanActive });
        
        // TF Topic
        let tfTopic = projectManager.tfTopic || "/tf";
        topics.push({ name: "TF", topic: tfTopic, isActive: robotHandler.isTfActive });
        
        statusPanel.updateTopics(topics);
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: refreshTopics()
    }
    
    Connections {
        target: robotHandler
        function onStatusChanged() {
            refreshTopics()
        }
        function onLogMessage(msg, type) {
            statusPanel.addLog(msg, type)
        }
    }
    
    Connections {
        target: mapController
        function onLogMessage(msg, type) {
            statusPanel.addLog(msg, type)
        }
    }

    Component.onCompleted: {
        // Sync persisted settings to projectManager immediately
        projectManager.mapTopic = slamSettings.mapTopic
        projectManager.scanTopic = slamSettings.scanTopic
        projectManager.tfTopic = slamSettings.tfTopic
        projectManager.robotFrame = slamSettings.robotFrame
        projectManager.initialPoseTopic = slamSettings.initialPoseTopic
        projectManager.useSimTime = slamSettings.useSimTime
        projectManager.initialUncertainty = slamSettings.initialUncertainty
        projectManager.resetMapServiceName = slamSettings.resetMapServiceName
        projectManager.resetMapServiceType = slamSettings.resetMapServiceType
        projectManager.pauseMappingServiceName = slamSettings.pauseMappingServiceName
        projectManager.pauseMappingServiceType = slamSettings.pauseMappingServiceType
        
        robotHandler.initialUncertainty = projectManager.initialUncertainty
        
        refreshTopics()
        
        // Start ROS with these settings
        robotHandler.start_ros(projectManager.scanTopic, projectManager.mapTopic, projectManager.tfTopic, projectManager.robotFrame, projectManager.initialPoseTopic, projectManager.useSimTime)
    }
}
