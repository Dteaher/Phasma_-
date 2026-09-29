"""Resize the illustrated Tailtown launcher icon for Android, web and RuStore."""

from pathlib import Path

from PIL import Image


root = Path(__file__).resolve().parents[1]
source = root / "assets" / "art" / "app-icon-v14.png"

with Image.open(source) as original:
    icon = original.convert("RGB")


def save(relative_path: str, size: int) -> None:
    path = root / relative_path
    path.parent.mkdir(parents=True, exist_ok=True)
    icon.resize((size, size), Image.Resampling.LANCZOS).save(path)


save("output/rustore/icon-512.png", 512)
for density, size in [
    ("mdpi", 48),
    ("hdpi", 72),
    ("xhdpi", 96),
    ("xxhdpi", 144),
    ("xxxhdpi", 192),
]:
    save(f"android/app/src/main/res/mipmap-{density}/ic_launcher.png", size)
save("web/icons/Icon-192.png", 192)
save("web/icons/Icon-512.png", 512)
save("web/favicon.png", 32)
for size in (192, 512):
    maskable = Image.new("RGB", (size, size), "#4FA7C3")
    inner_size = round(size * 0.8)
    inset = (size - inner_size) // 2
    maskable.paste(
        icon.resize((inner_size, inner_size), Image.Resampling.LANCZOS),
        (inset, inset),
    )
    maskable.save(root / "web" / "icons" / f"Icon-maskable-{size}.png")
