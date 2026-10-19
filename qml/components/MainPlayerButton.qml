import QtQuick 2.6
import QtGraphicalEffects 1.0
import Sailfish.Silica 1.0

BackgroundItem {
    id: root

    property var icon
    property color color: "transparent"

    width: Theme.itemSizeExtraSmall + Theme.paddingMedium * 2
    height: Theme.itemSizeExtraSmall
    _backgroundRadius: height / 2

    Rectangle {
        anchors.fill: parent
        color: Theme.rgba(root.color, Theme.opacityFaint)
        radius: root.height / 2
        
        border {
            width: Theme.dp(2)
            color: root.color
        }
    }

    Icon {
        anchors.centerIn: parent
        width: height
        height: parent.height - Theme.paddingMedium * 2
        source: root.icon
        sourceSize: Qt.size(width, height)

        color: !root.enabled
               ? Theme.rgba(Theme.secondaryColor, Theme.opacityHigh)
               : root.pressed || root.highlighted 
                 ? Theme.highlightColor
                 : Theme.primaryColor
    }
}
