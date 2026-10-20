import QtQuick 2.6
import Sailfish.Silica 1.0

ToolbarBase {
    id: root

    readonly property var buttonCut: buttonCut
    readonly property var buttonImage: buttonImage
    readonly property var buttonAudio: buttonAudio
    readonly property var buttonCollage: buttonCollage
    readonly property var buttonFile: buttonFile 

    property var selectedButton: buttonCut

    lineOnTop: false

    MainToolbarItem {
        id: buttonCut

        icon: "../symbols/icon-m-cut.svg"
        selected: root.selectedButton == buttonCut

        onClicked: root.selectedButton = buttonCut
    }

    MainToolbarItem {
        id: buttonImage

        icon: "image://theme/icon-m-ambience"
        selected: root.selectedButton == buttonImage

        onClicked: root.selectedButton = buttonImage
    }

    MainToolbarItem {
        id: buttonAudio

        icon: "image://theme/icon-m-sounds"
        selected: root.selectedButton == buttonAudio

        onClicked: root.selectedButton = buttonAudio
    }

    MainToolbarItem {
        id: buttonCollage

        icon: "../symbols/icon-m-timeline.svg"
        selected: root.selectedButton == buttonCollage

        onClicked: root.selectedButton = buttonCollage
    }

    MainToolbarItem {
        id: buttonFile

        icon: "image://theme/icon-m-file-document-light"
        selected: root.selectedButton == buttonFile

        onClicked: root.selectedButton = buttonFile
    }
}
