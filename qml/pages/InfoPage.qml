import QtQuick 2.6
import Sailfish.Silica 1.0
import io.thp.pyotherside 1.5


Page {
    id: page
    allowedOrientations: Orientation.Portrait //All

    SilicaFlickable {
        id: listView
        anchors.fill: parent
        contentHeight: columnSaveAs.height + idSectionHeader.height  // Tell SilicaFlickable the height of its content.
        VerticalScrollDecorator {}

        SectionHeader {
            id: idSectionHeader
            anchors.top: parent.top
            anchors.topMargin: Theme.paddingMedium
            Row {
                id: idSectionHeaderColumn
                width: parent.width
                spacing: Theme.paddingMedium * 1.3

                Column {
                    width: parent.width - Theme.itemSizeSmall - spacing
                    Label {
                        anchors.right: parent.right
                        font.pixelSize: Theme.fontSizeLarge
                        color: Theme.highlightColor
                        text: qsTr("Videoworks")
                    }
                    Label {
                        anchors.right: parent.right
                        font.pixelSize: Theme.fontSizeTiny
                        color: Theme.highlightColor
                        text: qsTr("Clip editor for SailfishOS") + "\n "
                    }
                }

                Image {
                    width: Theme.itemSizeSmall
                    source: "../cover/harbour_clipper.svg"
                    sourceSize.width: Theme.itemSizeSmall
                    sourceSize.height: Theme.itemSizeSmall
                    fillMode: Image.PreserveAspectFit
                }
            }
        }

        Column {
            id: columnSaveAs
            width: parent.width

            Item {
                width: parent.width
                height: idSectionHeader.height + Theme.paddingLarge * 3
            }

            Label {
                x: Theme.paddingLarge
                width: parent.width - 2 * Theme.paddingLarge
                wrapMode: Text.Wrap
                font.pixelSize: Theme.fontSizeExtraSmall
                text: qsTr("CONTACT") + "\n"
                    + qsTr("Development version. Bugs and inspiration: https://github.com/poetaster/harbour-clipper ")
            }

            Label {
                x: Theme.paddingLarge
                width: parent.width - 2 * Theme.paddingLarge
                wrapMode: Text.Wrap
                font.pixelSize: Theme.fontSizeExtraSmall
                text: qsTr("SHORTCUTS") + "\n"
                    + qsTr("Play, press => play / pause") + "\n"
                    + qsTr("Play, hold => stop") + "\n"
                    + qsTr("Forward / Backward, press => 1 sec") + "\n"
                    + qsTr("Forward / Backward, hold => 10 sec") + "\n"
                    + qsTr("Marker, press => mark beginning / end") + "\n"
                    + qsTr("Marker, hold => play from position") + "\n"
                    + qsTr("Font, press => pick new font") + "\n"
                    + qsTr("Font, hold => set Sailfish font") + "\n"
                    + "\n"
            }

            Label {
                x: Theme.paddingLarge
                width: parent.width - 2 * Theme.paddingLarge
                wrapMode: Text.Wrap
                font.pixelSize: Theme.fontSizeExtraSmall
                text: qsTr("TECHNICAL NOTES") + "\n"
                    + qsTr("This app uses FFMPEG which comes preinstalled on SailfishOS. Some functions furthermore require a static version included in this app.")
                    + "\n"
            }


        } // end Column



    } // end Silica Flickable
}
