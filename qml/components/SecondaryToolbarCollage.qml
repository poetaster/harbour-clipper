import QtQuick 2.6

ToolbarBase {
    id: root

    readonly property var buttonStoryline: buttonStoryline
    readonly property var buttonSlideshow: buttonSlideshow
    readonly property var buttonSubtitles: buttonSubtitles
    readonly property var buttonSplitScreen: buttonSplitScreen
    readonly property var buttonThumbnail: buttonThumbnail

    property var selectedButton: buttonStoryline

    signal scroll()

    SecondaryToolbarItem {
        id: buttonStoryline

        text: qsTr("Storyline")
        selected: root.selectedButton == buttonStoryline

        onClicked: {
            root.selectedButton = buttonStoryline
            root.scroll()
        }
    }

    SecondaryToolbarItem {
        id: buttonSlideshow

        text: qsTr("Slideshow")
        selected: root.selectedButton == buttonSlideshow

        onClicked: {
            root.selectedButton = buttonSlideshow
            root.scroll()
        }
    }

    SecondaryToolbarItem {
        id: buttonSubtitles

        text: qsTr("Subtitles")
        selected: root.selectedButton == buttonSubtitles

        onClicked: root.selectedButton = buttonSubtitles
    }

    SecondaryToolbarItem {
        id: buttonSplitScreen

        text: qsTr("Split-screen")
        selected: root.selectedButton == buttonSplitScreen

        onClicked: root.selectedButton = buttonSplitScreen
    }

    SecondaryToolbarItem {
        id: buttonThumbnail

        text: qsTr("Thumbnail")
        selected: root.selectedButton == buttonThumbnail

        onClicked: root.selectedButton = buttonThumbnail
    }
}
