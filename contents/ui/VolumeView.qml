import QtQuick
import QtQuick.Layouts
import org.kde.plasma.private.volume

// 音量视图：白色喇叭图形 + 可拖动音量条 + 百分比
// 点喇叭 = 静音/取消静音，拖动音量条 = 调整音量
Item {
    id: view

    property real percent: 0
    property bool muted: false
    property bool active: false

    opacity: active ? 1 : 0
    visible: opacity > 0
    Behavior on opacity { NumberAnimation { duration: 200 } }

    Connections {
        target: view
        function onMutedChanged() { glyph.requestPaint() }
    }

    function setFromMouse(mx, w) {
        const s = root.sink
        if (!s)
            return
        const ratio = Math.max(0, Math.min(1, mx / w))
        s.muted = false
        s.volume = Math.round(ratio * PulseAudio.NormalVolume)
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 14
        anchors.rightMargin: 14
        spacing: 12

        MouseArea {
            Layout.preferredWidth: 24
            Layout.preferredHeight: 24
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                const s = root.sink
                if (s)
                    s.muted = !s.muted
            }

            Canvas {
                id: glyph
                anchors.fill: parent
                onPaint: {
                    const c = getContext("2d")
                    c.reset()
                    c.strokeStyle = "#FFFFFF"
                    c.fillStyle = "#FFFFFF"
                    c.lineWidth = 1.8
                    c.lineCap = "round"
                    c.lineJoin = "round"

                    // 喇叭主体
                    c.beginPath()
                    c.moveTo(3, 9.2)
                    c.lineTo(7, 9.2)
                    c.lineTo(11, 5.6)
                    c.lineTo(11, 18.4)
                    c.lineTo(7, 14.8)
                    c.lineTo(3, 14.8)
                    c.closePath()
                    c.fill()

                    // 声波
                    c.beginPath()
                    c.arc(15, 12, 3.4, -0.95, 0.95)
                    c.stroke()
                    if (!view.muted) {
                        c.beginPath()
                        c.arc(15, 12, 6.2, -0.9, 0.9)
                        c.stroke()
                    }

                    // 静音斜线
                    if (view.muted) {
                        c.beginPath()
                        c.moveTo(19.5, 8)
                        c.lineTo(23.5, 16)
                        c.stroke()
                    }
                }
            }
        }

        MouseArea {
            id: barArea
            Layout.fillWidth: true
            Layout.preferredHeight: 14
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: view.setFromMouse(mouse.x, width)
            onPositionChanged: if (pressed) view.setFromMouse(mouse.x, width)

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
                opacity: view.muted ? 0.45 : 1
                Behavior on width { NumberAnimation { duration: 120 } }
            }
        }

        Text {
            Layout.preferredWidth: 40
            horizontalAlignment: Text.AlignRight
            text: Math.round(view.percent) + "%"
            color: view.muted ? "#6E6E73" : "#B8B8BD"
            font.pixelSize: 11
        }
    }
}
