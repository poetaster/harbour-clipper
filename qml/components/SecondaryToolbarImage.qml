import QtQuick 2.6

ToolbarBase {
    id: root 

    readonly property var buttonEffects: buttonEffects
    readonly property var buttonFilters: buttonFilters
    readonly property var buttonColor: buttonColor
    readonly property var buttonGeometry: buttonGeometry
    readonly property var buttonText: buttonText
    readonly property var buttonOverlay: buttonOverlay

    property var selectedButton: buttonEffects

    SecondaryToolbarItem {
        id: buttonEffects

        text: qsTr("Effects")
        selected: root.selectedButton == buttonEffects

        onClicked: root.selectedButton = buttonEffects
    }

    SecondaryToolbarItem {
        id: buttonFilters

        text: qsTr("Filters")
        selected: root.selectedButton == buttonFilters

        onClicked: root.selectedButton = buttonFilters
    }

    SecondaryToolbarItem {
        id: buttonColor

        text: qsTr("Color")
        selected: root.selectedButton == buttonColor

        onClicked: root.selectedButton = buttonColor
    }

    SecondaryToolbarItem {
        id: buttonGeometry

        text: qsTr("Geometry")
        selected: root.selectedButton == buttonGeometry

        onClicked: root.selectedButton = buttonGeometry
    }

    SecondaryToolbarItem {
        id: buttonText

        text: qsTr("Text")
        selected: root.selectedButton == buttonText

        onClicked: root.selectedButton = buttonText
    }

    SecondaryToolbarItem {
        id: buttonOverlay

        text: qsTr("Overlay")
        selected: root.selectedButton == buttonOverlay

        onClicked: root.selectedButton = buttonOverlay
    }
}
