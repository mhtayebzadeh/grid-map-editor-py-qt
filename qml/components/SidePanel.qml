import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../tabs"

Rectangle {
    id: sidePanelRoot
    color: "#1e2329"

    property int currentTab: 0
    property bool autoSaveEnabled: projectTab ? projectTab.autoSave : false

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 16

        // MODE Header
        Text {
            text: "MODE"
            color: "#a0a5ab"
            font.bold: true
            font.pixelSize: 12
            font.letterSpacing: 1.2
        }

        // Segmented Tab Switcher
        Rectangle {
            Layout.fillWidth: true
            height: 36
            color: "#2a3038"
            radius: 4
            
            RowLayout {
                anchors.fill: parent
                spacing: 0
                
                Repeater {
                    model: ["Project", "Map Edit", "Layers", "Gates"]
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        color: sidePanelRoot.currentTab === index ? "#2e6bf0" : "transparent"
                        radius: 4
                        Text {
                            anchors.centerIn: parent
                            text: modelData
                            color: "white"
                            font.pixelSize: 13
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                sidePanelRoot.currentTab = index;
                                let modes = ["project", "map-edit", "layers", "gates"];
                                root.activeMode = modes[index];
                            }
                        }
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: "#38404a"
            Layout.topMargin: 8
            Layout.bottomMargin: 8
        }

        StackLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: sidePanelRoot.currentTab

            ProjectTab {
                id: projectTab
                projectName: root.projectName
                projectPath: root.projectPath
                mapTopic: root.mapTopic
                scanTopic: root.scanTopic
                tfTopic: root.tfTopic
                robotFrame: root.robotFrame
                mappingParam: root.slamMappingEnabledParam
                
                showRobot: root.showRobot
                onShowRobotChanged: root.showRobot = showRobot
                
                showLaserScan: root.showLaserScan
                onShowLaserScanChanged: root.showLaserScan = showLaserScan
                
                onSaveRequested: {
                    if (typeof root.saveProject === "function") {
                        root.saveProject()
                    }
                }
            }
            MapEditTab {}
            LayersTab {}
            GatesTab {}
        }
    }
}
