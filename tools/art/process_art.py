#!/usr/bin/env python3
"""Turn the OpenArt paintings in art/source/ into game-ready files in assets/art/.

The paintings were generated on a flat magenta background, because image models
cannot give a transparent one. This script cuts that magenta away, trims and
resizes each picture to a sensible size for a phone, and writes the result.

Run it again whenever a painting in art/source/ is replaced:

    python3 tools/art/process_art.py

It needs Pillow and numpy (`python3 -m pip install --user pillow numpy`).
Nothing in the game reads art/source/ directly — only what this script writes.
"""
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parents[2]
SRC = ROOT / "art" / "source"
OUT = ROOT / "assets" / "art"


# --- cutting out the magenta ------------------------------------------------

def magenta_mask(rgb: np.ndarray, hue_from: float = 295, hue_to: float = 348) -> np.ndarray:
    """True where a pixel looks like the magenta backdrop.

    Judged by hue rather than exact colour, because the backdrop is never one
    flat colour: it darkens into purple shadows around each object. Reds (hue
    near 360) and oranges stay safely outside the range; narrow `hue_to` if a
    red part of the painting starts disappearing.
    """
    f = rgb.astype(np.float32) / 255.0
    mx, mn = f.max(axis=-1), f.min(axis=-1)
    delta = np.maximum(mx - mn, 1e-6)
    r, g, b = f[..., 0], f[..., 1], f[..., 2]
    hue = np.where(mx == r, ((g - b) / delta) % 6, np.where(mx == g, (b - r) / delta + 2, (r - g) / delta + 4)) * 60
    sat = (mx - mn) / np.maximum(mx, 1e-6)
    return (hue >= hue_from) & (hue <= hue_to) & (sat > 0.55) & (mx > 0.15)


def connected_to_border(mask: np.ndarray) -> np.ndarray:
    """Keep only the backdrop that touches the edge of the picture.

    A magenta-ish spot INSIDE an object (a purple band on the rainbow badge, a
    pink shutter) is not connected to the outside, so it survives.
    """
    img = Image.fromarray(np.where(mask, 255, 0).astype(np.uint8)).convert("L")
    h, w = mask.shape
    border = [(x, 0) for x in range(0, w, 8)] + [(x, h - 1) for x in range(0, w, 8)]
    border += [(0, y) for y in range(0, h, 8)] + [(w - 1, y) for y in range(0, h, 8)]
    for xy in border:
        if img.getpixel(xy) == 255:
            ImageDraw.floodfill(img, xy, 128)
    return np.array(img) == 128


def colour_mask(rgb: np.ndarray, colour: tuple, tolerance: float) -> np.ndarray:
    """True where a pixel is within `tolerance` of one exact backdrop colour."""
    diff = rgb.astype(np.float32) - np.array(colour, dtype=np.float32)
    return np.sqrt((diff ** 2).sum(axis=-1)) < tolerance


def cut_out(name: str, border_only: bool = True,
            colour: tuple = None, tolerance: float = 45, hue_to: float = 348) -> Image.Image:
    """The painting with its magenta backdrop made transparent, edges softened.

    Pass `colour` to cut one measured backdrop colour instead of "anything
    magenta" — safer when the painting has its own pinks and maroons.
    """
    im = Image.open(SRC / name).convert("RGB")
    rgb = np.array(im)
    bg = colour_mask(rgb, colour, tolerance) if colour else magenta_mask(rgb, hue_to=hue_to)
    if border_only:
        bg = connected_to_border(bg)

    # Soften the edge by a pixel or so, then pull the remaining pink out of the
    # edge pixels so nothing glows magenta against the sky.
    alpha = Image.fromarray(np.where(bg, 0, 255).astype(np.uint8))
    alpha = alpha.filter(ImageFilter.MinFilter(3)).filter(ImageFilter.GaussianBlur(1.2))
    a = np.array(alpha).astype(np.float32) / 255.0

    out = rgb.astype(np.float32)
    edge = a < 0.999
    r, g, b = out[..., 0], out[..., 1], out[..., 2]
    spill = np.clip(np.minimum(r, b) - g, 0, None)
    r[edge] -= spill[edge]
    b[edge] -= spill[edge]
    rgba = np.dstack([np.clip(out, 0, 255), a * 255]).astype(np.uint8)
    return Image.fromarray(rgba)


def trim(im: Image.Image, pad: int = 4) -> Image.Image:
    """Crop away fully transparent margins."""
    box = im.getchannel("A").point(lambda v: 255 if v > 8 else 0).getbbox()
    if box is None:
        return im
    l, t, r, b = box
    return im.crop((max(0, l - pad), max(0, t - pad), min(im.width, r + pad), min(im.height, b + pad)))


def fit_width(im: Image.Image, width: int) -> Image.Image:
    return im.resize((width, round(im.height * width / im.width)), Image.LANCZOS)


def fit_height(im: Image.Image, height: int) -> Image.Image:
    return im.resize((round(im.width * height / im.height), height), Image.LANCZOS)


