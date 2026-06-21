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

        Text {
            text: "More tools coming soon..."
            color: "#6b7280"
            font.pixelSize: 10
            font.italic: true
            Layout.alignment: Qt.AlignHCenter
        }
    }
}
