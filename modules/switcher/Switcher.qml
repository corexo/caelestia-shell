pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Widgets
import Caelestia.Config
import qs.components
import qs.components.containers
import qs.components.misc
import qs.services
import qs.utils

// Alt-Tab switcher: shows every workspace of the focused monitor with its windows.
// Driven by three global shortcuts (bound in Hyprland): switcherNext, switcherPrev, switcherCommit.
Scope {
    id: root

    property bool open
    property int index
    property HyprlandMonitor monitor
    // Snapshot taken when opening, so the order stays put while cycling
    property var spaces: []
    property var windows: []

    readonly property int columns: spaces.reduce((sum, s) => sum + root.columnsFor(s.windows.length), 0)
    readonly property real tileWidth: {
        const available = (monitor ? monitor.width / monitor.scale : 1920) * 0.9;
        // Plain numbers: Tokens needs a screen, which this Scope does not have
        const chrome = 48 + spaces.length * 40;
        return Math.max(110, Math.min(260, (available - chrome) / Math.max(1, columns) - 12));
    }

    // Large preview of the selected window, shown above the workspaces
    readonly property real bigHeight: (monitor ? monitor.height / monitor.scale : 1080) * 0.42
    readonly property real bigWidth: bigHeight * 16 / 9

    function columnsFor(count: int): int {
        return Math.ceil(Math.sqrt(count));
    }

    function refresh(): void {
        monitor = Hypr.focusedMonitor;
        const at = t => t.lastIpcObject?.at ?? [0, 0];
        const found = Hypr.workspaces.values.filter(w => w.monitor === monitor && w.id > 0).sort((a, b) => a.id - b.id).map(w => ({
                    ws: w,
                    windows: w.toplevels.values.slice().sort((a, b) => at(a)[0] - at(b)[0] || at(a)[1] - at(b)[1])
                })).filter(s => s.windows.length > 0);
        spaces = found;
        windows = found.reduce((all, s) => all.concat(s.windows), []);
    }

    function step(dir: int): void {
        if (!open) {
            refresh();
            if (windows.length === 0)
                return;
            index = Math.max(0, windows.indexOf(Hypr.activeToplevel));
            open = true;
        }
        index = (index + dir + windows.length) % windows.length;
    }

    function commit(): void {
        if (!open)
            return;
        open = false;

        const t = windows[index];
        if (t)
            Hypr.dispatch(Hypr.usingLua ? `hl.dsp.focus({ window = "address:0x${t.address}" })` : `focuswindow address:0x${t.address}`);
    }

    // qmllint disable unresolved-type
    CustomShortcut {
        name: "switcherNext"
        description: "Window switcher: next window"
        onPressed: root.step(1)
    }

    CustomShortcut {
        name: "switcherPrev"
        description: "Window switcher: previous window"
        onPressed: root.step(-1)
    }

    CustomShortcut {
        // qmllint enable unresolved-type
        name: "switcherCommit"
        description: "Window switcher: focus the selected window"
        onPressed: root.commit()
        onReleased: root.commit()
    }

    LazyLoader {
        active: root.open

        StyledWindow {
            screen: Quickshell.screens.find(s => Hypr.monitorFor(s) === root.monitor) ?? Quickshell.screens[0]
            name: "switcher"
            WlrLayershell.exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

            anchors.top: true
            anchors.bottom: true
            anchors.left: true
            anchors.right: true

            // Click outside closes without switching
            MouseArea {
                anchors.fill: parent
                onClicked: root.open = false
            }

            Rectangle {
                anchors.fill: parent
                color: Qt.alpha(Colours.palette.m3scrim, 0.4)
            }

            StyledRect {
                anchors.centerIn: parent
                implicitWidth: panelColumn.implicitWidth + Tokens.padding.large * 2
                implicitHeight: panelColumn.implicitHeight + Tokens.padding.large * 2
                radius: Tokens.rounding.large
                color: Colours.palette.m3surfaceContainer

                ColumnLayout {
                    id: panelColumn

                    anchors.centerIn: parent
                    spacing: Tokens.spacing.medium

                    StyledClippingRect {
                        Layout.alignment: Qt.AlignHCenter
                        implicitWidth: root.bigWidth
                        implicitHeight: root.bigHeight
                        radius: Tokens.rounding.medium
                        color: Colours.palette.m3surfaceContainerHighest

                        ScreencopyView {
                            anchors.centerIn: parent
                            captureSource: root.windows[root.index]?.wayland ?? null // qmllint disable unresolved-type
                            live: true
                            constraintSize: Qt.size(root.bigWidth, root.bigHeight)
                        }
                    }

                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.maximumWidth: root.bigWidth
                        text: root.windows[root.index]?.title ?? ""
                        color: Colours.palette.m3primary
                        font: Tokens.font.title.medium
                        elide: Text.ElideRight
                        maximumLineCount: 1
                    }

                RowLayout {
                    id: spacesRow

                    Layout.alignment: Qt.AlignHCenter
                    spacing: Tokens.spacing.medium

                    Repeater {
                        model: root.spaces

                        StyledRect {
                            id: space

                            required property var modelData
                            readonly property bool current: modelData.ws === root.monitor?.activeWorkspace

                            Layout.alignment: Qt.AlignTop
                            implicitWidth: spaceColumn.implicitWidth + Tokens.padding.medium * 2
                            implicitHeight: spaceColumn.implicitHeight + Tokens.padding.medium * 2
                            radius: Tokens.rounding.medium
                            color: Colours.layer(Colours.palette.m3surfaceContainerHigh, 2)
                            border.width: current ? 1 : 0
                            border.color: Colours.palette.m3outline

                            ColumnLayout {
                                id: spaceColumn

                                anchors.centerIn: parent
                                spacing: Tokens.spacing.small

                                StyledText {
                                    text: space.modelData.ws.name || space.modelData.ws.id
                                    color: space.current ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
                                    font: Tokens.font.label.medium
                                }

                                GridLayout {
                                    columns: root.columnsFor(space.modelData.windows.length)
                                    columnSpacing: Tokens.spacing.medium
                                    rowSpacing: Tokens.spacing.medium

                                    Repeater {
                                        model: space.modelData.windows

                                        Tile {}
                                    }
                                }
                            }
                        }
                    }
                }
                }
            }
        }
    }

    component Tile: Item {
        id: tile

        required property HyprlandToplevel modelData
        readonly property bool selected: root.windows[root.index] === modelData

        implicitWidth: root.tileWidth
        implicitHeight: frame.height + label.implicitHeight + Tokens.spacing.extraSmall

        RectangularShadow {
            id: glow

            anchors.fill: frame
            radius: frame.radius
            blur: 28
            spread: 4
            color: Colours.palette.m3primary
            opacity: 0

            SequentialAnimation on opacity {
                running: tile.selected
                loops: Animation.Infinite
                onStopped: glow.opacity = 0

                NumberAnimation {
                    from: 0.55
                    to: 1
                    duration: 700
                    easing.type: Easing.InOutSine
                }
                NumberAnimation {
                    from: 1
                    to: 0.55
                    duration: 700
                    easing.type: Easing.InOutSine
                }
            }
        }

        StyledClippingRect {
            id: frame

            width: parent.width
            height: Math.round(width * 9 / 16)
            radius: Tokens.rounding.small
            color: Colours.palette.m3surfaceContainerHighest

            IconImage {
                anchors.centerIn: parent
                implicitSize: Math.round(frame.height / 2)
                source: Icons.getAppIcon(tile.modelData.lastIpcObject?.class ?? "", "image-missing")
                visible: !preview.hasContent
            }

            ScreencopyView {
                id: preview

                anchors.centerIn: parent
                captureSource: tile.modelData.wayland // qmllint disable unresolved-type
                live: true
                constraintSize: Qt.size(frame.width, frame.height)
            }
        }

        Rectangle {
            anchors.fill: frame
            radius: frame.radius
            color: "transparent"
            border.width: tile.selected ? 3 : 0
            border.color: Colours.palette.m3primary
        }

        RowLayout {
            id: label

            anchors.top: frame.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.topMargin: Tokens.spacing.extraSmall
            spacing: Tokens.spacing.extraSmall

            IconImage {
                implicitSize: title.implicitHeight
                source: Icons.getAppIcon(tile.modelData.lastIpcObject?.class ?? "", "image-missing")
            }

            StyledText {
                id: title

                Layout.fillWidth: true
                text: tile.modelData.title
                color: tile.selected ? Colours.palette.m3primary : Colours.palette.m3onSurface
                font: Tokens.font.label.medium
                elide: Text.ElideRight
                maximumLineCount: 1
            }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                root.index = root.windows.indexOf(tile.modelData);
                root.commit();
            }
        }
    }
}
