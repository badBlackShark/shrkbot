import imagehash
from PIL import Image, ImageOps

MAX_SIDE = 1280


def preprocess(img):
    img = ImageOps.exif_transpose(img)
    img = img.convert("RGB")
    longest = max(img.width, img.height)
    if longest > MAX_SIDE:
        scale = MAX_SIDE / longest
        img = img.resize(
            (int(img.width * scale), int(img.height * scale)),
            Image.Resampling.LANCZOS,
        )
    return img


def phash_hex(img):
    return format(int(str(imagehash.phash(img)), 16), "016x")
