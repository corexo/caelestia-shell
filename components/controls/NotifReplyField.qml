import QtQuick
import Caelestia.Config
import Caelestia.I18n
import qs.services

// Text answer for notifications that accept an inline reply (e.g. scripts/caelestia-ask)
StyledTextField {
    id: root

    required property NotifData notif

    verticalPadding: Tokens.padding.small
    horizontalPadding: Tokens.padding.medium
    placeholderText: notif?.inlineReplyPlaceholder || Tr.tr("Reply")
    trailingIcon: "send"

    onAccepted: {
        if (!text)
            return;
        notif.reply(text);
        text = "";
    }
}
