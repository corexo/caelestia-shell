pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Caelestia.Config
import qs.components
import qs.components.containers
import qs.components.controls
import qs.services

// Tagesjournal aus ~/Journal/JJJJ-MM-TT.md. Einträge kommen vom Sidekick (~/projects/sidekick):
// per Sprache/Chat ("trag ins Journal ein …") und automatisch über "sidekick.py journal-sync".
Item {
    id: root

    property int daysBack: 0
    readonly property date day: new Date(Date.now() - daysBack * 86400000)
    property var entries: []

    readonly property string sidekick: `${Quickshell.env("HOME")}/projects/sidekick/sidekick.py`
    readonly property var kinds: ({
            Deployment: ["rocket_launch", Colours.palette.m3error],
            PR: ["merge", Colours.palette.m3primary],
            Issue: ["task_alt", Colours.palette.m3tertiary],
            Commit: ["commit", Colours.palette.m3secondary],
            Erledigt: ["check_circle", Colours.palette.m3primary],
            Meeting: ["groups", Colours.palette.m3tertiary],
            Notiz: ["edit_note", Colours.palette.m3onSurfaceVariant]
        })

    function look(kind: string): var {
        return kinds[kind] ?? kinds.Notiz;
    }

    function parse(content: string): void {
        const out = [];
        for (const line of content.split("\n")) {
            const m = line.match(/^- (\d\d:\d\d) · ([^·]+) · (.*?)(\s*<!--.*-->)?$/);
            if (m)
                out.push({
                    time: m[1],
                    kind: m[2].trim(),
                    text: m[3]
                });
        }
        out.sort((a, b) => b.time.localeCompare(a.time));
        root.entries = out;
    }

    implicitWidth: 840
    implicitHeight: 560
    Component.onCompleted: sync.running = true // beim Öffnen der Seite heutige Ereignisse nachholen

    FileView {
        id: file

        path: `${Quickshell.env("HOME")}/Journal/${Qt.formatDate(root.day, "yyyy-MM-dd")}.md`
        printErrors: false
        watchChanges: true
        onFileChanged: reload()
        onLoaded: root.parse(text())
        onLoadFailed: root.entries = []
    }

    Process {
        id: sync

        command: [root.sidekick, "journal-sync"]
        onExited: file.reload()
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: Tokens.spacing.medium

        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: Tokens.padding.large
            Layout.rightMargin: Tokens.padding.large
            spacing: Tokens.spacing.small

            Column {
                spacing: Tokens.spacing.extraSmall

                StyledText {
                    text: "Journal"
                    font: Tokens.font.body.builders.large.size(28).weight(Font.DemiBold).build()
                    color: Colours.palette.m3onSurface
                }

                StyledText {
                    text: root.day.toLocaleDateString(Qt.locale(), "dddd, d. MMMM yyyy")
                    font: Tokens.font.body.small
                    color: Colours.palette.m3onSurfaceVariant
                }
            }

            Item {
                Layout.fillWidth: true
            }

            IconButton {
                type: IconButton.Tonal
                icon: "chevron_left"
                isRound: true
                onClicked: root.daysBack++
            }

            IconButton {
                type: IconButton.Tonal
                icon: "today"
                isRound: true
                disabled: root.daysBack === 0
                onClicked: root.daysBack = 0
            }

            IconButton {
                type: IconButton.Tonal
                icon: "chevron_right"
                isRound: true
                disabled: root.daysBack === 0
                onClicked: root.daysBack--
            }

            IconButton {
                type: IconButton.Tonal
                icon: sync.running ? "hourglass_top" : "sync"
                isRound: true
                disabled: sync.running || root.daysBack !== 0
                onClicked: sync.running = true
            }
        }

        // Zusammenfassung: Anzahl je Art
        Row {
            Layout.leftMargin: Tokens.padding.large
            spacing: Tokens.spacing.small

            Repeater {
                model: ["Deployment", "PR", "Issue", "Erledigt", "Commit"]

                StyledRect {
                    id: chip

                    required property string modelData
                    readonly property int count: root.entries.filter(e => e.kind === modelData).length

                    implicitWidth: chipRow.implicitWidth + Tokens.padding.large * 2
                    implicitHeight: chipRow.implicitHeight + Tokens.padding.small * 2
                    radius: Tokens.rounding.full
                    color: Colours.tPalette.m3surfaceContainer
                    opacity: count > 0 ? 1 : 0.45

                    Row {
                        id: chipRow

                        anchors.centerIn: parent
                        spacing: Tokens.spacing.small

                        MaterialIcon {
                            anchors.verticalCenter: parent.verticalCenter
                            text: root.look(chip.modelData)[0]
                            color: root.look(chip.modelData)[1]
                        }

                        StyledText {
                            anchors.verticalCenter: parent.verticalCenter
                            text: `${chip.count} ${chip.modelData === "Erledigt" ? "Erledigt" : chip.modelData + (chip.count === 1 ? "" : "s")}`
                            color: Colours.palette.m3onSurface
                        }
                    }
                }
            }
        }

        StyledRect {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: Tokens.rounding.large
            color: Colours.tPalette.m3surfaceContainer

            StyledText {
                anchors.centerIn: parent
                visible: root.entries.length === 0
                width: parent.width - Tokens.padding.large * 4
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.Wrap
                text: "Noch nichts eingetragen. Sag dem Buddy z. B. „Trag ins Journal ein: Kundentermin mit Okami“ oder tipp auf Aktualisieren."
                color: Colours.palette.m3onSurfaceVariant
            }

            StyledListView {
                id: list

                anchors.fill: parent
                anchors.margins: Tokens.padding.medium
                clip: true
                spacing: Tokens.spacing.small
                model: root.entries

                StyledScrollBar.vertical: StyledScrollBar {
                    flickable: list
                }

                // feste Spalten statt RowLayout: im Dashboard brach der Text im Layout nicht um
                delegate: Item {
                    id: entry

                    required property var modelData

                    width: ListView.view.width - Tokens.padding.medium
                    height: Math.max(body.implicitHeight, icon.implicitHeight)

                    StyledText {
                        id: clock

                        width: 44
                        text: entry.modelData.time
                        color: Colours.palette.m3onSurfaceVariant
                    }

                    MaterialIcon {
                        id: icon

                        x: clock.width + Tokens.spacing.small
                        text: root.look(entry.modelData.kind)[0]
                        color: root.look(entry.modelData.kind)[1]
                    }

                    StyledText {
                        id: body

                        x: icon.x + icon.implicitWidth + Tokens.spacing.medium
                        width: entry.width - x
                        text: entry.modelData.text
                        wrapMode: Text.Wrap
                        color: Colours.palette.m3onSurface
                    }
                }
            }
        }
    }
}
