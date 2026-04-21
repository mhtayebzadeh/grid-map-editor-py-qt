import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 16

        RowLayout {
            Text { text: "GATES"; color: "#9ca3af"; font.pixelSize: 12; font.bold: true; font.letterSpacing: 1.2; Layout.fillWidth: true }
            Rectangle {
                width: 24; height: 24; color: "#2563eb"; radius: 12
                Text { anchors.centerIn: parent; text: "+"; color: "white"; font.pixelSize: 16; font.bold: true }
            }
        }

        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            
            ListView {
                anchors.fill: parent
                model: ListModel {
                    ListElement { label: "Main Entrance (1)" }
                    ListElement { label: "Emergency Exit (2)" }
                }
                delegate: Rectangle {
                    width: ListView.view.width; height: 40 + 8; color: "transparent"
                    Rectangle {
                        anchors.fill: parent; anchors.margins: 4; color: "#1f2937"; radius: 6
                        RowLayout {
                            anchors.fill: parent; anchors.margins: 8
                            Text { text: model.label; color: "#d1d5db"; font.pixelSize: 13 }
                            Item { Layout.fillWidth: true }
                        }
                    }
                }
            }
        }
    }
}
