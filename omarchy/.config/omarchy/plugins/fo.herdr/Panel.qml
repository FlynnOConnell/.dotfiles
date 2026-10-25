import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Commons as Commons
import qs.Ui

// herdr's agents from the bar: the icon counts the ones waiting on you, the
// panel says what each is doing. overview.py streams the data as JSON lines;
// choosing a row shows that agent in herdr and raises its terminal.
Panel {
  id: root
  moduleName: "fo.herdr"
  ipcTarget: "fo.herdr"

  readonly property string helperPath: String(Qt.resolvedUrl("overview.py")).replace(/^file:\/\//, "")
  readonly property color foreground: bar ? bar.foreground : Commons.Color.foreground
  readonly property color urgent: bar ? bar.urgent : Commons.Color.urgent
  readonly property color accent: Commons.Color.accent
  readonly property color dim: Qt.darker(foreground, 1.55)
  readonly property string fontFamily: bar ? bar.fontFamily : Style.font.family

  property var agents: []
  property string error: "Starting…"
  property int cursorIndex: 0
  property bool cursorActive: false
  property double nowMs: Date.now()

  readonly property var groups: groupAgents(agents)
  readonly property var flatAgents: groups.reduce(function(all, group) { return all.concat(group.agents) }, [])
  readonly property int blockedCount: countStatus(["blocked"])
  readonly property int doneCount: countStatus(["done"])
  readonly property int workingCount: countStatus(["working"])
  readonly property int needsYouCount: blockedCount + doneCount

  readonly property var statusGlyphs: ({ blocked: "󰀦", done: "󰄬", working: "󰦖", idle: "󰒲", unknown: "󰋗" })

  function countStatus(statuses) {
    return agents.filter(function(agent) { return statuses.indexOf(agent.status) >= 0 }).length
  }

  // Waiting on you first, then working, then the rest; herdr's workspace and
  // tab order within each, as overview.py sends them.
  function groupAgents(list) {
    var specs = [
      { title: "NEEDS YOU", statuses: ["blocked", "done"] },
      { title: "WORKING", statuses: ["working"] },
      { title: "IDLE", statuses: ["idle", "unknown"] }
    ]
    var out = []
    var start = 0
    for (var i = 0; i < specs.length; i++) {
      var members = list.filter(function(agent) { return specs[i].statuses.indexOf(agent.status) >= 0 })
      if (members.length === 0) continue
      out.push({ title: specs[i].title, agents: members, start: start })
      start += members.length
    }
    return out
  }

  function applyLine(line) {
    var parsed
    try {
      parsed = JSON.parse(line)
    } catch (e) {
      return
    }
    agents = parsed.agents || []
    error = parsed.ok ? "" : String(parsed.error || "herdr isn't reachable")
    if (cursorIndex >= flatAgents.length) cursorIndex = Math.max(0, flatAgents.length - 1)
  }

  function statusColor(status) {
    if (status === "blocked") return root.urgent
    if (status === "done") return root.accent
    if (status === "working") return root.foreground
    return root.dim
  }

  function age(ms) {
    if (!ms) return ""
    var minutes = Math.floor((root.nowMs - ms) / 60000)
    if (minutes < 1) return "now"
    if (minutes < 60) return minutes + "m"
    var hours = Math.floor(minutes / 60)
    return hours < 24 ? hours + "h" : Math.floor(hours / 24) + "d"
  }

  function statusText(agent) {
    if (agent.status === "blocked") return "needs approval"
    if (agent.status === "working") return "working " + age(agent.ms_prompt)
    var since = age(agent.ms_active)
    return agent.status + (since === "" ? "" : since === "now" ? " just now" : " " + since + " ago")
  }

  function heroMeta() {
    if (error !== "") return error
    if (agents.length === 0) return "No agents running"
    var parts = []
    if (needsYouCount > 0) parts.push(needsYouCount + " need" + (needsYouCount === 1 ? "s" : "") + " you")
    if (workingCount > 0) parts.push(workingCount + " working")
    var resting = agents.length - needsYouCount - workingCount
    if (resting > 0) parts.push(resting + " idle")
    return parts.join(" · ")
  }

  function focusAgent(agent) {
    if (!agent) return
    Quickshell.execDetached(["python3", "-I", root.helperPath, "focus", agent.pane_id])
    root.close()
  }

  function moveCursor(dy) {
    cursorActive = true
    if (flatAgents.length === 0) return
    cursorIndex = Math.max(0, Math.min(flatAgents.length - 1, cursorIndex + dy))
    scrollCursorIntoView()
  }

  function scrollCursorIntoView() {
    Qt.callLater(function() {
      var row = rowAt(cursorIndex)
      if (!row || !panelFlick) return
      var top = row.mapToItem(panelFlick.contentItem, 0, 0).y
      var bottom = top + row.height
      var margin = Style.space(6)
      if (top < panelFlick.contentY + margin) panelFlick.contentY = Math.max(0, top - margin)
      else if (bottom > panelFlick.contentY + panelFlick.height - margin)
        panelFlick.contentY = Math.min(Math.max(0, panelFlick.contentHeight - panelFlick.height), bottom + margin - panelFlick.height)
    })
  }

  function rowAt(index) {
    for (var g = 0; g < groupRepeater.count; g++) {
      var group = groupRepeater.itemAt(g)
      if (group && index >= group.start && index < group.start + group.rowCount) return group.rowAt(index - group.start)
    }
    return null
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  onOpenedChanged: if (opened) {
    nowMs = Date.now()
    cursorActive = false
    cursorIndex = 0
    if (panelFlick) panelFlick.contentY = 0
    Qt.callLater(function() { keyCatcher.forceActiveFocus() })
  }

  Process {
    id: helper
    running: true
    command: ["python3", "-I", root.helperPath, "watch"]
    stdout: SplitParser { onRead: function(line) { root.applyLine(line) } }
    onExited: function(exitCode) {
      root.error = "Overview helper stopped (" + exitCode + "), restarting…"
      restartTimer.start()
    }
  }

  Timer {
    id: restartTimer
    interval: 5000
    onTriggered: helper.running = true
  }

  Timer {
    interval: 30000
    running: root.opened
    repeat: true
    onTriggered: root.nowMs = Date.now()
  }

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: "󰚩" + (root.needsYouCount > 0 ? " " + root.needsYouCount : "")
    active: root.blockedCount > 0
    dimmed: root.error !== "" || (root.needsYouCount === 0 && root.workingCount === 0)
    tooltipText: root.opened ? "" : root.heroMeta()
    onPressed: function(buttonCode) { root.toggle() }
  }

  KeyboardPanel {
    id: panel
    anchorItem: button
    owner: root
    bar: root.bar
    open: root.opened
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(460))
    contentHeight: panel.fittedContentHeight(column.implicitHeight, Style.space(680))

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      onMoveRequested: function(dx, dy) {
        if (!root.cursorActive) { root.cursorActive = true; return }
        root.moveCursor(dy)
      }
      onActivateRequested: if (root.cursorActive) root.focusAgent(root.flatAgents[root.cursorIndex])
      onCloseRequested: root.close()
      onTabRequested: function(direction) { root.switchPanel(direction) }

      Flickable {
        id: panelFlick
        anchors.fill: parent
        contentWidth: width
        contentHeight: column.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        flickableDirection: Flickable.VerticalFlick
        interactive: contentHeight > height
        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

        Column {
          id: column
          width: panelFlick.width
          spacing: Style.space(12)

          PanelHero {
            width: parent.width
            title: "Agents"
            meta: root.heroMeta()
            foreground: root.foreground
            fontFamily: root.fontFamily
            iconComponent: Component {
              Text {
                text: "󰚩"
                color: root.foreground
                font.family: root.fontFamily
                font.pixelSize: Style.font.display
              }
            }
          }

          Repeater {
            id: groupRepeater
            model: root.groups

            Column {
              id: groupColumn
              required property var modelData
              readonly property int start: modelData.start
              readonly property int rowCount: rowRepeater.count
              function rowAt(index) { return rowRepeater.itemAt(index) }

              width: column.width
              spacing: Style.space(6)

              PanelSectionHeader {
                text: groupColumn.modelData.title
                foreground: root.foreground
                fontFamily: root.fontFamily
              }

              Repeater {
                id: rowRepeater
                model: groupColumn.modelData.agents
                AgentRow {
                  required property var modelData
                  required property int index
                  width: groupColumn.width
                  agent: modelData
                  rowIndex: groupColumn.start + index
                }
              }
            }
          }
        }
      }
    }
  }

  component AgentRow: CursorSurface {
    id: agentRow
    property var agent: ({})
    property int rowIndex: 0
    readonly property bool showPrompt: agent.summary_kind !== "prompt" && String(agent.prompt || "") !== ""

    hasCursor: root.cursorActive && root.cursorIndex === rowIndex
    foreground: root.foreground
    implicitHeight: rowContent.implicitHeight + Style.spacing.rowPaddingX

    MouseArea {
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onEntered: {
        root.cursorActive = true
        root.cursorIndex = agentRow.rowIndex
      }
      onClicked: root.focusAgent(agentRow.agent)
    }

    RowLayout {
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      anchors.leftMargin: Style.space(10)
      anchors.rightMargin: Style.space(10)
      spacing: Style.space(10)

      Text {
        textFormat: Text.PlainText
        text: root.statusGlyphs[agentRow.agent.status] || root.statusGlyphs.unknown
        color: root.statusColor(agentRow.agent.status)
        font.family: root.fontFamily
        font.pixelSize: Style.font.icon
        Layout.alignment: Qt.AlignTop
        Layout.topMargin: Style.space(1)
      }

      ColumnLayout {
        id: rowContent
        Layout.fillWidth: true
        spacing: Style.space(2)

        RowLayout {
          Layout.fillWidth: true
          spacing: Style.space(8)

          Text {
            textFormat: Text.PlainText
            Layout.fillWidth: true
            text: agentRow.agent.title
            color: root.foreground
            font.family: root.fontFamily
            font.pixelSize: Style.font.body
            elide: Text.ElideRight
          }

          Text {
            textFormat: Text.PlainText
            text: root.statusText(agentRow.agent)
            color: root.statusColor(agentRow.agent.status)
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
          }
        }

        Text {
          textFormat: Text.PlainText
          Layout.fillWidth: true
          text: agentRow.agent.workspace + "  ›  tab " + agentRow.agent.tab
          color: root.dim
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
          elide: Text.ElideRight
        }

        Text {
          textFormat: Text.PlainText
          visible: text !== ""
          Layout.fillWidth: true
          Layout.topMargin: Style.space(2)
          text: agentRow.agent.summary || ""
          color: root.foreground
          opacity: 0.85
          font.family: root.fontFamily
          font.pixelSize: Style.font.bodySmall
          wrapMode: Text.WordWrap
          maximumLineCount: 3
          elide: Text.ElideRight
        }

        Text {
          textFormat: Text.PlainText
          visible: agentRow.showPrompt
          Layout.fillWidth: true
          text: "You: " + (agentRow.agent.prompt || "")
          color: root.dim
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
          elide: Text.ElideRight
        }
      }
    }
  }
}
