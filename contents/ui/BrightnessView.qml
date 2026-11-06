import QtQuick
import QtQuick.Layouts

// 亮度视图：白色太阳图形 + 可拖动亮度条 + 百分比
Item {
    id: view

    property real percent: 0
    property bool active: false

    opacity: active ? 1 : 0
    visible: opacity > 0
    Behavior on opacity { NumberAnimation { duration: 200 } }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 14
        anchors.rightMargin: 14
        spacing: 12

        Canvas {
            id: sun
            Layout.preferredWidth: 24
            Layout.preferredHeight: 24
            onPaint: {
                const c = getContext("2d")
                c.reset()
                c.strokeStyle = "#FFFFFF"
                c.lineWidth = 1.8
                c.lineCap = "round"

                // 太阳本体
                c.beginPath()
                c.arc(12, 12, 3.6, 0, Math.PI * 2)
                c.stroke()

                // 8 条光线
                for (let i = 0; i < 8; ++i) {
                    const a = i * Math.PI / 4
                    c.beginPath()
                    c.moveTo(12 + Math.cos(a) * 6.4, 12 + Math.sin(a) * 6.4)
                    c.lineTo(12 + Math.cos(a) * 9.6, 12 + Math.sin(a) * 9.6)
                    c.stroke()
                }
            }
        }

        MouseArea {
            id: barArea
            Layout.fillWidth: true
            Layout.preferredHeight: 14
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.setBrightnessPercent(mouse.x / width * 100)
            onPositionChanged: if (pressed) root.setBrightnessPercent(mouse.x / width * 100)

            Rectangle {
                id: track
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width
                height: 8
                radius: 4
                color: "#2EFFFFFF"
            }
            Rectangle {
                id: fill
                anchors.verticalCenter: parent.verticalCenter
                width: track.width * Math.min(100, view.percent) / 100
                height: 8
                radius: 4
                color: "#FFFFFF"
                Behavior on width { NumberAnimation { duration: 120 } }
            }
        }

        Text {
            Layout.preferredWidth: 40
            horizontalAlignment: Text.AlignRight
            text: Math.round(view.percent) + "%"
            color: "#B8B8BD"
            font.pixelSize: 11
        }
    }
}
