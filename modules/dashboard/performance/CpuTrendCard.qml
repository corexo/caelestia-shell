pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import Caelestia.Config
import Caelestia.Services
import qs.components
import qs.components.controls
import qs.services

// CPU temperature and load over the last two minutes, plus a switch for the clock limit.
// The switch calls the root-owned /usr/local/bin/cpu-takt (installed by ~/dualboot/cpu-takt-install.sh).
StyledRect {
    id: root

    readonly property int samples: 120
    // shortcut: history only exists while the tab is open, move it into a service if it should run always
    property var temps: []
    property var loads: []
    property int maxKhz
    property int limitKhz
    readonly property bool limited: limitKhz > 0 && limitKhz < maxKhz
    property string error

    color: Colours.tPalette.m3surfaceContainer
    radius: Tokens.rounding.medium
    implicitHeight: layout.implicitHeight + Tokens.padding.large * 2

    ServiceRef {
        service: Cpu
    }

    Timer {
        interval: 1000
        repeat: true
        running: root.visible
        triggeredOnStart: true
        onTriggered: {
            if (!isFinite(Cpu.percentage) || !isFinite(Cpu.temperature))
                return;
            root.loads = [...root.loads, Cpu.percentage * 100].slice(-root.samples);
            root.temps = [...root.temps, Cpu.temperature].slice(-root.samples);
            chart.requestPaint();
        }
    }

    Process {
        id: reader

        command: ["cat", "/sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq", "/sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_max_freq"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const [limit, max] = text.trim().split("\n").map(Number);
                root.limitKhz = limit || 0;
                root.maxKhz = max || 0;
                toggle.checked = Qt.binding(() => root.limited);
            }
        }
    }

    Process {
        id: writer

        onExited: exitCode => {
            root.error = exitCode === 0 ? "" : "Helfer fehlt: sudo ~/dualboot/cpu-takt-install.sh ausführen.";
            reader.running = true;
        }
    }

    ColumnLayout {
        id: layout

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.margins: Tokens.padding.large
        spacing: Tokens.spacing.small

        RowLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacing.small

            MaterialIcon {
                text: "monitoring"
                color: Colours.palette.m3primary
                fontStyle: Tokens.font.icon.medium
            }

            StyledText {
                Layout.fillWidth: true
                text: "CPU-Verlauf"
                font: Tokens.font.title.medium
            }

            StyledText {
                text: root.limited ? `Takt-Grenze ${(root.limitKhz / 1e6).toFixed(1)} GHz` : `Takt-Grenze aus (${(root.maxKhz / 1e6).toFixed(1)} GHz)`
                font: Tokens.font.body.small
                color: Colours.palette.m3onSurfaceVariant
            }

            StyledSwitch {
                id: toggle

                checked: root.limited
                onToggled: {
                    if (writer.running)
                        return;
                    writer.command = ["sudo", "-n", "/usr/local/bin/cpu-takt", ...(checked ? [] : ["aus"])];
                    writer.running = true;
                }
            }
        }

        Item {
            Layout.fillWidth: true
            implicitHeight: 120

            Canvas {
                id: chart

                function line(ctx: var, values: var, colour: color): void {
                    if (values.length < 2)
                        return;
                    const step = width / (root.samples - 1);
                    const start = width - (values.length - 1) * step;
                    ctx.beginPath();
                    values.forEach((v, i) => {
                        const y = height - Math.max(0, Math.min(100, v)) / 100 * height;
                        i ? ctx.lineTo(start + i * step, y) : ctx.moveTo(start, y);
                    });
                    ctx.strokeStyle = colour;
                    ctx.lineWidth = 2;
                    ctx.stroke();
                }

                anchors.fill: parent
                onPaint: {
                    const ctx = getContext("2d");
                    ctx.clearRect(0, 0, width, height);
                    ctx.strokeStyle = Qt.alpha(Colours.palette.m3outline, 0.3);
                    ctx.lineWidth = 1;
                    // Grid at 0, 25, 50, 75 and 100 (percent and °C share the scale)
                    for (let i = 0; i <= 4; i++) {
                        const y = Math.round(height * i / 4) + (i === 4 ? -0.5 : 0.5);
                        ctx.beginPath();
                        ctx.moveTo(0, y);
                        ctx.lineTo(width, y);
                        ctx.stroke();
                    }
                    line(ctx, root.loads, Colours.palette.m3primary);
                    line(ctx, root.temps, Colours.palette.m3tertiary);
                }
                onWidthChanged: requestPaint()
            }

            StyledText {
                anchors.centerIn: parent
                visible: root.temps.length < 2
                text: "Sammle Daten …"
                font: Tokens.font.body.small
                color: Colours.palette.m3outline
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacing.large

            StyledText {
                text: `● Last ${root.loads.length ? Math.round(root.loads[root.loads.length - 1]) : "–"} %`
                font: Tokens.font.body.small
                color: Colours.palette.m3primary
            }

            StyledText {
                text: `● Temperatur ${root.temps.length ? Math.round(root.temps[root.temps.length - 1]) : "–"} °C` + (root.temps.length ? ` (max ${Math.round(Math.max(...root.temps))} °C)` : "")
                font: Tokens.font.body.small
                color: Colours.palette.m3tertiary
            }

            StyledText {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignRight
                text: "Skala 0–100, letzte 2 Minuten"
                font: Tokens.font.body.small
                color: Colours.palette.m3onSurfaceVariant
            }
        }

        StyledText {
            Layout.fillWidth: true
            visible: text.length > 0
            text: root.error
            font: Tokens.font.body.small
            color: Colours.palette.m3error
            wrapMode: Text.Wrap
        }
    }
}
