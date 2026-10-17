import QtQuick 2.6
import Sailfish.Silica 1.0
import QtGraphicalEffects 1.0

MouseArea {
    id: root

    readonly property color elementColor: pressed || selected ? Theme.highlightColor : Theme.primaryColor
    readonly property real radius: Theme.paddingMedium

    property bool selected: false
    property alias icon: icon.source

    width: implicitWidth
    height: implicitHeight
    implicitWidth: icon.width + radius * 2
    implicitHeight: Theme.itemSizeSmall

    Rectangle {
        anchors.fill: parent
        opacity: root.selected ? 1 : 0

        gradient: Gradient {
            GradientStop {
                position: 0
                color: Theme.rgba(Theme.highlightColor, 0.0)
            }

            GradientStop {
                position: 1
                color: Theme.rgba(Theme.highlightColor, Theme.opacityHigh)
            }
        }

        Behavior on opacity {
            FadeAnimation { }
        }
    }

    Rectangle {
        anchors.bottom: parent.bottom
        width: parent.width
        height: Theme.dp(1)
        color: Theme.highlightColor
        opacity: root.selected ? 1 : 0

        Behavior on opacity {
            FadeAnimation { }
        }
    }

    Icon {
        id: icon

        anchors.centerIn: parent
        width: height
        height: parent.height
        color: root.elementColor
    }
}
