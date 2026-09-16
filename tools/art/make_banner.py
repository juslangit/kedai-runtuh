#!/usr/bin/env python3
"""Build the Google Play feature graphic from art we already have.

OpenArt was asked for this banner twice and split it into two panels both times,
so it is composed here instead: the painted street from a real screenshot as the
backdrop, the painted logo on the left, and an actual phone-shaped screenshot of
the tower on the right. Everything in it is the real game, which is also what the
store rules want.

    python3 tools/art/make_banner.py

Writes press/store_feature_graphic.png at 1024x500, RGB with no alpha - Google
Play rejects a feature graphic that carries one. Re-run it after new press stills
are rendered, since it reads them directly.

It needs Pillow (`python3 -m pip install --user pillow`).
"""
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = Path(__file__).resolve().parents[2]
PRESS = ROOT / "press"
ART = ROOT / "assets" / "art"
FONT = ROOT / "assets" / "fonts" / "LilitaOne-Regular.ttf"

W, H = 1024, 500          # the size Google Play asks for, exactly
TAGLINE = "stack it as high as you can"

# banner_shot.gd renders a taller tower than the ordinary press run reaches, and
# a second copy of the same frame with the HUD switched off. Use those when they
# are there, and fall back to the standard stills when they are not.
HERO = ["08_banner_tower.png", "03_tower_9.png"]
PLATE = ["09_banner_plate.png", "03_tower_9.png"]


def first_of(names: list[str]) -> Image.Image:
    for name in names:
        path = PRESS / name
        if path.exists():
            return Image.open(path).convert("RGB")
    raise SystemExit(f"none of {names} exist in press/ - render the stills first")


def backdrop() -> Image.Image:
    """A wide band of the painted street, blurred back so the logo can sit on it.

    Taken from the gameplay still rather than from assets/art/, because the
    layers in there are separate cards that only line up once the game has
    arranged them in 3D. The screenshot is that arrangement, already done.
    """
    shot = first_of(PLATE)
    # A band across the stall itself: busy enough to look like somewhere, empty
    # enough not to fight the logo. It deliberately starts below the middle of
    # the frame, because higher up sits the PERFECT toast, and a huge ghosted
    # "PERFECT!" behind the logo reads as a mistake rather than as a background.
    band_h = round(shot.width * H / W)
    # Measured as a fraction of the frame rather than in pixels, because the
    # stills come out at whatever size the window was - 810x1440 from one run,
    # 540x960 from another - and a fixed pixel offset lands somewhere different
    # in each. Just past half way is the stall front, below the PERFECT toast.
    top = min(round(shot.height * 0.53), shot.height - band_h)
    crop = shot.crop((0, top, shot.width, top + band_h)).resize((W, H), Image.LANCZOS)

    # Push it back: a little blur for depth of field, then a warm dark wash so
    # white text and the pale logo outline keep their contrast.
    crop = crop.filter(ImageFilter.GaussianBlur(3.5))
    wash = Image.new("RGB", (W, H), (38, 22, 10))
    return Image.blend(crop, wash, 0.34)


def phone_mock(names: list[str], height: int, angle: float) -> Image.Image:
    """A screenshot dressed as a phone: rounded corners, a pale bezel, a shadow."""
    shot = first_of(names)
    w = round(height * shot.width / shot.height)
    shot = shot.resize((w, height), Image.LANCZOS)

    radius = round(height * 0.055)
    mask = Image.new("L", (w, height), 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, w - 1, height - 1), radius, fill=255)

    bezel = round(height * 0.018)
    bw, bh = w + bezel * 2, height + bezel * 2
    card = Image.new("RGBA", (bw, bh), (0, 0, 0, 0))
    ImageDraw.Draw(card).rounded_rectangle(
        (0, 0, bw - 1, bh - 1), radius + bezel, fill=(252, 249, 240, 255)
    )
    card.paste(shot, (bezel, bezel), mask)

    # The shadow is the card's own silhouette, blurred and offset.
    pad = round(height * 0.09)
    plate = Image.new("RGBA", (bw + pad * 2, bh + pad * 2), (0, 0, 0, 0))
    shadow = Image.new("RGBA", plate.size, (0, 0, 0, 0))
    shadow.paste(Image.new("RGBA", (bw, bh), (0, 0, 0, 150)), (pad, pad + round(pad * 0.35)), card)
    plate.alpha_composite(shadow.filter(ImageFilter.GaussianBlur(pad * 0.42)))
    plate.alpha_composite(card, (pad, pad))
    return plate.rotate(angle, Image.BICUBIC, expand=True)


def main() -> None:
    banner = backdrop().convert("RGBA")

    # Right: the game itself, tilted just enough to look placed rather than pasted.
    phone = phone_mock(HERO, height=436, angle=-6)
    banner.alpha_composite(phone, (W - phone.width + 34, (H - phone.height) // 2))

    # Left: the painted logo, as large as fits beside it.
    logo = Image.open(ART / "logo.png").convert("RGBA")
    logo_w = 590
    logo = logo.resize((logo_w, round(logo_w * logo.height / logo.width)), Image.LANCZOS)
    logo_x, logo_y = 46, 92
    banner.alpha_composite(logo, (logo_x, logo_y))

    # Tagline, in the game's own font and the same wording as the title screen.
    draw = ImageDraw.Draw(banner)
    font = ImageFont.truetype(str(FONT), 40)
    text_x = logo_x + 18
    text_y = logo_y + logo.height + 14
    # Drawn twice: a soft dark pass underneath so it survives a busy backdrop.
    draw.text((text_x + 2, text_y + 3), TAGLINE, font=font, fill=(26, 14, 6, 190))
    draw.text((text_x, text_y), TAGLINE, font=font, fill=(255, 248, 232, 255))

    out = PRESS / "store_feature_graphic.png"
    banner.convert("RGB").save(out)
    print(f"wrote {out.relative_to(ROOT)}  {W}x{H}")


if __name__ == "__main__":
    main()
