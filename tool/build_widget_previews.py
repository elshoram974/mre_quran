#!/usr/bin/env python3
"""Draws the home-screen widgets' preview images.

Launchers before Android 12, and some after it, show a widget in their
picker from `android:previewImage`; without one they show the app icon. The
images are drawn here from the same colours and sample texts the widgets'
own layouts use, so they stay in step with them:

  python3 tool/build_widget_previews.py

Needs Pillow. Writes android/app/src/main/res/drawable-nodpi/*_preview.png.
The text is set in Arial, a font of the machine that runs the tool; nothing
of it ships except the drawn letters.
"""
import re
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

RES = Path("android/app/src/main/res")
OUT = RES / "drawable-nodpi"
SCALE = 3  # Pixels per dp.
FONT = "/System/Library/Fonts/Supplemental/Arial.ttf"
BOLD = "/System/Library/Fonts/Supplemental/Arial Bold.ttf"


def values(name: str, tag: str) -> dict[str, str]:
    text = (RES / "values" / name).read_text()
    found = re.findall(rf'<{tag} name="([^"]+)">(.*?)</{tag}>', text)
    return {key: value.replace("\\'", "'") for key, value in found}


COLORS = values("widget_colors.xml", "color")
TEXT = values("prayer_widget_strings.xml", "string")


def color(name: str) -> tuple[int, int, int, int]:
    """An Android #RRGGBB or #AARRGGBB colour as RGBA."""
    value = COLORS[name].lstrip("#")
    if len(value) == 6:
        value = "FF" + value
    alpha, red, green, blue = (int(value[i : i + 2], 16) for i in (0, 2, 4, 6))
    return red, green, blue, alpha


def font(size_sp: float, bold: bool = False) -> ImageFont.FreeTypeFont:
    return ImageFont.truetype(BOLD if bold else FONT, round(size_sp * SCALE))


def card(width_dp: int, height_dp: int) -> Image.Image:
    """The widgets' background: a rounded card with a diagonal gradient."""
    width, height = width_dp * SCALE, height_dp * SCALE
    start, end = color("widget_bg_start"), color("widget_bg_end")
    gradient = Image.new("RGBA", (width, height))
    pixels = gradient.load()
    for y in range(height):
        for x in range(width):
            t = (x / width + y / height) / 2
            pixels[x, y] = tuple(
                round(start[i] + (end[i] - start[i]) * t) for i in range(4)
            )
    mask = Image.new("L", (width, height), 0)
    ImageDraw.Draw(mask).rounded_rectangle(
        (0, 0, width - 1, height - 1), radius=24 * SCALE, fill=255
    )
    image = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    image.paste(gradient, (0, 0), mask)
    return image


def star(image: Image.Image, left_dp: float, top_dp: float, size_dp: float) -> None:
    """The eight-pointed star of widget_star.xml."""
    layer = Image.new("RGBA", image.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer)
    unit = size_dp * SCALE / 100
    ox, oy = left_dp * SCALE, top_dp * SCALE

    def outline(points: list[tuple[float, float]]) -> None:
        draw.line(
            [(ox + x * unit, oy + y * unit) for x, y in points + points[:1]],
            fill=color("widget_star"),
            width=max(1, round(2.5 * unit)),
        )

    outline([(18, 18), (82, 18), (82, 82), (18, 82)])
    outline([(50, 2), (98, 50), (50, 98), (2, 50)])
    outline([(50, 22), (78, 50), (50, 78), (22, 50)])
    image.alpha_composite(layer)


def write(draw: ImageDraw.ImageDraw, x_dp: float, y_dp: float, text: str,
          size: float, name: str, bold: bool = False, end: bool = False) -> None:
    """Text with its top-left corner at the point, or top-right when [end]."""
    face = font(size, bold)
    x = x_dp * SCALE
    if end:
        x -= draw.textlength(text, font=face)
    draw.text((x, y_dp * SCALE), text, font=face, fill=color(name))


