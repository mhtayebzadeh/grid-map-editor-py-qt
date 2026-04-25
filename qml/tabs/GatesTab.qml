import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs

Item {
    id: gatesTab


    FileDialog {
        id: editImageFileDialog
        title: "Select Gate Image"
        nameFilters: ["Image files (*.png *.jpg *.jpeg)", "All files (*)"]
        
        property var targetModel: null
        property int targetIndex: -1
        property string catId: ""
        onAccepted: {
            if (targetModel && targetIndex >= 0) {
                let gateName = targetModel.get(targetIndex).name;
                let gateId = targetModel.get(targetIndex).gateId;
                let oldImagePath = targetModel.get(targetIndex).imageFile;
                let newPath = projectManager.copyGateImage(selectedFile.toString(), catId, gateName, gateId, oldImagePath);
                targetModel.setProperty(targetIndex, "imageFile", newPath);
            }
        }
    }

    // A small overlay to show if we are in "add gate" mode
    Rectangle {
        anchors.fill: parent
        color: "#1f2937"
        opacity: 0.9
        visible: root.pendingGateModel !== null
        z: 100
        
        ColumnLayout {
            anchors.centerIn: parent
            spacing: 12
            Text { text: "Click on the map to place the gate"; color: "white"; font.pixelSize: 14; font.bold: true }
            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                width: 100; height: 32; color: "#ef4444"; radius: 4
                Text { anchors.centerIn: parent; text: "Cancel"; color: "white"; font.pixelSize: 13; font.bold: true }
                MouseArea { 
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.pendingGateModel = null 
                }
            }
        }
    }

    ScrollView {
        anchors.fill: parent
        contentWidth: availableWidth
        clip: true

        ColumnLayout {
            width: parent.width
            anchors.margins: 16
            spacing: 24

            Repeater {
                model: root.gateCategories
                delegate: ColumnLayout {
                    id: categoryDelegate
                    property var catModel: modelData.model
                    property string catName: modelData.name
                    property string catIcon: modelData.icon
                    property string catId: modelData.id
                    
                    Layout.fillWidth: true
                    spacing: 8
                    
                    // Category Header
                    RowLayout {
                        Layout.fillWidth: true
                        Text { text: categoryDelegate.catIcon; color: "#d1d5db"; font.pixelSize: 16 }
                        Text { text: categoryDelegate.catName; color: "white"; font.pixelSize: 14; font.bold: true; Layout.fillWidth: true }
                        
                        Rectangle {
                            width: 28; height: 28; color: "#2563eb"; radius: 14
                            Text { anchors.centerIn: parent; text: "+"; color: "white"; font.pixelSize: 18; font.bold: true }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.pendingGateCategoryId = categoryDelegate.catId
                                    root.pendingGateModel = categoryDelegate.catModel
                                }
                            }
                        }
                    }

                    // Divider
                    Rectangle { Layout.fillWidth: true; height: 1; color: "#374151"; visible: categoryDelegate.catModel.count === 0 }

                    // Gates List
                    Repeater {
                        model: categoryDelegate.catModel
                        delegate: Rectangle {
                            id: gateRect
                            property int gateIndex: index
                            property bool isExpanded: root.activeGateId === model.gateId
                            
                            Layout.fillWidth: true
                            Layout.preferredHeight: isExpanded ? expandedLayout.implicitHeight + 16 : 40
                            Layout.alignment: Qt.AlignTop
                            color: isExpanded ? "#2d3748" : "#1f2937"
                            radius: 6
                            clip: true
                            border.color: isExpanded ? "#3b82f6" : "#374151"
                            border.width: 1

                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    if (root.activeGateId === model.gateId) root.activeGateId = "";
                                    else root.activeGateId = model.gateId;
                                }
                            }

                            ColumnLayout {
                                id: expandedLayout
                                anchors.top: parent.top
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.margins: 8
                                spacing: 12

                                // Header
                                RowLayout {
                                    Layout.fillWidth: true
                                    Text { text: "ID: " + model.gateId; color: "#9ca3af"; font.pixelSize: 10; font.family: "monospace" }
                                    Text { text: model.name; color: "white"; font.pixelSize: 13; font.bold: true; Layout.fillWidth: true; elide: Text.ElideRight }
                                    Text { text: gateRect.isExpanded ? "▲" : "▼"; color: "#9ca3af"; font.pixelSize: 10 }
                                }

                                // Details (visible if expanded)
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    visible: gateRect.isExpanded
                                    spacing: 8
                                    
                                    // Swallow clicks so it doesn't trigger collapse
                                    MouseArea { anchors.fill: parent; onClicked: {} }
                                    
                                    RowLayout {
                                        Layout.fillWidth: true
                                        Text { text: "Name"; color: "#9ca3af"; font.pixelSize: 11; Layout.preferredWidth: 60 }
                                        Rectangle {
                                            Layout.fillWidth: true; height: 28; color: "#111827"; radius: 4; border.color: "#374151"
                                            TextInput {
                                                anchors.fill: parent; anchors.margins: 6; color: "white"; font.pixelSize: 12
                                                text: model.name
                                                onEditingFinished: {
                                                    categoryDelegate.catModel.setProperty(gateRect.gateIndex, "name", text)
                                                    let newPath = projectManager.copyGateImage(model.imageFile, categoryDelegate.catId, text, model.gateId, model.imageFile);
                                                    if (newPath !== model.imageFile) {
                                                        categoryDelegate.catModel.setProperty(gateRect.gateIndex, "imageFile", newPath);
                                                    }
                                                }
                                            }
                                        }
                                    }
                                    
                                    RowLayout {
                                        Layout.fillWidth: true
                                        Text { text: "X (m)"; color: "#9ca3af"; font.pixelSize: 11; Layout.preferredWidth: 60 }
                                        Rectangle {
                                            Layout.fillWidth: true; height: 28; color: "#111827"; radius: 4; border.color: "#374151"
                                            TextInput {
                                                anchors.fill: parent; anchors.margins: 6; color: "white"; font.pixelSize: 12
                                                text: Number(model.xPos).toFixed(2)
                                                validator: DoubleValidator {}
                                                onEditingFinished: categoryDelegate.catModel.setProperty(gateRect.gateIndex, "xPos", parseFloat(text) || 0.0)
                                            }
                                        }
                                        Text { text: "Y (m)"; color: "#9ca3af"; font.pixelSize: 11 }
                                        Rectangle {
                                            Layout.fillWidth: true; height: 28; color: "#111827"; radius: 4; border.color: "#374151"
                                            TextInput {
                                                anchors.fill: parent; anchors.margins: 6; color: "white"; font.pixelSize: 12
                                                text: Number(model.yPos).toFixed(2)
                                                validator: DoubleValidator {}
                                                onEditingFinished: categoryDelegate.catModel.setProperty(gateRect.gateIndex, "yPos", parseFloat(text) || 0.0)
                                            }
                                        }
                                    }
                                    
                                    RowLayout {
                                        Layout.fillWidth: true
                                        Text { text: "Desc"; color: "#9ca3af"; font.pixelSize: 11; Layout.preferredWidth: 60 }
                                        Rectangle {
                                            Layout.fillWidth: true; height: 28; color: "#111827"; radius: 4; border.color: "#374151"
                                            TextInput {
                                                anchors.fill: parent; anchors.margins: 6; color: "white"; font.pixelSize: 12
                                                text: model.description
                                                onEditingFinished: categoryDelegate.catModel.setProperty(gateRect.gateIndex, "description", text)
                                            }
                                        }
                                    }
                                    
                                    RowLayout {
                                        Layout.fillWidth: true
                                        Text { text: "Image"; color: "#9ca3af"; font.pixelSize: 11; Layout.preferredWidth: 60 }
                                        RowLayout {
                                            Layout.fillWidth: true
                                            Rectangle {
                                                Layout.fillWidth: true; height: 28; color: "#111827"; radius: 4; border.color: "#374151"
                                                TextInput {
                                                    anchors.fill: parent; anchors.margins: 6; color: "white"; font.pixelSize: 12
                                                    text: model.imageFile
                                                    readOnly: true; clip: true
                                                }
                                            }
                                            Rectangle {
                                                width: 28; height: 28; color: "#374151"; radius: 4
                                                Text { anchors.centerIn: parent; text: "..."; color: "white" }
                                                MouseArea {
                                                    anchors.fill: parent
                                                    onClicked: {
                                                        editImageFileDialog.targetModel = categoryDelegate.catModel;
                                                        editImageFileDialog.targetIndex = gateRect.gateIndex;
                                                        editImageFileDialog.catId = categoryDelegate.catId;
                                                        editImageFileDialog.open();
                                                    }
                                                }
                                            }
                                        }
                                    }
                                    
                                    // Delete button
                                    Rectangle {
                                        Layout.alignment: Qt.AlignRight
                                        width: 80; height: 28; color: "#ef4444"; radius: 4
                                        Text { anchors.centerIn: parent; text: "Delete"; color: "white"; font.pixelSize: 11; font.bold: true }
                                        MouseArea {
                                            anchors.fill: parent
                                            onClicked: {
                                                projectManager.deleteGateImage(model.imageFile)
                                                categoryDelegate.catModel.remove(gateRect.gateIndex)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            
            // Vertical Spacer to push everything to the top
            Item { Layout.fillHeight: true; Layout.fillWidth: true }
        }
    }
}
