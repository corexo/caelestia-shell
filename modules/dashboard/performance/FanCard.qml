import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import Quickshell.Services.UPower
import Caelestia.Config
import qs.components
import qs.services

StyledRect {
    id: root

    property var fans: []

    color: Colours.tPalette.m3surfaceContainer
    radius: Tokens.rounding.medium
    implicitHeight: layout.implicitHeight + Tokens.padding.large * 2

    Process {
        id: reader
        command: ["python", "/home/oguz/.local/lib/fan-speeds.py"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.fans = JSON.parse(text);
                } catch (_) {
                    root.fans = [];
                }
            }
        }
        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0)
                root.fans = [];
        }
    }

    Timer {
        interval: 3000
        repeat: true
        running: root.visible
        onTriggered: if (!reader.running) reader.running = true
    }

    ColumnLayout {
        id: layout
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.margins: Tokens.padding.large
        spacing: Tokens.spacing.extraSmall

        RowLayout {
            spacing: Tokens.spacing.small
            MaterialIcon {
                text: "mode_fan"
                color: Colours.palette.m3primary
                fontStyle: Tokens.font.icon.medium
            }
            StyledText {
                text: "Lüfter · RPM"
                font: Tokens.font.title.medium
            }
        }

        StyledText {
            Layout.fillWidth: true
            text: root.fans.length ? root.fans.map(fan => `${fan.label}: ${fan.rpm} RPM`).join("  ·  ") : "Nicht verfügbar (N/A)"
            font: Tokens.font.body.medium
            wrapMode: Text.Wrap
        }

        // No direct RPM control with the in-tree drivers: the firmware picks the fan curve from the power profile
        RowLayout {
            Layout.topMargin: Tokens.spacing.extraSmall
            spacing: Tokens.spacing.small

            Repeater {
                model: [
                    {
                        profile: PowerProfile.PowerSaver,
                        icon: "bedtime",
                        text: "Leise"
                    },
                    {
                        profile: PowerProfile.Balanced,
                        icon: "balance",
                        text: "Ausgewogen"
                    },
                    {
                        profile: PowerProfile.Performance,
                        icon: "rocket_launch",
                        text: "Leistung"
                    }
                ]

                StyledRect {
                    id: chip

                    required property var modelData
                    readonly property bool current: PowerProfiles.profile === modelData.profile

                    implicitWidth: chipRow.implicitWidth + Tokens.padding.large * 2
                    implicitHeight: chipRow.implicitHeight + Tokens.padding.small * 2
                    radius: Tokens.rounding.full
                    color: current ? Colours.palette.m3primary : Colours.layer(Colours.palette.m3surfaceContainerHighest, 2)

                    StateLayer {
                        radius: Tokens.rounding.full
                        color: chip.current ? Colours.palette.m3onPrimary : Colours.palette.m3onSurface
                        onClicked: PowerProfiles.profile = chip.modelData.profile
                    }

                    RowLayout {
                        id: chipRow

                        anchors.centerIn: parent
                        spacing: Tokens.spacing.extraSmall

                        MaterialIcon {
                            text: chip.modelData.icon
                            color: chip.current ? Colours.palette.m3onPrimary : Colours.palette.m3onSurface
                        }

                        StyledText {
                            text: chip.modelData.text
                            color: chip.current ? Colours.palette.m3onPrimary : Colours.palette.m3onSurface
                            font: Tokens.font.body.medium
                        }
                    }
                }
            }
        }

        StyledText {
            Layout.fillWidth: true
            text: "Die Firmware regelt die Drehzahl nach dem gewählten Profil."
            font: Tokens.font.body.small
            color: Colours.palette.m3onSurfaceVariant
            wrapMode: Text.Wrap
        }
    }
}