def next_prayer() -> Image.Image:
    image = card(180, 64)
    star(image, 120, 4, 56)
    draw = ImageDraw.Draw(image)
    write(draw, 14, 14, TEXT["prayer_widget_label"], 11, "widget_accent", bold=True)
    write(draw, 14, 30, TEXT["widget_preview_fajr"], 16, "widget_text", bold=True)
    write(draw, 166, 14, TEXT["widget_preview_fajr_time"], 15, "widget_text", bold=True, end=True)
    write(draw, 166, 36, TEXT["widget_preview_remaining"], 10, "widget_accent", end=True)
    return image


def schedule() -> Image.Image:
    image = card(180, 200)
    star(image, 120, 14, 44)
    draw = ImageDraw.Draw(image)
    write(draw, 14, 12, TEXT["widget_preview_date"], 12, "widget_text", bold=True)
    write(draw, 14, 28, TEXT["widget_preview_hijri"], 10, "widget_accent")
    y = 48.0
    for name in ("fajr", "sunrise", "dhuhr", "asr", "maghrib", "isha"):
        ink = "widget_text_muted" if name == "sunrise" else "widget_text"
        if name == "dhuhr":
            # The sample's coming prayer: lit, with the time left above it.
            draw.rounded_rectangle(
                (6 * SCALE, y * SCALE, 174 * SCALE, (y + 36) * SCALE),
                radius=10 * SCALE,
                fill=color("widget_row_next"),
            )
            write(draw, 14, y + 3, TEXT["widget_preview_remaining"], 10, "widget_accent")
            y += 14
        write(draw, 14, y + 4, TEXT[f"widget_preview_{name}"], 12, ink)
        write(draw, 166, y + 4, TEXT[f"widget_preview_{name}_time"], 12, ink, bold=True, end=True)
        y += 22
    return image


def adhkar() -> Image.Image:
    image = card(180, 64)
    draw = ImageDraw.Draw(image)
    write(draw, 14, 10, TEXT["adhkar_widget_name"], 12, "widget_accent", bold=True)
    write(draw, 166, 10, TEXT["widget_preview_adhkar_count"], 12, "widget_text_muted", end=True)
    write(draw, 14, 27, TEXT["widget_preview_adhkar_title"], 18, "widget_text", bold=True)
    # Progress: 3 of 12, as in the layout.
    track = (14 * SCALE, 52 * SCALE, 166 * SCALE, 56 * SCALE)
    draw.rounded_rectangle(track, radius=2 * SCALE, fill=color("widget_pill"))
    draw.rounded_rectangle(
        (track[0], track[1], track[0] + (track[2] - track[0]) // 4, track[3]),
        radius=2 * SCALE,
        fill=color("widget_accent"),
    )
    return image


def tasbih() -> Image.Image:
    image = card(180, 180)
    star(image, 110, 10, 60)
    draw = ImageDraw.Draw(image)
    write(draw, 16, 16, TEXT["tasbih_widget_name"], 12, "widget_accent", bold=True)
    count = "33"
    face = font(48, bold=True)
    width = draw.textlength(count, font=face)
    draw.text(((180 * SCALE - width) / 2, 58 * SCALE), count, font=face, fill=color("widget_text"))
    reset = TEXT["tasbih_widget_reset"]
    face = font(11)
    width = draw.textlength(reset, font=face)
    pill = ((180 * SCALE - width) / 2 - 12 * SCALE, 138 * SCALE,
            (180 * SCALE + width) / 2 + 12 * SCALE, 160 * SCALE)
    layer = Image.new("RGBA", image.size, (0, 0, 0, 0))
    ImageDraw.Draw(layer).rounded_rectangle(pill, radius=11 * SCALE, fill=color("widget_pill"))
    image.alpha_composite(layer)
    ImageDraw.Draw(image).text(
        ((180 * SCALE - width) / 2, 143 * SCALE), reset, font=face, fill=color("widget_text")
    )
    return image


def main() -> None:
    OUT.mkdir(exist_ok=True)
    for name, draw in (
        ("prayer_widget_preview", next_prayer),
        ("prayer_schedule_widget_preview", schedule),
        ("adhkar_widget_preview", adhkar),
        ("tasbih_widget_preview", tasbih),
    ):
        path = OUT / f"{name}.png"
        draw().save(path, optimize=True)
        print(path, path.stat().st_size)


if __name__ == "__main__":
    main()
