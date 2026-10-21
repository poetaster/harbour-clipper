import QtQuick 2.6
import Sailfish.Silica 1.0
import QtGraphicalEffects 1.0

MouseArea {
    id: root

    readonly property color elementColor: pressed || selected ? Theme.highlightColor : Theme.primaryColor

    property bool invert: false
    property bool selected: false
    property Item contentItem: Item { }

    width: implicitWidth
    height: implicitHeight
    implicitWidth: container.width + Theme.paddingMedium * 2
    implicitHeight: container.height + Theme.paddingMedium * 2

    onContentItemChanged: contentItem.parent = container

    Rectangle {
        anchors.fill: parent
        opacity: root.selected ? 1 : 0

        gradient: Gradient {
            GradientStop {
                position: root.invert ? 1 : 0
                color: Theme.rgba(Theme.highlightColor, 0.0)
            }

            GradientStop {
                position: root.invert ? 0 : 1
                color: Theme.rgba(Theme.highlightColor, Theme.opacityLow)
            }
        }

        Behavior on opacity {
            FadeAnimation { }
        }
    }

    Rectangle {
        anchors {
            top: root.invert ? parent.top : undefined
            bottom: root.invert ? undefined : parent.bottom
        }
        
        width: parent.width
        height: Theme.dp(1)
        color: Theme.highlightColor
        opacity: root.selected ? 1 : 0

        Behavior on opacity {
            FadeAnimation { }
        }
    }

    Item {
        id: container

        anchors.centerIn: parent
        width: childrenRect.width
        height: childrenRect.height
    }
}
