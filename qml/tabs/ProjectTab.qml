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
    property bool isSlamMode: false
    property bool autoSave: autoSaveCb.checked
    property alias showRobot: showRobotCb.checked
    property alias showLaserScan: showLaserScanCb.checked
    property alias safetyLockEnabled: safetyLockCb.checked

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

                    // ── SLAM Mode Toggle Switch ────────────────────────
                    // Only visible when the editor was launched in SLAM mode.
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 6
                        visible: root.isSlamMode

                        Rectangle { Layout.fillWidth: true; height: 1; color: "#1f2937"; Layout.topMargin: 4; Layout.bottomMargin: 2 }

                        Text {
                            text: "SLAM MODE"
                            color: "#9ca3af"
                            font.pixelSize: 11
                            font.bold: true
                            font.letterSpacing: 1.2
                        }

                        // Toggle card
                        Rectangle {
                            id: slamToggleCard
                            Layout.fillWidth: true
                            height: 72
                            radius: 8
                            color: "#111827"
                            border.color: slamModeHandler.currentMode === "mapping" ? "#2563eb" : "#7c3aed"
                            border.width: 1

                            property bool isMapping: slamModeHandler.currentMode === "mapping"

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 10
                                spacing: 6

                                // Top row: label + status badge
                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 6

                                    Text {
                                        text: slamToggleCard.isMapping ? "🗺️" : "📍"
                                        font.pixelSize: 14
                                    }
                                    Text {
                                        text: slamToggleCard.isMapping ? "Mapping Mode" : "Localization Mode"
                                        color: "#e4e4e7"
                                        font.pixelSize: 13
                                        font.bold: true
                                        Layout.fillWidth: true
                                    }

                                    // Busy indicator
                                    Rectangle {
                                        width: 18; height: 18
                                        radius: 9
                                        color: "transparent"
                                        visible: slamModeHandler.isSwitching

                                        Rectangle {
                                            id: spinner
                                            width: 14; height: 14
                                            anchors.centerIn: parent
                                            radius: 7
                                            color: "transparent"
                                            border.width: 2
                                            border.color: "#6b7280"

                                            Rectangle {
                                                width: 6; height: 6
                                                radius: 3
                                                color: "#3b82f6"
                                                anchors.top: parent.top
                                                anchors.horizontalCenter: parent.horizontalCenter
                                            }

                                            RotationAnimator {
                                                target: spinner
                                                from: 0; to: 360
                                                duration: 1000
                                                loops: Animation.Infinite
                                                running: slamModeHandler.isSwitching
                                            }
                                        }
                                    }
                                }

                                // Pill toggle
                                Rectangle {
                                    id: toggleTrack
                                    Layout.fillWidth: true
                                    height: 28
                                    radius: 14
                                    color: slamToggleCard.isMapping ? "#1e3a5f" : "#3b1f6e"

                                    Behavior on color { ColorAnimation { duration: 300 } }

                                    // Knob
                                    Rectangle {
                                        id: toggleKnob
                                        width: (parent.width / 2) - 4
                                        height: 22
                                        y: 3
                                        x: slamToggleCard.isMapping ? 3 : parent.width - width - 3
                                        radius: 11
                                        color: slamToggleCard.isMapping ? "#2563eb" : "#7c3aed"

                                        Behavior on x { NumberAnimation { duration: 300; easing.type: Easing.InOutCubic } }
                                        Behavior on color { ColorAnimation { duration: 300 } }

                                        Text {
                                            anchors.centerIn: parent
                                            text: slamToggleCard.isMapping ? "Mapping" : "Localization"
                                            color: "white"
                                            font.pixelSize: 11
                                            font.bold: true
                                        }
                                    }

                                    // Labels on the track
                                    Text {
                                        anchors.left: parent.left
                                        anchors.leftMargin: 12
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: "MAP"
                                        color: slamToggleCard.isMapping ? "transparent" : "#6b7280"
                                        font.pixelSize: 10
                                        font.bold: true
                                        Behavior on color { ColorAnimation { duration: 200 } }
                                    }
                                    Text {
                                        anchors.right: parent.right
                                        anchors.rightMargin: 12
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: "LOC"
                                        color: slamToggleCard.isMapping ? "#6b7280" : "transparent"
                                        font.pixelSize: 10
                                        font.bold: true
                                        Behavior on color { ColorAnimation { duration: 200 } }
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: slamModeHandler.isSwitching ? Qt.WaitCursor : Qt.PointingHandCursor
                                        enabled: !slamModeHandler.isSwitching
                                        onClicked: {
                                            let nextMode = slamToggleCard.isMapping ? "localization" : "mapping"
                                            slamModeHandler.requestSwitch(nextMode)
                                        }
                                    }
                                }
                            }
                        }

                        // Status text
                        Text {
                            text: slamModeHandler.isSwitching
                                  ? "Switching mode…"
                                  : (slamToggleCard.isMapping
                                     ? "Building map — click to switch to localization"
                                     : "Localizing on saved map — click to resume mapping")
                            color: "#6b7280"
                            font.pixelSize: 10
                            font.italic: true
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
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
