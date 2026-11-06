import QtQuick

// 视图冒烟测试：QT_QPA_PLATFORM=offscreen qml6 test/views.qml
Item {
    width: 350
    height: 34

    NoticeView {
        anchors.fill: parent
        notice: { "app": "测试应用", "title": "你好，刘海！", "body": "这是一条测试通知", "icon": "dialog-information" }
    }
    VolumeView {
        anchors.fill: parent
        active: true
        percent: 42
        muted: false
    }
    BrightnessView {
        anchors.fill: parent
        active: false
        percent: 75
    }

    Component.onCompleted: print("views loaded ok")
}
