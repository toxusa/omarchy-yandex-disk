import QtQuick
import Quickshell.Io
import qs.Ui
import QtQuick.Controls as Controls
import qs.Commons as Commons

BarWidget {
    id: root
    moduleName: "toxusa.yandex-disk"

    property string diskState: "loading"
    property string controlError: ""
    property string controlAction: ""
    property bool opened: false
    property bool popoutSwitchClosing: false

    function open() {
        root.opened = true
    }

    function close() {
        root.opened = false
    }

    function toggle() {
        root.opened = root.opened === false
    }

    function closeForPopoutSwitch() {
        root.popoutSwitchClosing = true
        root.close()
        Qt.callLater(function() {
            root.popoutSwitchClosing = false
        })
    }
    function controlDaemon(action) {
        if (controlProcess.running)
            return

        if (action === "start") {
            if (root.diskState !== "stopped")
                return
        } else if (action === "stop") {
            if (["idle", "busy", "index"].indexOf(root.diskState) === -1)
                return
        } else {
            return
        }
        root.controlError = ""
        root.controlAction = action
        controlProcess.command = ["yandex-disk", action]
        controlProcess.running = true
      }

    implicitWidth: label.implicitWidth + 16
    implicitHeight: barSize

    Text {
        id: label
        anchors.centerIn: parent
        text: "YD: " + root.diskState
        color: Commons.Color.foreground
        font.pixelSize: 14
    }
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.toggle()
    }

    KeyboardPanel {
        id: popup
        anchorItem: root
        owner: root
        bar: root.bar
        open: root.opened
        focusTarget: popupContent

        contentWidth: 280
        contentHeight: Math.max(160, popupColumn.implicitHeight)
        padding: 16

        Item {
            id: popupContent
            anchors.fill: parent

            Keys.onPressed: function(event) {
                if (event.key === Qt.Key_Escape) {
                    root.close()
                    event.accepted = true
                }
            }

            Column {
                id: popupColumn
                anchors.fill: parent
                spacing: 12

                Text {
                    text: "Yandex Disk"
                    color: Commons.Color.foreground
                    font.pixelSize: 16
                    font.bold: true
                }

                Text {
                    text: "Status: " + root.diskState
                    color: Commons.Color.foreground
                    font.pixelSize: 14
                }

                Row {
                    spacing: 12

                    Controls.Button {
                        text: "Start"
                        enabled: root.diskState === "stopped"
                            && controlProcess.running === false
                        onClicked: root.controlDaemon("start")
                    }

                    Controls.Button {
                        text: "Stop"
                        enabled: ["idle", "busy", "index"].indexOf(root.diskState) >= 0
                            && controlProcess.running === false
                        onClicked: root.controlDaemon("stop")
                    }
                }
                Text {
                    width: parent.width
                    visible: root.controlError.length > 0
                    text: root.controlError
                    textFormat: Text.PlainText
                    wrapMode: Text.Wrap
                    color: Commons.Color.foreground
                    font.pixelSize: 13
                }
            }
        }
    }
    Process {
        id: controlProcess
        onExited: function(exitCode, exitStatus) {
            if (exitStatus !== 0) {
                root.controlError =
                    "Command '" + root.controlAction + "' terminated abnormally."
            } else if (exitCode !== 0) {
                root.controlError =
                    "Command '" + root.controlAction
                    + "' failed (exit code " + exitCode + ")."
            }
        }
        stdout: StdioCollector {
            onStreamFinished: {
                if (this.text.trim().length > 0)
                    console.log("Yandex Disk control:", this.text.trim())
            }
        }

        stderr: StdioCollector {
            onStreamFinished: {
                if (this.text.trim().length > 0)
                    console.warn("Yandex Disk control:", this.text.trim())
            }
        }
    }
    Process {
        id: statusProcess
        command: [
            "python3",
            decodeURIComponent(Qt.resolvedUrl("yd-status.py").toString().replace(/^file:\/\//, ""))
        ]
        running: true

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const result = JSON.parse(this.text)
                    root.diskState = result.state || "unknown"
                } catch (error) {
                    root.diskState = "error"
                    console.warn("Yandex Disk: invalid status response:", this.text)
                }
            }
        }
    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        onTriggered: {
            if (statusProcess.running === false)
                statusProcess.running = true
        }
    }
}
