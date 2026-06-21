import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: root
    width: 150
    height: content.implicitHeight + 30
    color: "#1f2937"
    radius: 8
    border.color: "#374151"
    border.width: 1
    visible: false

    property bool isSelectingInitPose: false
    property bool isTouchPanMode: false

    signal zoomInRequested()
    signal zoomOutRequested()

    ColumnLayout {
        id: content
        anchors.fill: parent
        anchors.margins: 15
        spacing: 12

        Text {
            text: "Tools"
            color: "white"
            font.pixelSize: 14
            font.bold: true
        }

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: "#374151"
        }

        Button {
            id: initPoseBtn
            Layout.fillWidth: true
            height: 50
            text: root.isSelectingInitPose ? "Cancel Selection" : "Set Initial Pose"
            
            contentItem: RowLayout {
                spacing: 5
                Text {
                    text: root.isSelectingInitPose ? "Cancel Selection" : "Set Initial Pose"
                    color: "white"
                    font.pixelSize: 12
                    font.bold: true
                }
            }

            background: Rectangle {
                color: root.isSelectingInitPose ? "#ef4444" : (parent.hovered ? "#374151" : "#111827")
                radius: 4
                border.color: root.isSelectingInitPose ? "#f87171" : "#374151"
            }

            onClicked: {
                root.isSelectingInitPose = !root.isSelectingInitPose
                if (root.isSelectingInitPose) {
                    statusPanel.addLog("Click on the map to set initial pose. Right-click to cancel.", "info")
                }
            }
            HoverHandler { cursorShape: Qt.PointingHandCursor }
        }

        Button {
            id: touchPanBtn
            Layout.fillWidth: true
            height: 50
            text: root.isTouchPanMode ? "Disable Touch Pan" : "Enable Touch Pan"
            
            contentItem: RowLayout {
                spacing: 5
                Text {
                    text: root.isTouchPanMode ? "Disable Touch Pan" : "Enable Touch Pan"
                    color: "white"
                    font.pixelSize: 12
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                    Layout.fillWidth: true
                }
            }

            background: Rectangle {
                color: root.isTouchPanMode ? "#3b82f6" : (parent.hovered ? "#374151" : "#111827")
                radius: 4
                border.color: root.isTouchPanMode ? "#60a5fa" : "#374151"
            }

            onClicked: {
                root.isTouchPanMode = !root.isTouchPanMode
            }
            HoverHandler { cursorShape: Qt.PointingHandCursor }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Button {
                Layout.fillWidth: true
                height: 40
                
                contentItem: Text {
                    text: "-"
                    color: "white"
                    font.pixelSize: 20
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                background: Rectangle {
                    color: parent.hovered ? "#374151" : "#111827"
                    radius: 4
                    border.color: "#374151"
                }

                onClicked: root.zoomOutRequested()
                HoverHandler { cursorShape: Qt.PointingHandCursor }
            }

            Button {
                Layout.fillWidth: true
                height: 40
                
                contentItem: Text {
                    text: "+"
                    color: "white"
                    font.pixelSize: 20
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                background: Rectangle {
                    color: parent.hovered ? "#374151" : "#111827"
                    radius: 4
                    border.color: "#374151"
                }

                onClicked: root.zoomInRequested()
                HoverHandler { cursorShape: Qt.PointingHandCursor }
            }
        }

        Text {
            text: "More tools coming soon..."
            color: "#6b7280"
            font.pixelSize: 10
            font.italic: true
            Layout.alignment: Qt.AlignHCenter
        }
    }
}
