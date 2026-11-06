#!/usr/bin/env python3
"""渲染 4 种刘海顶角候选造型（黑底灰面板模拟），供用户挑选。"""
import math
from PIL import Image, ImageDraw

W, H = 720, 260
BG = (46, 46, 52)          # 模拟深色面板背景
FG = (0, 0, 0)             # 刘海纯黑
SW, SH = 400, 80           # 刘海尺寸
X0 = (W - SW) // 2


def canvas():
    img = Image.new("RGB", (W, H), BG)
    return img, ImageDraw.Draw(img)


def arc(cx, cy, r, a0, a1, n=28):
    pts = []
    for i in range(n + 1):
        a = math.radians(a0 + (a1 - a0) * i / n)
        pts.append((cx + r * math.cos(a), cy + r * math.sin(a)))
    return pts


def caption(d, text):
    d.rectangle([6, 6, 700, 34], fill=(30, 30, 34))
    d.text((14, 14), text, fill=(255, 255, 255))


def shape_A(path):
    """A: 顶角小圆角(6px) + 底角大圆角(40px)"""
    img, d = canvas()
    rt, rb = 6, 40
    x1 = X0 + SW
    pts = [(X0, SH - rb)]
    pts += arc(X0 + rb, SH - rb, rb, 180, 90)
    pts += [(x1 - rb, SH)]
    pts += arc(x1 - rb, SH - rb, rb, 90, 0)
    pts += [(x1, rt)]
    pts += arc(x1 - rt, rt, rt, 0, -90)
    pts += [(X0 + rt, 0)]
    pts += arc(X0 + rt, rt, rt, -90, -180)
    d.polygon(pts, fill=FG)
    caption(d, "A: top corners barely rounded (6px), bottom big arch (40px)")
    img.save(path)


def shape_B(path):
    """B: 顶角内凹耳形曲线 + 底角大圆角（notch 覆盖层经典做法）"""
    img, d = canvas()
    e, rb = 18, 40
    x1 = X0 + SW
    pts = []
    # 左耳：从 (X0+e,0) 到 (X0,e) 的凹曲线（控制点偏向刘海内部）
    n = 24
    for i in range(n + 1):
        t = i / n
        # 二次贝塞尔：P0=(X0+e,0) P1=(X0+e*1.3, e*0.6) P2=(X0, e)
        x = (1 - t) ** 2 * (X0 + e) + 2 * (1 - t) * t * (X0 + e * 1.3) + t * t * X0
        y = (1 - t) ** 2 * 0 + 2 * (1 - t) * t * (e * 0.6) + t * t * e
        pts.append((x, y))
    pts += [(X0, SH - rb)]
    pts += arc(X0 + rb, SH - rb, rb, 180, 90)
    pts += [(x1 - rb, SH)]
    pts += arc(x1 - rb, SH - rb, rb, 90, 0)
    pts += [(x1, e)]
    for i in range(n + 1):
        t = i / n
        x = (1 - t) ** 2 * (x1 - e) + 2 * (1 - t) * t * (x1 - e * 1.3) + t * t * x1
        y = (1 - t) ** 2 * 0 + 2 * (1 - t) * t * (e * 0.6) + t * t * e
        pts.append((x, y))
    d.polygon(pts, fill=FG)
    caption(d, "B: concave 'ear' curves at top + big bottom arch")
    img.save(path)


def shape_C(path):
    """C: 顶角底角都是大圆角（当前线上版本）"""
    img, d = canvas()
    r = 40
    x1 = X0 + SW
    pts = [(X0, r)]
    pts += arc(X0 + r, r, r, 180, 90)
    pts += [(x1 - r, 0)]
    pts += arc(x1 - r, r, r, 90, 0)
    pts += [(x1, SH - r)]
    pts += arc(x1 - r, SH - r, r, 90, 180)
    pts += [(X0 + r, SH)]
    pts += arc(X0 + r, SH - r, r, 270, 180)
    d.polygon(pts, fill=FG)
    caption(d, "C: all corners big rounded (current deployed version)")
    img.save(path)


def shape_D(path):
    """D: 顶角外凸(squircle 风格 n=3) + 底角大圆角"""
    img, d = canvas()
    rc, rb = 22, 40
    x1 = X0 + SW
    n = 26
    pts = []
    # 左下大圆角
    pts.append((X0, SH - rb))
    pts += arc(X0 + rb, SH - rb, rb, 180, 90)
    pts += [(x1 - rb, SH)]
    pts += arc(x1 - rb, SH - rb, rb, 90, 0)
    # 右侧边到右上角
    pts.append((x1, rc))
    # 右上外凸角：从 (x1, rc) 到 (x1-rc, 0)，超椭圆 n=3
    for i in range(n, -1, -1):
        t = math.pi / 2 * i / n
        x = x1 - rc + rc * max(0.0, math.sin(t)) ** (2 / 3)
        y = rc - rc * max(0.0, math.cos(t)) ** (2 / 3)
        pts.append((x, y))
    # 顶边
    pts.append((X0 + rc, 0))
    # 左上外凸角
    for i in range(n + 1):
        t = math.pi / 2 * i / n
        x = X0 + rc - rc * max(0.0, math.sin(t)) ** (2 / 3)
        y = rc - rc * max(0.0, math.cos(t)) ** (2 / 3)
        pts.append((x, y))
    d.polygon(pts, fill=FG)
    caption(d, "D: outward-bulging 'arch' top corners (squircle) + big bottom arch")
    img.save(path)


shape_A("notch-candidate-A.png")
shape_B("notch-candidate-B.png")
shape_C("notch-candidate-C.png")
shape_D("notch-candidate-D.png")
print("rendered A/B/C/D")
