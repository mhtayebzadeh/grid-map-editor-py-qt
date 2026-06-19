import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs

Item {
    id: root
    signal saveRequested()

    property string projectName: ""
    property string projectPath: ""
    property bool isSlamMode: false
    property bool mappingActive: false
    property string mapTopic: ""
    property string scanTopic: ""
    property string tfTopic: ""
    property string robotFrame: ""
    property string resetMapServiceName: ""
    property string resetMapServiceType: ""
    property string pauseMappingServiceName: ""
    property string pauseMappingServiceType: ""
    property bool autoSave: autoSaveCb.checked
    property alias showRobot: showRobotCb.checked
    property alias showLaserScan: showLaserScanCb.checked
    property alias safetyLockEnabled: safetyLockCb.checked
    property bool isMappingActive: true

    ScrollView {
        id: scroll
        anchors.fill: parent
        clip: true
        contentWidth: availableWidth
        ScrollBar.vertical.policy: ScrollBar.AsNeeded
        
        Pane {
            width: scroll.availableWidth
            background: null
            padding: 16

            ColumnLayout {
                width: parent.width - 32
                spacing: 12

                // OPERATION MODE SECTION
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    
                    Text { 
                        text: "OPERATION MODE"
                        color: "#9ca3af"
                        font.pixelSize: 12
                        font.bold: true
                        font.letterSpacing: 1.2
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        height: 40
                        color: "#111827"
                        radius: 6
                        border.color: "#1f2937"
                        
                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 4
                            spacing: 4
                            
                            // Mapping (SLAM) Tab
                            Rectangle {
                                id: mappingBtn
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                color: root.mappingActive ? "#2563eb" : "transparent"
                                radius: 4
                                opacity: root.isSlamMode ? 1.0 : 0.4
                                
                                RowLayout {
                                    anchors.centerIn: parent
                                    spacing: 8
                                    Rectangle {
                                        width: 8; height: 8; radius: 4
                                        color: root.mappingActive ? "white" : "#4b5563"
                                        visible: root.isSlamMode
                                    }
                                    Text {
                                        text: "Mapping (SLAM)"
                                        color: root.mappingActive ? "white" : "#9ca3af"
                                        font.pixelSize: 13
                                        font.bold: root.mappingActive
                                    }
                                }
                                
                                MouseArea {
                                    anchors.fill: parent
                                    enabled: root.isSlamMode
                                    cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                                    onClicked: root.mappingActive = true
                                }
                            }
                            
                            // Map Editing Tab
                            Rectangle {
                                id: editingBtn
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                color: !root.mappingActive ? "#2563eb" : "transparent"
                                radius: 4
                                
                                Text {
                                    anchors.centerIn: parent
                                    text: "Map Editing"
                                    color: !root.mappingActive ? "white" : "#9ca3af"
                                    font.pixelSize: 13
                                    font.bold: !root.mappingActive
                                }
                                
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.mappingActive = false
                                }
                            }
                        }
                    }

                    Text {
                        Layout.fillWidth: true
                        text: !root.isSlamMode ? "SLAM is disabled because you are editing an existing map." : 
                              root.mappingActive ? "Live mapping is active. Safety lock prevents editing." :
                              "Mapping is paused. You can now edit the map layers."
                        color: "#9ca3af"
                        font.pixelSize: 11
                        font.italic: true
                        wrapMode: Text.Wrap
                    }
                }

                Rectangle { Layout.fillWidth: true; height: 1; color: "#1f2937"; Layout.topMargin: 4; Layout.bottomMargin: 4 }

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

            // OPERATION MODE TOGGLE
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 8
                
                Text { text: "Operation Mode"; color: "#9ca3af"; font.pixelSize: 11; font.bold: true; font.letterSpacing: 1.2 }
                
                Rectangle {
                    Layout.fillWidth: true
                    height: 40
                    color: "#111827"
                    radius: 6
                    border.color: "#1f2937"
                    
                    RowLayout {
                        anchors.fill: parent
                        spacing: 0
                        
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            color: root.isMappingActive ? "#ef4444" : "transparent"
                            radius: 6
                            
                            RowLayout {
                                anchors.centerIn: parent
                                spacing: 8
                                Rectangle { width: 8; height: 8; radius: 4; color: root.isMappingActive ? "white" : "#4b5563"; opacity: root.isMappingActive ? 1.0 : 0.5 }
                                Text { text: "Mapping (SLAM)"; color: "white"; font.bold: root.isMappingActive; font.pixelSize: 13 }
                            }
                            
                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    if (!root.isMappingActive) {
                                        warningDialog.open()
                                    }
                                }
                            }
                        }
                        
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            color: !root.isMappingActive ? "#2563eb" : "transparent"
                            radius: 6
                            
                            Text { 
                                anchors.centerIn: parent
                                text: "Map Editing" 
                                color: "white" 
                                font.bold: !root.isMappingActive 
                                font.pixelSize: 13 
                            }
                            
                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    if (root.isMappingActive) {
                                        confirmDialog.open()
                                    }
                                }
                            }
                        }
                    }
                }
                
                Text {
                    visible: root.isMappingActive && root.safetyLockEnabled
                    text: "Map annotation is disabled while SLAM is active to prevent data corruption."
                    color: "#f87171"
                    font.pixelSize: 12
                    font.italic: true
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }
            }

            MessageDialog {
                id: confirmDialog
                title: "Switch to Editing Mode"
                text: "Are you sure? Once you enter Editing mode, you cannot resume mapping."
                buttons: MessageDialog.Yes | MessageDialog.Cancel
                onButtonClicked: (button, role) => {
                    if (role === MessageDialog.YesRole) {
                        root.isMappingActive = false
                        console.log("Switching to Edit mode, calling pause service: " + root.pauseMappingServiceName)
                        robotHandler.call_service_async(root.pauseMappingServiceName, root.pauseMappingServiceType)
                    }
                }
            }

            MessageDialog {
                id: warningDialog
                title: "Action Not Allowed"
                text: "Mapping can only be done once per project. You cannot return to Mapping mode."
                buttons: MessageDialog.Ok
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
                        Text { text: "Reset Map Service Name"; color: "#71717a"; font.pixelSize: 11; font.bold: true }
                        Rectangle { 
                            Layout.fillWidth: true; height: 32; color: "#111827"; radius: 4; border.color: "#1f2937"
                            clip: true
                            TextInput { 
                                anchors.verticalCenter: parent.verticalCenter; anchors.left: parent.left; anchors.right: parent.right; anchors.margins: 8
                                text: root.resetMapServiceName; color: "#e4e4e7"; font.pixelSize: 12; selectByMouse: true; selectionColor: "#2563eb"
                                onEditingFinished: projectManager.resetMapServiceName = text
                                HoverHandler { cursorShape: Qt.IBeamCursor }
                            }
                        }
                    }

                    ColumnLayout {
                        spacing: 4
                        Layout.fillWidth: true
                        Text { text: "Reset Map Service Type"; color: "#71717a"; font.pixelSize: 11; font.bold: true }
                        Rectangle { 
                            Layout.fillWidth: true; height: 32; color: "#111827"; radius: 4; border.color: "#1f2937"
                            clip: true
                            TextInput { 
                                anchors.verticalCenter: parent.verticalCenter; anchors.left: parent.left; anchors.right: parent.right; anchors.margins: 8
                                text: root.resetMapServiceType; color: "#e4e4e7"; font.pixelSize: 12; selectByMouse: true; selectionColor: "#2563eb"
                                onEditingFinished: projectManager.resetMapServiceType = text
                                HoverHandler { cursorShape: Qt.IBeamCursor }
                            }
                        }
                    }

                    ColumnLayout {
                        spacing: 4
                        Layout.fillWidth: true
                        Text { text: "Pause Mapping Service Name"; color: "#71717a"; font.pixelSize: 11; font.bold: true }
                        Rectangle { 
                            Layout.fillWidth: true; height: 32; color: "#111827"; radius: 4; border.color: "#1f2937"
                            clip: true
                            TextInput { 
                                anchors.verticalCenter: parent.verticalCenter; anchors.left: parent.left; anchors.right: parent.right; anchors.margins: 8
                                text: root.pauseMappingServiceName; color: "#e4e4e7"; font.pixelSize: 12; selectByMouse: true; selectionColor: "#2563eb"
                                onEditingFinished: projectManager.pauseMappingServiceName = text
                                HoverHandler { cursorShape: Qt.IBeamCursor }
                            }
                        }
                    }

                    ColumnLayout {
                        spacing: 4
                        Layout.fillWidth: true
                        Text { text: "Pause Mapping Service Type"; color: "#71717a"; font.pixelSize: 11; font.bold: true }
                        Rectangle { 
                            Layout.fillWidth: true; height: 32; color: "#111827"; radius: 4; border.color: "#1f2937"
                            clip: true
                            TextInput { 
                                anchors.verticalCenter: parent.verticalCenter; anchors.left: parent.left; anchors.right: parent.right; anchors.margins: 8
                                text: root.pauseMappingServiceType; color: "#e4e4e7"; font.pixelSize: 12; selectByMouse: true; selectionColor: "#2563eb"
                                onEditingFinished: projectManager.pauseMappingServiceType = text
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

            CheckBox {
                id: safetyLockCb
                text: "Editing Safety Lock (Disable edit in Mapping)"
                checked: true
                contentItem: Text { text: parent.text; color: "#ef4444"; font.pixelSize: 13; font.bold: true; leftPadding: safetyLockCb.indicator.width + parent.spacing; verticalAlignment: Text.AlignVCenter }
            }

            Item { Layout.fillHeight: true; Layout.minimumHeight: 20 }
        }
    }
}
}
