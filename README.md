# Azen Notch

iPhone Dynamic Island / MacBook 刘海风格的 KDE Plasma 6 面板组件。
放在顶部面板中央，纯黑圆角胶囊，带摄像头小点。

## 功能

- **静息**：约 5 个应用图标宽的纯黑胶囊（中间有 MacBook 风格的摄像头小点）
- **来通知**：弹性展开，显示应用图标 + 标题 + 应用名/正文，3 秒后收起（通知最多排队 3 条）
- **调音量**：展开显示白色喇叭 + 音量条 + 百分比，3 秒后收起；点喇叭切换静音，拖动音量条调音量
- **调亮度**：展开显示白色太阳 + 亮度条 + 百分比，3 秒后收起；拖动亮度条调亮度
- 展开动画使用 iOS 式弹簧曲线（Easing.Bezier），组件在面板里预留固定宽度、胶囊内部变形，不会挤压两侧面板元素

## 样式（贴边刘海）

- 放在**顶部面板**时是真正的 MacBook 刘海样式：顶边全宽紧贴屏幕上缘，且两侧各有一个
  **向外鼓起的拱形翼**（拱门式肩部，顶边接触比主体略宽、曲线平滑收窄进直边），接缝与屏幕
  黑框融为一体、自然隐形；两侧直边、底部拱形大圆角；放在底部面板时自动改为向下贴边；
  放在桌面等位置时保持完整悬浮胶囊
- 贴边模式自动识别面板位置（`Plasmoid.location`），并实测组件格位到屏幕边缘的距离
  （`attachGap`）自动补足，保证零缝隙

## 参数调整（contents/ui/main.qml 顶部常量区）

| 常量 | 默认 | 含义 |
|---|---|---|
| `idleWidth` | 178 | 静息时宽度 |
| `noticeWidth` | 350 | 通知时宽度（也是面板预留宽度） |
| `ctrlWidth` | 270 | 音量/亮度时宽度 |
| `showDuration` | 3000 | 显示时长（毫秒） |
| `notchColor` | #000000 | 胶囊颜色 |

改完重新打包即可生效：`kpackagetool6 -t Plasma/Applet -u .`，然后重启 plasmashell。

## 技术要点

- **通知**：`org.kde.notificationmanager` 的 `Notifications` 模型，
  用 `unreadNotificationsCount` 增量检测新通知（避免开机把历史通知弹出来）
- **音量**：`org.kde.plasma.private.volume` 的 `PreferredDevice.sink` + `PulseAudio.NormalVolume`，
  监听 `volumeChanged`/`mutedChanged`
- **亮度**：`org.kde.plasma.private.brightnesscontrolplugin` 的 `ScreenBrightnessControl`，
  通过 `displays` 模型的 `brightnessChanged` 信号监听变化
- **部署**：`kpackagetool6 -t Plasma/Applet -i .`（升级用 `-u`）
- **调试**：`journalctl --user -u plasma-plasmashell.service`

## 测试

- `test/engines.qml`：三个数据源的冒烟测试
- `test/views.qml`：三个视图的渲染测试
- `test/screenshot.py`：通过 xdg-desktop-portal 截屏（需要 portal 正常时可用）
- 真实触发：`gdbus call ... org.freedesktop.Notifications.Notify` 发通知；
  `qdbus6 org.kde.kglobalaccel /component/kmix ... invokeShortcut increase_volume` 模拟音量键；
  `... /component/org_kde_powerdevil ... "Increase Screen Brightness Small"` 模拟亮度键
