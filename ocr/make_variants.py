#!/usr/bin/env python3
"""
make_variants.py - Manufacture hard OCR cases from your clean source images.

Two clean screenshots can't separate v5_mobile / v5_server / EasyOCR -- they all
ace them. This script degrades each source image in the ways real-world scam
images are degraded (recompression, blur, downscaling, noise, low contrast,
rotation, and realistic combos), and writes a ground_truth.json that maps every
variant back to its parent's expected tokens. Running the bakeoff over the result
is what actually reveals which model holds up when the text gets hard.

It reuses the token lists from paddle_bakeoff.py, so there's one source of truth:
edit GROUND_TRUTH there and it flows through here automatically.

--------------------------------------------------------------------------------
SETUP   python -m pip install pillow numpy      (both already present via Paddle)
USAGE   python make_variants.py --images ./images --out ./variants
        # then:
        python paddle_bakeoff.py --images ./variants --truth ground_truth.json --repeats 1

TIP: 12 variants x 2 images x 6 configs is a lot of compute on a laptop. For this
run use --repeats 1, and consider commenting out the two v6 rows in
paddle_bakeoff.py (already eliminated) so it finishes faster.
--------------------------------------------------------------------------------
"""

import argparse
import io
import json
import sys
from pathlib import Path

try:
    import numpy as np
    from PIL import Image, ImageEnhance, ImageFilter
except ImportError as e:
    sys.exit(f"Needs Pillow + numpy: pip install pillow numpy  ({e})")

# Reuse the token lists from the bakeoff so ground truth stays single-source.
sys.path.insert(0, str(Path(__file__).resolve().parent))
try:
    from paddle_bakeoff import GROUND_TRUTH
except ImportError:
    sys.exit("Couldn't import GROUND_TRUTH from paddle_bakeoff.py. "
             "Run this from the same directory as paddle_bakeoff.py.")


# --- Degradation primitives (each takes and returns a PIL RGB image) ---------

def _rgb(img):
    return img.convert("RGB")


def jpeg(img, quality):
    """Round-trip through JPEG to bake in compression artifacts."""
    buf = io.BytesIO()
    _rgb(img).save(buf, format="JPEG", quality=quality)
    buf.seek(0)
    return Image.open(buf).copy()


def blur(img, radius):
    return _rgb(img).filter(ImageFilter.GaussianBlur(radius))


def downscale(img, factor):
    """Shrink (and keep it small) so detail is genuinely lost."""
    w, h = img.size
    return _rgb(img).resize((max(1, int(w * factor)), max(1, int(h * factor))))


def noise(img, sigma):
    arr = np.asarray(_rgb(img)).astype(np.float32)
    arr += np.random.normal(0, sigma, arr.shape)
    return Image.fromarray(np.clip(arr, 0, 255).astype(np.uint8))


def contrast(img, factor):
    return ImageEnhance.Contrast(_rgb(img)).enhance(factor)


def rotate(img, degrees):
    """Small skew like a phone photo of a screen; black-fill the corners."""
    return _rgb(img).rotate(degrees, expand=True, fillcolor=(0, 0, 0))


# --- Variant recipes: (suffix, function) -------------------------------------
# Ordered from mild to harsh. Combos simulate realistic capture conditions.
RECIPES = [
    ("clean",         lambda im: _rgb(im)),                       # baseline
    ("jpeg_q15",      lambda im: jpeg(im, 15)),
    ("jpeg_q8",       lambda im: jpeg(im, 8)),                    # heavy artifacts
    ("blur_2",        lambda im: blur(im, 2)),
    ("blur_3",        lambda im: blur(im, 3)),                    # soft focus
    ("downscale_50",  lambda im: downscale(im, 0.50)),
    ("downscale_35",  lambda im: downscale(im, 0.35)),           # thumbnail-ish
    ("noise_25",      lambda im: noise(im, 25)),
    ("contrast_040",  lambda im: contrast(im, 0.40)),           # washed-out
    ("rotate_5",      lambda im: rotate(im, 5)),
    # phone photo of a screen: shrink, soften, dim, skew, recompress, add noise
    ("phone_capture", lambda im: jpeg(rotate(noise(contrast(
        blur(downscale(im, 0.70), 1.2), 0.85), 10), 2), 30)),
    # kitchen-sink worst case
    ("harsh_combo",   lambda im: jpeg(noise(blur(im, 2), 20), 15)),
]


def main():
    ap = argparse.ArgumentParser(description="Generate degraded OCR test variants.")
    ap.add_argument("--images", default="./images", help="Folder with source images")
    ap.add_argument("--out", default="./variants", help="Where to write variants")
    ap.add_argument("--truth-out", default="ground_truth.json",
                    help="Where to write the ground-truth JSON")
    ap.add_argument("--seed", type=int, default=0, help="RNG seed (reproducible noise)")
    args = ap.parse_args()

    np.random.seed(args.seed)

    src = Path(args.images)
    if not src.is_dir():
        sys.exit(f"'{src}' is not a folder.")
    out = Path(args.out)
    out.mkdir(parents=True, exist_ok=True)

    # Only process source images we have ground truth for.
    sources = [p for p in sorted(src.iterdir())
               if p.name in GROUND_TRUTH and p.is_file()]
    if not sources:
        sys.exit(f"No images in {src} match GROUND_TRUTH keys "
                 f"({list(GROUND_TRUTH)}). Names must match exactly.")

    truth = {}
    made = 0
    for path in sources:
        try:
            base = Image.open(path)
        except Exception as e:
            print(f"  skip {path.name}: {e}")
            continue
        tokens = GROUND_TRUTH[path.name]
        print(f"{path.name} -> {len(RECIPES)} variants")
        for suffix, fn in RECIPES:
            try:
                variant = fn(base)
            except Exception as e:
                print(f"  {suffix}: failed ({e})")
                continue
            name = f"{path.stem}__{suffix}.png"
            variant.save(out / name)
            truth[name] = tokens          # same expected tokens as the parent
            made += 1

    Path(args.truth_out).write_text(json.dumps(truth, indent=2), encoding="utf-8")
    print(f"\nWrote {made} variants to {out}/ and ground truth to {args.truth_out}")
    print(f"Next: python paddle_bakeoff.py --images {out} "
          f"--truth {args.truth_out} --repeats 1")


if __name__ == "__main__":
    main()