import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services

// Hover-Popout für den Sidekick in der Leiste (components/Sidekick.qml)
ColumnLayout {
    id: root

    implicitWidth: 300
    spacing: Tokens.spacing.small

    RowLayout {
        Layout.fillWidth: true

        StyledText {
            Layout.fillWidth: true
            text: "Sidekick"
            font: Tokens.font.title.small
        }

        StyledRect {
            implicitWidth: state.implicitWidth + Tokens.padding.medium * 2
            implicitHeight: state.implicitHeight + Tokens.padding.extraSmall * 2
            radius: Tokens.rounding.full
            color: Qt.alpha(Sidekick.accent, 0.2)

            StyledText {
                id: state

                anchors.centerIn: parent
                text: Sidekick.label
                color: Sidekick.accent
                font: Tokens.font.label.small
            }
        }
    }

    StyledText {
        Layout.fillWidth: true
        visible: Sidekick.bubble !== ""
        text: Sidekick.bubble
        wrapMode: Text.Wrap
        font: Tokens.font.body.small
    }

    RowLayout {
        Layout.topMargin: Tokens.spacing.small
        Layout.fillWidth: true
        spacing: Tokens.spacing.small

        TextButton {
            Layout.fillWidth: true
            text: "Chat"
            inactiveColour: Colours.palette.m3primaryContainer
            inactiveOnColour: Colours.palette.m3onPrimaryContainer
            onClicked: Sidekick.chatOpen = !Sidekick.chatOpen
        }

        TextButton {
            Layout.fillWidth: true
            text: Sidekick.mode === "muted" ? "Mikro an" : "Stumm"
            inactiveColour: Colours.palette.m3secondaryContainer
            inactiveOnColour: Colours.palette.m3onSecondaryContainer
            onClicked: Sidekick.toggleMute()
        }
    }
}
