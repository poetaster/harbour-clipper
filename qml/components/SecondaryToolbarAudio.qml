import QtQuick 2.6

ToolbarBase {
    id: root

    readonly property var buttonVolume: buttonVolume
    readonly property var buttonFilters: buttonFilters
    readonly property var buttonFade: buttonFade
    readonly property var buttonExtract: buttonExtract
    readonly property var buttonMixer: buttonMixer
    readonly property var buttonRecorder: buttonRecorder

    property var selectedButton: buttonVolume

    SecondaryToolbarItem {
        id: buttonVolume

        text: qsTr("Volume")
        selected: root.selectedButton == buttonVolume

        onClicked: root.selectedButton = buttonVolume
    }

    SecondaryToolbarItem {
        id: buttonFilters

        text: qsTr("Filters")
        selected: root.selectedButton == buttonFilters

        onClicked: root.selectedButton = buttonFilters
    }

    SecondaryToolbarItem {
        id: buttonFade

        text: qsTr("Fade")
        selected: root.selectedButton == buttonFade

        onClicked: root.selectedButton = buttonFade
    }

    SecondaryToolbarItem {
        id: buttonExtract

        text: qsTr("Extract")
        selected: root.selectedButton == buttonExtract

        onClicked: root.selectedButton = buttonExtract
    }

    SecondaryToolbarItem {
        id: buttonMixer

        text: qsTr("Mixer")
        selected: root.selectedButton == buttonMixer

        onClicked: root.selectedButton = buttonMixer
    }

    SecondaryToolbarItem {
        id: buttonRecorder

        text: qsTr("Recorder")
        selected: root.selectedButton == buttonRecorder

        onClicked: root.selectedButton = buttonRecorder
    }
}
