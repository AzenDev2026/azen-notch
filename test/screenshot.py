#!/usr/bin/env python3
"""通过 xdg-desktop-portal 截取当前屏幕，保存为 PNG。用法: python3 screenshot.py 输出路径"""
import gi
import os
import sys
import uuid

gi.require_version("Gio", "2.0")
from gi.repository import Gio, GLib

token = "azen_notch_" + uuid.uuid4().hex
out = sys.argv[1] if len(sys.argv) > 1 else "screenshot.png"

bus = Gio.bus_get_sync(Gio.BusType.SESSION, None)
portal = Gio.DBusProxy.new_sync(
    bus, 0, None,
    "org.freedesktop.portal.Desktop", "/org/freedesktop/portal/desktop",
    "org.freedesktop.portal.Screenshot", None)

r, w = os.pipe()
fds = Gio.UnixFDList.new()
fds.append(w)

opts = {
    "handle_token": GLib.Variant("s", token),
    "interactive": GLib.Variant("b", False),
}

loop = GLib.MainLoop()
saved = {"ok": False}


def save():
    if saved["ok"]:
        return True
    chunks = []
    while True:
        try:
            b = os.read(r, 65536)
        except BlockingIOError:
            break
        if not b:
            break
        chunks.append(b)
    blob = b"".join(chunks)
    if blob:
        with open(out, "wb") as f:
            f.write(blob)
        saved["ok"] = True
        print("saved %s (%d bytes)" % (out, len(blob)))
    return saved["ok"]


def on_response(proxy, sender, signal, params):
    code, results = params.unpack()
    if code == 0:
        save()
    else:
        print("portal response code:", code)
    loop.quit()


def on_done(proxy, result, user_data=None):
    try:
        handle = proxy.call_with_unix_fd_list_finish(result)
    except Exception as e:
        print("call error:", e)
        loop.quit()
        return
    # Response 信号发在 handle 指向的 Request 对象上，为它单独建代理
    req2 = Gio.DBusProxy.new_sync(
        bus, 0, None,
        "org.freedesktop.portal.Desktop", handle,
        "org.freedesktop.portal.Request", None)
    req2.connect("g-signal", on_response)
    # 兜底：如果信号没赶上，2 秒后直接从管道读
    GLib.timeout_add(2000, lambda: (save() and loop.quit() or False))


params = GLib.Variant("(sa{sv})", ("", opts))
portal.call_with_unix_fd_list(
    "Screenshot", params, Gio.DBusCallFlags.NONE, -1, fds, None, on_done)
GLib.timeout_add_seconds(15, lambda: (print("timeout"), loop.quit()))
loop.run()
os.close(r)
os.close(w)
sys.exit(0 if saved["ok"] else 1)
