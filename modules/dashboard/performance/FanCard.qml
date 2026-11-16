import QtQuick
import QtQuick.Layouts
import Quickshell.Io
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

        StyledText {
            Layout.fillWidth: true
            text: "Automatisch durch die Geräte-Firmware geregelt."
            font: Tokens.font.body.small
            color: Colours.palette.m3onSurfaceVariant
            wrapMode: Text.Wrap
        }
    }
}
