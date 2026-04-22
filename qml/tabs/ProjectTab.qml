import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root
    signal saveRequested()

    property string projectName: ""
    property string projectPath: ""
    property string robotTopic: ""
    property string mapTopic: ""
    property string mappingParam: ""
    property bool autoSave: autoSaveCb.checked

    ColumnLayout {
        anchors.fill: parent
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

        Text { text: "SLAM CONFIGURATION"; color: "#9ca3af"; font.pixelSize: 12; font.bold: true; font.letterSpacing: 1.2 }

        ColumnLayout {
            spacing: 4
            Layout.fillWidth: true
            Text { text: "Robot Position Topic"; color: "#71717a"; font.pixelSize: 11; font.bold: true }
            Rectangle { 
                Layout.fillWidth: true; height: 32; color: "#111827"; radius: 4; border.color: "#1f2937"
                clip: true
                TextEdit { 
                    anchors.verticalCenter: parent.verticalCenter; anchors.left: parent.left; anchors.right: parent.right; anchors.margins: 8
                    text: root.robotTopic; color: "#e4e4e7"; font.pixelSize: 12; readOnly: true; selectByMouse: true; selectionColor: "#2563eb"
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
                TextEdit { 
                    anchors.verticalCenter: parent.verticalCenter; anchors.left: parent.left; anchors.right: parent.right; anchors.margins: 8
                    text: root.mapTopic; color: "#e4e4e7"; font.pixelSize: 12; readOnly: true; selectByMouse: true; selectionColor: "#2563eb"
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
                TextEdit { 
                    anchors.verticalCenter: parent.verticalCenter; anchors.left: parent.left; anchors.right: parent.right; anchors.margins: 8
                    text: root.mappingParam; color: "#e4e4e7"; font.pixelSize: 12; readOnly: true; selectByMouse: true; selectionColor: "#2563eb"
                }
            }
        }


        RowLayout {
            spacing: 8
            CheckBox {
                id: autoSaveCb
                text: "Auto-save changes (Every 20s)"
                checked: true
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

