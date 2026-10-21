import QtQuick 2.6
import Sailfish.Silica 1.0
import io.thp.pyotherside 1.5

// more details FILE
Item{
    id:funs
    signal filenameChanged(string msg)

    Item {
        id: idToolsRowFileShare
        visible: (mainToolbar.buttonFile.selected && fileToolbar.buttonShare.selected )
        x: spacerLandscapeLowerToolRow
        width: mainToolbar.width - 2 * spacerLandscapeLowerToolRow
        height: idFileShareColumn.height

        Item {
            width: mainToolbar.x
            height: standardDetailItemHeight
        }
        Column {
            id: idFileShareColumn
            width: parent.width
            DetailItem {
                label: qsTr("CURRENT FILE")
                value:  ( idMediaPlayer.source.toString().length <=0 ) ? "none" : ( "/" + idMediaPlayer.source.toString().replace(/^(file:\/{3})|(qrc:\/{2})|(http:\/{2}|)/,"") )
            }
            DetailItem {
                label: qsTr("size")
                value: tmpVideoFileSize+ " MB"
            }
            DetailItem {
                label: qsTr("duration")
                value: new Date(idMediaPlayer.duration).toISOString().substr(11,8)
            }
        }
    }

    Item {
        id: idToolsRowFileInfo
        visible: (mainToolbar.buttonFile.selected && fileToolbar.buttonInfo.selected )
        x: spacerLandscapeLowerToolRow
        width: mainToolbar.width - 2 * spacerLandscapeLowerToolRow
        height: idFileInfoColumn.height

        Item {
            width: mainToolbar.x
            height: standardDetailItemHeight
        }
        Column {
            id: idFileInfoColumn
            width: parent.width
            DetailItem {
                label: qsTr("SOURCE FILE")
                value: origMediaFileName
            }
            DetailItem {
                label: qsTr("size")
                value: origFileSize+ " MB"
            }
            DetailItem {
                label: qsTr("duration")
                value: origVideoDuration
            }
            DetailItem {
                label: qsTr("container")
                value: origMediaType
            }
            DetailItem {
                label: qsTr("width")
                value: origVideoWidth
            }
            DetailItem {
                label: qsTr("height")
                value: origVideoHeight
            }
            DetailItem {
                label: qsTr("display-ratio")
                value: origDAR
            }
            DetailItem {
                label: qsTr("pixel-ratio")
                value: origSAR
            }
            DetailItem {
                label: qsTr("rotation")
                value: origVideoRotation
            }
            DetailItem {
                label: qsTr("frames/s")
                value: origFrameRate
            }
            DetailItem {
                label: qsTr("video-codec")
                value: origCodecVideo
            }
            DetailItem {
                label: qsTr("pixel-format")
                value: origPixelFormat
            }
            DetailItem {
                label: qsTr("audio-codec")
                value: origCodecAudio
            }
            DetailItem {
                label: qsTr("samplerate")
                value: origAudioSamplerate + " Hz"
            }
            DetailItem {
                label: qsTr("layout")
                value: origAudioLayout
            }
        }
    }

    Row {
        id: idToolsRowFileRename
        visible: (mainToolbar.buttonFile.selected && fileToolbar.buttonRename.selected )
        x: spacerLandscapeLowerToolRow
        width: mainToolbar.width - 2 * spacerLandscapeLowerToolRow
        height: idToolsRowFileRenameText.height

        Item {
            width: mainToolbar.x
            height: standardDetailItemHeight
        }
        Item {
            width: parent.width / 5 * 4
            height: parent.height //standardDetailItemHeight

            TextField {
                id: idToolsRowFileRenameText
                enabled: ( finishedLoading === true )
                visible: ( mainToolbar.buttonFile.selected && fileToolbar.buttonRename.selected )
                width: parent.width
                textTopMargin: Theme.paddingLarge
                inputMethodHints: Qt.ImhNoPredictiveText
                font.pixelSize: Theme.fontSizeExtraSmall
                text: origMediaName
                validator: RegExpValidator { regExp: /^[^<>'\"/;*:`#?]*$/ } // negative list
                EnterKey.onClicked: {
                    if (idToolsRowFileRenameText.text < 1 || idToolsRowFileRenameText.text === "") {
                        idToolsRowFileRenameText.text = origMediaName
                    }
                    idToolsRowFileRenameText.focus = false
                    funs.filenameChanged(idToolsRowFileRenameText.text)
                }
                Label {
                    anchors.top: parent.bottom
                    anchors.topMargin: Theme.paddingSmall
                    font.pixelSize: Theme.fontSizeExtraSmall
                    color: Theme.secondaryColor
                    text: qsTr("new filename")
                }
            }
        }
        Item {
            width: parent.width / 5
            height: parent.height

            Label {
                width: parent.width
                color: Theme.highlightColor
                anchors.bottom: parent.verticalCenter
                horizontalAlignment: Text.AlignHCenter
                truncationMode: TruncationMode.Elide
                font.pixelSize: Theme.fontSizeExtraSmall
                text: "." + origMediaType
            }
        }
    }

    /*
Item {
    visible: (mainToolbar.buttonFile.selected && fileToolbar.buttonDelete.selected )
    width: parent.width
    height: standardDetailItemHeight
}*/
    IconButton {
        id: confirmButton
        anchors {
            left: idToolsRowFileRename.right
            leftMargin: Theme.paddingLarge

        }
        enabled: true//idToolsRowFileRenameText.text != ""

        height: Theme.itemSizeSmall
        width: parent.width / 7
        icon.source: "image://theme/icon-m-accept"

        onClicked:  {
            console.log("hi there")
            funs.filenameChanged(idToolsRowFileRenameText.text)
        }
         Rectangle {
            z: -1
            anchors.centerIn: parent
            anchors.verticalCenterOffset: -Theme.paddingSmall / 2.5
            anchors.horizontalCenterOffset: Theme.paddingSmall / 5
            width: parent.icon.width * 1/0.9
            height: width
            radius: width/2
            color: (parent.enabled) ? Theme.rgba(Theme.primaryColor, 0.2) : "transparent"
        }
    }
}
