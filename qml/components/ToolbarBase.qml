import QtQuick 2.6
import QtGraphicalEffects 1.0
import Sailfish.Silica 1.0

SilicaFlickable {
    id: toolbarFlickable

    readonly property bool leftFade: contentX >= 0
    readonly property bool rightFade: contentX + width < contentWidth

    readonly property alias itemWidth: toolbar.itemWidth
    readonly property alias itemHeight: toolbar.itemHeight

    default property alias toolbarChildren: toolbar.children

    implicitHeight: toolbar.height
    contentWidth: toolbar.width
    leftMargin: Theme.horizontalPageMargin
    rightMargin: Theme.horizontalPageMargin
    boundsBehavior: Flickable.DragAndOvershootBounds


    layer.enabled: true
    layer.effect: OpacityMask {
        maskSource: LinearGradient {
            id: maskRectangle

            property real leftFadeOpacity: toolbarFlickable.leftFade ? 0 : 1
            property real rightFadeOpacity: toolbarFlickable.rightFade ? 0 : 1

            // Here we assume flickable's left and right margins are the same
            readonly property real fraction: toolbarFlickable.leftMargin / toolbarFlickable.width

            width: toolbarFlickable.width
            height: toolbarFlickable.height
            start: Qt.point(0, 0)
            end: Qt.point(width, 0)

            gradient: Gradient {
                GradientStop {
                    position: 0.0
                    color: Qt.rgba(1.0, 1.0, 1.0, maskRectangle.leftFadeOpacity)
                }

                GradientStop {
                    position: maskRectangle.fraction
                    color: "white"
                }

                GradientStop {
                    position: 1.0 - maskRectangle.fraction
                    color: "white"
                }

                GradientStop {
                    position: 1.0
                    color: Qt.rgba(1.0, 1.0, 1.0, maskRectangle.rightFadeOpacity)
                }
            }

            Behavior on leftFadeOpacity {
                NumberAnimation {
                    duration: 100
                }
            }

            Behavior on rightFadeOpacity {
                NumberAnimation {
                    duration: 100
                }
            }
        }
    }

    Row {
        id: toolbar

        readonly property real itemWidth: {
            var maxWidth = 0

            for (var i = 0; i < children.length; i++) {
                maxWidth = Math.max(maxWidth, children[i].implicitWidth)
            }

            return Math.max(toolbarFlickable.width / children.length, maxWidth)
        }

        readonly property real itemHeight: {
            var maxHeight = 0

            for (var i = 0; i < children.length; i++) {
                maxHeight = Math.max(maxHeight, children[i].implicitHeight)
            }

            return maxHeight
        }

        height: implicitHeight
        width: implicitWidth
    }
}
