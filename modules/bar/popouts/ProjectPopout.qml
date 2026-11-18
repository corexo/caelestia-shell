pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Widgets
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services
import qs.utils

// Hover popout for a project tile in the bar (components/ProjectBar.qml)
ColumnLayout {
    id: root

    readonly property var project: Projects.find(Projects.hovered)
    readonly property var windows: Hypr.workspaces.values.find(w => w.name === Projects.hovered)?.toplevels.values ?? []
    readonly property string status: project ? Projects.status(project.name) : ""

    implicitWidth: 300
    spacing: Tokens.spacing.small

    RowLayout {
        Layout.fillWidth: true

        StyledText {
            Layout.fillWidth: true
            text: root.project?.name ?? ""
            font: Tokens.font.title.small
            elide: Text.ElideRight
        }

        StyledRect {
            visible: root.status !== ""
            implicitWidth: statusText.implicitWidth + Tokens.padding.medium * 2
            implicitHeight: statusText.implicitHeight + Tokens.padding.extraSmall * 2
            radius: Tokens.rounding.full
            color: root.status === "wait" ? "#5c4413" : "#1e4a33"

            StyledText {
                id: statusText

                anchors.centerIn: parent
                text: root.status === "wait" ? "wartet auf dich" : "Agent arbeitet"
                color: root.status === "wait" ? "#f5c06b" : "#8fd6a8"
                font: Tokens.font.label.small
            }
        }
    }

    StyledText {
        Layout.fillWidth: true
        text: Paths.shortenHome(root.project?.dir ?? "")
        color: Colours.palette.m3onSurfaceVariant
        font: Tokens.font.body.small
        elide: Text.ElideMiddle
    }

    StyledText {
        Layout.topMargin: Tokens.spacing.small
        visible: root.windows.length === 0
        text: "Noch keine Fenster"
        color: Colours.palette.m3outline
        font: Tokens.font.body.small
    }

    Repeater {
        model: ScriptModel {
            values: root.windows
        }

        delegate: StyledRect {
            id: row

            required property HyprlandToplevel modelData

            Layout.fillWidth: true
            implicitHeight: rowLayout.implicitHeight + Tokens.padding.small * 2
            radius: Tokens.rounding.medium
            color: mouse.containsMouse ? Colours.tPalette.m3surfaceContainerHighest : "transparent"

            RowLayout {
                id: rowLayout

                anchors.fill: parent
                anchors.margins: Tokens.padding.small
                spacing: Tokens.spacing.medium

                IconImage {
                    implicitSize: 20
                    source: Icons.getAppIcon(row.modelData.lastIpcObject.class, "image-missing")
                }

                StyledText {
                    Layout.fillWidth: true
                    text: row.modelData.title
                    font: Tokens.font.body.small
                    elide: Text.ElideRight
                }
            }

            MouseArea {
                id: mouse

                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: Hypr.dispatch(Hypr.usingLua ? `hl.dsp.focus({ window = "address:0x${row.modelData.address}" })` : `focuswindow address:0x${row.modelData.address}`)
            }
        }
    }

    RowLayout {
        Layout.topMargin: Tokens.spacing.small
        Layout.fillWidth: true
        spacing: Tokens.spacing.small

        Repeater {
            model: [
                {
                    kind: "terminal",
                    text: "+ Terminal"
                },
                {
                    kind: "agent",
                    text: "+ Agent"
                },
                {
                    kind: "browser",
                    text: "+ Browser"
                }
            ]

            delegate: TextButton {
                required property var modelData

                Layout.fillWidth: true
                text: modelData.text
                inactiveColour: Colours.palette.m3secondaryContainer
                inactiveOnColour: Colours.palette.m3onSecondaryContainer
                onClicked: Projects.launch(root.project.name, modelData.kind)
            }
        }
    }
}
