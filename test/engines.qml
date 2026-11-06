import QtQuick
import org.kde.notificationmanager as NotificationManager
import org.kde.plasma.private.volume
import org.kde.plasma.private.brightnesscontrolplugin as Brightness

// 引擎冒烟测试：QT_QPA_PLATFORM=offscreen qml6 test/engines.qml
QtObject {
    NotificationManager.Notifications {
        id: n
        limit: 8
        showNotifications: true
        showJobs: false
        showExpired: true
        showDismissed: true
        sortMode: NotificationManager.Notifications.SortByTypeAndUrgency
        sortOrder: Qt.DescendingOrder
        groupMode: NotificationManager.Notifications.GroupDisabled
        Component.onCompleted: {
            print("notif: count=" + count + " unread=" + unreadNotificationsCount)
            print("roles: Type=" + NotificationManager.Notifications.TypeRole
                + " Summary=" + NotificationManager.Notifications.SummaryRole
                + " AppName=" + NotificationManager.Notifications.ApplicationNameRole
                + " AppIcon=" + NotificationManager.Notifications.ApplicationIconNameRole
                + " Icon=" + NotificationManager.Notifications.IconNameRole
                + " Body=" + NotificationManager.Notifications.BodyRole
                + " DesktopEntry=" + NotificationManager.Notifications.DesktopEntryRole
                + " Expired=" + NotificationManager.Notifications.ExpiredRole
                + " NoType=" + NotificationManager.Notifications.NoType
                + " NotificationType=" + NotificationManager.Notifications.NotificationType)
        }
    }

    readonly property var sink: PreferredDevice.sink || null

    Brightness.ScreenBrightnessControl {
        id: sc
        isSilent: true
        Component.onCompleted: {
            print("brightness: available=" + sc.isBrightnessAvailable
                + " displays=" + (sc.displays ? sc.displays.count : -1))
        }
    }

    Component.onCompleted: {
        if (sink)
            print("sink: volume=" + sink.volume + " muted=" + sink.muted + " NORMAL=" + PulseAudio.NormalVolume)
        else
            print("sink: null")
    }
}
