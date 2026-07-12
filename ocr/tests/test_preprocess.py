import io

from PIL import Image

from preprocess import preprocess


def _solid(width, height, mode="RGB", color=(128, 64, 32)):
    return Image.new(mode, (width, height), color)


def test_downscale_landscape():
    img = _solid(2560, 1440)
    out = preprocess(img)
    assert out.size == (1280, 720)


def test_small_image_unchanged():
    img = _solid(800, 600)
    out = preprocess(img)
    assert out.size == (800, 600)


def test_downscale_portrait():
    img = _solid(1440, 2560)
    out = preprocess(img)
    assert out.size == (720, 1280)


def test_rgba_converted_to_rgb():
    img = _solid(400, 300, mode="RGBA", color=(10, 20, 30, 128))
    out = preprocess(img)
    assert out.mode == "RGB"


def test_animated_gif_uses_first_frame():
    # We whitelist image/gif on the Ruby side relying on preprocess() reducing
    # an animated GIF to frame 0 (convert("RGB") operates on the current frame,
    # which Image.open positions at 0). Lock that guarantee.
    frame0 = _solid(120, 120, color=(200, 40, 40))  # red-dominant
    frame1 = _solid(120, 120, color=(40, 40, 200))  # blue-dominant
    buf = io.BytesIO()
    frame0.save(buf, format="GIF", save_all=True, append_images=[frame1])
    buf.seek(0)
    img = Image.open(buf)
    assert img.n_frames == 2

    out = preprocess(img)
    assert out.mode == "RGB"
    assert not getattr(out, "is_animated", False)
    r, _, b = out.getpixel((0, 0))
    assert r > b


def test_exif_orientation_6():
    # Orientation tag 6 = 90° CW rotation; PIL exif_transpose corrects it.
    # Build a non-square image so swapped dims are detectable.
    base = _solid(300, 100)  # landscape before EXIF correction
    buf = io.BytesIO()
    exif = Image.Exif()
    exif[274] = 6  # tag 274 = Orientation; value 6 = 90° CW
    base.save(buf, format="JPEG", exif=exif.tobytes())
    buf.seek(0)
    img = Image.open(buf)
    out = preprocess(img)
    # After transpose, what was 300×100 becomes 100×300 (portrait).
    assert out.width < out.height