def extend_floor(im: Image.Image, extra: int) -> Image.Image:
    """Continue the plain concrete floor downward by `extra` pixels.

    The painting's floor is shorter than a phone screen is tall, so without this
    the sky would show underneath the stall at the bottom of the screen. The new
    floor is the painting's own average floor colour, fading in over a short band
    so there is no visible join. (Stretching the last rows instead smeared every
    crack in the concrete into long streaks.)
    """
    strip = np.array(im.crop((0, im.height - 40, im.width, im.height - 4)).convert("RGB")).reshape(-1, 3)
    floor = tuple(int(v) for v in np.median(strip, axis=0)) + (255,)
    fade = 60
    out = Image.new("RGBA", (im.width, im.height + extra), (0, 0, 0, 0))
    # floor colour only BELOW the painting (plus the fade band), never behind
    # its see-through sky
    out.paste(Image.new("RGBA", (im.width, extra + fade), floor), (0, im.height - fade))
    body = im.copy()
    mask = Image.new("L", im.size, 255)
    ramp = Image.linear_gradient("L").resize((im.width, fade)).transpose(Image.FLIP_TOP_BOTTOM)
    mask.paste(ramp, (0, im.height - fade))
    body.putalpha(Image.fromarray(np.minimum(np.array(im.getchannel("A")), np.array(mask))))
    out.alpha_composite(body)
    return out


def save(im: Image.Image, name: str) -> None:
    path = OUT / name
    if name.endswith(".jpg"):
        im.convert("RGB").save(path, quality=90)
    else:
        im.save(path, optimize=True)
    print(f"wrote {path.relative_to(ROOT)}  {im.width}x{im.height}")


def pieces(sheet: Image.Image) -> list:
    """Separate items on a cut-out sheet, left to right then top to bottom."""
    solid = np.array(sheet.getchannel("A")) > 40
    cols = np.where(solid.any(axis=0))[0]
    rows = np.where(solid.any(axis=1))[0]
    return _runs(cols), _runs(rows)


def _runs(idx: np.ndarray) -> list:
    """Group consecutive indices into (start, end) spans, ignoring tiny gaps."""
    spans = []
    start = prev = int(idx[0])
    for i in idx[1:]:
        i = int(i)
        if i - prev > 12:
            spans.append((start, prev + 1))
            start = i
        prev = i
    spans.append((start, prev + 1))
    return [s for s in spans if s[1] - s[0] > 40]


# --- each asset --------------------------------------------------------------

def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)

    # Background layers, far to near.
    save(fit_width(Image.open(SRC / "sky.jpg"), 1024), "bg_sky.jpg")
    # The street's backdrop is a paler pink, and the painting has maroon doors
    # that "anything magenta" would eat, so cut that one measured colour. Gaps
    # between palm fronds do not touch the border, so cut it everywhere.
    street = fit_width(trim(cut_out("street.jpg", border_only=False, colour=(235, 103, 143), tolerance=48)), 1200)
    save(extend_floor(street, 700), "bg_street.png")
    save(fit_width(trim(cut_out("canopy.jpg")), 2048), "bg_canopy.png")
    # Magenta shows between the stool legs without touching the border, and the
    # stools are yellow and red, so cut it everywhere — but stop the hue range
    # short (the backdrop sits near 330) so the red stool's dark shading stays.
    save(fit_width(trim(cut_out("foreground.jpg", border_only=False, hue_to=340)), 2048), "bg_foreground.png")

    # Marble: the painting came out as tiles with gold grout, so take one clean
    # patch from inside the top-middle tile.
    marble = Image.open(SRC / "marble.jpg")
    w, h = marble.size
    save(marble.crop((int(w * .35), int(h * .02), int(w * .65), int(h * .31))).resize((512, 512), Image.LANCZOS),
         "tex_marble.jpg")

    # Round buttons: badge, pause, spare teal.
    round_sheet = cut_out("ui_round.jpg")
    cols, rows = pieces(round_sheet)
    names = ["ui_badge.png", "ui_pause.png", "ui_round_teal.png"]
    for (x0, x1), name in zip(cols, names):
        save(fit_height(trim(round_sheet.crop((x0, rows[0][0], x1, rows[-1][1]))), 256), name)

    # Pills and panel, stacked top to bottom.
    pill_sheet = cut_out("ui_pills_panel.jpg")
    cols, rows = pieces(pill_sheet)
    x0, x1 = cols[0][0], cols[-1][1]
    primary, plain, panel = (trim(pill_sheet.crop((x0, r0, x1, r1))) for r0, r1 in rows[:3])
    # The orange pill changes to red with a hard line two-thirds along. It is
    # symmetrical, so mirror its clean left half over the right.
    half = primary.crop((0, 0, primary.width // 2, primary.height))
    primary.paste(half.transpose(Image.FLIP_LEFT_RIGHT), (primary.width - half.width, 0))
    save(fit_height(primary, 128), "ui_button_primary.png")
    save(fit_height(plain, 128), "ui_button.png")
    save(fit_width(panel, 720), "ui_panel.png")

    save(fit_width(trim(cut_out("logo.png")), 1024), "logo.png")

    # App icon at the three sizes the project and Android ask for.
    icon = Image.open(SRC / "icon.jpg").convert("RGB")
    for size, path in [(512, "icon.png"), (192, "icon_192.png"), (432, "icon_432.png")]:
        icon.resize((size, size), Image.LANCZOS).save(ROOT / path, optimize=True)
        print(f"wrote {path}  {size}x{size}")


if __name__ == "__main__":
    main()
