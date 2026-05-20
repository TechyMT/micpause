#!/usr/bin/env python3
"""Generate lomographic header banners for the micpause README.

Style: dark navy base, large blurred light blobs in lomo colors,
heavy vignette, film grain, serif title in Didot. One PNG per frame.

Run from project root:
    python3 tools/generate_headers.py
"""
from __future__ import annotations

import random
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont

OUT_DIR = Path(__file__).resolve().parent.parent / "assets" / "headers"
WIDTH, HEIGHT = 1400, 200

BASE_COLOR = (14, 11, 31)  # deep navy, matches banner
LOMO_COLORS = [
    (214, 51, 132),   # magenta
    (13, 202, 240),   # cyan
    (253, 126, 20),   # amber
    (111, 66, 193),   # purple
    (220, 53, 69),    # red
    (255, 193, 7),    # yellow
    (32, 201, 151),   # teal
]

TITLE_FONT = "/System/Library/Fonts/Supplemental/Didot.ttc"
LABEL_FONT = "/System/Library/Fonts/Supplemental/Bodoni 72.ttc"

FRAMES = [
    ("01", "The Shot"),
    ("02", "Exposure Settings"),
    ("03", "Loading the Film"),
    ("04", "The Control Dial"),
    ("05", "Contact Sheet"),
    ("06", "Developer Notes"),
    ("07", "Darkroom"),
    ("08", "End of Roll"),
]


def make_base() -> Image.Image:
    return Image.new("RGB", (WIDTH, HEIGHT), BASE_COLOR)


def add_light_blobs(img: Image.Image, rng: random.Random, count: int = 5) -> Image.Image:
    layer = Image.new("RGB", (WIDTH, HEIGHT), (0, 0, 0))
    draw = ImageDraw.Draw(layer)
    colors = rng.sample(LOMO_COLORS, k=min(count, len(LOMO_COLORS)))
    for color in colors:
        cx = rng.randint(-80, WIDTH + 80)
        cy = rng.randint(-40, HEIGHT + 40)
        radius = rng.randint(120, 260)
        draw.ellipse(
            [cx - radius, cy - radius, cx + radius, cy + radius],
            fill=color,
        )
    layer = layer.filter(ImageFilter.GaussianBlur(radius=90))
    return Image.blend(img, layer, alpha=0.55)


def add_vignette(img: Image.Image, strength: float = 0.75) -> Image.Image:
    mask = Image.new("L", (WIDTH, HEIGHT), 0)
    draw = ImageDraw.Draw(mask)
    pad = 80
    draw.ellipse([-pad, -pad, WIDTH + pad, HEIGHT + pad], fill=255)
    mask = mask.filter(ImageFilter.GaussianBlur(radius=120))
    dark = Image.new("RGB", (WIDTH, HEIGHT), (0, 0, 0))
    inv = Image.eval(mask, lambda v: int((255 - v) * strength))
    return Image.composite(dark, img, inv)


def add_grain(img: Image.Image, rng: random.Random, intensity: int = 18) -> Image.Image:
    noise = Image.new("L", (WIDTH, HEIGHT))
    pixels = noise.load()
    for y in range(HEIGHT):
        for x in range(WIDTH):
            pixels[x, y] = rng.randint(0, intensity)
    noise_rgb = Image.merge("RGB", (noise, noise, noise))
    return Image.blend(img, ImageChopAdd(img, noise_rgb), alpha=0.35)


def ImageChopAdd(a: Image.Image, b: Image.Image) -> Image.Image:
    from PIL import ImageChops
    return ImageChops.add(a, b, scale=1.0)


def add_sprockets(img: Image.Image) -> Image.Image:
    """Thin film-edge motif: small rectangles top and bottom like sprocket holes."""
    draw = ImageDraw.Draw(img)
    color = (255, 240, 220, 60)
    hole_w, hole_h = 22, 6
    gap = 18
    y_top = 8
    y_bot = HEIGHT - 8 - hole_h
    x = gap
    while x + hole_w < WIDTH:
        draw.rectangle([x, y_top, x + hole_w, y_top + hole_h], fill=(255, 240, 220))
        draw.rectangle([x, y_bot, x + hole_w, y_bot + hole_h], fill=(255, 240, 220))
        x += hole_w + gap
    return img


def draw_text(img: Image.Image, frame_no: str, title: str) -> Image.Image:
    draw = ImageDraw.Draw(img)
    label_font = ImageFont.truetype(LABEL_FONT, 22)
    title_font = ImageFont.truetype(TITLE_FONT, 64)

    label = f"FRAME · {frame_no}"
    draw.text((48, 36), label, fill=(255, 240, 220), font=label_font)
    draw.text((50, 38), label, fill=(255, 240, 220), font=label_font)  # faux-bold

    title_upper = title.upper()
    bbox = draw.textbbox((0, 0), title_upper, font=title_font)
    tw = bbox[2] - bbox[0]
    th = bbox[3] - bbox[1]
    tx = (WIDTH - tw) // 2
    ty = (HEIGHT - th) // 2 + 4

    shadow = Image.new("RGBA", img.size, (0, 0, 0, 0))
    sdraw = ImageDraw.Draw(shadow)
    sdraw.text((tx + 3, ty + 3), title_upper, fill=(0, 0, 0, 140), font=title_font)
    shadow = shadow.filter(ImageFilter.GaussianBlur(radius=3))
    img = Image.alpha_composite(img.convert("RGBA"), shadow).convert("RGB")

    draw = ImageDraw.Draw(img)
    draw.text((tx, ty), title_upper, fill=(255, 245, 230), font=title_font)
    return img


def generate(frame_no: str, title: str) -> Image.Image:
    rng = random.Random(int(frame_no) * 7919 + 31)
    img = make_base()
    img = add_light_blobs(img, rng, count=rng.randint(4, 6))
    img = add_vignette(img, strength=0.85)
    img = add_grain(img, rng, intensity=22)
    img = add_sprockets(img)
    img = draw_text(img, frame_no, title)
    return img


def main() -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    for frame_no, title in FRAMES:
        img = generate(frame_no, title)
        path = OUT_DIR / f"frame-{frame_no}.png"
        img.save(path, "PNG", optimize=True)
        print(f"wrote {path.relative_to(OUT_DIR.parent.parent)}")


if __name__ == "__main__":
    main()
