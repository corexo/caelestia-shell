pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Caelestia.Config
import qs.components
import qs.services

// CPU cores (P/E), memory and GPU memory in detail. Data comes from scripts/sysdetails.py.
StyledRect {
    id: root

    property var stats: null
    readonly property var gpu: stats?.gpu ?? null

    function gib(kib: real): string {
        return (kib / 1048576).toFixed(1);
    }

    color: Colours.tPalette.m3surfaceContainer
    radius: Tokens.rounding.medium
    implicitHeight: layout.implicitHeight + Tokens.padding.large * 2

    Process {
        command: ["python3", `${Quickshell.shellDir}/scripts/sysdetails.py`]
        running: root.visible
        stdout: SplitParser {
            onRead: line => {
                try {
                    root.stats = JSON.parse(line);
                } catch (_) {}
            }
        }
    }

    RowLayout {
        id: layout

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.margins: Tokens.padding.large
        spacing: Tokens.spacing.extraLarge

        Section {
            icon: "developer_board"
            title: "CPU-Kerne"
            accent: Colours.palette.m3primary

            Repeater {
                model: [
                    {
                        key: "p",
                        name: "P-Kerne"
                    },
                    {
                        key: "e",
                        name: "E-Kerne"
                    },
                    {
                        key: "all",
                        name: "Kerne"
                    }
                ].filter(g => root.stats?.cpu[g.key])

                ColumnLayout {
                    id: group

                    required property var modelData
                    readonly property var cpu: root.stats.cpu[modelData.key]
                    readonly property real avg: cpu.usage.reduce((a, b) => a + b, 0) / cpu.usage.length

                    Layout.fillWidth: true
                    spacing: Tokens.spacing.extraSmall

                    Line {
                        // Frequency: average / fastest core right now
                        name: `${group.modelData.name} ${group.cpu.cores}C` + (group.cpu.threads > group.cpu.cores ? `/${group.cpu.threads}T` : "")
                        value: `${Math.round(group.avg * 100)} % · ${(group.cpu.mhz / 1000).toFixed(1)} / ${(group.cpu.maxMhz / 1000).toFixed(1)} GHz`
                    }

                    // One bar per thread
                    Row {
                        Layout.fillWidth: true
                        spacing: 2

                        Repeater {
                            model: group.cpu.usage

                            Rectangle {
                                required property real modelData

                                width: (parent.width - (group.cpu.threads - 1) * 2) / group.cpu.threads
                                height: 22
                                radius: 2
                                color: Colours.layer(Colours.palette.m3surfaceContainerHighest, 2)

                                Rectangle {
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.bottom: parent.bottom
                                    height: Math.max(2, parent.height * parent.modelData)
                                    radius: 2
                                    color: Colours.palette.m3primary

                                    Behavior on height {
                                        Anim {}
                                    }
                                }
                            }
                        }
                    }
                }
            }

            Line {
                name: "Last (1 / 5 / 15 min)"
                value: root.stats ? root.stats.load.map(l => l.toFixed(2)).join(" / ") : "…"
            }
        }

        Section {
            icon: "memory_alt"
            title: "RAM"
            accent: Colours.palette.m3tertiary

            Meter {
                name: "Belegt"
                value: root.stats ? `${root.gib(root.stats.mem.used)} / ${root.gib(root.stats.mem.total)} GiB` : "…"
                fraction: root.stats ? root.stats.mem.used / root.stats.mem.total : 0
                accent: Colours.palette.m3tertiary
            }

            Meter {
                name: "Cache"
                value: root.stats ? `${root.gib(root.stats.mem.cached)} GiB` : "…"
                fraction: root.stats ? root.stats.mem.cached / root.stats.mem.total : 0
                accent: Colours.palette.m3tertiary
            }

            Meter {
                name: "Swap"
                value: root.stats ? `${root.gib(root.stats.mem.swapUsed)} / ${root.gib(root.stats.mem.swapTotal)} GiB` : "…"
                fraction: root.stats?.mem.swapTotal ? root.stats.mem.swapUsed / root.stats.mem.swapTotal : 0
                accent: Colours.palette.m3tertiary
            }
        }

        Section {
            icon: "desktop_windows"
            title: "GPU"
            accent: Colours.palette.m3secondary

            Meter {
                name: "VRAM"
                value: root.gpu ? `${(root.gpu.vramUsed / 1024).toFixed(1)} / ${(root.gpu.vramTotal / 1024).toFixed(1)} GiB` : root.stats ? "Nicht verfügbar" : "…"
                fraction: root.gpu ? root.gpu.vramUsed / root.gpu.vramTotal : 0
                accent: Colours.palette.m3secondary
            }

            Meter {
                name: "Auslastung"
                value: root.gpu ? `${Math.round(root.gpu.util)} %` : "…"
                fraction: root.gpu ? root.gpu.util / 100 : 0
                accent: Colours.palette.m3secondary
            }

            Line {
                name: "Leistung · Temperatur"
                value: root.gpu ? `${Math.round(root.gpu.watts)} W · ${Math.round(root.gpu.temp)} °C` : "…"
            }
        }
    }

    component Section: ColumnLayout {
        id: section

        required property string icon
        required property string title
        required property color accent
        default property alias content: body.data

        Layout.fillWidth: true
        Layout.preferredWidth: 1
        Layout.alignment: Qt.AlignTop
        spacing: Tokens.spacing.small

        RowLayout {
            spacing: Tokens.spacing.small

            MaterialIcon {
                text: section.icon
                color: section.accent
                fontStyle: Tokens.font.icon.medium
            }

            StyledText {
                text: section.title
                font: Tokens.font.title.medium
            }
        }

        ColumnLayout {
            id: body

            Layout.fillWidth: true
            spacing: Tokens.spacing.small
        }
    }

    component Line: RowLayout {
        required property string name
        required property string value

        Layout.fillWidth: true
        spacing: Tokens.spacing.small

        StyledText {
            Layout.fillWidth: true
            text: parent.name
            font: Tokens.font.body.small
            color: Colours.palette.m3onSurfaceVariant
            elide: Text.ElideRight
        }

        StyledText {
            text: parent.value
            font: Tokens.font.body.small
        }
    }

    component Meter: ColumnLayout {
        id: meter

        required property string name
        required property string value
        required property real fraction
        required property color accent

        Layout.fillWidth: true
        spacing: Tokens.spacing.extraSmall

        Line {
            name: meter.name
            value: meter.value
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 6
            radius: 3
            color: Colours.layer(Colours.palette.m3surfaceContainerHighest, 2)

            Rectangle {
                width: parent.width * Math.min(1, Math.max(0, meter.fraction))
                height: parent.height
                radius: 3
                color: meter.accent

                Behavior on width {
                    Anim {}
                }
            }
        }
    }
}
