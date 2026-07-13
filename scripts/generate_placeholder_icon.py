"""One-off generator for the placeholder app icon and Play Store feature graphic.

Not part of the app build — run manually (`python scripts/generate_placeholder_icon.py`)
whenever the placeholder needs regenerating. Swap assets/icon/icon.png for real
branding artwork when it's ready, then re-run `flutter pub run flutter_launcher_icons`
and `flutter pub run flutter_native_splash:create`.
"""

from PIL import Image, ImageDraw, ImageFont

BG_COLOR = (13, 148, 136, 255)  # teal-700, matches a health/habit-tracking tone
MARK_COLOR = (255, 255, 255, 255)


def draw_check_mark(draw: ImageDraw.ImageDraw, cx: int, cy: int, radius: int) -> None:
    draw.ellipse(
        [cx - radius, cy - radius, cx + radius, cy + radius],
        outline=MARK_COLOR,
        width=int(radius * 0.16),
    )
    stroke = int(radius * 0.16)
    points = [
        (cx - radius * 0.45, cy + radius * 0.05),
        (cx - radius * 0.1, cy + radius * 0.4),
        (cx + radius * 0.5, cy - radius * 0.35),
    ]
    draw.line(points, fill=MARK_COLOR, width=stroke, joint="curve")
    for point in (points[0], points[-1]):
        draw.ellipse(
            [point[0] - stroke / 2, point[1] - stroke / 2, point[0] + stroke / 2, point[1] + stroke / 2],
            fill=MARK_COLOR,
        )


def generate_icon(size: int, path: str) -> None:
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    corner_radius = int(size * 0.22)
    draw.rounded_rectangle([0, 0, size - 1, size - 1], radius=corner_radius, fill=BG_COLOR)
    draw_check_mark(draw, size // 2, size // 2, int(size * 0.28))
    img.save(path)
    print(f"wrote {path}")


def generate_feature_graphic(width: int, height: int, path: str) -> None:
    img = Image.new("RGB", (width, height), BG_COLOR[:3])
    draw = ImageDraw.Draw(img)
    mark_x = int(height * 0.55)
    draw_check_mark(draw, mark_x, height // 2, int(height * 0.22))

    font = ImageFont.truetype("C:/Windows/Fonts/arialbd.ttf", int(height * 0.14))
    text = "Habit Tracker"
    text_x = int(height * 0.95)
    bbox = draw.textbbox((0, 0), text, font=font)
    text_height = bbox[3] - bbox[1]
    draw.text(
        (text_x, height // 2 - text_height // 2 - bbox[1]),
        text,
        font=font,
        fill=MARK_COLOR,
    )
    img.save(path)
    print(f"wrote {path}")


if __name__ == "__main__":
    generate_icon(1024, "assets/icon/icon.png")
    generate_icon(512, "assets/icon/icon_512.png")
    generate_feature_graphic(1024, 500, "assets/icon/feature_graphic.png")
