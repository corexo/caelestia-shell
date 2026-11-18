import QtQuick
import Caelestia.Config
import qs.components
import qs.services
import qs.modules.sidekick

// Sidekick in der Leiste: Figur verkleinert, Klick = Chat, Rechtsklick = stumm.
// Zustand und letzter Satz stehen im Hover-Popout (popouts/SidekickPopout.qml).
Item {
    id: root

    implicitWidth: Tokens.sizes.bar.innerWidth
    implicitHeight: buddy.implicitHeight * buddy.scale

    Buddy {
        id: buddy

        anchors.centerIn: parent
        scale: root.implicitWidth / implicitWidth
    }

    // Stumm-Punkt unten rechts
    StyledRect {
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        visible: Sidekick.mode === "muted"
        implicitWidth: 16
        implicitHeight: 16
        radius: Tokens.rounding.full
        color: Colours.palette.m3error

        MaterialIcon {
            anchors.centerIn: parent
            text: "mic_off"
            color: Colours.palette.m3onError
            fontStyle: Tokens.font.icon.size(8).build()
        }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onClicked: event => {
            if (event.button === Qt.RightButton)
                Sidekick.toggleMute();
            else
                Sidekick.chatOpen = !Sidekick.chatOpen;
        }
    }
}
