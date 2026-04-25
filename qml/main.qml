import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ApplicationWindow {
    id: window
    visible: true
    width: 1024
    height: 768
    title: qsTr("Occupancy Grid Map Editor")
    color: "#1a1e24"

    StackView {
        id: stackView
        anchors.fill: parent
        initialItem: StartScreen {
            onStartEditor: (isSlamMode, projectName, projectPath, mapFile, yamlFile, resolution, mapTopic, scanTopic, mappingParam, tfTopic, robotFrame) => {
                
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
                    "slamMappingEnabledParam": mappingParam,
                    "slamTfTopic": tfTopic,
                    "slamRobotFrame": robotFrame
                })
            }
        }
    }
}
