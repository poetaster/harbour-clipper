import QtQuick 2.6

ToolbarBase {
    id: root

    readonly property var buttonShare: buttonShare
    readonly property var buttonInfo: buttonInfo
    readonly property var buttonRename: buttonRename
    readonly property var buttonDelete: buttonDelete

    property var selectedButton: buttonShare

    signal scroll()

    SecondaryToolbarItem {
        id: buttonShare

        text: qsTr("Share")
        selected: root.selectedButton == buttonShare

        onClicked: {
            root.selectedButton = buttonShare
            root.scroll()
        }
    }

    SecondaryToolbarItem {
        id: buttonInfo

        text: qsTr("Properties")
        selected: root.selectedButton == buttonInfo

        onClicked: {
            root.selectedButton = buttonInfo
            root.scroll()
        }
    }

    SecondaryToolbarItem {
        id: buttonRename

        text: qsTr("Rename")
        selected: root.selectedButton == buttonRename

        onClicked: root.selectedButton = buttonRename
    }

    SecondaryToolbarItem {
        id: buttonDelete

        text: qsTr("Delete")
        selected: root.selectedButton == buttonDelete

        onClicked: root.selectedButton = buttonDelete
    }
}
