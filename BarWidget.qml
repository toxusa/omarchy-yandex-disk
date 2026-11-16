import QtQuick
import Quickshell.Io
import qs.Ui

BarWidget {
    id: root
    moduleName: "toxusa.yandex-disk"

    property string diskState: "loading"

    implicitWidth: label.implicitWidth + 16
    implicitHeight: barSize

    Text {
        id: label
        anchors.centerIn: parent
        text: "YD: " + root.diskState
        color: "white"
        font.pixelSize: 14
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
