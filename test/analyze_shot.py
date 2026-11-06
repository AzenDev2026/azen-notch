#!/usr/bin/env python3
"""分析用户截图：定位刘海与屏幕顶边之间的黑线，输出颜色/位置/厚度。"""
import sys
import numpy as np
from PIL import Image

path = sys.argv[1] if len(sys.argv) > 1 else "/home/nvazen/Desktop/scr.png"
img = Image.open(path).convert("RGB")
a = np.asarray(img, dtype=np.int16)
H, W, _ = a.shape
print(f"image {W}x{H}")

lum = a.sum(axis=2)
black = lum < 90  # 纯黑区域（刘海）

# 找刘海：顶部中央的黑色块
# 扫描 y=0..H//3 行，统计每行黑色像素的连续段
def black_runs(row):
    xs = np.where(black[row])[0]
    if len(xs) == 0:
        return []
    runs = []
    start = xs[0]
    prev = xs[0]
    for x in xs[1:]:
        if x - prev > 5:
            runs.append((start, prev))
            start = x
        prev = x
    runs.append((start, prev))
    return runs

# 找刘海所在的行（宽 > 100px 的黑色段）
notch_rows = []
for y in range(min(H, 300)):
    for s, e in black_runs(y):
        if e - s > 80:
            notch_rows.append(y)
            break

if not notch_rows:
    print("no black notch found in top 300 rows")
    # 打印每行的黑色段摘要帮助诊断
    for y in range(0, 60, 3):
        runs = black_runs(y)
        print(f"y={y}: " + "; ".join(f"{s}-{e}" for s, e in runs[:6]))
    sys.exit(0)

y_top = min(notch_rows)
y_bottom = max(notch_rows)
print(f"notch black rows: y={y_top}..{y_bottom} (height {y_bottom - y_top + 1})")

# 刘海横向范围（取中间一行）
mid_y = (y_top + y_bottom) // 2
runs = [r for r in black_runs(mid_y) if r[1] - r[0] > 80]
xs, xe = runs[0]
print(f"notch span x: {xs}..{xe}")

# 逐行分析刘海上方区域：每行的颜色分布（在刘海横向范围内）
print("\nrows above/around notch top (y, x from notch span):")
for y in range(max(0, y_top - 8), min(H, y_top + 4)):
    row = a[y, xs:xe + 1]
    mean = row.mean(axis=0).astype(int)
    black_frac = (row.sum(axis=1) < 90).mean()
    print(f"y={y}: meanRGB={tuple(mean)} black%={black_frac:.2f}")

# 重点：找"黑线"——刘海上方一行内，接近纯黑且与刘海颜色一致的行
print("\nrows above notch that are dark:")
for y in range(max(0, y_top - 8), y_top):
    row = a[y, xs:xe + 1]
    mean = row.mean(axis=0).astype(int)
    print(f"y={y}: meanRGB={tuple(mean)}")

# 侧边（刘海外）参考颜色
ref = a[min(y_top - 1, H - 1), W // 2 - 200:W // 2 - 100].mean(axis=0).astype(int)
print(f"\npanel background reference (left of notch): {tuple(ref)}")
