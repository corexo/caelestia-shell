pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Widgets
import Caelestia.Config
import qs.components
import qs.services
import qs.utils

Item {
    id: root

    required property ShellScreen screen

    readonly property int activeWorkspace: Hypr.monitorFor(screen)?.activeWorkspace?.id ?? 0
    readonly property int previewSize: Tokens.sizes.bar.innerWidth
    readonly property alias count: repeater.count

    property real hoverY: -1
    property HyprlandToplevel currentHoveredClient: null

    implicitWidth: previewSize
    implicitHeight: column.implicitHeight

    Behavior on implicitHeight {
        Anim {
            type: Anim.FastSpatial
        }
    }

    signal previewEntered(client: HyprlandToplevel, center: real)
    signal previewExited(client: HyprlandToplevel)

    Column {
        id: column

        anchors.horizontalCenter: parent.horizontalCenter
        spacing: Tokens.spacing.extraSmall

        Repeater {
            id: repeater

            model: ScriptModel {
                values: Hypr.toplevelsForWs(root.activeWorkspace, GlobalConfig.bar.workspaces.ignoredTags)
            }

            delegate: Item {
                id: tile

                required property HyprlandToplevel modelData
                required property int index
                readonly property bool focused: Hypr.activeToplevel === modelData

                readonly property real baseCenterY: index * (root.previewSize + column.spacing) + root.previewSize / 2
                readonly property real dist: root.hoverY >= 0 ? Math.abs(root.hoverY - baseCenterY) : 9999
                readonly property real proximity: Math.max(0, 1 - dist / (root.previewSize * 2.2))
                readonly property real magFactor: 1 + 0.55 * (proximity * proximity * (3 - 2 * proximity))
                readonly property bool isClosest: root.currentHoveredClient === modelData

                width: root.previewSize
                height: Math.round(root.previewSize * (1 + 0.35 * (proximity * proximity)))
                z: isClosest ? 10 : Math.round(proximity * 5)

                Behavior on height {
                    Anim {
                        type: Anim.FastSpatial
                    }
                }

                Item {
                    id: visual

                    width: Math.round(root.previewSize * tile.magFactor)
                    height: Math.round(root.previewSize * tile.magFactor)
                    anchors.verticalCenter: parent.verticalCenter
                    x: Math.round((tile.magFactor - 1) * root.previewSize * 0.35)

                    Behavior on width {
                        Anim {
                            type: Anim.FastSpatial
                        }
                    }

                    Behavior on height {
                        Anim {
                            type: Anim.FastSpatial
                        }
                    }

                    Behavior on x {
                        Anim {
                            type: Anim.FastSpatial
                        }
                    }

                    Rectangle {
                        anchors.fill: parent
                        color: Colours.palette.m3surfaceContainer
                        radius: Tokens.rounding.small
                        border.color: tile.focused || tile.isClosest ? Colours.palette.m3primary : Colours.palette.m3outline
                        border.width: tile.focused || tile.isClosest ? 2 : (tile.proximity > 0.2 ? 1 : 0)
                    }

                    IconImage {
                        anchors.centerIn: parent
                        implicitSize: visual.width / 2
                        source: Icons.getAppIcon(tile.modelData.lastIpcObject.class, "image-missing")
                        visible: !preview.hasContent
                    }

                    ScreencopyView {
                        id: preview

                        anchors.centerIn: parent
                        captureSource: tile.modelData.wayland // qmllint disable unresolved-type
                        live: visible
                        constraintSize.width: Math.max(1, visual.width - 4)
                        constraintSize.height: Math.max(1, visual.height - 4)
                    }

                    // Mini app badge on the corner so you always see the app icon over the live preview
                    IconImage {
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        anchors.margins: 2
                        implicitSize: Math.round(14 * tile.magFactor)
                        source: Icons.getAppIcon(tile.modelData.lastIpcObject.class, "image-missing")
                        visible: preview.hasContent
                    }

                    // Close badge on top-right when hovered
                    Rectangle {
                        id: closeBadge

                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: 2
                        width: 18
                        height: 18
                        radius: 9
                        color: Colours.palette.m3errorContainer
                        visible: tile.isClosest

                        MaterialIcon {
                            anchors.centerIn: parent
                            text: "close"
                            color: Colours.palette.m3onErrorContainer
                            font.pointSize: 9
                        }
                    }

                    // A failed capture (e.g. right after login) never restarts on its own, so rebind the source
                    Timer {
                        interval: 3000
                        repeat: true
                        running: !preview.hasContent && tile.visible
                        onTriggered: {
                            preview.captureSource = null;
                            preview.captureSource = Qt.binding(() => tile.modelData?.wayland ?? null); // qmllint disable unresolved-type
                        }
                    }
                }
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        anchors.margins: -Tokens.padding.small
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
        cursorShape: Qt.PointingHandCursor

        function updateHovered(my: real): void {
            const localY = my - Tokens.padding.small;
            root.hoverY = localY;

            let bestTile = null;
            let bestDist = 9999;
            for (let i = 0; i < repeater.count; i++) {
                const item = repeater.itemAt(i);
                if (!item)
                    continue;
                const center = item.y + item.height / 2;
                const d = Math.abs(localY - center);
                if (d < bestDist) {
                    bestDist = d;
                    bestTile = item;
                }
            }

            if (bestTile && bestDist <= bestTile.height * 0.85) {
                if (root.currentHoveredClient !== bestTile.modelData) {
                    root.currentHoveredClient = bestTile.modelData;
                }
                root.previewEntered(bestTile.modelData, bestTile.y + bestTile.height / 2);
            } else if (root.currentHoveredClient) {
                const prev = root.currentHoveredClient;
                root.currentHoveredClient = null;
                root.previewExited(prev);
            }
        }

        onPositionChanged: event => updateHovered(event.y)
        onEntered: updateHovered(mouseY)
        onExited: {
            root.hoverY = -1;
            if (root.currentHoveredClient) {
                const prev = root.currentHoveredClient;
                root.currentHoveredClient = null;
                root.previewExited(prev);
            }
        }
        onClicked: event => {
            updateHovered(event.y);
            if (!root.currentHoveredClient)
                return;

            const address = `address:0x${root.currentHoveredClient.address}`;
            let isCloseClick = event.button === Qt.MiddleButton;

            if (!isCloseClick && event.button === Qt.LeftButton) {
                for (let i = 0; i < repeater.count; i++) {
                    const item = repeater.itemAt(i);
                    if (item && item.modelData === root.currentHoveredClient) {
                        const localX = event.x - Tokens.padding.small;
                        const localY = event.y - Tokens.padding.small;
                        const visW = Math.round(root.previewSize * item.magFactor);
                        const visX = Math.round((item.magFactor - 1) * root.previewSize * 0.35);
                        const visY = item.y + (item.height - visW) / 2;
                        if (localX >= visX + visW - 22 && localY >= visY && localY <= visY + 22)
                            isCloseClick = true;
                        break;
                    }
                }
            }

            if (isCloseClick) {
                Hypr.dispatch(Hypr.usingLua ? `hl.dsp.window.close({ window = "${address}" })` : `closewindow ${address}`);
            } else {
                Hypr.dispatch(Hypr.usingLua ? `hl.dsp.focus({ window = "${address}" })` : `focuswindow ${address}`);
            }
        }
    }
}
