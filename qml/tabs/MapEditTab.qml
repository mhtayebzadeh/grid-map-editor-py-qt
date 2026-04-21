import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: mapEditTab

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 16

        Text { text: "TOOLS"; color: "#9ca3af"; font.pixelSize: 12; font.bold: true; font.letterSpacing: 1.2 }

        RowLayout {
            spacing: 8
            Rectangle { Layout.fillWidth: true; height: 36; color: root.currentMapEditTool === "obstacle" ? "#2563eb" : "#1f2937"; radius: 6
                Text { anchors.centerIn: parent; text: "⬛ Obstacle"; color: root.currentMapEditTool === "obstacle" ? "white" : "#d1d5db"; font.pixelSize: 13 }
                MouseArea { anchors.fill: parent; onClicked: root.currentMapEditTool = "obstacle" }
            }
            Rectangle { Layout.fillWidth: true; height: 36; color: root.currentMapEditTool === "free" ? "#2563eb" : "#1f2937"; radius: 6
                Text { anchors.centerIn: parent; text: "⬜ Free"; color: root.currentMapEditTool === "free" ? "white" : "#d1d5db"; font.pixelSize: 13 }
                MouseArea { anchors.fill: parent; onClicked: root.currentMapEditTool = "free" }
            }
            Rectangle { Layout.fillWidth: true; height: 36; color: root.currentMapEditTool === "revert" ? "#2563eb" : "#1f2937"; radius: 6
                Text { anchors.centerIn: parent; text: "▧ Revert"; color: root.currentMapEditTool === "revert" ? "white" : "#d1d5db"; font.pixelSize: 13; font.bold: true }
                MouseArea { anchors.fill: parent; onClicked: root.currentMapEditTool = "revert" }
            }
        }

        ColumnLayout {
            spacing: 4
            RowLayout {
                Text { text: "Brush Size"; color: "#9ca3af"; font.pixelSize: 12; font.bold: true; Layout.fillWidth: true }
                Text { text: Math.round(brushSlider.value) + " px"; color: "#d1d5db"; font.pixelSize: 12; font.bold: true }
            }
            Slider { 
                id: brushSlider; Layout.fillWidth: true; from: 1; to: 50; 
                value: root.brushSize
                onValueChanged: root.brushSize = Math.round(value)
            }
        }

        Rectangle { Layout.fillWidth: true; height: 1; color: "#374151"; Layout.topMargin: 8; Layout.bottomMargin: 8 }

        Item { Layout.fillHeight: true }

        Rectangle {
            Layout.fillWidth: true; height: 40; color: "#16a34a"; radius: 6
            Text { anchors.centerIn: parent; text: "Save Merged Map"; color: "white"; font.pixelSize: 14; font.bold: true }
            MouseArea { 
                anchors.fill: parent
                onClicked: {
                    root.requestSaveMapEdits();
                }
            }
        }
    }
}
