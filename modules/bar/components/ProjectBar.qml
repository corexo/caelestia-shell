pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Caelestia.Config
import qs.components
import qs.services

// Named project workspaces (services/Projects.qml), shown below the numbered ones
StyledRect {
    id: root

    required property ShellScreen screen
    readonly property string activeName: Hypr.monitorFor(screen)?.activeWorkspace?.name ?? ""

    // Project tile at y (in this item's coordinates), for the hover popout in Bar.qml
    function tileAt(y: real): Item {
        const item = column.childAt(column.width / 2, y - column.y);
        return item?.modelData ? item : null;
    }

    implicitWidth: Tokens.sizes.bar.innerWidth
    implicitHeight: column.implicitHeight + Tokens.padding.small * 2

    color: Colours.tPalette.m3surfaceContainer
    radius: Tokens.rounding.full

    Column {
        id: column

        anchors.centerIn: parent
        spacing: Tokens.spacing.small

        Repeater {
            model: ScriptModel {
                values: Projects.list
            }

            delegate: StyledRect {
                id: tile

                required property var modelData
                readonly property bool active: root.activeName === modelData.name
                readonly property bool occupied: Hypr.workspaces.values.some(w => w.name === tile.modelData.name && w.toplevels.values.length > 0)

                implicitWidth: root.implicitWidth - Tokens.padding.small * 2
                implicitHeight: implicitWidth
                radius: active ? Tokens.rounding.medium : Tokens.rounding.full
                color: active ? modelData.colour : Colours.tPalette.m3surfaceContainerHighest

                StyledText {
                    anchors.centerIn: parent
                    text: tile.modelData.short
                    color: tile.active ? Colours.palette.m3surface : tile.occupied ? Colours.palette.m3onSurface : Colours.palette.m3outline
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
                    implicitWidth: 10
                    implicitHeight: 10
                    radius: Tokens.rounding.full
                    visible: status !== ""
                    color: status === "wait" ? "#f5c06b" : "#8fd6a8"
                    border.width: 2
                    border.color: Colours.palette.m3surfaceContainer
                }

                Behavior on radius {
                    Anim {}
                }
            }
        }

        StyledRect {
            implicitWidth: root.implicitWidth - Tokens.padding.small * 2
            implicitHeight: implicitWidth
            radius: Tokens.rounding.full
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
