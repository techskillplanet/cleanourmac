#!/usr/bin/env python3
"""Generate reproducible Mobile Dev Assistant brand assets."""

from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter


ROOT = Path(__file__).resolve().parents[1]
ASSET_DIR = ROOT / "assets" / "brand"
ICONSET_DIR = (
    ROOT / "macos" / "Runner" / "Assets.xcassets" / "AppIcon.appiconset"
)


def _interpolate(start: tuple[int, int, int], end: tuple[int, int, int], t: float):
    return tuple(round(a + (b - a) * t) for a, b in zip(start, end))


def _rounded_line(
    draw: ImageDraw.ImageDraw,
    points: list[tuple[int, int]],
    fill: tuple[int, int, int, int],
    width: int,
):
    draw.line(points, fill=fill, width=width, joint="curve")
    radius = width // 2
    for x, y in points:
        draw.ellipse(
            (x - radius, y - radius, x + radius, y + radius),
            fill=fill,
        )


def create_icon(size: int = 1024) -> Image.Image:
    scale = 4
    canvas_size = size * scale
    image = Image.new("RGBA", (canvas_size, canvas_size), (0, 0, 0, 0))

    def s(value: int) -> int:
        return value * scale

    # Soft macOS-style shadow behind the rounded app tile.
    shadow = Image.new("RGBA", image.size, (0, 0, 0, 0))
    shadow_draw = ImageDraw.Draw(shadow)
    shadow_draw.rounded_rectangle(
        (s(72), s(78), s(952), s(958)),
        radius=s(220),
        fill=(4, 15, 29, 150),
    )
    shadow = shadow.filter(ImageFilter.GaussianBlur(s(28)))
    image.alpha_composite(shadow)

    tile = Image.new("RGBA", image.size, (0, 0, 0, 0))
    tile_mask = Image.new("L", image.size, 0)
    mask_draw = ImageDraw.Draw(tile_mask)
    mask_draw.rounded_rectangle(
        (s(72), s(72), s(952), s(952)),
        radius=s(220),
        fill=255,
    )

    # Deep navy-to-teal gradient gives the icon a technical, premium feel.
    gradient = Image.new("RGBA", image.size)
    gradient_pixels = gradient.load()
    top = (8, 24, 43)
    bottom = (9, 76, 82)
    for y in range(s(72), s(953)):
        t = (y - s(72)) / s(880)
        color = _interpolate(top, bottom, t)
        for x in range(s(72), s(953)):
            gradient_pixels[x, y] = (*color, 255)
    tile = Image.composite(gradient, tile, tile_mask)

    # Cyan atmospheric glow, intentionally subtle at small sizes.
    glow = Image.new("RGBA", image.size, (0, 0, 0, 0))
    glow_draw = ImageDraw.Draw(glow)
    glow_draw.ellipse(
        (s(540), s(40), s(1040), s(540)),
        fill=(45, 212, 191, 80),
    )
    glow = glow.filter(ImageFilter.GaussianBlur(s(90)))
    glow.putalpha(Image.composite(glow.getchannel("A"), Image.new("L", image.size), tile_mask))
    tile.alpha_composite(glow)

    # Hairline inner border keeps the silhouette crisp on dark wallpapers.
    tile_draw = ImageDraw.Draw(tile)
    tile_draw.rounded_rectangle(
        (s(83), s(83), s(941), s(941)),
        radius=s(210),
        outline=(255, 255, 255, 28),
        width=s(3),
    )

    # An abstract "M" built from device-like vertical rails.
    mark = Image.new("RGBA", image.size, (0, 0, 0, 0))
    mark_draw = ImageDraw.Draw(mark)
    mark_points = [
        (s(282), s(682)),
        (s(282), s(382)),
        (s(350), s(330)),
        (s(512), s(548)),
        (s(674), s(330)),
        (s(742), s(382)),
        (s(742), s(682)),
    ]
    _rounded_line(
        mark_draw,
        mark_points,
        (242, 251, 249, 255),
        s(72),
    )

    # Mint highlight suggests an active terminal cursor / connected device.
    mark_draw.rounded_rectangle(
        (s(613), s(704), s(748), s(744)),
        radius=s(20),
        fill=(72, 230, 197, 255),
    )
    mark_draw.rounded_rectangle(
        (s(282), s(270), s(382), s(292)),
        radius=s(11),
        fill=(72, 230, 197, 220),
    )

    mark_shadow = mark.filter(ImageFilter.GaussianBlur(s(12)))
    mark_shadow.putalpha(mark_shadow.getchannel("A").point(lambda value: value // 3))
    tile.alpha_composite(mark_shadow, (0, s(12)))
    tile.alpha_composite(mark)
    image.alpha_composite(tile)

    return image.resize((size, size), Image.Resampling.LANCZOS)


def write_svg(path: Path):
    path.write_text(
        """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1024 1024">
  <defs>
    <linearGradient id="tile" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0" stop-color="#08182b"/>
      <stop offset="1" stop-color="#094c52"/>
    </linearGradient>
    <radialGradient id="glow" cx="78%" cy="17%" r="52%">
      <stop offset="0" stop-color="#2dd4bf" stop-opacity=".42"/>
      <stop offset="1" stop-color="#2dd4bf" stop-opacity="0"/>
    </radialGradient>
  </defs>
  <rect x="72" y="72" width="880" height="880" rx="220" fill="url(#tile)"/>
  <rect x="72" y="72" width="880" height="880" rx="220" fill="url(#glow)"/>
  <rect x="83" y="83" width="858" height="858" rx="210" fill="none"
        stroke="#fff" stroke-opacity=".11" stroke-width="3"/>
  <path d="M282 682V382L350 330 512 548 674 330 742 382V682"
        fill="none" stroke="#f2fbf9" stroke-width="72"
        stroke-linecap="round" stroke-linejoin="round"/>
  <rect x="613" y="704" width="135" height="40" rx="20" fill="#48e6c5"/>
  <rect x="282" y="270" width="100" height="22" rx="11" fill="#48e6c5"
        fill-opacity=".86"/>
</svg>
""",
        encoding="utf-8",
    )


def main():
    ASSET_DIR.mkdir(parents=True, exist_ok=True)
    ICONSET_DIR.mkdir(parents=True, exist_ok=True)

    icon = create_icon()
    icon.save(ASSET_DIR / "mobile_dev_assistant_icon_1024.png")
    icon.resize((160, 160), Image.Resampling.LANCZOS).save(
        ASSET_DIR / "mobile_dev_assistant_mark.png"
    )
    write_svg(ASSET_DIR / "mobile_dev_assistant_mark.svg")

    for target_size in (16, 32, 64, 128, 256, 512, 1024):
        icon.resize((target_size, target_size), Image.Resampling.LANCZOS).save(
            ICONSET_DIR / f"app_icon_{target_size}.png"
        )


if __name__ == "__main__":
    main()
