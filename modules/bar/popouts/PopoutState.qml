import QtQuick
import Quickshell.Hyprland

QtObject {
    property int previewWorkspace
    property HyprlandMonitor previewMonitor
    property HyprlandToplevel previewClient
    property string currentName
    property bool hasCurrent

    signal detachRequested(mode: string)
}
