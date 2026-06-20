import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../tabs"

Rectangle {
    id: sidePanelRoot
    color: "#1e2329"

    property int currentTab: 0
    property bool autoSaveEnabled: projectTab ? projectTab.autoSave : false
    
    signal saveRequested()
    signal exitRequested()

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 16

        // MODE Header
        Text {
            text: "MODE: " + (root.isSlamMode ? "MAPPING" : "EDITING")
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
                            cursorShape: Qt.PointingHandCursor
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

        // TABS AREA - Expands to fill space
        StackLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: sidePanelRoot.currentTab

            ProjectTab {
                id: projectTab
                projectName: root.projectName
                projectPath: root.projectPath
                isSlamMode: root.isSlamMode
                mapTopic: root.mapTopic
                scanTopic: root.scanTopic
                tfTopic: root.tfTopic
                robotFrame: root.robotFrame
                resetMapServiceName: root.resetMapServiceName
                resetMapServiceType: root.resetMapServiceType
                pauseMappingServiceName: root.pauseMappingServiceName
                pauseMappingServiceType: root.pauseMappingServiceType
                isMappingActive: root.isMappingActive
                onIsMappingActiveChanged: root.isMappingActive = isMappingActive
                
                showRobot: root.showRobot
                onShowRobotChanged: root.showRobot = showRobot
                
                showLaserScan: root.showLaserScan
                onShowLaserScanChanged: root.showLaserScan = showLaserScan

                safetyLockEnabled: root.safetyLockEnabled
                onSafetyLockEnabledChanged: root.safetyLockEnabled = safetyLockEnabled
            }
            MapEditTab {
                enabled: !root.editingDisabled
            }
            LayersTab {
                enabled: !root.editingDisabled
            }
            GatesTab {
                enabled: !root.editingDisabled
            }
        }

        // BOTTOM AREA - Fixed height
        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: "#38404a"
            Layout.topMargin: 4
            Layout.bottomMargin: 4
        }

        RowLayout {
            id: bottomButtons
            Layout.fillWidth: true
            Layout.preferredHeight: 40
            Layout.fillHeight: false
            spacing: 8

            // EXIT BUTTON
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredWidth: 80
                Layout.fillHeight: true
                color: "#dc2626"
                radius: 6
                Text {
                    anchors.centerIn: parent
                    text: "Exit"
                    color: "white"
                    font.pixelSize: 14
                    font.bold: true
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: sidePanelRoot.exitRequested()
                }
            }

            // SAVE BUTTON
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredWidth: 240
                Layout.fillHeight: true
                color: "#16a34a"
                radius: 6
                Text {
                    anchors.centerIn: parent
                    text: "Save Project"
                    color: "white"
                    font.pixelSize: 15
                    font.bold: true
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: sidePanelRoot.saveRequested()
                }
            }
        }
    }
}
