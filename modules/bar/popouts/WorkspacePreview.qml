pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Widgets
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.services
import qs.utils

Column {
    id: root

    required property int workspaceId
    required property HyprlandMonitor monitor

    readonly property list<HyprlandToplevel> windows: Hypr.toplevelsForWs(workspaceId, GlobalConfig.bar.workspaces.ignoredTags)
    readonly property var output: monitor?.lastIpcObject
    readonly property bool rotated: (output?.transform ?? 0) % 2 === 1
    readonly property real outputWidth: (rotated ? output?.height ?? 1 : output?.width ?? 1) / (output?.scale || 1)
    readonly property real outputHeight: (rotated ? output?.width ?? 1 : output?.height ?? 1) / (output?.scale || 1)
    readonly property real ratio: Tokens.sizes.bar.windowPreviewSize / Math.max(outputWidth, outputHeight, 1)

    spacing: Tokens.spacing.medium

    StyledText {
        text: Tr.tr("Workspace %1").arg(root.workspaceId)
        font: Tokens.font.body.medium
    }

    Rectangle {
        id: map

        width: root.outputWidth * root.ratio
        height: root.outputHeight * root.ratio
        clip: true
        radius: Tokens.rounding.medium
        color: Colours.palette.m3surfaceContainer

        Repeater {
            model: ScriptModel {
                values: [...root.windows]
            }

            delegate: MouseArea {
                id: tile

                required property HyprlandToplevel modelData
                readonly property var geometry: modelData.lastIpcObject

                x: ((geometry.at?.[0] ?? 0) - (root.output?.x ?? 0)) * root.ratio
                y: ((geometry.at?.[1] ?? 0) - (root.output?.y ?? 0)) * root.ratio
                width: (geometry.size?.[0] ?? 0) * root.ratio
                height: (geometry.size?.[1] ?? 0) * root.ratio
                z: containsMouse ? 10 : (geometry.floating ? 1 : 0)
                scale: containsMouse ? 1.08 : 1.0
                hoverEnabled: true
                acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                cursorShape: Qt.PointingHandCursor

                onClicked: event => {
                    const address = `address:0x${modelData.address}`;
                    if (event.button === Qt.MiddleButton) {
                        Hypr.dispatch(Hypr.usingLua ? `hl.dsp.window.close({ window = "${address}" })` : `closewindow ${address}`);
                        return;
                    }
                    if (Hypr.activeWsId !== root.workspaceId)
                        Hypr.focusWorkspace(root.workspaceId);
                    Hypr.dispatch(Hypr.usingLua ? `hl.dsp.focus({ window = "${address}" })` : `focuswindow ${address}`);
                }

                Behavior on scale {
                    Anim {
                        type: Anim.FastSpatial
                    }
                }

                Rectangle {
                    anchors.fill: parent
                    color: Colours.palette.m3surfaceContainerHighest
                    border.color: tile.containsMouse ? Colours.palette.m3primary : Colours.palette.m3outlineVariant
                    border.width: tile.containsMouse ? 2 : 1
                    radius: Tokens.rounding.small
                }

                IconImage {
                    anchors.centerIn: parent
                    implicitSize: Math.min(24, tile.width / 2, tile.height / 2)
                    source: Icons.getAppIcon(tile.geometry.class, "image-missing")
                    visible: !preview.hasContent
                }

                ScreencopyView {
                    id: preview

                    anchors.centerIn: parent
                    captureSource: tile.modelData.wayland // qmllint disable unresolved-type
                    live: visible
                    constraintSize.width: Math.max(1, tile.width - 2)
                    constraintSize.height: Math.max(1, tile.height - 2)
                }
            }
        }

        StyledText {
            anchors.centerIn: parent
            visible: root.windows.length === 0
            text: Tr.tr("No windows")
            color: Colours.palette.m3onSurfaceVariant
        }
    }
}
