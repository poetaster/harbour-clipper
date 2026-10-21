import QtQuick 2.6
import Sailfish.Silica 1.0

SectionHeader {
    id: root

    property int undoNumber
    property string filename
    property bool finishedLoading

    signal undo()

    height: column.height
    
    Column {
        id: column

        anchors {
            top: parent.top
            topMargin: Theme.paddingMedium
            right: parent.right
            rightMargin: -Theme.paddingMedium
        }

        width: parent.width / 5 * 4
        height: appNameLabel.height + filePathLabel.height
        
        Label {
            id: appNameLabel
        
            width: parent.width
            anchors.right: parent.right
            horizontalAlignment: Text.AlignRight
            font.pixelSize: Theme.fontSizeLarge
            color: Theme.primaryColor
            text: qsTr("Videoworks")
        }

        Label {
            id: filePathLabel
        
            width: parent.width
            anchors.right: parent.right
            horizontalAlignment: Text.AlignRight
            font.pixelSize: Theme.fontSizeTiny
            color: Theme.primaryColor
            truncationMode: TruncationMode.Elide
            text: root.filename
        }
    }

    IconButton {
        id: idIconUndoButton
        
        anchors {
            top: parent.top
            topMargin: Theme.paddingMedium + Theme.paddingSmall/2
            left: parent.left
            leftMargin: -Theme.paddingMedium * 3
        }

        visible: root.undoNumber >= 1 && root.finishedLoading
        width: parent.width / 5 * 1
        height: appNameLabel.height + filePathLabel.height
        scale: 1.5
        
        icon {
            source: "../symbols/icon-l-undo.svg"
            width: Theme.iconSizeMedium
            height: Theme.iconSizeMedium
        }
        
        Label {
            anchors {
                horizontalCenter: parent.horizontalCenter
                verticalCenter: parent.verticalCenter
            }

            font.pixelSize: Theme.fontSizeTiny
            text: root.undoNumber
            scale: 1/1.5
        }

        onClicked: root.undo()
    }

    BusyIndicator {
        anchors {
            horizontalCenter: idIconUndoButton.horizontalCenter
            horizontalCenterOffset: -Theme.paddingSmall/3.5
            verticalCenter: idIconUndoButton.verticalCenter
            verticalCenterOffset: Theme.paddingSmall/3.5
        }

        running: !root.finishedLoading
        size: BusyIndicatorSize.Medium
    }
}
