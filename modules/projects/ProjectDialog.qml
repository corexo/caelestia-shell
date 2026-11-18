pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Caelestia.Config
import qs.components
import qs.components.containers
import qs.components.controls
import qs.services

// New / edit project dialog, opened by Projects.openDialog() (the + tile and right-click in the bar)
Scope {
    LazyLoader {
        active: Projects.dialogOpen

        StyledWindow {
            id: win

            readonly property var editing: Projects.editing
            property string colour: editing?.colour ?? Projects.colours[Projects.list.length % Projects.colours.length]
            property string error

            function close(): void {
                Projects.dialogOpen = false;
            }

            function submit(): void {
                const name = nameField.text.trim();
                if (editing) {
                    Projects.update(editing.name, dirField.text.trim(), shortField.text.trim(), colour);
                } else {
                    error = Projects.add(name, dirField.text.trim(), shortField.text.trim(), colour);
                    if (error)
                        return;
                    Projects.open(name);
                }
                close();
            }

            screen: Quickshell.screens.find(s => s.name === Hypr.focusedMonitor?.name) ?? Quickshell.screens[0]
            name: "project-dialog"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.exclusionMode: ExclusionMode.Ignore
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
            color: Qt.alpha(Colours.palette.m3scrim, 0.4)

            anchors.top: true
            anchors.bottom: true
            anchors.left: true
            anchors.right: true

            MouseArea {
                anchors.fill: parent
                onClicked: win.close()
            }

            StyledRect {
                anchors.centerIn: parent
                implicitWidth: 460
                implicitHeight: form.implicitHeight + Tokens.padding.extraLarge * 2
                radius: Tokens.rounding.extraLarge
                color: Colours.palette.m3surfaceContainer

                // Swallow clicks so they don't close the dialog
                MouseArea {
                    anchors.fill: parent
                }

                ColumnLayout {
                    id: form

                    anchors.fill: parent
                    anchors.margins: Tokens.padding.extraLarge
                    spacing: Tokens.spacing.large

                    Keys.onEscapePressed: win.close()
                    Keys.onReturnPressed: win.submit()
                    Keys.onEnterPressed: win.submit()

                    StyledText {
                        text: win.editing ? `Projekt ${win.editing.name}` : "Neues Projekt"
                        font: Tokens.font.title.medium
                    }

                    StyledTextField {
                        id: nameField

                        Layout.fillWidth: true
                        placeholderText: "Name"
                        text: win.editing?.name ?? ""
                        readOnly: !!win.editing
                        focus: !win.editing
                        isError: !!win.error
                        errorText: win.error
                        supportingText: win.editing ? "Der Name ist der Workspace und bleibt fest" : "Buchstaben, Ziffern, . _ -"
                        onTextEdited: win.error = ""
                    }

                    StyledTextField {
                        id: dirField

                        Layout.fillWidth: true
                        placeholderText: nameField.text ? `~/projects/${nameField.text.trim()}` : "Ordner"
                        text: win.editing?.dir ?? ""
                        focus: !!win.editing
                        supportingText: "Leer lassen für ~/projects/<Name>"
                    }

                    RowLayout {
                        spacing: Tokens.spacing.large

                        StyledTextField {
                            id: shortField

                            Layout.preferredWidth: 110
                            placeholderText: "Kürzel"
                            text: win.editing?.short ?? ""
                            maximumLength: 3
                        }

                        Repeater {
                            model: Projects.colours

                            delegate: StyledRect {
                                id: swatch

                                required property string modelData

                                implicitWidth: 32
                                implicitHeight: 32
                                radius: Tokens.rounding.full
                                color: modelData
                                border.width: win.colour === modelData ? 3 : 0
                                border.color: Colours.palette.m3onSurface

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: win.colour = swatch.modelData
                                }
                            }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Tokens.spacing.medium

                        TextButton {
                            visible: !!win.editing
                            text: "Entfernen"
                            type: TextButton.Text
                            inactiveOnColour: Colours.palette.m3error
                            onClicked: {
                                Projects.remove(win.editing.name);
                                win.close();
                            }
                        }

                        Item {
                            Layout.fillWidth: true
                        }

                        TextButton {
                            text: "Abbrechen"
                            type: TextButton.Text
                            onClicked: win.close()
                        }

                        TextButton {
                            text: win.editing ? "Speichern" : "Anlegen"
                            inactiveColour: Colours.palette.m3primary
                            inactiveOnColour: Colours.palette.m3onPrimary
                            onClicked: win.submit()
                        }
                    }
                }
            }
        }
    }
}
