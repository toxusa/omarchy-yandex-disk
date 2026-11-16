import QtQuick
import QtQuick.Effects
import qs.Commons as Commons

Item {
    id: root

    property color color: Commons.Color.foreground

    implicitWidth: 24
    implicitHeight: 24

    Image {
        id: sourceImage
        anchors.fill: parent
        source: Qt.resolvedUrl("assets/yandex-disk.svg")
        sourceSize.width: Math.max(1, Math.round(width))
        sourceSize.height: Math.max(1, Math.round(height))
        fillMode: Image.PreserveAspectFit
        smooth: true
        visible: false
        layer.enabled: true
    }

    MultiEffect {
        anchors.fill: sourceImage
        source: sourceImage
        colorization: 1.0
        colorizationColor: root.color
    }
}
