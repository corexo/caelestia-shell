// Eigene Caelestia-Karte "KI-Kontingent" (Claude Code + Codex) fuer das Utilities-Panel.
// Daten: ~/.local/bin/kontingent (JSON). Wird von ~/.config/caelestia/overlay/bauen.sh eingebunden.
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services

StyledRect {
    id: root

    property var daten: null

    readonly property real nonAnimHeight: layout.implicitHeight + Tokens.padding.large * 2

    implicitHeight: nonAnimHeight

    radius: Tokens.rounding.large
    color: Colours.tPalette.m3surfaceContainer
    clip: true

    function resetText(epoch: var): string {
        if (!epoch)
            return "";
        const d = new Date(epoch * 1000);
        const restMin = Math.round((d.getTime() - Date.now()) / 60000);
        if (restMin <= 0)
            return "zurückgesetzt";
        const tage = Math.floor(restMin / 1440);
        const std = Math.floor((restMin % 1440) / 60);
        const min = restMin % 60;
        let rest;
        if (tage > 0)
            rest = tage + (tage === 1 ? " Tag" : " Tage") + (std > 0 ? " " + std + " Std" : "");
        else if (std > 0)
            rest = std + " Std" + (min > 0 ? " " + min + " Min" : "");
        else
            rest = min + " Min";
        return Qt.formatDateTime(d, "dd.MM.") + " " + Qt.formatTime(d, "hh:mm") + " Uhr · noch " + rest;
    }

    function farbe(pct: real): color {
        if (pct >= 90)
            return Colours.palette.m3error;
        if (pct >= 70)
            return Colours.palette.m3tertiary;
        return Colours.palette.m3primary;
    }

    Process {
        id: proc

        command: [Quickshell.env("HOME") + "/.local/bin/kontingent"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.daten = JSON.parse(text);
                } catch (e) {}
            }
        }
    }

    Timer {
        interval: 60000
        repeat: true
        running: root.visible
        triggeredOnStart: true
        onTriggered: proc.running = true
    }

    ColumnLayout {
        id: layout

        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: Tokens.padding.large
        spacing: Tokens.spacing.medium

        RowLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacing.medium

            StyledRect {
                implicitWidth: implicitHeight
                implicitHeight: icon.implicitHeight + Tokens.padding.large

                radius: Tokens.rounding.full
                color: Colours.palette.m3secondaryContainer

                MaterialIcon {
                    id: icon

                    anchors.centerIn: parent
                    text: "data_usage"
                    color: Colours.palette.m3onSecondaryContainer
                    fontStyle: Tokens.font.icon.large
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                StyledText {
                    Layout.fillWidth: true
                    text: "KI-Kontingent"
                    font: Tokens.font.body.medium
                    elide: Text.ElideRight
                }

                StyledText {
                    Layout.fillWidth: true
                    text: "Claude Code & Codex"
                    color: Colours.palette.m3onSurfaceVariant
                    font: Tokens.font.body.small
                    elide: Text.ElideRight
                }
            }

            IconButton {
                icon: "refresh"
                type: IconButton.Text
                disabled: proc.running
                onClicked: proc.running = true
            }
        }

        Repeater {
            model: [
                {
                    key: "claude",
                    name: "Claude Code"
                },
                {
                    key: "codex",
                    name: "Codex"
                }
            ]

            ColumnLayout {
                id: abschnitt

                required property var modelData
                readonly property var info: root.daten ? root.daten[modelData.key] : null

                Layout.fillWidth: true
                spacing: Tokens.spacing.small

                RowLayout {
                    Layout.fillWidth: true

                    StyledText {
                        Layout.fillWidth: true
                        text: abschnitt.modelData.name + (abschnitt.info && abschnitt.info.plan ? "  ·  " + abschnitt.info.plan : "")
                        font: Tokens.font.body.small
                        color: Colours.palette.m3onSurface
                        elide: Text.ElideRight
                    }

                    // Data only changes while the CLI runs, so show how old it is
                    StyledText {
                        readonly property int alterMin: abschnitt.info?.stand && root.daten?.jetzt ? Math.round((root.daten.jetzt - abschnitt.info.stand) / 60) : -1

                        visible: alterMin >= 0
                        text: "Stand " + Qt.formatTime(new Date(abschnitt.info?.stand * 1000), "hh:mm")
                        color: alterMin > 30 ? Colours.palette.m3error : Colours.palette.m3onSurfaceVariant
                        font: Tokens.font.body.small
                    }
                }

                StyledText {
                    Layout.fillWidth: true
                    visible: !abschnitt.info || !abschnitt.info.ok
                    text: abschnitt.info ? (abschnitt.info.fehler ?? "") : "lade …"
                    color: Colours.palette.m3onSurfaceVariant
                    font: Tokens.font.body.small
                    wrapMode: Text.WordWrap
                }

                Repeater {
                    model: abschnitt.info && abschnitt.info.ok ? abschnitt.info.fenster : []

                    ColumnLayout {
                        id: fenster

                        required property var modelData

                        Layout.fillWidth: true
                        spacing: 2

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Tokens.spacing.medium

                            StyledText {
                                Layout.preferredWidth: 64
                                Layout.maximumWidth: 64
                                text: fenster.modelData.label
                                color: Colours.palette.m3onSurfaceVariant
                                font: Tokens.font.body.small
                            }

                            StyledProgressBar {
                                Layout.fillWidth: true
                                implicitHeight: Tokens.padding.small
                                value: fenster.modelData.percent / 100
                                fgColour: root.farbe(fenster.modelData.percent)
                            }

                            StyledText {
                                Layout.preferredWidth: 40
                                horizontalAlignment: Text.AlignRight
                                text: Math.round(fenster.modelData.percent) + " %"
                                font: Tokens.font.body.small
                            }
                        }

                        StyledText {
                            Layout.fillWidth: true
                            Layout.leftMargin: 64 + Tokens.spacing.medium
                            text: root.resetText(fenster.modelData.resets_at)
                            color: Colours.palette.m3onSurfaceVariant
                            font: Tokens.font.body.builders.small.size(Math.round(Tokens.font.body.small.pointSize * 0.9)).build()
                            elide: Text.ElideRight
                        }
                    }
                }
            }
        }
    }

    Behavior on implicitHeight {
        Anim {}
    }
}
