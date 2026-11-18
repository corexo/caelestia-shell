pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Caelestia.Config
import qs.components
import qs.services

// Named project workspaces (services/Projects.qml), shown below the numbered ones as
// rounded square tiles (not a pill like the numbers) so the two are easy to tell apart
Item {
    id: root

    required property ShellScreen screen
    readonly property string activeName: Hypr.monitorFor(screen)?.activeWorkspace?.name ?? ""

    // Project tile at y (in this item's coordinates), for the hover popout in Bar.qml
    function tileAt(y: real): Item {
        const item = column.childAt(column.width / 2, y - column.y);
        return item?.modelData ? item : null;
    }

    implicitWidth: Tokens.sizes.bar.innerWidth
    implicitHeight: column.implicitHeight

    Column {
        id: column

        anchors.centerIn: parent
        spacing: Tokens.spacing.small

        // Divider between numbers and projects (a text label is wider than the bar)
        StyledRect {
            anchors.horizontalCenter: parent.horizontalCenter
            implicitWidth: root.implicitWidth * 0.6
            implicitHeight: 1
            color: Colours.palette.m3outlineVariant
        }

        Repeater {
            model: ScriptModel {
                values: Projects.list
            }

            delegate: StyledRect {
                id: tile

                required property var modelData
                readonly property bool active: root.activeName === modelData.name
                readonly property bool occupied: Hypr.workspaces.values.some(w => w.name === tile.modelData.name && w.toplevels.values.length > 0)

                implicitWidth: root.implicitWidth
                implicitHeight: implicitWidth
                radius: Tokens.rounding.large
                color: active ? modelData.colour : Colours.tPalette.m3surfaceContainerHigh

                StyledText {
                    anchors.centerIn: parent
                    text: tile.modelData.short
                    color: tile.active ? Colours.palette.m3surface : tile.occupied ? Colours.palette.m3onSurface : Colours.palette.m3onSurfaceVariant
                    font.pointSize: Tokens.font.body.small.pointSize
                    font.weight: 500
                }

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    cursorShape: Qt.PointingHandCursor
                    onClicked: event => event.button === Qt.RightButton ? Projects.openDialog(tile.modelData) : Projects.open(tile.modelData.name)
                }

                StyledRect {
                    readonly property string status: Projects.status(tile.modelData.name)

                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: -3
                    implicitWidth: 12
                    implicitHeight: 12
                    radius: Tokens.rounding.full
                    visible: status !== ""
                    color: status === "wait" ? "#f5c06b" : "#8fd6a8"
                    border.width: 2
                    border.color: Colours.palette.m3surface
                }
            }
        }

        StyledRect {
            implicitWidth: root.implicitWidth
            implicitHeight: implicitWidth
            radius: Tokens.rounding.large
            color: "transparent"
            border.width: 1
            border.color: Colours.palette.m3outline

            MaterialIcon {
                anchors.centerIn: parent
                text: "add"
                color: Colours.palette.m3onSurfaceVariant
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: Projects.openDialog(null)
            }
        }
    }
}
