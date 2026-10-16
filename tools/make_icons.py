#!/usr/bin/env python
"""Generate dark launcher icons: black background + white "dark" text."""
import os
from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
RES = os.path.join(ROOT, "app", "src", "main", "res")

FONT_CANDIDATES = [
    "C:/Windows/Fonts/seguisb.ttf",
    "C:/Windows/Fonts/segoeui.ttf",
    "C:/Windows/Fonts/arialbd.ttf",
    "C:/Windows/Fonts/arial.ttf",
]

def load_font(size):
    for path in FONT_CANDIDATES:
        if os.path.exists(path):
            return ImageFont.truetype(path, size)
    raise RuntimeError("no usable TTF font found")

def fit_text(draw, text, max_w, max_h, start=400):
    """Find largest font size where text fits in max_w x max_h."""
    size = start
    while size > 8:
        font = load_font(size)
        bbox = draw.textbbox((0, 0), text, font=font)
        w, h = bbox[2] - bbox[0], bbox[3] - bbox[1]
        if w <= max_w and h <= max_h:
            return font, bbox
        size -= 4
    raise RuntimeError("text never fits")

def draw_centered_text(img, text, max_w, max_h, color=(255, 255, 255, 255)):
    draw = ImageDraw.Draw(img)
    font, bbox = fit_text(draw, text, max_w, max_h)
    w, h = bbox[2] - bbox[0], bbox[3] - bbox[1]
    x = (img.width - w) / 2 - bbox[0]
    y = (img.height - h) / 2 - bbox[1]
    draw.text((x, y), text, font=font, fill=color)

def make_foreground(path):
    """Adaptive icon foreground: transparent bg, white 'dark' in safe zone.

    安全区：以画布中心为圆心、直径 264px(66dp) 的圆，任何遮罩形状下都不会被裁切。
    文字框半对角线需 <=132px，按 "dark" 的宽高比折算即约 228x92。
    """
    img = Image.new("RGBA", (432, 432), (0, 0, 0, 0))
    draw_centered_text(img, "dark", max_w=228, max_h=92)
    img.save(path)

def make_legacy(size_px, path, round_icon):
    """Legacy launcher icon: black rounded-square (or circle) + white text."""
    SS = 4  # supersample
    big = size_px * SS
    img = Image.new("RGBA", (big, big), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    if round_icon:
        draw.ellipse([0, 0, big - 1, big - 1], fill=(0, 0, 0, 255))
    else:
        radius = int(big * 0.22)
        draw.rounded_rectangle([0, 0, big - 1, big - 1], radius=radius,
                               fill=(0, 0, 0, 255))
    draw_centered_text(img, "dark", max_w=int(big * 0.58), max_h=int(big * 0.30))
    img = img.resize((size_px, size_px), Image.LANCZOS)
    img.save(path)

def main():
    fg_dir = os.path.join(RES, "mipmap-xxxhdpi")
    os.makedirs(fg_dir, exist_ok=True)
    make_foreground(os.path.join(fg_dir, "ic_launcher_foreground.png"))

    densities = {"mdpi": 48, "hdpi": 72, "xhdpi": 96,
                 "xxhdpi": 144, "xxxhdpi": 192}
    for dpi, px in densities.items():
        d = os.path.join(RES, "mipmap-" + dpi)
        os.makedirs(d, exist_ok=True)
        make_legacy(px, os.path.join(d, "ic_launcher.png"), round_icon=False)
        make_legacy(px, os.path.join(d, "ic_launcher_round.png"), round_icon=True)
        print("generated", dpi, px)

    print("icons done")

if __name__ == "__main__":
    main()
