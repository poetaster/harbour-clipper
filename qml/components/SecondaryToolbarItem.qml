import QtQuick 2.6
import Sailfish.Silica 1.0

ToolbarItemBase {
    id: root

    property alias text: label.text

    invert: true

    contentItem: Label {
        id: label

        color: root.elementColor
        font.pixelSize: Theme.fontSizeSmall
    }   
}
