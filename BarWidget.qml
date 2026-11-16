pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Io
import qs.Ui
import QtQuick.Controls as Controls
import qs.Commons as Commons

BarWidget {
    id: root
    moduleName: "toxusa.yandex-disk"

    property string diskState: "loading"
    property string statusMessage: ""
    property var recentFiles: []
    property real progressPercent: -1
    property string progressText: ""
    property string controlError: ""
    property string controlAction: ""
    property bool controlTimedOut: false
    property bool opened: false
    property bool popoutSwitchClosing: false
    property string syncMessage: ""
    property string syncDirectory: ""
    property real directoryFileCount: -1
    property real directoryDiskBytes: -1
    property string directoryStatsError: ""
    property int directoryStatsGeneration: 0
    property bool directoryStatsPending: false

    function formatDirectoryStats(fileCount, diskBytes) {
        const countText = String(fileCount).replace(/\B(?=(\d{3})+(?!\d))/g, " ")
        const sizeText = (diskBytes / 1073741824).toFixed(2)
        return countText + " files · " + sizeText + " GiB on disk"
    }
    function refreshDirectoryStats() {
        if (root.syncDirectory.length === 0)
            return

        if (directoryStatsProcess.running) {
            root.directoryStatsPending = true
            return
        }

        root.directoryStatsPending = false
        root.directoryStatsError = ""

        directoryStatsProcess.requestDirectory = root.syncDirectory
        directoryStatsProcess.requestGeneration = root.directoryStatsGeneration
        directoryStatsProcess.command = [
            "python3",
            decodeURIComponent(
                Qt.resolvedUrl("yd-directory-stats.py").toString().replace(/^file:\/\//, "")
            ),
            root.syncDirectory
        ]
        directoryStatsProcess.running = true
    }

    onSyncDirectoryChanged: {
        root.directoryStatsGeneration += 1
        root.directoryFileCount = -1
        root.directoryDiskBytes = -1
        root.directoryStatsError = ""
        root.directoryStatsPending = false

        if (root.syncDirectory.length > 0)
            root.refreshDirectoryStats()
    }

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
    function installClient() {
        if (root.diskState !== "not_installed" || installProcess.running)
            return
        root.controlError = ""
        installProcess.running = true
    }
    function controlDaemon(action) {
        if (controlProcess.running || syncProcess.running)
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
        root.controlTimedOut = false
        controlProcess.command = ["yandex-disk", action]
        controlProcess.running = true
    }

    function refreshStatus() {
         if (statusProcess.running)
              return

          statusProcess.running = true
    }
    function syncNow() {
        if (syncProcess.running || controlProcess.running)
            return

        if (["idle", "busy", "index"].indexOf(root.diskState) === -1)
            return

        root.syncMessage = ""
        syncProcess.running = true
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

        contentWidth: popup.fittedContentWidth(520)
        contentHeight: popup.fittedContentHeight(
            Math.max(160, popupColumn.implicitHeight)
        )

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
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                spacing: 12

                Text {
                    text: "Yandex Disk"
                    color: Commons.Color.foreground
                    font.pixelSize: 16
                    font.bold: true
                }
                Column {
                    width: parent.width
                    spacing: 4
                    visible: root.syncDirectory.length > 0

                    Text {
                        width: parent.width
                        text: root.syncDirectory.endsWith("/")
                            ? root.syncDirectory
                            : root.syncDirectory + "/"
                        textFormat: Text.PlainText
                        wrapMode: Text.WrapAnywhere
                        color: "#888888"
                        font.pixelSize: 12
                    }

                    Text {
                        width: parent.width
                        visible: root.directoryFileCount >= 0
                            && root.directoryDiskBytes >= 0
                        text: root.formatDirectoryStats(
                            root.directoryFileCount,
                            root.directoryDiskBytes
                        )
                        textFormat: Text.PlainText
                        wrapMode: Text.Wrap
                        color: "#888888"
                        font.pixelSize: 12
                    }

                    Text {
                        width: parent.width
                        visible: root.directoryStatsError.length > 0
                        text: "Directory statistics: " + root.directoryStatsError
                        textFormat: Text.PlainText
                        wrapMode: Text.Wrap
                        color: "#888888"
                        font.pixelSize: 12
                    }
                }
                Text {
                    text: "Status: " + root.diskState
                    color: Commons.Color.foreground
                    font.pixelSize: 14
                }
                Column {
                    width: parent.width
                    spacing: 6
                    visible: root.progressText.length > 0
                        || root.progressPercent >= 0

                    Text {
                        width: parent.width
                        text: root.progressText.length > 0
                            ? "Sync progress: " + root.progressText
                            : "Sync progress: " + root.progressPercent + "%"
                        textFormat: Text.PlainText
                        wrapMode: Text.Wrap
                        color: Commons.Color.foreground
                        font.pixelSize: 13
                    }

                    Controls.ProgressBar {
                        width: parent.width
                        visible: root.progressPercent >= 0
                        from: 0
                        to: 100
                        value: root.progressPercent >= 0
                            ? root.progressPercent
                            : 0
                    }
                }

                Text {
                    width: parent.width
                    visible: root.statusMessage.length > 0
                    text: root.statusMessage
                    textFormat: Text.PlainText
                    wrapMode: Text.Wrap
                    color: Commons.Color.foreground
                    font.pixelSize: 13
                }
                Row {
                    spacing: 12

                    Controls.Button {
                        text: "Start"
                        enabled: root.diskState === "stopped"
                            && controlProcess.running === false
                            && syncProcess.running === false
                        onClicked: root.controlDaemon("start")
                        visible: root.diskState !== "not_installed"
                    }

                    Controls.Button {
                        text: "Stop"
                        enabled: ["idle", "busy", "index"].indexOf(root.diskState) >= 0
                            && controlProcess.running === false
                            && syncProcess.running === false
                        onClicked: root.controlDaemon("stop")
                        visible: root.diskState !== "not_installed"
                    }
                    Controls.Button {
                        text: "Install"
                        visible: root.diskState === "not_installed"
                        enabled: installProcess.running === false
                        onClicked: root.installClient()
                    }
                    Controls.Button {
                        text: statusProcess.running ? "Refreshing..." : "Status"
                        enabled: statusProcess.running === false
                        onClicked: root.refreshStatus()
                    }
                    Controls.Button {
                        text: syncProcess.running ? "Syncing..." : "Sync"
                        visible: root.diskState !== "not_installed"
                        enabled: ["idle", "busy", "index"].indexOf(root.diskState) >= 0
                            && controlProcess.running === false
                            && syncProcess.running === false
                        onClicked: root.syncNow()
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
                Text {
                    width: parent.width
                    visible: syncProcess.running || root.syncMessage.length > 0
                    text: syncProcess.running
                        ? "Sync command is running; waiting for synchronization to finish."
                        : root.syncMessage
                    textFormat: Text.PlainText
                    wrapMode: Text.Wrap
                    color: Commons.Color.foreground
                    font.pixelSize: 13
                }
                Text {
                    visible: root.recentFiles.length > 0
                    text: "Last synchronized files"
                    color: Commons.Color.foreground
                    font.pixelSize: 14
                }
                Flickable {
                    id: recentFilesView

                    width: parent.width
                    height: Math.min(recentFilesColumn.implicitHeight, 180)
                    visible: root.recentFiles.length > 0

                    contentWidth: width
                    contentHeight: recentFilesColumn.implicitHeight
                    flickableDirection: Flickable.VerticalFlick
                    boundsBehavior: Flickable.StopAtBounds
                    clip: true

                    Column {
                        id: recentFilesColumn
                        width: Math.max(0, recentFilesView.width - 16)
                        spacing: 8

                        Repeater {
                              model: root.recentFiles

                              delegate: Text {
                                  required property string modelData

                                  width: recentFilesColumn.width
                                  text: modelData
                                  textFormat: Text.PlainText
                                  wrapMode: Text.WrapAnywhere
                                  color: Commons.Color.foreground
                                  font.pixelSize: 12
                              }
                        }
                    }

                    Controls.ScrollBar.vertical: Controls.ScrollBar {
                          policy: Controls.ScrollBar.AsNeeded
                    }
                }
            }
        }
    }
    Process {
      id: controlProcess
        onStarted: controlTimeoutTimer.restart()
        onExited: function(exitCode, exitStatus) {
            controlTimeoutTimer.stop()
            controlKillTimer.stop()
            if (!root.controlTimedOut) {
                if (exitStatus !== 0) {
                    root.controlError =
                        "Command '" + root.controlAction + "' terminated abnormally."
                } else if (exitCode !== 0) {
                    root.controlError =
                        "Command '" + root.controlAction
                        + "' failed (exit code " + exitCode + ")."
                }
            }
            if (statusProcess.running === false)
                statusProcess.running = true
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
        id: directoryStatsProcess

        property string requestDirectory: ""
        property int requestGeneration: -1

        stdout: StdioCollector {
            onStreamFinished: {
                if (directoryStatsProcess.requestGeneration
                        !== root.directoryStatsGeneration
                    || directoryStatsProcess.requestDirectory
                        !== root.syncDirectory) {
                    return
                }

                try {
                    const result = JSON.parse(this.text)

                    if (result.state !== "ok") {
                        root.directoryStatsError =
                            typeof result.message === "string"
                            && result.message.length > 0
                                ? result.message
                                : "Directory statistics request failed."
                        return
                    }

                    if (typeof result.file_count !== "number"
                        || !Number.isSafeInteger(result.file_count)
                        || result.file_count < 0
                        || typeof result.disk_bytes !== "number"
                        || !Number.isSafeInteger(result.disk_bytes)
                        || result.disk_bytes < 0) {
                        root.directoryStatsError =
                            "Invalid values from directory statistics adapter."
                        return
                    }

                    root.directoryFileCount = result.file_count
                    root.directoryDiskBytes = result.disk_bytes
                    root.directoryStatsError = ""
                } catch (error) {
                    root.directoryStatsError =
                        "Invalid response from directory statistics adapter."
                    console.warn(
                        "Yandex Disk: invalid directory statistics response:",
                        this.text
                    )
                }
            }
        }

        stderr: StdioCollector {
            onStreamFinished: {
                if (this.text.trim().length > 0) {
                    console.warn(
                        "Yandex Disk directory statistics:",
                        this.text.trim()
                    )
                }
            }
        }

        onExited: function(exitCode, exitStatus) {
            if (directoryStatsProcess.requestGeneration
                    === root.directoryStatsGeneration
                && directoryStatsProcess.requestDirectory
                    === root.syncDirectory
                && (exitStatus !== 0 || exitCode !== 0)) {
                root.directoryStatsError =
                    "Directory statistics command failed (exit code "
                    + exitCode + ")."
            }

            Qt.callLater(function() {
                if (root.directoryStatsPending)
                    root.refreshDirectoryStats()
            })
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
                    root.statusMessage = result.message || ""
                    root.syncDirectory =
                          typeof result.sync_dir === "string"
                          ? result.sync_dir
                          : ""
                    root.recentFiles = Array.isArray(result.recent_files)
                       ? result.recent_files
                       : []
                    root.progressPercent =
                        typeof result.progress_percent === "number"
                        && Number.isFinite(result.progress_percent)
                        && result.progress_percent >= 0
                        && result.progress_percent <= 100
                            ? result.progress_percent
                            : -1

                    root.progressText =
                        typeof result.progress_text === "string"
                        ? result.progress_text
                        : ""
                } catch (error) {
                    root.diskState = "error"
                    root.statusMessage = "Invalid response from status adapter."
                    console.warn("Yandex Disk: invalid status response:", this.text)
                    root.recentFiles = []
                    root.progressPercent = -1
                    root.progressText = ""
                    root.syncDirectory = ""
                }
            }
        }
    }
    Process {
        id: installProcess

        command: [
            "omarchy-launch-terminal",
            "bash",
            decodeURIComponent(
                Qt.resolvedUrl("install-client.sh").toString().replace(/^file:\/\//, "")
            )
        ]
        onExited: function(exitCode, exitStatus) {
            if (exitStatus !== 0 || exitCode !== 0) {
                root.controlError = "Could not launch the installer terminal."
            }
        }

        stderr: StdioCollector {
            onStreamFinished: {
                if (this.text.trim().length > 0)
                    console.warn("Yandex Disk installer:", this.text.trim())
            }
        }
    }
    Process {
        id: syncProcess
        command: ["yandex-disk", "sync"]

        onStarted: root.refreshStatus()

        onExited: function(exitCode, exitStatus) {
            if (exitStatus !== 0) {
                root.syncMessage = "Sync command terminated abnormally."
            } else if (exitCode !== 0) {
                root.syncMessage =
                    "Sync command failed (exit code " + exitCode + ")."
            } else {
                root.syncMessage = "Sync command completed successfully."
            }

            root.refreshStatus()
            root.refreshDirectoryStats()
        }

        stdout: StdioCollector {
            onStreamFinished: {
                if (this.text.trim().length > 0)
                    console.log("Yandex Disk sync:", this.text.trim())
            }
       }

        stderr: StdioCollector {
            onStreamFinished: {
                if (this.text.trim().length > 0)
                    console.warn("Yandex Disk sync:", this.text.trim())
            }
        }
    }
    Timer {
        interval: 300000
        running: root.syncDirectory.length > 0
        repeat: true
        onTriggered: root.refreshDirectoryStats()
    }
    Timer {
        interval: 5000
        running: true
        repeat: true
        onTriggered: root.refreshStatus()
    }
    Timer {
        id: controlTimeoutTimer
        interval: 15000
        repeat: false

        onTriggered: {
            if (!controlProcess.running)
                return

            root.controlTimedOut = true
            root.controlError =
                "Command '" + root.controlAction
                + "' timed out after 15 seconds. Requesting termination."

            controlKillTimer.restart()
            controlProcess.signal(15) // SIGTERM
        }
    }

    Timer {
        id: controlKillTimer
        interval: 3000
        repeat: false

        onTriggered: {
            if (!controlProcess.running)
                return

            root.controlError =
                "Command '" + root.controlAction
                + "' timed out and required forced termination."

            controlProcess.signal(9) // SIGKILL
        }
    }
}
