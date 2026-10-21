import QtQuick 2.6
import Sailfish.Silica 1.0

ToolbarItemBase {
    id: root

    property alias icon: iconItem.source

    contentItem: Icon {
        id: iconItem

        width: Theme.iconSizeMedium
        height: width
        smooth: true
        color: root.elementColor
    }
}
