import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: rootTab

    property var toolNames: ["pencil", "line", "poly", "eraser"]
    property var colors: ["#ef4444", "#3b82f6", "#22c55e", "#eab308", "#a855f7", "#ec4899", "#f97316"]

    ScrollView {
        anchors.fill: parent
        contentWidth: availableWidth
        clip: true

        ColumnLayout {
            width: parent.width
            anchors.margins: 16
            spacing: 16

        Text { text: "TOOLS"; color: "#9ca3af"; font.pixelSize: 12; font.bold: true; font.letterSpacing: 1.2 }

        RowLayout {
            spacing: 8
            Repeater {
                model: ["✏️ Pencil", "⧹ Line", "⬡ Poly", "▧ Eraser"]
                Rectangle {
                    Layout.fillWidth: true; height: 36; 
                    color: root.currentLayerTool === rootTab.toolNames[index] ? "#2563eb" : "#1f2937"; radius: 6
                    Text { 
                        anchors.centerIn: parent; text: modelData; 
                        color: root.currentLayerTool === rootTab.toolNames[index] ? "white" : "#d1d5db"; 
                        font.pixelSize: 12; font.bold: root.currentLayerTool === rootTab.toolNames[index] 
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.currentLayerTool = rootTab.toolNames[index]
                    }
                }
            }
        }

        ColumnLayout {
            spacing: 4
            RowLayout {
                Text { text: "Brush Size"; color: "#9ca3af"; font.pixelSize: 12; font.bold: true; Layout.fillWidth: true }
                Text { text: Math.round(brushSlider.value); color: "#d1d5db"; font.pixelSize: 12; font.bold: true }
            }
            Slider { 
                id: brushSlider; Layout.fillWidth: true; from: 1; to: 50; 
                value: root.brushSize
                onValueChanged: root.brushSize = Math.round(value)
            }
        }
        
        ColumnLayout {
            spacing: 4
            RowLayout {
                Text { text: "Draw Value (Grayscale)"; color: "#9ca3af"; font.pixelSize: 12; font.bold: true; Layout.fillWidth: true }
                Text { text: Math.round(drawValSlider.value); color: "#d1d5db"; font.pixelSize: 12; font.bold: true }
            }
            Slider { 
                id: drawValSlider; Layout.fillWidth: true; from: 0; to: 255; 
                value: root.layerDrawValue
                onValueChanged: root.layerDrawValue = Math.round(value)
            }
        }
        
        Rectangle { Layout.fillWidth: true; height: 1; color: "#374151"; Layout.topMargin: 8; Layout.bottomMargin: 8 }

        RowLayout {
            Text { text: "LAYERS"; color: "#9ca3af"; font.pixelSize: 12; font.bold: true; font.letterSpacing: 1.2; Layout.fillWidth: true }
            Rectangle {
                width: 24; height: 24; color: "#2563eb"; radius: 12
                Text { anchors.centerIn: parent; text: "+"; color: "white"; font.pixelSize: 16; font.bold: true }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        let newColor = rootTab.colors[layersModel.count % rootTab.colors.length];
                        layersModel.append({ 
                            "layerId": "layer_" + Date.now(), 
                            "name": "Layer No." + (layersModel.count + 1), 
                            "colorStr": newColor, 
                            "opacity": 0.70, 
                            "layerVisible": true 
                        });
                        root.activeLayerId = layersModel.get(layersModel.count - 1).layerId;
                    }
                }
            }
        }

            ListView {
                id: layerList
                Layout.fillWidth: true
                Layout.preferredHeight: Math.max(100, contentHeight)
                interactive: false // Let the outer ScrollView handle scrolling

                model: layersModel
                spacing: 4
                delegate: Rectangle {
                    width: ListView.view.width; height: 70
                    color: root.activeLayerId === model.layerId ? "transparent" : "transparent"
                    border.color: root.activeLayerId === model.layerId ? "#2e6bf0" : "#38404a"
                    border.width: 1
                    radius: 6

                    Rectangle {
                        anchors.fill: parent
                        color: root.activeLayerId === model.layerId ? "#2e6bf0" : "transparent"
                        opacity: 0.1
                        radius: 6
                    }
                    
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.activeLayerId = model.layerId
                    }

                    ColumnLayout {
                        anchors.fill: parent; anchors.margins: 8; spacing: 4
                        RowLayout {
                            Layout.fillWidth: true; spacing: 12
                            
                            // Visibility Toggle
                            Text { 
                                text: model.layerVisible ? "👁" : "✖"
                                color: model.layerVisible ? "white" : "#6b7280"
                                font.pixelSize: 14
                                MouseArea {
                                    anchors.fill: parent; anchors.margins: -5
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: layersModel.setProperty(index, "layerVisible", !model.layerVisible)
                                }
                            }

                            // Color Block
                            Rectangle { width: 16; height: 16; color: model.colorStr; radius: 4 }
                            
                            // Name Edit
                            TextInput { 
                                text: model.name; color: "white"; font.pixelSize: 13; font.bold: true; Layout.fillWidth: true 
                                onEditingFinished: layersModel.setProperty(index, "name", text)
                                HoverHandler { cursorShape: Qt.IBeamCursor }
                            }
                            
                            // Delete
                            Text { 
                                text: "🗑"; color: "#9ca3af"; font.pixelSize: 14
                                MouseArea {
                                    anchors.fill: parent; anchors.margins: -5
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        layersModel.remove(index);
                                        if (layersModel.count > 0 && root.activeLayerId === model.layerId) {
                                            root.activeLayerId = layersModel.get(Math.max(0, index - 1)).layerId;
                                        }
                                    }
                                }
                            }
                        }
                        
                        // Opacity Slider
                        RowLayout {
                            Layout.fillWidth: true
                            Text { text: "OPACITY"; color: "#6b7280"; font.pixelSize: 10; font.bold: true }
                            Slider {
                                Layout.fillWidth: true
                                from: 0.0; to: 1.0; value: model.opacity
                                onValueChanged: layersModel.setProperty(index, "opacity", value)
                            }
                        }
                    }
                }
            }
        }
    }
}
