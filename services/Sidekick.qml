pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Sprach-Sidekick (~/projects/sidekick): hält "sidekick.py live" am Laufen und merkt sich Zustand und Chat.
// Angezeigt in der Leiste (modules/bar/components/Sidekick.qml), Chat-Fenster in modules/sidekick.
// Chat ein/aus: qs -c caelestia ipc call buddy toggleChat
Singleton {
    id: root

    readonly property string script: `${Quickshell.env("HOME")}/projects/sidekick/sidekick.py`
    property string mode: "starting" // starting | listening | hearing | thinking | speaking | muted | off
    property string bubble: ""
    property bool chatOpen: false
    readonly property alias chatLog: chatLog

    readonly property var look: ({
            starting: ["#8a8f98", "Starte …"],
            listening: ["#4ade80", "Ich höre zu"],
            hearing: ["#22d3ee", "Ich höre dich"],
            thinking: ["#fbbf24", "Ich denke nach"],
            speaking: ["#818cf8", "Ich spreche"],
            muted: ["#f87171", "Stumm"],
            off: ["#8a8f98", "Aus"]
        })
    readonly property color accent: (look[mode] ?? look.off)[0]
    readonly property string label: (look[mode] ?? look.off)[1]

    function send(text: string): void {
        text = text.trim();
        if (text)
            live.write(text.replace(/\n/g, " ") + "\n");
    }

    function toggleMute(): void {
        Quickshell.execDetached([script, "mute"]);
    }

    ListModel {
        id: chatLog
    }

    IpcHandler {
        target: "buddy"

        function toggleChat(): void {
            root.chatOpen = !root.chatOpen;
        }
    }

    Process {
        id: live

        command: [root.script, "live"]
        running: true
        stdinEnabled: true
        stdout: SplitParser {
            onRead: line => {
                let msg;
                try {
                    msg = JSON.parse(line);
                } catch (e) {
                    return;
                }
                root.mode = msg.state;
                if (msg.from && msg.text)
                    chatLog.append({
                        who: msg.from,
                        text: msg.text
                    });
                if (msg.text) {
                    root.bubble = msg.text;
                    hideBubble.restart();
                }
            }
        }
        onExited: {
            root.mode = "off";
            restart.start();
        }
    }

    Timer {
        id: restart

        interval: 3000
        onTriggered: live.running = true
    }

    Timer {
        id: hideBubble

        interval: 9000
        onTriggered: root.bubble = ""
    }
}
