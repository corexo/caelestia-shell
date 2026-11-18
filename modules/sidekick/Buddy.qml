import QtQuick
import qs.services

// Der Sidekick als Figur (Pikachu im Chibi-Stil, aus ~/projects/sidekick/buddy.qml), 104 × 116.
// Der Ring um den Kopf trägt die Zustandsfarbe aus Sidekick.accent.
Item {
    id: person

    readonly property color fur: "#ffd93b"
    readonly property color furDark: "#f2c41f"
    readonly property color ink: "#2b2118"
    readonly property color cheek: "#e8443a"
    readonly property bool asleep: Sidekick.mode === "muted" || Sidekick.mode === "off" || Sidekick.mode === "starting"
    readonly property bool lively: Sidekick.mode === "hearing" || Sidekick.mode === "speaking"

    implicitWidth: 104
    implicitHeight: 116

    Rectangle {
        id: halo

        anchors.centerIn: head
        width: head.width + 14
        height: width
        radius: width / 2
        color: "transparent"
        border.color: Sidekick.accent
        border.width: 2
        opacity: 0

        SequentialAnimation {
            running: Sidekick.mode === "hearing" || Sidekick.mode === "speaking" || Sidekick.mode === "thinking"
            loops: Animation.Infinite
            onRunningChanged: if (!running) {
                halo.opacity = 0;
                halo.scale = 1;
            }

            ParallelAnimation {
                NumberAnimation { target: halo; property: "scale"; from: 1; to: 1.3; duration: 900 }
                NumberAnimation { target: halo; property: "opacity"; from: 0.8; to: 0; duration: 900 }
            }
        }
    }

    // Blitz-Schwanz: braunes Ansatzstück, dann zwei gelbe Zacken
    Repeater {
        model: [[70, 90, 8, 18, -38, "#8a5a2b"], [74, 70, 13, 26, 32, "#ffd93b"], [80, 50, 18, 26, -22, "#ffd93b"]]

        Rectangle {
            required property var modelData

            x: modelData[0]
            y: modelData[1]
            width: modelData[2]
            height: modelData[3]
            radius: 2
            rotation: modelData[4]
            color: modelData[5]
        }
    }

    // Füße
    Repeater {
        model: 2

        Rectangle {
            x: index === 0 ? 30 : 58
            y: 106
            width: 16
            height: 9
            radius: 4.5
            color: person.furDark
        }
    }

    // Ärmchen
    Repeater {
        model: 2

        Rectangle {
            x: index === 0 ? 26 : 68
            y: 86
            width: 10
            height: 17
            radius: 5
            rotation: index === 0 ? 22 : -22
            color: person.furDark
        }
    }

    // Körper
    Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        y: 80
        width: 44
        height: 32
        topLeftRadius: 18
        topRightRadius: 18
        bottomLeftRadius: 13
        bottomRightRadius: 13
        color: person.fur
    }

    // Kopf; neigt sich, wenn er dich hört
    Rectangle {
        id: head

        anchors.horizontalCenter: parent.horizontalCenter
        y: 38
        width: 68
        height: 54
        radius: 27
        color: person.fur
        rotation: Sidekick.mode === "hearing" ? -8 : 0
        transformOrigin: Item.Bottom

        Behavior on rotation {
            NumberAnimation { duration: 250; easing.type: Easing.OutBack }
        }

        // Lange Ohren mit schwarzen Spitzen; hängen bei Stumm herunter
        Repeater {
            model: 2

            Rectangle {
                z: -1
                x: index === 0 ? 3 : parent.width - 18
                y: -36
                width: 15
                height: 48
                radius: 7.5
                color: person.fur
                transformOrigin: Item.Bottom
                rotation: (index === 0 ? -1 : 1) * (person.asleep ? 36 : 24)

                Behavior on rotation {
                    NumberAnimation { duration: 300; easing.type: Easing.OutBack }
                }

                Rectangle {
                    width: parent.width
                    height: 18
                    topLeftRadius: 7.5
                    topRightRadius: 7.5
                    bottomLeftRadius: 3
                    bottomRightRadius: 3
                    color: person.ink
                }
            }
        }

        // Augen mit Glanzpunkt
        Repeater {
            model: 2

            Rectangle {
                id: eye

                x: index === 0 ? 13 : parent.width - 24
                y: 24 - height / 2
                width: 11
                height: person.asleep ? 2.5 : 11
                radius: person.asleep ? 1.25 : 5.5
                color: person.ink

                Behavior on height {
                    NumberAnimation { duration: 120 }
                }

                SequentialAnimation on height {
                    running: !person.asleep
                    loops: Animation.Infinite

                    PauseAnimation { duration: 3400 }
                    NumberAnimation { to: 2.5; duration: 80 }
                    NumberAnimation { to: 11; duration: 100 }
                }

                Rectangle {
                    x: 2
                    y: 1.5
                    width: 4
                    height: 4
                    radius: 2
                    color: "white"
                    visible: eye.height > 7
                }
            }
        }

        // Nase
        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            y: 29
            width: 4
            height: 2.5
            radius: 1.25
            color: person.ink
        }

        // Mund: geht beim Sprechen auf
        Rectangle {
            id: mouth

            anchors.horizontalCenter: parent.horizontalCenter
            y: 34
            width: Sidekick.mode === "speaking" ? 11 : 9
            height: 2.5
            topLeftRadius: 1.5
            topRightRadius: 1.5
            bottomLeftRadius: 5.5
            bottomRightRadius: 5.5
            color: Sidekick.mode === "speaking" ? "#b83a3a" : person.ink

            SequentialAnimation on height {
                running: Sidekick.mode === "speaking"
                loops: Animation.Infinite
                onRunningChanged: if (!running) mouth.height = 2.5

                NumberAnimation { to: 10; duration: 140 }
                NumberAnimation { to: 4; duration: 110 }
                NumberAnimation { to: 8; duration: 120 }
                NumberAnimation { to: 2.5; duration: 130 }
            }
        }

        // Rote Backen; leuchten, wenn er hört oder spricht
        Repeater {
            model: 2

            Rectangle {
                x: index === 0 ? 1 : parent.width - 15
                y: 29
                width: 14
                height: 14
                radius: 7
                color: person.cheek
                scale: person.lively ? 1.15 : 1
                opacity: person.asleep ? 0.6 : 1

                Behavior on scale {
                    NumberAnimation { duration: 200; easing.type: Easing.OutBack }
                }
            }
        }
    }
}
