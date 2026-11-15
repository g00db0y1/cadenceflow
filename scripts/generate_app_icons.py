#!/usr/bin/env python3
"""Generates CadenceFlow Android adaptive/legacy mipmap icons, web icons, and in-app brand assets."""

from pathlib import Path
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent.parent
SOURCE_IMAGE = Path(
    "/home/antigravity/.gemini/jetski/brain/v1/default/jetski_remote_agents_3p/f12c2a99-7a6a-4059-aec6-df791271cf74/cadenceflow_app_icon_1794786260314.jpg"
)

MIPMAP_SIZES = {
    "mipmap-mdpi": 48,
    "mipmap-hdpi": 72,
    "mipmap-xhdpi": 96,
    "mipmap-xxhdpi": 144,
    "mipmap-xxxhdpi": 192,
}

ADAPTIVE_FOREGROUND_SIZES = {
    "mipmap-mdpi": 108,
    "mipmap-hdpi": 162,
    "mipmap-xhdpi": 216,
    "mipmap-xxhdpi": 324,
    "mipmap-xxxhdpi": 432,
}


def add_rounded_corners(im: Image.Image, radius_ratio: float = 0.22) -> Image.Image:
    im = im.convert("RGBA")
    w, h = im.size
    radius = int(min(w, h) * radius_ratio)
    mask = Image.new("L", (w, h), 0)
    draw = ImageDraw.Draw(mask)
    draw.rounded_rectangle((0, 0, w, h), radius=radius, fill=255)
    out = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    out.paste(im, (0, 0), mask=mask)
    return out


def main() -> None:
    if not SOURCE_IMAGE.exists():
        raise FileNotFoundError(f"Source icon not found: {SOURCE_IMAGE}")

    base = Image.open(SOURCE_IMAGE).convert("RGBA")

    # 1. In-app high-res brand icon (`assets/icons/cadenceflow_icon.png`)
    assets_dir = ROOT / "assets" / "icons"
    assets_dir.mkdir(parents=True, exist_ok=True)
    in_app_icon = add_rounded_corners(
        base.resize((512, 512), Image.Resampling.LANCZOS), radius_ratio=0.22
    )
    in_app_icon.save(assets_dir / "cadenceflow_icon.png", format="PNG", optimize=True)

    # 2. Android mipmap launcher icons + adaptive foreground icons
    res_dir = ROOT / "android" / "app" / "src" / "main" / "res"
    for folder, size in MIPMAP_SIZES.items():
        target_dir = res_dir / folder
        target_dir.mkdir(parents=True, exist_ok=True)
        legacy = add_rounded_corners(
            base.resize((size, size), Image.Resampling.LANCZOS), radius_ratio=0.20
        )
        legacy.save(target_dir / "ic_launcher.png", format="PNG", optimize=True)
        legacy.save(target_dir / "ic_launcher_round.png", format="PNG", optimize=True)

        fg_size = ADAPTIVE_FOREGROUND_SIZES[folder]
        fg_canvas = Image.new("RGBA", (fg_size, fg_size), (12, 22, 24, 255))
        inner_size = int(fg_size * 0.72)
        resized_inner = base.resize((inner_size, inner_size), Image.Resampling.LANCZOS)
        offset = (fg_size - inner_size) // 2
        fg_canvas.paste(resized_inner, (offset, offset))
        fg_canvas.save(
            target_dir / "ic_launcher_foreground.png", format="PNG", optimize=True
        )

    # 3. Android Adaptive Icon XML (Android 8.0+ / API 26+)
    anydpi_dir = res_dir / "mipmap-anydpi-v26"
    anydpi_dir.mkdir(parents=True, exist_ok=True)
    adaptive_xml = """<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@color/ic_launcher_background"/>
    <foreground android:drawable="@mipmap/ic_launcher_foreground"/>
</adaptive-icon>
"""
    (anydpi_dir / "ic_launcher.xml").write_text(adaptive_xml, encoding="utf-8")
    (anydpi_dir / "ic_launcher_round.xml").write_text(adaptive_xml, encoding="utf-8")

    values_dir = res_dir / "values"
    values_dir.mkdir(parents=True, exist_ok=True)
    colors_xml = """<?xml version="1.0" encoding="utf-8"?>
<resources>
    <color name="ic_launcher_background">#0C1618</color>
</resources>
"""
    (values_dir / "ic_launcher_background.xml").write_text(colors_xml, encoding="utf-8")

    # 4. Web / PWA icons
    web_icons_dir = ROOT / "web" / "icons"
    web_icons_dir.mkdir(parents=True, exist_ok=True)
    in_app_icon.resize((192, 192), Image.Resampling.LANCZOS).save(
        web_icons_dir / "Icon-192.png", format="PNG", optimize=True
    )
    in_app_icon.resize((512, 512), Image.Resampling.LANCZOS).save(
        web_icons_dir / "Icon-512.png", format="PNG", optimize=True
    )
    in_app_icon.resize((64, 64), Image.Resampling.LANCZOS).save(
        ROOT / "web" / "favicon.png", format="PNG", optimize=True
    )

    print("✅ Generated CadenceFlow app icons for Android mipmaps, Adaptive v26, Web, and in-app AppBar.")


if __name__ == "__main__":
    main()
