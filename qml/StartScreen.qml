import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import QtCore

Rectangle {
    id: root
    color: "#1a1e24"

    Settings {
        category: "SlamTopics"
        property alias mapTopic: slamMapTopicField.text
        property alias scanTopic: slamScanTopicField.text
        property alias mappingEnabledParam: slamMappingEnabledParamField.text
        property alias tfTopic: slamTfTopicField.text
        property alias robotFrame: slamRobotFrameField.text
        property alias initialPoseTopic: slamInitPoseTopicField.text
        property alias useSimTime: slamUseSimTimeCheck.checked
        property alias initialUncertainty: slamInitUncertaintyField.text
    }

    Settings {
        id: folderSettings
        category: "LastFolders"
        property string lastSlamFolder: ""
        property string lastMapFolder: ""
        property string lastYamlFolder: ""
        property string lastProjectSaveFolder: ""
        property string lastOpenProjectFolder: ""
        property string lastGateImageFolder: ""
    }

    signal startEditor(bool isSlamMode, string projectName, string projectPath, string mapFile, string yamlFile, string resolution, string mapTopic, string scanTopic, string mappingParam, string tfTopic, string robotFrame, bool useSimTime)
    property bool isEditMode: true

    // ROS CONFIGURATION POPUP (FLOATING ON TOP)
    Popup {
        id: rosConfigPopup
        anchors.centerIn: parent
        width: 650
        height: 480
        modal: true
        focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        
        function resetSlamFields() {
            slamMapTopicField.text = "/map"
            slamScanTopicField.text = "/scan"
            slamTfTopicField.text = "/tf"
            slamRobotFrameField.text = "base_link"
            slamMappingEnabledParamField.text = "/slam_toolbox/mapping_enabled"
            slamInitPoseTopicField.text = "/initialpose"
            slamUseSimTimeCheck.checked = false
            slamInitUncertaintyField.text = "1.5"
        }

        background: Rectangle { 
            color: "#1e2329" 
            radius: 8 
            border.color: "#38404a"
            border.width: 1
            
            // Header for popup
            Rectangle {
                id: popupHeader
                width: parent.width; height: 50; color: "#252b32"; radius: 8
                Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 10; color: "#252b32" } // hide bottom radius
                Text { 
                    anchors.left: parent.left; 
                    anchors.leftMargin: 20; 
                    anchors.verticalCenter: parent.verticalCenter;
                    text: "⚙️ ROS & TOPIC CONFIGURATION"; 
                    color: "white"; font.pixelSize: 15; font.bold: true 
                }

                Rectangle {
                    anchors.right: closeBtn.left
                    anchors.rightMargin: 15
                    anchors.verticalCenter: parent.verticalCenter
                    width: 110; height: 26; color: "#374151"; radius: 4
                    Text { anchors.centerIn: parent; text: "Reset to default"; color: "white"; font.pixelSize: 11; font.bold: true }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: rosConfigPopup.resetSlamFields()
                    }
                }
                
                Text {
                    id: closeBtn
                    anchors.right: parent.right
                    anchors.rightMargin: 16
                    anchors.verticalCenter: parent.verticalCenter
                    text: "✕"
                    color: "#9ca3af"
                    font.pixelSize: 18
                    MouseArea { 
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: rosConfigPopup.close() 
                    }
                }
            }
        }

        onClosed: {
            // Sync with projectManager if it exists
            if (projectManager) {
                projectManager.mapTopic = slamMapTopicField.text
                projectManager.scanTopic = slamScanTopicField.text
                projectManager.tfTopic = slamTfTopicField.text
                projectManager.robotFrame = slamRobotFrameField.text
                projectManager.mappingEnabledParam = slamMappingEnabledParamField.text
                projectManager.initialPoseTopic = slamInitPoseTopicField.text
                
                // Update global settings for persistence
                if (window.slamSettings) {
                    window.slamSettings.mapTopic = slamMapTopicField.text
                    window.slamSettings.scanTopic = slamScanTopicField.text
                    window.slamSettings.tfTopic = slamTfTopicField.text
                    window.slamSettings.robotFrame = slamRobotFrameField.text
                    window.slamSettings.mappingEnabledParam = slamMappingEnabledParamField.text
                    window.slamSettings.initialPoseTopic = slamInitPoseTopicField.text
                    window.slamSettings.useSimTime = slamUseSimTimeCheck.checked
                    window.slamSettings.initialUncertainty = parseFloat(slamInitUncertaintyField.text) || 1.5
                }
                
                // Restart ROS to check topic availability on first page
                robotHandler.start_ros(projectManager.scanTopic, projectManager.mapTopic, projectManager.tfTopic, projectManager.robotFrame, projectManager.initialPoseTopic, projectManager.useSimTime)
            }
        }

        contentItem: ColumnLayout {
            anchors.fill: parent
            anchors.margins: 0
            spacing: 0

            Item { Layout.preferredHeight: 60 } // Spacer for header

            GridLayout {
                columns: 2
                Layout.fillWidth: true
                Layout.margins: 24
                rowSpacing: 20
                columnSpacing: 24

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4
                    Text { text: "Map Topic"; color: "#a0a5ab"; font.pixelSize: 11; font.bold: true }
                    TextField {
                        id: slamMapTopicField
                        Layout.fillWidth: true
                        text: "/map"
                        color: "white"
                        font.pixelSize: 13
                        padding: 8
                        background: Rectangle { color: "#111827"; radius: 4; border.color: "#38404a" }
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4
                    Text { text: "Laser Scan Topic"; color: "#a0a5ab"; font.pixelSize: 11; font.bold: true }
                    TextField {
                        id: slamScanTopicField
                        Layout.fillWidth: true
                        text: "/scan"
                        color: "white"
                        font.pixelSize: 13
                        padding: 8
                        background: Rectangle { color: "#111827"; radius: 4; border.color: "#38404a" }
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4
                    Text { text: "TF Topic"; color: "#a0a5ab"; font.pixelSize: 11; font.bold: true }
                    TextField {
                        id: slamTfTopicField
                        Layout.fillWidth: true
                        text: "/tf"
                        color: "white"
                        font.pixelSize: 13
                        padding: 8
                        selectByMouse: true
                        background: Rectangle { color: "#111827"; radius: 4; border.color: "#38404a" }
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4
                    Text { text: "Robot Base Frame"; color: "#a0a5ab"; font.pixelSize: 11; font.bold: true }
                    TextField {
                        id: slamRobotFrameField
                        Layout.fillWidth: true
                        text: "base_link"
                        color: "white"
                        font.pixelSize: 13
                        padding: 8
                        background: Rectangle { color: "#111827"; radius: 4; border.color: "#38404a" }
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.columnSpan: 2
                    spacing: 4
                    Text { text: "Mapping Enabled Param (Slam Toolbox)"; color: "#a0a5ab"; font.pixelSize: 11; font.bold: true }
                    TextField {
                        id: slamMappingEnabledParamField
                        Layout.fillWidth: true
                        text: "/slam_toolbox/mapping_enabled"
                        color: "white"
                        font.pixelSize: 13
                        padding: 8
                        background: Rectangle { color: "#111827"; radius: 4; border.color: "#38404a" }
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.columnSpan: 1
                    spacing: 4
                    Text { text: "Initial Pose Topic"; color: "#a0a5ab"; font.pixelSize: 11; font.bold: true }
                    TextField {
                        id: slamInitPoseTopicField
                        Layout.fillWidth: true
                        text: "/initialpose"
                        color: "white"
                        font.pixelSize: 13
                        padding: 8
                        background: Rectangle { color: "#111827"; radius: 4; border.color: "#38404a" }
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.columnSpan: 1
                    spacing: 4
                    Text { text: "Init Uncertainty (m)"; color: "#a0a5ab"; font.pixelSize: 11; font.bold: true }
                    TextField {
                        id: slamInitUncertaintyField
                        Layout.fillWidth: true
                        text: "1.5"
                        color: "white"
                        font.pixelSize: 13
                        padding: 8
                        validator: DoubleValidator { bottom: 0.1; top: 10.0 }
                        background: Rectangle { color: "#111827"; radius: 4; border.color: "#38404a" }
                    }
                }

                CheckBox {
                    id: slamUseSimTimeCheck
                    Layout.columnSpan: 2
                    text: "Use Simulation Time"
                    font.pixelSize: 12
                    font.bold: true
                    palette.windowText: "white"
                    checked: false
                }
            }
        }
    }

    Rectangle {
        width: 750
        height: 600
        anchors.centerIn: parent
        color: "#1e2329"
        radius: 8
        border.color: "#2a3038"
        border.width: 1

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 24
            spacing: 16

            RowLayout {
                Layout.fillWidth: true
                Layout.bottomMargin: 8
                
                Item { Layout.fillWidth: true }
                Text {
                    text: "Occupancy Map Editor"
                    color: "white"
                    font.pixelSize: 24
                    font.bold: true
                }
                Item { Layout.fillWidth: true }
                
                Rectangle {
                    width: 40; height: 40; color: "#252b32"; radius: 4
                    Text { anchors.centerIn: parent; text: "⚙️"; font.pixelSize: 20; color: "white" }
                    MouseArea { anchors.fill: parent; onClicked: rosConfigPopup.open() }
                }
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
                        Text { anchors.centerIn: parent; text: "SLAM MODE"; color: "white"; font.bold: true; font.pixelSize: 13 }
                        MouseArea { anchors.fill: parent; onClicked: root.isEditMode = false }
                    }
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        color: root.isEditMode ? "#2e6bf0" : "transparent"
                        radius: 4
                        Text { anchors.centerIn: parent; text: "MAP EDIT MODE"; color: "white"; font.bold: true; font.pixelSize: 13 }
                        MouseArea { anchors.fill: parent; onClicked: root.isEditMode = true }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: "#2a3038"
                Layout.topMargin: 8
                Layout.bottomMargin: 8
            }

            StackLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                currentIndex: root.isEditMode ? 1 : 0

                // SLAM MODE TAB
                RowLayout {
                    spacing: 20
                    Layout.fillWidth: true
                    Layout.fillHeight: true

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
                                text: "Create New Project"
                                color: "white"
                                font.pixelSize: 16
                                font.bold: true
                                Layout.alignment: Qt.AlignHCenter
                            }

                            ColumnLayout {
                                spacing: 4
                                Layout.fillWidth: true
                                Text { text: "Project Name"; color: "#80858b"; font.pixelSize: 11 }
                                TextField {
                                    id: slamProjNameField
                                    Layout.fillWidth: true
                                    placeholderText: "e.g. MySlamProject"
                                    color: "white"
                                    font.pixelSize: 13
                                    background: Rectangle { color: "#1a1e24"; radius: 4; border.color: "#38404a" }
                                }
                            }

                            Text {
                                text: "Start a new SLAM session. The map will be saved as you explore."
                                color: "#a0a5ab"
                                font.pixelSize: 12
                                wrapMode: Text.WordWrap
                                Layout.fillWidth: true
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
                                    if (slamProjNameField.text === "") {
                                        errorDialog.text = "Project Name is required."
                                        errorDialog.open()
                                        return
                                    }
                                    slamFolderDialog.open()
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
                                text: "Resume SLAM Session"
                                color: "white"
                                font.pixelSize: 16
                                font.bold: true
                                Layout.alignment: Qt.AlignHCenter
                            }

                            Text {
                                text: "Open an existing .mepro project to continue SLAM mapping."
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
                                onClicked: meproSlamDialog.open()
                                HoverHandler { cursorShape: Qt.PointingHandCursor }
                            }
                        }
                    }
                }

                // EDIT MODE TAB
                RowLayout {
                    spacing: 20
                    Layout.fillWidth: true
                    Layout.fillHeight: true

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
                                text: "Create New Project"
                                color: "white"
                                font.pixelSize: 16
                                font.bold: true
                                Layout.alignment: Qt.AlignHCenter
                            }

                            ColumnLayout {
                                spacing: 4
                                Layout.fillWidth: true
                                Text { text: "Project Name"; color: "#80858b"; font.pixelSize: 11 }
                                TextField {
                                    id: projNameField
                                    Layout.fillWidth: true
                                    placeholderText: "e.g. MyProject"
                                    color: "white"
                                    font.pixelSize: 13
                                    background: Rectangle { color: "#1a1e24"; radius: 4; border.color: "#38404a" }
                                    HoverHandler { cursorShape: Qt.IBeamCursor }
                                }
                            }

                            ColumnLayout {
                                spacing: 4
                                Layout.fillWidth: true
                                Text { text: "Base Map (.pgm)"; color: "#80858b"; font.pixelSize: 11 }
                                RowLayout {
                                    TextField {
                                        id: mapPathField
                                        Layout.fillWidth: true
                                        placeholderText: "Select .pgm file..."
                                        color: "white"
                                        font.pixelSize: 12
                                        background: Rectangle { color: "#1a1e24"; radius: 4; border.color: "#38404a" }
                                        HoverHandler { cursorShape: Qt.IBeamCursor }
                                    }
                                    Button {
                                        text: "Browse"
                                        palette.buttonText: "white"
                                        background: Rectangle { color: "#374151"; radius: 4 }
                                        onClicked: mapFileDialog.open()
                                        HoverHandler { cursorShape: Qt.PointingHandCursor }
                                    }
                                }
                            }

                            ColumnLayout {
                                spacing: 4
                                Layout.fillWidth: true
                                Text { text: "Meta Data (.yaml)"; color: "#80858b"; font.pixelSize: 11 }
                                RowLayout {
                                    TextField {
                                        id: yamlPathField
                                        Layout.fillWidth: true
                                        placeholderText: "Select .yaml file..."
                                        color: "white"
                                        font.pixelSize: 12
                                        background: Rectangle { color: "#1a1e24"; radius: 4; border.color: "#38404a" }
                                    }
                                    Button {
                                        text: "Browse"
                                        palette.buttonText: "white"
                                        background: Rectangle { color: "#374151"; radius: 4 }
                                        onClicked: yamlFileDialog.open()
                                    }
                                }
                            }

                            ColumnLayout {
                                spacing: 4
                                Layout.fillWidth: true
                                Text { text: "Map Resolution (m/px)"; color: "#80858b"; font.pixelSize: 11 }
                                TextField {
                                    id: resField
                                    Layout.fillWidth: true
                                    text: "0.05"
                                    color: "white"
                                    font.pixelSize: 13
                                    background: Rectangle { color: "#1a1e24"; radius: 4; border.color: "#38404a" }
                                }
                            }

                            Item { Layout.fillHeight: true }

                            Button {
                                Layout.fillWidth: true
                                height: 40
                                text: "Create Project"
                                font.bold: true
                                palette.buttonText: "white"
                                background: Rectangle { color: "#4b5563"; radius: 4 }
                                onClicked: {
                                    if (projNameField.text === "" || mapPathField.text === "" || yamlPathField.text === "") {
                                        errorDialog.text = "All fields are required."
                                        errorDialog.open()
                                        return
                                    }
                                    folderDialog.open()
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
                                onClicked: meproFileDialog.open()
                            }
                        }
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

    FolderDialog {
        id: slamFolderDialog
        title: "Select Directory to Create SLAM Project"
        currentFolder: folderSettings.lastSlamFolder !== "" ? folderSettings.lastSlamFolder : StandardPaths.writableLocation(StandardPaths.HomeLocation)
        onAccepted: {
            folderSettings.lastSlamFolder = currentFolder
            if(projectManager.createProject(slamProjNameField.text, currentFolder.toString(), "", "", "0.05", slamMapTopicField.text, slamScanTopicField.text, slamMappingEnabledParamField.text, slamTfTopicField.text, slamRobotFrameField.text)) {
                root.startEditor(true, projectManager.projectName, projectManager.projectPath, "", "", "0.05", projectManager.mapTopic, projectManager.scanTopic, projectManager.mappingEnabledParam, projectManager.tfTopic, projectManager.robotFrame, slamUseSimTimeCheck.checked)
            }
        }
    }

    FileDialog {
        id: mapFileDialog
        title: "Please choose a PGM file"
        nameFilters: ["PGM files (*.pgm)"]
        currentFolder: folderSettings.lastMapFolder !== "" ? folderSettings.lastMapFolder : StandardPaths.writableLocation(StandardPaths.HomeLocation)
        onAccepted: {
            folderSettings.lastMapFolder = currentFolder
            mapPathField.text = selectedFile.toString().replace("file://", "")
        }
    }

    FileDialog {
        id: yamlFileDialog
        title: "Please choose a YAML file"
        nameFilters: ["YAML files (*.yaml *.yml)"]
        currentFolder: folderSettings.lastYamlFolder !== "" ? folderSettings.lastYamlFolder : StandardPaths.writableLocation(StandardPaths.HomeLocation)
        onAccepted: {
            folderSettings.lastYamlFolder = currentFolder
            yamlPathField.text = selectedFile.toString().replace("file://", "")
        }
    }

    FolderDialog {
        id: folderDialog
        title: "Select Directory to Save Project"
        currentFolder: folderSettings.lastProjectSaveFolder !== "" ? folderSettings.lastProjectSaveFolder : StandardPaths.writableLocation(StandardPaths.HomeLocation)
        onAccepted: {
            folderSettings.lastProjectSaveFolder = currentFolder
            if (projectManager.createProject(projNameField.text, currentFolder.toString(), mapPathField.text, yamlPathField.text, resField.text, slamMapTopicField.text, slamScanTopicField.text, slamMappingEnabledParamField.text, slamTfTopicField.text, slamRobotFrameField.text)) {
                root.startEditor(false, projectManager.projectName, projectManager.projectPath, projectManager.getOriginalMap(), projectManager.getOriginalYaml(), projectManager.getResolution().toString(), slamMapTopicField.text, slamScanTopicField.text, slamMappingEnabledParamField.text, slamTfTopicField.text, slamRobotFrameField.text, slamUseSimTimeCheck.checked)
            }
        }
    }

    FileDialog {
        id: meproFileDialog
        title: "Open Map Project"
        nameFilters: ["Map Project (*.mepro)"]
        currentFolder: folderSettings.lastOpenProjectFolder !== "" ? folderSettings.lastOpenProjectFolder : StandardPaths.writableLocation(StandardPaths.HomeLocation)
        onAccepted: {
            folderSettings.lastOpenProjectFolder = currentFolder
            if (projectManager.openProject(selectedFile.toString().replace("file://", ""))) {
                root.startEditor(false, projectManager.projectName, projectManager.projectPath, projectManager.getOriginalMap(), projectManager.getOriginalYaml(), projectManager.getResolution().toString(), slamMapTopicField.text, slamScanTopicField.text, slamMappingEnabledParamField.text, slamTfTopicField.text, slamRobotFrameField.text, slamUseSimTimeCheck.checked)
            }
        }
    }

    FileDialog {
        id: meproSlamDialog
        title: "Open SLAM Map Project"
        nameFilters: ["Map Project (*.mepro)"]
        currentFolder: folderSettings.lastOpenProjectFolder !== "" ? folderSettings.lastOpenProjectFolder : StandardPaths.writableLocation(StandardPaths.HomeLocation)
        onAccepted: {
            folderSettings.lastOpenProjectFolder = currentFolder
            if (projectManager.openProject(selectedFile.toString().replace("file://", ""))) {
                root.startEditor(true, projectManager.projectName, projectManager.projectPath, projectManager.getOriginalMap(), projectManager.getOriginalYaml(), projectManager.getResolution().toString(), slamMapTopicField.text, slamScanTopicField.text, slamMappingEnabledParamField.text, slamTfTopicField.text, slamRobotFrameField.text, slamUseSimTimeCheck.checked)
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
