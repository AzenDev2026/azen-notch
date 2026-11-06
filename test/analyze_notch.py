#!/usr/bin/env python3
"""分析 MacBook 刘海实拍照片：提取刘海轮廓，测量角部曲线形状。
用法: ./venv/bin/python analyze_notch.py 图片路径"""
import sys
import numpy as np
from PIL import Image

path = sys.argv[1] if len(sys.argv) > 1 else "notch-ref-1.jpg"
img = Image.open(path).convert("RGB")
a = np.asarray(img, dtype=np.int16)
H, W, _ = a.shape
print(f"image {W}x{H}")

# 刘海/边框是纯黑，屏幕是亮的
lum = a[:, :, 0] + a[:, :, 1] + a[:, :, 2]
black = lum < 120
not_black = ~black

# 每列第一个非黑像素的行号 = 屏幕内容开始的位置
first = np.where(not_black.any(axis=0), np.argmax(not_black, axis=0), -1)

# 找刘海跨度：bottom edge 大值区域（刘海底部边缘），两侧是屏幕直接开始（小值）
# 用直方图找两个层级
vals = first[first >= 0]
lo = int(np.median(vals[vals < np.median(vals)])) if (vals < np.median(vals)).any() else 0
# 屏幕顶边（刘海外）大约是最常见的低值
hist_lo = np.bincount(vals[vals <= np.percentile(vals, 50)])
screen_top = int(hist_lo.argmax())
# 刘海底部主平台 = 高值区最常见值
high = vals[vals > screen_top + 5]
hist_hi = np.bincount(high)
notch_bottom = int(hist_hi.argmax())
print(f"screen_top(y)= {screen_top}  notch_bottom(y)= {notch_bottom}  notch_height= {notch_bottom - screen_top}")

# 刘海列范围：y 接近 notch_bottom 的列
margin = 10
cols = np.where((first >= notch_bottom - margin) & (first <= notch_bottom + margin))[0]
# 分组取最大连续段
if len(cols):
    breaks = np.where(np.diff(cols) > 20)[0]
    segs = []
    start = 0
    for b in list(breaks) + [len(cols) - 1]:
        segs.append(cols[start:b + 1])
        start = b + 1
    seg = max(segs, key=len)
    xl, xr = seg[0], seg[-1]
    print(f"notch span x: {xl}..{xr}  width= {xr - xl}")
else:
    print("no notch found")
    sys.exit(1)

h = notch_bottom - screen_top
w = xr - xl

# 底部轮廓 y(x)（在刘海跨度内）
profile = {x: first[x] for x in range(xl, xr + 1) if first[x] >= 0}

# 左侧角：x in [xl, xl+h+20]，归一化 u=(x-xl)/h, v=(notch_bottom-y)/h
print("\nleft corner normalized (u=x/h, v=depth/h):")
left_pts = []
for x in range(xl, min(xl + h + 25, xr)):
    y = profile.get(x)
    if y is None or y > notch_bottom + 2:
        continue
    u = (x - xl) / h
    v = (notch_bottom - y) / h
    left_pts.append((u, v))
    if x % 4 == 0:
        print(f"  u={u:6.3f} v={v:6.3f}")

# 拟合：假设 v(u) 是半径为 R(=r/h) 的圆弧（圆心 (R, R)）: (1-u... 对右下角圆弧：
# 圆心在 (xl + r, notch_bottom - r) → (u - R)^2 + (v - R)^2 = R^2, 点在 u in [0, R]
def fit_R(pts):
    Rs = []
    for u, v in pts:
        if u > 0.05 and v > 0.05:
            # (u-R)^2+(v-R)^2=R^2 → R^2 - 2R(u+v) + u^2+v^2 = 0
            b = u + v
            c = u * u + v * v
            disc = b * b - c
            if disc >= 0:
                Rs.append(b - np.sqrt(disc))
    return np.mean(Rs) if Rs else None, np.std(Rs) if Rs else None

R, Rstd = fit_R(left_pts)
print(f"\ncorner arc fit: r/h = {R:.3f} (std {Rstd:.4f})" if R else "\nno fit")
print(f"  -> if r/h≈0.5 半圆角(胶囊/拱形底); ≈1.0 整个角是大圆弧; <0.3 小圆角")

# ASCII 渲染刘海底部轮廓（左侧角 + 底部 + 右侧角）
print("\nASCII silhouette (bottom edge, '#'=notch, '.'=screen):")
x0, x1 = xl - 10, xr + 10
y0, y1 = screen_top - 5, notch_bottom + 8
W_ascii = 96
for yy in np.linspace(y0, y1, 26):
    row = ""
    for xx in np.linspace(x0, x1, W_ascii):
        x = int(xx)
        y = int(yy)
        is_black = y < first[x] if first[x] >= 0 else True
        row += "#" if is_black else "."
    print(row)
