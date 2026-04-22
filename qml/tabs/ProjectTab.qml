import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root
    signal saveRequested()

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 16

        Text { text: "OPERATION MODE"; color: "#9ca3af"; font.pixelSize: 12; font.bold: true; font.letterSpacing: 1.2 }

        Rectangle {
            Layout.fillWidth: true; height: 36
            color: "#1f2937"; radius: 6
            RowLayout {
                anchors.fill: parent; anchors.margins: 4; spacing: 4
                Rectangle { Layout.fillWidth: true; Layout.fillHeight: true; color: "transparent"; radius: 4
                    Text { anchors.centerIn: parent; text: "Mapping (SLAM)"; color: "#9ca3af"; font.pixelSize: 13 }
                }
                Rectangle { Layout.fillWidth: true; Layout.fillHeight: true; color: "#2563eb"; radius: 4
                    Text { anchors.centerIn: parent; text: "Map Editing"; color: "white"; font.pixelSize: 13; font.bold: true }
                }
            }
        }

        Rectangle { Layout.fillWidth: true; height: 1; color: "#374151"; Layout.topMargin: 8; Layout.bottomMargin: 8 }

        ColumnLayout {
            spacing: 4
            Text { text: "Project Name"; color: "#9ca3af"; font.pixelSize: 12; font.bold: true }
            Rectangle { Layout.fillWidth: true; height: 36; color: "#1f2937"; radius: 6; border.color: "#374151"
                Text { anchors.verticalCenter: parent.verticalCenter; anchors.left: parent.left; anchors.margins: 8; text: "My Project"; color: "#d1d5db"; font.pixelSize: 13 }
            }
        }

        ColumnLayout {
            spacing: 4
            Text { text: "Project Path"; color: "#9ca3af"; font.pixelSize: 12; font.bold: true }
            Rectangle { Layout.fillWidth: true; height: 36; color: "#1f2937"; radius: 6; border.color: "#374151"
                Text { anchors.verticalCenter: parent.verticalCenter; anchors.left: parent.left; anchors.margins: 8; text: "/documents/maps"; color: "#d1d5db"; font.pixelSize: 13 }
            }
        }

        RowLayout {
            spacing: 8
            CheckBox {
                id: autoSaveCb
                text: "Auto-save changes"
                contentItem: Text { text: parent.text; color: "#d1d5db"; font.pixelSize: 13; leftPadding: autoSaveCb.indicator.width + parent.spacing; verticalAlignment: Text.AlignVCenter }
            }
        }

        Item { Layout.fillHeight: true }

        Rectangle {
            Layout.fillWidth: true; height: 40; color: "#16a34a"; radius: 6
            Text { anchors.centerIn: parent; text: "Save Project"; color: "white"; font.pixelSize: 14; font.bold: true }
            MouseArea { 
                anchors.fill: parent 
                onClicked: root.saveRequested()
            }
        }
    }
}
