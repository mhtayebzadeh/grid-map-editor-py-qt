import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root
    visible: false
    anchors.fill: parent
    z: 1000 // Ensure it's on top of everything

    property bool isOpen: false
    
    // Dark overlay for background clicking
    Rectangle {
        id: overlay
        anchors.fill: parent
        color: "#000000"
        opacity: root.isOpen ? 0.4 : 0
        Behavior on opacity { NumberAnimation { duration: 250 } }
        
        MouseArea {
            anchors.fill: parent
            enabled: root.isOpen
            onClicked: root.isOpen = false
        }
    }

    // The actual panel
    Rectangle {
        id: panel
        width: parent.width * 0.5
        height: parent.height
        x: root.isOpen ? parent.width - width : parent.width
        color: "#111827"
        border.color: "#374151"
        border.width: 1

        // Consume all mouse clicks inside the panel to prevent closing
        MouseArea {
            anchors.fill: parent
            onClicked: {} 
        }

        Behavior on x { 
            NumberAnimation { 
                duration: 300
                easing.type: Easing.OutCubic
            } 
        }

        ColumnLayout {
            anchors.fill: parent
            spacing: 0

            // Header
            Rectangle {
                Layout.fillWidth: true
                height: 50
                color: "#1f2937"
                
                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 20
                    anchors.rightMargin: 20
                    
                    Text {
                        text: "System Status & Logs"
                        color: "white"
                        font.pixelSize: 16
                        font.bold: true
                    }
                    
                    Item { Layout.fillWidth: true }
                    
                    Rectangle {
                        width: 32; height: 32; color: "transparent"; radius: 4
                        Text { anchors.centerIn: parent; text: "✕"; color: "#9ca3af"; font.pixelSize: 18 }
                        MouseArea { 
                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                            onClicked: root.isOpen = false 
                        }
                    }
                }
            }

            // Terminal Area (Logs)
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.margins: 15
                color: "#0a0a0a"
                radius: 4
                border.color: "#374151"
                clip: true

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 0

                    // Toolbar for terminal
                    Rectangle {
                        Layout.fillWidth: true
                        height: 35
                        color: "#1a1a1a"
                        
                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 8
                            
                            Text {
                                text: "TERMINAL"
                                color: "#4ade80"
                                font.pixelSize: 10
                                font.bold: true
                                font.letterSpacing: 1
                            }
                            
                            Item { Layout.fillWidth: true }
                            
                            Button {
                                text: "Copy All"
                                flat: true
                                contentItem: Text {
                                    text: "Copy All"
                                    color: "#9ca3af"
                                    font.pixelSize: 11
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                }
                                background: Rectangle { 
                                    color: parent.hovered ? "#374151" : "transparent"
                                    radius: 4
                                }
                                onClicked: clipboardHelper.copyText(terminalOutput.text)
                            }

                            Button {
                                text: "Clear"
                                flat: true
                                contentItem: Text {
                                    text: "Clear"
                                    color: "#9ca3af"
                                    font.pixelSize: 11
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                }
                                background: Rectangle { 
                                    color: parent.hovered ? "#374151" : "transparent"
                                    radius: 4
                                }
                                onClicked: terminalOutput.clear()
                            }
                        }
                    }

                    ScrollView {
                        id: logScrollView
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        
                        TextArea {
                            id: terminalOutput
                            readOnly: true
                            selectByMouse: true
                            color: "#d1d5db"
                            font.family: "Monospace"
                            font.pixelSize: 12
                            background: null
                            wrapMode: TextArea.Wrap
                            textFormat: TextArea.RichText
                            padding: 10
                            
                            // Auto-scroll to bottom
                            onTextChanged: {
                                cursorPosition = text.length
                            }
                        }
                        
                        ScrollBar.vertical: ScrollBar {
                            id: vBar
                            policy: ScrollBar.AsNeeded
                            width: 10
                            background: Rectangle { color: "transparent" }
                            contentItem: Rectangle {
                                color: "#374151"
                                radius: 5
                                opacity: parent.hovered || parent.pressed ? 0.8 : 0.4
                            }
                        }
                    }
                }
            }

            // Topic Status Area (Simplified for single glance)
            Rectangle {
                Layout.fillWidth: true
                height: 130
                color: "#1f2937"
                Layout.margins: 15
                Layout.topMargin: 0
                radius: 4

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 8

                    Text {
                        text: "ROS TOPICS STATUS"
                        color: "#9ca3af"
                        font.pixelSize: 10
                        font.bold: true
                        font.letterSpacing: 0.5
                    }

                    ColumnLayout {
                        id: topicGrid
                        Layout.fillWidth: true
                        spacing: 6

                        Repeater {
                            model: topicModel
                            delegate: RowLayout {
                                Layout.fillWidth: true
                                spacing: 10
                                
                                Rectangle {
                                    width: 10; height: 10; radius: 5
                                    color: model.isActive ? "#10b981" : "#ef4444"
                                    
                                    SequentialAnimation on opacity {
                                        running: model.isActive
                                        loops: Animation.Infinite
                                        NumberAnimation { from: 1; to: 0.3; duration: 600 }
                                        NumberAnimation { from: 0.3; to: 1; duration: 600 }
                                    }
                                }

                                Text {
                                    text: model.name
                                    color: "white"
                                    font.pixelSize: 12
                                    font.bold: true
                                    Layout.preferredWidth: 80
                                }

                                Text {
                                    text: model.topic
                                    color: "#9ca3af"
                                    font.pixelSize: 11
                                    Layout.fillWidth: true
                                    elide: Text.ElideMiddle
                                }
                                
                                Text {
                                    text: model.isActive ? "ACTIVE" : "INACTIVE"
                                    color: model.isActive ? "#10b981" : "#ef4444"
                                    font.pixelSize: 9
                                    font.bold: true
                                }
                            }
                        }
                    }
                    
                    Item { Layout.fillHeight: true }
                }
            }
        }
    }

    ListModel {
        id: topicModel
    }

    function addLog(msg, type="info") {
        let now = new Date()
        let timeStr = now.getHours().toString().padStart(2, '0') + ":" + 
                      now.getMinutes().toString().padStart(2, '0') + ":" + 
                      now.getSeconds().toString().padStart(2, '0')
        
        let color = "#d1d5db"
        if (type === "error") color = "#ef4444"
        else if (type === "warning") color = "#fbbf24"
        else if (type === "success") color = "#10b981"
        
        let logLine = "<font color='#6b7280'>[" + timeStr + "]</font> <font color='" + color + "'>" + msg + "</font><br>"
        terminalOutput.append(logLine)
    }

    function updateTopics(topicList) {
        topicModel.clear()
        for(let i=0; i<topicList.length; i++) {
            topicModel.append({
                "name": topicList[i].name,
                "topic": topicList[i].topic,
                "isActive": topicList[i].isActive || false
            })
        }
    }

    onIsOpenChanged: {
        if (isOpen) {
            root.visible = true
        } else {
            closeTimer.start()
        }
    }

    Timer {
        id: closeTimer
        interval: 350
        onTriggered: if (!root.isOpen) root.visible = false
    }
    
    Component.onCompleted: {
        addLog("System initialized.", "info")
        addLog("Welcome to Occupancy Grid Map Editor.", "info")
    }
}
