import QtQuick
import qs.Ui

BarWidget {
    id: root
    moduleName: "toxusa.yandex-disk"

    implicitWidth: label.implicitWidth + 16
    implicitHeight: barSize

    Text {
        id: label
        anchors.centerIn: parent
        text: "YD"
        color: "white"
        font.pixelSize: 14
    }
}
