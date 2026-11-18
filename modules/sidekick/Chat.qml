pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import Caelestia.Config
import qs.components
import qs.components.containers
import qs.services

// Chat mit dem Sidekick, mittig über allen Fenstern des aktiven Bildschirms.
// Öffnen: Klick auf den Sidekick in der Leiste oder qs -c caelestia ipc call buddy toggleChat
Scope {
    LazyLoader {
        active: Sidekick.chatOpen

        StyledWindow {
            id: win

            screen: Quickshell.screens.find(s => s.name === Hypr.focusedMonitor?.name) ?? Quickshell.screens[0]
            name: "sidekick-chat"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.exclusionMode: ExclusionMode.Ignore
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
            implicitWidth: 560
            implicitHeight: 620
            color: "transparent"

            StyledRect {
                anchors.fill: parent
                radius: Tokens.rounding.large
                color: Colours.palette.m3surfaceContainer
                border.color: Sidekick.accent
                border.width: 2

                Item {
                    id: header

                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 48

                    StyledText {
                        anchors.left: parent.left
                        anchors.leftMargin: 18
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Sidekick · " + Sidekick.label
                        font: Tokens.font.title.small
                    }

                    StyledText {
                        anchors.right: parent.right
                        anchors.rightMargin: 18
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Esc schließt"
                        color: Colours.palette.m3outline
                        font: Tokens.font.body.small
                    }
                }

                ListView {
                    id: messages

                    anchors.top: header.bottom
                    anchors.bottom: inputBox.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.margins: 14
                    clip: true
                    spacing: 8
                    model: Sidekick.chatLog
                    onCountChanged: Qt.callLater(positionViewAtEnd)
                    Component.onCompleted: positionViewAtEnd()

                    delegate: Item {
                        id: entry

                        required property string who
                        required property string text

                        width: messages.width
                        height: bubble.height

                        StyledRect {
                            id: bubble

                            anchors.right: entry.who === "user" ? parent.right : undefined
                            anchors.left: entry.who === "user" ? undefined : parent.left
                            width: Math.min(body.implicitWidth, messages.width * 0.8) + 24
                            height: body.height + 16
                            radius: Tokens.rounding.medium
                            color: entry.who === "user" ? Colours.palette.m3primaryContainer : Colours.palette.m3surfaceContainerHighest

                            StyledText {
                                id: body

                                anchors.centerIn: parent
                                width: Math.min(implicitWidth, messages.width * 0.8)
                                text: entry.text
                                wrapMode: Text.Wrap
                                textFormat: Text.PlainText
                                color: entry.who === "user" ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurface
                            }
                        }
                    }

                    StyledText {
                        anchors.centerIn: parent
                        visible: messages.count === 0
                        width: parent.width - 40
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.Wrap
                        text: "Schreib mir etwas, z. B. „Leg die Aufgabe Steuer machen an“ oder „Welche Aufgaben habe ich?“"
                        color: Colours.palette.m3outline
                    }
                }

                StyledRect {
                    id: inputBox

                    anchors.bottom: parent.bottom
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.margins: 14
                    height: 46
                    radius: Tokens.rounding.medium
                    color: Colours.palette.m3surfaceContainerHighest
                    border.color: input.activeFocus ? Sidekick.accent : Colours.palette.m3outlineVariant

                    TextInput {
                        id: input

                        function submit(): void {
                            Sidekick.send(text);
                            text = "";
                        }

                        anchors.fill: parent
                        anchors.leftMargin: 14
                        anchors.rightMargin: 14
                        verticalAlignment: TextInput.AlignVCenter
                        color: Colours.palette.m3onSurface
                        selectionColor: Colours.palette.m3secondaryContainer
                        font: Tokens.font.body.medium
                        clip: true
                        focus: true
                        Component.onCompleted: forceActiveFocus()

                        Keys.onReturnPressed: submit()
                        Keys.onEnterPressed: submit()
                        Keys.onEscapePressed: Sidekick.chatOpen = false

                        StyledText {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: !input.text && !input.preeditText
                            text: Sidekick.mode === "thinking" ? "Sidekick denkt nach …" : "Nachricht an den Sidekick, Enter zum Senden"
                            color: Colours.palette.m3outline
                        }
                    }
                }
            }
        }
    }
}
