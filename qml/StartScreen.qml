import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs

Rectangle {
    id: root
    color: "#1a1e24"

    signal startEditor(bool isSlamMode, string projectName, string projectPath, string mapFile, string yamlFile, string resolution)
    property bool isEditMode: true

    Rectangle {
        width: 750
        height: isEditMode ? 600 : 400
        anchors.centerIn: parent
        color: "#1e2329"
        radius: 8
        border.color: "#2a3038"
        border.width: 1

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 24
            spacing: 16

            Text {
                text: "Occupancy Map Editor"
                color: "white"
                font.pixelSize: 24
                font.bold: true
                Layout.alignment: Qt.AlignHCenter
                Layout.bottomMargin: 8
            }

            Rectangle {
                Layout.fillWidth: true
                height: 40
                color: "#2a3038"
                radius: 4
                
                RowLayout {
                    anchors.fill: parent
                    spacing: 0

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        color: !root.isEditMode ? "#2e6bf0" : "transparent"
                        radius: 4
                        Text {
                            anchors.centerIn: parent
                            text: "Create New Map (SLAM)"
                            color: "white"
                            font.bold: !root.isEditMode
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: root.isEditMode = false
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        color: root.isEditMode ? "#2e6bf0" : "transparent"
                        radius: 4
                        Text {
                            anchors.centerIn: parent
                            text: "Edit Existing Map"
                            color: "white"
                            font.bold: root.isEditMode
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: root.isEditMode = true
                        }
                    }
                }
            }

            RowLayout {
                visible: root.isEditMode
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 24

                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    color: "transparent"
                    border.color: "#38404a"
                    border.width: 1
                    radius: 6

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 16
                        spacing: 12

                        Text {
                            text: "Create New Project"
                            color: "white"
                            font.pixelSize: 16
                            font.bold: true
                            Layout.alignment: Qt.AlignHCenter
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 4
                            Text { text: "Project Name"; color: "#a0a5ab"; font.pixelSize: 12 }
                            TextField {
                                id: projNameField
                                Layout.fillWidth: true
                                text: "My Project"
                                color: "white"
                                background: Rectangle { color: "#252b32"; radius: 4; border.color: "#38404a" }
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 4
                            Text { text: "Base Map (.pgm)"; color: "#a0a5ab"; font.pixelSize: 12 }
                            RowLayout {
                                Layout.fillWidth: true
                                TextField {
                                    Layout.fillWidth: true
                                    text: mapFileDialog.currentFile ? mapFileDialog.currentFile.toString().split('/').pop() : "No map selected"
                                    readOnly: true
                                    color: "white"
                                    background: Rectangle { color: "#1a1e24"; radius: 4; border.color: "#38404a" }
                                }
                                Button {
                                    text: "Browse"
                                    background: Rectangle { color: "#38404a"; radius: 4 }
                                    palette.buttonText: "white"
                                    onClicked: mapFileDialog.open()
                                }
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 4
                            Text { text: "Meta Data (.yaml)"; color: "#a0a5ab"; font.pixelSize: 12 }
                            RowLayout {
                                Layout.fillWidth: true
                                TextField {
                                    Layout.fillWidth: true
                                    text: yamlFileDialog.currentFile ? yamlFileDialog.currentFile.toString().split('/').pop() : "Optional (Overrides resolution)"
                                    readOnly: true
                                    color: "white"
                                    background: Rectangle { color: "#1a1e24"; radius: 4; border.color: "#38404a" }
                                }
                                Button {
                                    text: "Browse"
                                    background: Rectangle { color: "#38404a"; radius: 4 }
                                    palette.buttonText: "white"
                                    onClicked: yamlFileDialog.open()
                                }
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 4
                            Text { text: "Map Resolution (m/px)"; color: yamlFileDialog.currentFile.toString() === "" ? "#a0a5ab" : "#4c566a"; font.pixelSize: 12 }
                            TextField {
                                id: resolutionField
                                Layout.fillWidth: true
                                text: "0.05"
                                enabled: yamlFileDialog.currentFile.toString() === ""
                                color: enabled ? "white" : "#4c566a"
                                background: Rectangle { color: enabled ? "#252b32" : "#1a1e24"; radius: 4; border.color: "#38404a" }
                            }
                        }

                        Item { Layout.fillHeight: true }

                        Button {
                            Layout.fillWidth: true
                            height: 40
                            text: "Create Project"
                            font.bold: true
                            palette.buttonText: "white"
                            background: Rectangle { color: "#4c566a"; radius: 4 }
                            onClicked: {
                                if (projNameField.text === "" || mapFileDialog.currentFile.toString() === "") {
                                    errorDialog.text = "Project Name and Base Map are required."
                                    errorDialog.open()
                                    return
                                }
                                createFolderDialog.open()
                            }
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    color: "transparent"
                    border.color: "#38404a"
                    border.width: 1
                    radius: 6

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 16
                        spacing: 16

                        Text {
                            text: "Open Existing Project"
                            color: "white"
                            font.pixelSize: 16
                            font.bold: true
                            Layout.alignment: Qt.AlignHCenter
                        }

                        Text {
                            text: "Open a .mepro file to resume editing a saved project."
                            color: "#a0a5ab"
                            font.pixelSize: 12
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignHCenter
                            horizontalAlignment: Text.AlignHCenter
                        }

                        Item { Layout.fillHeight: true }

                        Button {
                            Layout.fillWidth: true
                            height: 40
                            text: "Open .mepro Project"
                            font.bold: true
                            palette.buttonText: "white"
                            background: Rectangle { color: "#2e6bf0"; radius: 4 }
                            onClicked: meproDialog.open()
                        }
                    }
                }
            }

            ColumnLayout {
                visible: !root.isEditMode
                Layout.fillWidth: true
                spacing: 16

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4
                    Text { text: "Project Name"; color: "#a0a5ab"; font.pixelSize: 12 }
                    TextField {
                        id: slamProjNameField
                        Layout.fillWidth: true
                        text: "My Map"
                        color: "white"
                        background: Rectangle { color: "#252b32"; radius: 4; border.color: "#38404a" }
                    }
                }
                
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4
                    Text { text: "Robot Position Topic"; color: "#a0a5ab"; font.pixelSize: 12 }
                    TextField {
                        id: slamRobotTopicField
                        Layout.fillWidth: true
                        text: "/robot_pose"
                        color: "white"
                        background: Rectangle { color: "#252b32"; radius: 4; border.color: "#38404a" }
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4
                    Text { text: "Map Topic"; color: "#a0a5ab"; font.pixelSize: 12 }
                    TextField {
                        id: slamMapTopicField
                        Layout.fillWidth: true
                        text: "/map"
                        color: "white"
                        background: Rectangle { color: "#252b32"; radius: 4; border.color: "#38404a" }
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4
                    Text { text: "Mapping Enabled Param"; color: "#a0a5ab"; font.pixelSize: 12 }
                    TextField {
                        id: slamMappingEnabledParamField
                        Layout.fillWidth: true
                        text: "/slam_toolbox/mapping_enabled"
                        color: "white"
                        background: Rectangle { color: "#252b32"; radius: 4; border.color: "#38404a" }
                    }
                }

                Item { Layout.fillHeight: true }

                Button {
                    Layout.fillWidth: true
                    height: 40
                    text: "Start SLAM Mapping"
                    font.bold: true
                    palette.buttonText: "white"
                    background: Rectangle { color: "#22c55e"; radius: 4 }
                    onClicked: {
                        root.startEditor(true, slamProjNameField.text, "", "", "", "")
                    }
                }
            }

            Text {
                visible: root.isEditMode
                text: "Supports P5 (binary) PGM format."
                color: "#6b7280"
                font.pixelSize: 11
                Layout.alignment: Qt.AlignHCenter
            }
        }
    }

    FileDialog {
        id: mapFileDialog
        title: "Please choose a PGM file"
        nameFilters: ["PGM files (*.pgm)"]
    }

    FileDialog {
        id: yamlFileDialog
        title: "Please choose a YAML file"
        nameFilters: ["YAML files (*.yaml *.yml)"]
    }

    FolderDialog {
        id: createFolderDialog
        title: "Select Directory to Save Project"
        onAccepted: {
            let yamlFile = yamlFileDialog.currentFile ? yamlFileDialog.currentFile.toString() : ""
            let pgmFile = mapFileDialog.currentFile ? mapFileDialog.currentFile.toString() : ""
            
            if(projectManager.createProject(projNameField.text, currentFolder.toString(), pgmFile, yamlFile, resolutionField.text)) {
                root.startEditor(false, projectManager.projectName, projectManager.projectPath, projectManager.getOriginalMap(), projectManager.getOriginalYaml(), projectManager.getResolution().toString())
            }
        }
    }

    FileDialog {
        id: meproDialog
        title: "Open Map Edit Project"
        nameFilters: ["Map Project (*.mepro)"]
        onAccepted: {
            if (projectManager.openProject(currentFile.toString())) {
                root.startEditor(false, projectManager.projectName, projectManager.projectPath, projectManager.getOriginalMap(), projectManager.getOriginalYaml(), projectManager.getResolution().toString())
            }
        }
    }

    MessageDialog {
        id: errorDialog
        title: "Error"
        text: ""
        buttons: MessageDialog.Ok
    }

    Connections {
        target: projectManager
        function onErrorOccurred(msg) {
            errorDialog.text = msg
            errorDialog.open()
        }
    }
}
