import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

// A frame around one monitor on the overlay layer, so it shows over fullscreen
// windows, and click-through. bindings.lua shows it while the focused Moonlight
// stream has the keyboard and mouse:
//   omarchy-shell fo.stream-frame show eDP-1
//   omarchy-shell fo.stream-frame hide
Item {
  id: root

  property string monitor: ""

  IpcHandler {
    target: "fo.stream-frame"

    function show(monitor: string): void { root.monitor = monitor }
    function hide(): void { root.monitor = "" }
  }

  Variants {
    model: Quickshell.screens

    PanelWindow {
      required property var modelData

      screen: modelData
      visible: modelData.name === root.monitor
      color: "transparent"
      anchors { top: true; bottom: true; left: true; right: true }
      WlrLayershell.namespace: "fo-stream-frame"
      WlrLayershell.layer: WlrLayer.Overlay
      WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
      exclusionMode: ExclusionMode.Ignore
      mask: Region {}

      Rectangle {
        anchors.fill: parent
        color: "transparent"
        border.color: "#1f6b2a"
        border.width: 4
      }
    }
  }
}
