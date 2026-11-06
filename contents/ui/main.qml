/*
 * Azen Notch — iPhone Dynamic Island 风格的桌面刘海
 *
 * 放在 KDE Plasma 6 顶部面板中央：
 *   - 平时显示一块纯黑圆角胶囊（中间带摄像头小点，像 MacBook 刘海）
 *   - 来通知 / 调音量 / 调亮度时弹性展开，显示 3 秒后收起
 *
 * 尺寸和时长可在下方"外观常量"区调整。
 */
import QtQuick
import QtQuick.Layouts
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid
import org.kde.notificationmanager as NotificationManager
import org.kde.plasma.private.volume
import org.kde.plasma.private.brightnesscontrolplugin as Brightness

PlasmoidItem {
    id: root

    // ==================== 外观常量（想改大小就在这里改） ====================
    readonly property int idleWidth: 178      // 静息时宽度 ≈ 5 个应用图标
    readonly property int noticeWidth: 350    // 显示通知时的宽度
    readonly property int ctrlWidth: 270      // 显示音量/亮度时的宽度
    readonly property int showDuration: 3000  // 每次显示的时长（毫秒），默认 3 秒
    readonly property color notchColor: "#000000"

    // 贴边模式：在顶部面板时刘海与屏幕上缘融为一体（MacBook 刘海样式），
    // 顶部平直连接边框、底部圆润；在底部面板时同理向下贴边；
    // 在其他位置（桌面等）保持完整的悬浮胶囊
    readonly property bool topEdge: plasmoid.location === PlasmaCore.Types.TopEdge
    readonly property bool bottomEdge: plasmoid.location === PlasmaCore.Types.BottomEdge
    readonly property bool attached: topEdge || bottomEdge
    readonly property bool verticalPanel: plasmoid.formFactor === PlasmaCore.Types.Vertical
    readonly property int islandHeight: parent
        ? (attached
            ? parent.height
            : Math.max(26, Math.min(38, (verticalPanel ? parent.width : parent.height) - 6)))
        : 34

    // 组件在面板中预留固定宽度（= 通知宽度），刘海在其中弹性变形，
    // 这样展开时不会把两侧的面板元素挤得跳来跳去
    readonly property int cellWidth: noticeWidth

    // ==================== 显示状态 ====================
    property string mode: "idle"            // idle | notice | volume | brightness
    property var currentNotice: null
    property var noticeQueue: []
    property real volumePercent: 0
    property bool volumeMuted: false
    property real brightnessPercent: 0
    property bool brightnessAvailable: false

    property real pillWidth: idleWidth
    Behavior on pillWidth {
        NumberAnimation {
            duration: 460
            easing.type: Easing.Bezier
            easing.bezierCurve: [0.32, 1.30, 0.42, 1.0]   // iOS 弹簧式回弹曲线
        }
    }

    function applyMode(m) {
        mode = m
        pillWidth = m === "notice" ? noticeWidth : (m === "idle" ? idleWidth : ctrlWidth)
    }

    function advance() {
        if (noticeQueue.length > 0) {
            currentNotice = noticeQueue.shift()
            applyMode("notice")
            hideTimer.restart()
        } else {
            currentNotice = null
            applyMode("idle")
        }
    }

    // ==================== 事件入口 ====================
    function showNotice(d) {
        noticeQueue.push(d)
        if (noticeQueue.length > 3)
            noticeQueue.shift()                  // 最多排队 3 条
        if (mode === "idle")
            advance()
    }

    function showVolume() {
        if (mode === "notice" && currentNotice)
            noticeQueue.unshift(currentNotice)    // 被打断的通知放回队首
        currentNotice = null
        applyMode("volume")
        hideTimer.restart()
    }

    function showBrightness() {
        if (mode === "notice" && currentNotice)
            noticeQueue.unshift(currentNotice)
        currentNotice = null
        applyMode("brightness")
        hideTimer.restart()
    }

    Timer {
        id: hideTimer
        interval: showDuration
        repeat: false
        onTriggered: root.advance()
    }

    // ==================== 数据源 1：系统通知 ====================
    NotificationManager.Notifications {
        id: notifications
        limit: 8
        showNotifications: true
        showJobs: false
        showExpired: true
        showDismissed: true
        sortMode: NotificationManager.Notifications.SortByTypeAndUrgency
        sortOrder: Qt.DescendingOrder
        groupMode: NotificationManager.Notifications.GroupDisabled
    }

    property int lastUnread: 0

    function rowValue(row, role, fallback) {
        const idx = notifications.index(row, 0)
        const v = notifications.data(idx, role)
        return (v === undefined || v === null) ? fallback : v
    }

    function latestNotificationRow() {
        for (let i = 0; i < notifications.count; ++i) {
            const type = rowValue(i, NotificationManager.Notifications.TypeRole, NotificationManager.Notifications.NoType)
            if (type === NotificationManager.Notifications.NotificationType
                && !rowValue(i, NotificationManager.Notifications.ExpiredRole, false))
                return i
        }
        return -1
    }

    function cleanText(s) {
        return String(s || "")
            .replace(/<[^>]*>/g, " ")
            .replace(/&amp;/g, "&").replace(/&lt;/g, "<").replace(/&gt;/g, ">")
            .replace(/&quot;/g, "\"").replace(/&#39;/g, "'").replace(/&nbsp;/g, " ")
            .replace(/\s+/g, " ").trim()
    }

    Connections {
        target: notifications
        function onUnreadNotificationsCountChanged() {
            const c = notifications.unreadNotificationsCount
            if (c > root.lastUnread) {
                const row = root.latestNotificationRow()
                if (row >= 0) {
                    root.showNotice({
                        app: root.cleanText(
                            root.rowValue(row, NotificationManager.Notifications.ApplicationNameRole, "") ||
                            root.rowValue(row, NotificationManager.Notifications.DesktopEntryRole, "通知")),
                        title: root.cleanText(root.rowValue(row, NotificationManager.Notifications.SummaryRole, "通知")),
                        body: root.cleanText(root.rowValue(row, NotificationManager.Notifications.BodyRole, "")),
                        icon: root.rowValue(row, NotificationManager.Notifications.IconNameRole, "") ||
                              root.rowValue(row, NotificationManager.Notifications.ApplicationIconNameRole, "") ||
                              "notifications"
                    })
                }
            }
            root.lastUnread = c
        }
    }

    // ==================== 数据源 2：音量 ====================
    readonly property var sink: PreferredDevice.sink || null

    function refreshVolume() {
        const s = sink
        if (!s)
            return
        volumePercent = Math.round(s.volume / PulseAudio.NormalVolume * 100)
        volumeMuted = s.muted
    }

    Connections {
        target: root.sink
        function onVolumeChanged() {
            root.refreshVolume()
            if (root.sink)
                root.showVolume()
        }
        function onMutedChanged() {
            root.refreshVolume()
            if (root.sink)
                root.showVolume()
        }
    }

    // ==================== 数据源 3：屏幕亮度 ====================
    property string brightnessDisplayName: ""
    property int brightnessMax: 1
    property bool brightnessInitDone: false

    Brightness.ScreenBrightnessControl {
        id: screenBrightness
        isSilent: true
    }

    Instantiator {
        model: screenBrightness.displays
        delegate: QtObject {
            required property int index
            required property string displayName
            required property int brightness
            required property int maxBrightness
            function sync() {
                if (index === 0)
                    root.applyBrightness(displayName, brightness, maxBrightness)
            }
            Component.onCompleted: sync()
            onBrightnessChanged: sync()
            onMaxBrightnessChanged: sync()
            onDisplayNameChanged: sync()
        }
    }

    function applyBrightness(name, value, max) {
        const safeMax = Math.max(1, max)
        brightnessDisplayName = name || ""
        brightnessMax = safeMax
        brightnessAvailable = screenBrightness.isBrightnessAvailable
        const pct = Math.round(Math.max(0, value) * 100 / safeMax)
        if (!brightnessInitDone) {
            brightnessInitDone = true
            brightnessPercent = pct
            return
        }
        if (brightnessAvailable && Math.abs(pct - brightnessPercent) >= 1) {
            brightnessPercent = pct
            showBrightness()
        }
    }

    function setBrightnessPercent(pct) {
        if (!brightnessAvailable)
            return
        const p = Math.max(0, Math.min(100, pct))
        screenBrightness.setBrightness(brightnessDisplayName, Math.round(brightnessMax * p / 100))
    }

    Component.onCompleted: {
        lastUnread = notifications.unreadNotificationsCount
        refreshVolume()
    }

    // ==================== 面板集成 ====================
    Layout.preferredWidth: cellWidth
    Layout.minimumWidth: cellWidth
    Layout.maximumWidth: cellWidth
    Layout.preferredHeight: islandHeight
    Layout.minimumHeight: islandHeight
    Layout.maximumHeight: islandHeight

    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
    Plasmoid.status: PlasmaCore.Types.PassiveStatus
    Plasmoid.title: "Azen Notch"
    preferredRepresentation: compactRepresentation
    compactRepresentation: compactRep
    fullRepresentation: Component { Item {} }

    Component {
        id: compactRep

        Item {
            Rectangle {
                id: pill

                anchors.centerIn: parent
                width: root.pillWidth
                height: parent.height
                radius: root.attached ? Math.round(height * 0.45) : height / 2
                color: root.notchColor
                border.width: root.attached ? 0 : 1
                border.color: "#1AFFFFFF"

                // 摄像头小点（静息时露出，像 MacBook 刘海）
                Rectangle {
                    id: cameraDot
                    anchors.centerIn: pill
                    width: 8
                    height: 8
                    radius: 4
                    color: "#1C1C1E"
                    opacity: root.mode === "idle" ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 200 } }
                }

                NoticeView {
                    anchors.fill: pill
                    notice: root.mode === "notice" ? root.currentNotice : null
                }

                VolumeView {
                    anchors.fill: pill
                    active: root.mode === "volume"
                    percent: root.volumePercent
                    muted: root.volumeMuted
                }

                BrightnessView {
                    anchors.fill: pill
                    active: root.mode === "brightness"
                    percent: root.brightnessPercent
                }

                // 贴边时把顶角/底角修成直角，与面板边框平齐连接
                Rectangle {
                    visible: root.topEdge
                    anchors.top: pill.top
                    anchors.left: pill.left
                    width: pill.radius
                    height: pill.radius
                    color: root.notchColor
                }
                Rectangle {
                    visible: root.topEdge
                    anchors.top: pill.top
                    anchors.right: pill.right
                    width: pill.radius
                    height: pill.radius
                    color: root.notchColor
                }
                Rectangle {
                    visible: root.bottomEdge
                    anchors.bottom: pill.bottom
                    anchors.left: pill.left
                    width: pill.radius
                    height: pill.radius
                    color: root.notchColor
                }
                Rectangle {
                    visible: root.bottomEdge
                    anchors.bottom: pill.bottom
                    anchors.right: pill.right
                    width: pill.radius
                    height: pill.radius
                    color: root.notchColor
                }
            }
        }
    }
}
