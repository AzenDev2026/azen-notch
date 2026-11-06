import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

// 通知视图：应用图标 + 标题 + 应用名/正文
Item {
    id: view

    property var notice: null

    readonly property bool active: notice !== null
    opacity: active ? 1 : 0
    visible: opacity > 0
    Behavior on opacity { NumberAnimation { duration: 200 } }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 16
        spacing: 12

        Rectangle {
            Layout.preferredWidth: 32
            Layout.preferredHeight: 32
            radius: 8
            color: "#1C1C1E"

            Kirigami.Icon {
                anchors.centerIn: parent
                width: 24
                height: 24
                source: view.notice && view.notice.icon ? view.notice.icon : "notifications"
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 1

            Text {
                Layout.fillWidth: true
                text: view.notice ? view.notice.title : ""
                color: "#FFFFFF"
                font.pixelSize: 12
                font.weight: Font.DemiBold
                elide: Text.ElideRight
                maximumLineCount: 1
            }

            Text {
                Layout.fillWidth: true
                text: {
                    if (!view.notice)
                        return ""
                    const app = view.notice.app || ""
                    const body = view.notice.body || ""
                    return app && body ? app + " · " + body : (app || body)
                }
                color: "#98989F"
                font.pixelSize: 10
                elide: Text.ElideRight
                maximumLineCount: 1
            }
        }
    }
}
