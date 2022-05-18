import QtQuick 2.6
import Sailfish.Silica 1.0
import io.thp.pyotherside 1.5

Page {
    id: page
    allowedOrientations: Orientation.All

    // values transmitted from FirstPage.qml
    property string homeDirectory
    property string origMediaFilePath
    property string origMediaFileName
    property string origMediaFolderPath
    property string origMediaName
    property string origMediaType
    property var tempMediaFolderPath
    property var inputPathPy
    property string ffmpeg_staticPath
    property string origCodecVideo
    property string origCodecAudio
    property var origFrameRate
    property bool showHintSavingSubtitles

    // variables for saving
    property bool validatorNameOverwrite : false
    property var estimatedFolder
    property var processedPercent : 0


    Banner {
        id: banner
    }

    // autostart functions
    Component.onCompleted: {
        // set incoming variables to items
        var setSliderFramerate = parseInt(origFrameRate)
        if (setSliderFramerate > 30) { idSliderTargetFramerate.value = 25 }
        else { idSliderTargetFramerate.value = parseInt(origFrameRate) }

        // get container infos from the original file
        if (origMediaType.indexOf('mp4') !== -1 ) {
            idComboBoxFileExtension.currentIndex = 0
        }
        else if (origMediaType.indexOf('mkv') !== -1) {
            idComboBoxFileExtension.currentIndex = 1
        }
        else if (origMediaType.indexOf('flv') !== -1) {
            idComboBoxFileExtension.currentIndex = 2
        }
        else if (origMediaType.indexOf('mpeg') !== -1) {
            idComboBoxFileExtension.currentIndex = 3
        }
        else if (origMediaType.indexOf('avi') !== -1) {
            idComboBoxFileExtension.currentIndex = 4
        }
        else if (origMediaType.indexOf('mov') !== -1) {
            idComboBoxFileExtension.currentIndex = 5
        }

        else if (origMediaType.indexOf('m4v') !== -1) {
            idComboBoxFileExtension.currentIndex = 6
        }
        else {
            idComboBoxFileExtension.currentIndex = 0
        }
    }



    Python {
        id: py
        Component.onCompleted: {
            // Which Pythonfile will be used?
            importModule('videox', function () {});

            // Handlers = Signals to do something in QML whith received Infos from pyotherside.send
            setHandler('tempFilesDeleted', function(i) {
                console.log("temp files deleted: " + i)
            });
            setHandler('fileIsSaved', function(i) {
                idSaveButtonRunningIndicator.running = false
                idSaveButton.enabled = true
                page.backNavigation = true
                pageStack.pop()
            });
            setHandler('debugPythonLogs', function(i) {
                //console.log(i)
            });
            setHandler('progressPercentageSave', function( percentDone ) {
                processedPercent = percentDone
            });
        }

        // file operations
        function saveFunction() {
            // UI response
            idSaveButtonRunningIndicator.running = true
            idSaveButton.enabled = false

            // get path and name
            if (idComboBoxTargetFolder.currentIndex === 0) { var folderSavePath = origMediaFolderPath }
            else if (idComboBoxTargetFolder.currentIndex === 1) { folderSavePath = homeDirectory + "/Videos" + "/Clipper/" }
            else if (idComboBoxTargetFolder.currentIndex === 2) { folderSavePath = homeDirectory + "/Videos/" }
            else if (idComboBoxTargetFolder.currentIndex === 3) { folderSavePath = homeDirectory + "/Downloads/" }
            else if (idComboBoxTargetFolder.currentIndex === 4) { folderSavePath = homeDirectory + "/" }

            var newFileName = idFilenameNew.text.toString()
            var newFileType = idComboBoxFileExtension.value.toString().substring(1)
            var savePath = folderSavePath + newFileName + idComboBoxFileExtension.value.toString()
            inputPathPy = ( "/" + inputPathPy.replace(/^(file:\/{3})|(qrc:\/{2})|(http:\/{2})/,"") )

            // get other infos
            if (idComboBoxTargetCodecVideo.currentIndex !== 0) {
                // Patch: for strange values use standard
                var needFrameChange = "true"
                var newVideoFrameRate = idSliderTargetFramerate.value.toString()
            }
            else {
                needFrameChange = "false"
                newVideoFrameRate = origFrameRate
            }

            // get video codec
            if (idComboBoxTargetCodecVideo.currentIndex === 0) { var newVideoCodec = "copy" }
            else { newVideoCodec = idComboBoxTargetCodecVideo.value.toString() }

            // get audio codec
            if (idComboBoxTargetCodecAudio.currentIndex === 0) { var newAudioCodec = "copy" }
            else { newAudioCodec = idComboBoxTargetCodecAudio.value.toString() }

            // Patch: mpeg
            if ( (idComboBoxCodexAutoManual.currentIndex === 0) || (idComboBoxCodexAutoManual.currentIndex === 1 && (newFileType === "mpeg" || newFileType === "avi" || newFileType === "mov")) ) { var ignoreAllCodecs = "true" }
            else { ignoreAllCodecs = "false" }

            console.log(needFrameChange)
            call("videox.saveFile", [ ffmpeg_staticPath, inputPathPy, savePath, tempMediaFolderPath, newFileName, newFileType, ignoreAllCodecs, newAudioCodec, newVideoCodec, newVideoFrameRate, needFrameChange ])
        }

        onError: {
            // when an exception is raised, this error handler will be called
            //console.log('python error: ' + traceback);
        }
        onReceived: {
            // asychronous messages from Python arrive here; done there via pyotherside.send()
            //console.log('got message from python: ' + data);
        }
    } // end Python


    SilicaFlickable {
        id: listView
        anchors.fill: parent
        contentHeight: columnSaveAs.height
        VerticalScrollDecorator {}


        Column {
            id: columnSaveAs
            width: page.width

            PageHeader {
                title:  qsTr("Save as")
                width: parent.width
                Item {
                    visible: (idSaveButtonRunningIndicator.running === true)
                    anchors.right: parent.right
                    anchors.left: parent.left
                    height: Theme.paddingMedium
                    Rectangle {
                        height: parent.height
                        width: parent.width / 100 * processedPercent
                        color: Theme.highlightColor
                    }
                }
            }

            Row {
                id: idFilenameContainerRow
                width: parent.width
                TextField {
                    id: idFilenameNew
                    label: (validatorNameOverwrite === true) ? qsTr("overwrite...") : ""
                    width: parent.width / 6 * 3.5
                    anchors.top: parent.top
                    anchors.topMargin: Theme.paddingMedium
                    y: Theme.paddingSmall
                    inputMethodHints: Qt.ImhNoPredictiveText
                    text: origMediaName + "_edit"
                    EnterKey.onClicked: idFilenameNew.focus = false
                    validator: RegExpValidator { regExp: /^[^<>'\"/;*:`#?]*$/ } // negative list
                    onTextChanged: {
                        checkOverwriting()
                    }
                }
                ComboBox {
                    id: idComboBoxFileExtension
                    width: parent.width / 6 * 1.5
                    menu: ContextMenu {
                        MenuItem {
                            text: ".mp4"
                            font.pixelSize: Theme.fontSizeExtraSmall
                        }
                        MenuItem {
                            text: ".mkv"
                            font.pixelSize: Theme.fontSizeExtraSmall
                        }
                        MenuItem {
                            text: ".gif"
                            font.pixelSize: Theme.fontSizeExtraSmall
                        }
                        MenuItem {
                            text: ".mpeg"
                            font.pixelSize: Theme.fontSizeExtraSmall
                        }
                        MenuItem {
                            text: ".avi"
                            font.pixelSize: Theme.fontSizeExtraSmall
                        }
                        MenuItem {
                            text: ".mov"
                            font.pixelSize: Theme.fontSizeExtraSmall
                        }
                        MenuItem {
                            text: ".m4v"
                            font.pixelSize: Theme.fontSizeExtraSmall
                        }
                    }
                }
                IconButton {
                    id: idSaveButton
                    visible: (idFilenameNew.text.length > 0) ? true : false
                    width: parent.width / 6
                    height: Theme.itemSizeSmall
                    icon.source: "../symbols/icon-m-apply.svg"
                    icon.width: Theme.iconSizeMedium
                    icon.height: Theme.iconSizeMedium
                    onClicked: {
                        page.backNavigation = false
                        py.saveFunction()
                    }
                    BusyIndicator {
                        id: idSaveButtonRunningIndicator
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.horizontalCenter: parent.horizontalCenter
                        size: BusyIndicatorSize.Medium
                    }
                }
            }

            ComboBox {
                id: idComboBoxTargetFolder
                width: parent.width
                label: qsTr("Folder")
                menu: ContextMenu {
                    MenuItem {
                        text: qsTr("Original")
                        font.pixelSize: Theme.fontSizeExtraSmall
                    }
                    MenuItem {
                        text: "Videos/Clipper"
                        font.pixelSize: Theme.fontSizeExtraSmall
                    }
                    MenuItem {
                        text: "Videos"
                        font.pixelSize: Theme.fontSizeExtraSmall
                    }
                    MenuItem {
                        text: "Downloads"
                        font.pixelSize: Theme.fontSizeExtraSmall
                    }
                    MenuItem {
                        text: "/home"
                        font.pixelSize: Theme.fontSizeExtraSmall
                    }
                }
                onCurrentItemChanged: {
                    checkOverwriting()
                }
            }

            ComboBox {
                id: idComboBoxCodexAutoManual
                width: parent.width
                label: qsTr("Codecs")
                menu: ContextMenu {
                    MenuItem {
                        text: qsTr("auto")
                        font.pixelSize: Theme.fontSizeExtraSmall
                    }
                    MenuItem {
                        text: "manual"
                        font.pixelSize: Theme.fontSizeExtraSmall
                    }
                }
            }

            ComboBox {
                id: idComboBoxTargetCodecAudio
                visible: idComboBoxCodexAutoManual.currentIndex === 1 && (idComboBoxFileExtension.currentIndex !== 3 && idComboBoxFileExtension.currentIndex !== 4 && idComboBoxFileExtension.currentIndex !== 5)
                width: parent.width
                label: qsTr("Audio")
                description: (currentIndex !== 0) ? qsTr("Re-encoding, this may take a while.") : ""
                menu: ContextMenu {
                    MenuItem {
                        text: qsTr("COPY") + " (" + origCodecAudio + ")"
                        font.pixelSize: Theme.fontSizeExtraSmall
                    }
                    MenuItem {
                        text: "aac"
                        font.pixelSize: Theme.fontSizeExtraSmall
                    }
                    MenuItem {
                        text: "mp3"
                        font.pixelSize: Theme.fontSizeExtraSmall
                    }
                    MenuItem {
                        enabled: idComboBoxFileExtension.currentIndex !== 0
                        text: "flac"
                        font.pixelSize: Theme.fontSizeExtraSmall
                    }
                }
            }

            ComboBox {
                id: idComboBoxTargetCodecVideo
                visible: idComboBoxTargetCodecAudio.visible
                width: parent.width
                label: qsTr("Video")
                description: (currentIndex !== 0) ? qsTr("Re-encoding, this may take a while.") : ""
                menu: ContextMenu {
                    MenuItem {
                        text: qsTr("COPY") + " (" + origCodecVideo + ")"
                        font.pixelSize: Theme.fontSizeExtraSmall
                    }
                    MenuItem {
                        text: "h264"
                        font.pixelSize: Theme.fontSizeExtraSmall
                    }
                    MenuItem {
                        text: "mpeg2video"
                        font.pixelSize: Theme.fontSizeExtraSmall
                    }
                    MenuItem {
                        enabled: idComboBoxFileExtension.currentIndex !== 0
                        text: "ffv1"
                        font.pixelSize: Theme.fontSizeExtraSmall
                    }
                }
            }

            Slider {
                id: idSliderTargetFramerate
                visible: idComboBoxTargetCodecAudio.visible
                width: parent.width
                leftMargin: Theme.paddingLarge + Theme.paddingSmall
                rightMargin: Theme.paddingLarge + Theme.paddingSmall
                stepSize: 1
                minimumValue: 1
                maximumValue: 50
                label: value + " " + "frames/s"
            }

            Label {
                x: Theme.paddingLarge * 1.2
                visible: (idComboBoxTargetCodecAudio.visible) ? false : true
                width: parent.width - 2*x
                font.pixelSize: Theme.fontSizeExtraSmall
                wrapMode: Text.Wrap
                text: qsTr("Re-encoding may take a while. For quick saving use MANUAL codec with COPY for video and audio.") + "\n"
            }

            Label {
                x: Theme.paddingLarge * 1.2
                visible: showHintSavingSubtitles === true
                width: parent.width - 2*x
                font.pixelSize: Theme.fontSizeExtraSmall
                wrapMode: Text.Wrap
                text: qsTr("Subtitles will be lost in case of saving in different container.") + "\n"
            }


            Item {
                width: parent.width
                height: 2*Theme.paddingLarge
            }

        } // end Column
    } // end Silica Flickable


    function checkOverwriting() {
        if (idComboBoxTargetFolder.currentIndex === 0) {
            estimatedFolder = origMediaFolderPath
        }
        else if (idComboBoxTargetFolder.currentIndex === 1) {
            estimatedFolder = homeDirectory + "/Videos" + "/Clipper/"
        }
        else if (idComboBoxTargetFolder.currentIndex === 2) {
            estimatedFolder = homeDirectory + "/Videos/"
        }
        else if (idComboBoxTargetFolder.currentIndex === 3) {
            estimatedFolder = homeDirectory + "/Downloads/"
        }
        else if (idComboBoxTargetFolder.currentIndex === 4) {
            estimatedFolder = homeDirectory + "/"
        }

        if ( (estimatedFolder === origMediaFolderPath ) && (origMediaName === idFilenameNew.text) && (("."+origMediaType) === (idComboBoxFileExtension.value.toString())) ) {
            validatorNameOverwrite = true
        }
        else {
            validatorNameOverwrite = false
        }
    }
}
