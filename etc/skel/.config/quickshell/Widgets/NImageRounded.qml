import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Widgets
import qs.Commons

Item {
  id: root

  property real radius: 0
  property string imagePath: ""
  property string fallbackIcon: ""
  property real fallbackIconSize: Style.fontSizeXXL
  property real borderWidth: 0
  property color borderColor: Color.transparent
  property int imageFillMode: Image.PreserveAspectCrop

  readonly property bool showFallback: (fallbackIcon !== undefined && fallbackIcon !== "") && (imagePath === undefined || imagePath === "")

  signal statusChanged(int status)

  ClippingRectangle {
    anchors.fill: parent
    color: Color.transparent
    radius: root.radius
    border.color: root.borderColor
    border.width: root.borderWidth

    Image {
      anchors.fill: parent
      visible: !showFallback
      source: imagePath
      mipmap: true
      smooth: true
      asynchronous: true
      antialiasing: true
      fillMode: root.imageFillMode
      onStatusChanged: root.statusChanged(status)
    }

    NIcon {
      anchors.centerIn: parent
      visible: showFallback
      icon: fallbackIcon
      pointSize: fallbackIconSize
    }
  }
}
