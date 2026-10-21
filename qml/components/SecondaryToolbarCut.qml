import QtQuick 2.6

ToolbarBase {
    id: root

    readonly property var buttonTrim: buttonTrim
    readonly property var buttonInsert: buttonInsert
    readonly property var buttonCrop: buttonCrop
    readonly property var buttonPad: buttonPad
    readonly property var buttonResize: buttonResize
    readonly property var buttonSpeed: buttonSpeed

    property var selectedButton: buttonTrim

    SecondaryToolbarItem {
        id: buttonTrim

        text: qsTr("Trim")
        selected: root.selectedButton == buttonTrim

        onClicked: root.selectedButton = buttonTrim
    }

    SecondaryToolbarItem {
        id: buttonInsert

        text: qsTr("Insert")
        selected: root.selectedButton == buttonInsert

        onClicked: root.selectedButton = buttonInsert
    }

    SecondaryToolbarItem {
        id: buttonCrop

        text: qsTr("Crop")
        selected: root.selectedButton == buttonCrop

        onClicked: root.selectedButton = buttonCrop
    }

    SecondaryToolbarItem {
        id: buttonPad

        text: qsTr("Pad")
        selected: root.selectedButton == buttonPad

        onClicked: root.selectedButton = buttonPad
    }

    SecondaryToolbarItem {
        id: buttonResize

        text: qsTr("Resize")
        selected: root.selectedButton == buttonResize

        onClicked: root.selectedButton = buttonResize
    }

    SecondaryToolbarItem {
        id: buttonSpeed

        text: qsTr("Speed")
        selected: root.selectedButton == buttonSpeed

        onClicked: root.selectedButton = buttonSpeed
    }
}