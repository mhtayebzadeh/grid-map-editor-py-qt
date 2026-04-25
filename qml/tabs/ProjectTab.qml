import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root
    signal saveRequested()

    property string projectName: ""
    property string projectPath: ""
    property string mapTopic: ""
    property string scanTopic: ""
    property string mappingParam: ""
    property string tfTopic: ""
    property string robotFrame: ""
    property bool autoSave: autoSaveCb.checked
    property alias showRobot: showRobotCb.checked
    property alias showLaserScan: showLaserScanCb.checked

    ScrollView {
        anchors.fill: parent
        clip: true
        ScrollBar.vertical.policy: ScrollBar.AsNeeded
        
        ColumnLayout {
            width: parent.availableWidth
            anchors.margins: 16
            spacing: 12

            Text { text: "PROJECT INFO"; color: "#9ca3af"; font.pixelSize: 12; font.bold: true; font.letterSpacing: 1.2 }

            ColumnLayout {
                spacing: 4
                Layout.fillWidth: true
                Text { text: "Project Name"; color: "#71717a"; font.pixelSize: 11; font.bold: true }
                Rectangle { 
                    Layout.fillWidth: true; height: 32; color: "#111827"; radius: 4; border.color: "#1f2937"
                    clip: true
                    TextEdit { 
                        anchors.verticalCenter: parent.verticalCenter; anchors.left: parent.left; anchors.right: parent.right; anchors.margins: 8
                        text: root.projectName; color: "#e4e4e7"; font.pixelSize: 13; readOnly: true; selectByMouse: true; selectionColor: "#2563eb"
                    }
                }
            }

            ColumnLayout {
                spacing: 4
                Layout.fillWidth: true
                Text { text: "Project Path"; color: "#71717a"; font.pixelSize: 11; font.bold: true }
                Rectangle { 
                    Layout.fillWidth: true; height: 32; color: "#111827"; radius: 4; border.color: "#1f2937"
                    clip: true
                    TextEdit { 
                        anchors.verticalCenter: parent.verticalCenter; anchors.left: parent.left; anchors.right: parent.right; anchors.margins: 8
                        text: root.projectPath; color: "#a1a1aa"; font.pixelSize: 11; readOnly: true; selectByMouse: true; selectionColor: "#2563eb"
                    }
                }
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: "#1f2937"; Layout.topMargin: 4; Layout.bottomMargin: 4 }

            // COLLAPSIBLE SLAM CONFIG
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 8
                
                Rectangle {
                    id: slamHeader
                    Layout.fillWidth: true
                    height: 32
                    color: "#1f2937"
                    radius: 4
                    
                    property bool collapsed: true

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 8
                        Text { text: "SLAM CONFIGURATION"; color: "#9ca3af"; font.pixelSize: 11; font.bold: true; Layout.fillWidth: true }
                        Text { text: slamHeader.collapsed ? "▶" : "▼"; color: "#9ca3af"; font.pixelSize: 10 }
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: slamHeader.collapsed = !slamHeader.collapsed
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 12
                    visible: !slamHeader.collapsed
                    Layout.leftMargin: 8
                    Layout.topMargin: 4

                    ColumnLayout {
                        spacing: 4
                        Layout.fillWidth: true
                        Text { text: "Laser Scan Topic"; color: "#71717a"; font.pixelSize: 11; font.bold: true }
                        Rectangle { 
                            Layout.fillWidth: true; height: 32; color: "#111827"; radius: 4; border.color: "#1f2937"
                            clip: true
                            TextInput { 
                                anchors.verticalCenter: parent.verticalCenter; anchors.left: parent.left; anchors.right: parent.right; anchors.margins: 8
                                text: root.scanTopic; color: "#e4e4e7"; font.pixelSize: 12; selectByMouse: true; selectionColor: "#2563eb"
                                onEditingFinished: projectManager.scanTopic = text
                            }
                        }
                    }

                    ColumnLayout {
                        spacing: 4
                        Layout.fillWidth: true
                        Text { text: "Map Topic"; color: "#71717a"; font.pixelSize: 11; font.bold: true }
                        Rectangle { 
                            Layout.fillWidth: true; height: 32; color: "#111827"; radius: 4; border.color: "#1f2937"
                            clip: true
                            TextInput { 
                                anchors.verticalCenter: parent.verticalCenter; anchors.left: parent.left; anchors.right: parent.right; anchors.margins: 8
                                text: root.mapTopic; color: "#e4e4e7"; font.pixelSize: 12; selectByMouse: true; selectionColor: "#2563eb"
                                onEditingFinished: projectManager.mapTopic = text
                                HoverHandler { cursorShape: Qt.IBeamCursor }
                            }
                        }
                    }

                    ColumnLayout {
                        spacing: 4
                        Layout.fillWidth: true
                        Text { text: "TF Topic"; color: "#71717a"; font.pixelSize: 11; font.bold: true }
                        Rectangle { 
                            Layout.fillWidth: true; height: 32; color: "#111827"; radius: 4; border.color: "#1f2937"
                            clip: true
                            TextInput { 
                                anchors.verticalCenter: parent.verticalCenter; anchors.left: parent.left; anchors.right: parent.right; anchors.margins: 8
                                text: root.tfTopic; color: "#e4e4e7"; font.pixelSize: 12; selectByMouse: true; selectionColor: "#2563eb"
                                onEditingFinished: projectManager.tfTopic = text
                                HoverHandler { cursorShape: Qt.IBeamCursor }
                            }
                        }
                    }

                    ColumnLayout {
                        spacing: 4
                        Layout.fillWidth: true
                        Text { text: "Robot Base Frame"; color: "#71717a"; font.pixelSize: 11; font.bold: true }
                        Rectangle { 
                            Layout.fillWidth: true; height: 32; color: "#111827"; radius: 4; border.color: "#1f2937"
                            clip: true
                            TextInput { 
                                anchors.verticalCenter: parent.verticalCenter; anchors.left: parent.left; anchors.right: parent.right; anchors.margins: 8
                                text: root.robotFrame; color: "#e4e4e7"; font.pixelSize: 12; selectByMouse: true; selectionColor: "#2563eb"
                                onEditingFinished: projectManager.robotFrame = text
                                HoverHandler { cursorShape: Qt.IBeamCursor }
                            }
                        }
                    }

                    ColumnLayout {
                        spacing: 4
                        Layout.fillWidth: true
                        Text { text: "Mapping Enabled Param"; color: "#71717a"; font.pixelSize: 11; font.bold: true }
                        Rectangle { 
                            Layout.fillWidth: true; height: 32; color: "#111827"; radius: 4; border.color: "#1f2937"
                            clip: true
                            TextInput { 
                                anchors.verticalCenter: parent.verticalCenter; anchors.left: parent.left; anchors.right: parent.right; anchors.margins: 8
                                text: root.mappingParam; color: "#e4e4e7"; font.pixelSize: 12; selectByMouse: true; selectionColor: "#2563eb"
                                onEditingFinished: projectManager.mappingEnabledParam = text
                                HoverHandler { cursorShape: Qt.IBeamCursor }
                            }
                        }
                    }
                }
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: "#1f2937"; Layout.topMargin: 4; Layout.bottomMargin: 4 }

            CheckBox {
                id: autoSaveCb
                text: "Auto-save changes (Every 60s)"
                checked: true
                contentItem: Text { text: parent.text; color: "#d1d5db"; font.pixelSize: 13; leftPadding: autoSaveCb.indicator.width + parent.spacing; verticalAlignment: Text.AlignVCenter }
            }
            
            CheckBox {
                id: showRobotCb
                text: "Show Robot Position"
                checked: true
                contentItem: Text { text: parent.text; color: "#d1d5db"; font.pixelSize: 13; leftPadding: showRobotCb.indicator.width + parent.spacing; verticalAlignment: Text.AlignVCenter }
            }

            CheckBox {
                id: showLaserScanCb
                text: "Show Laser Scan"
                checked: true
                contentItem: Text { text: parent.text; color: "#d1d5db"; font.pixelSize: 13; leftPadding: showLaserScanCb.indicator.width + parent.spacing; verticalAlignment: Text.AlignVCenter }
            }

            Item { Layout.fillHeight: true; Layout.minimumHeight: 20 }
        }
    }
}
