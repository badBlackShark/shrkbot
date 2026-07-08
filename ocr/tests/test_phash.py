import re

from PIL import Image

from preprocess import phash_hex


def _gradient(width=64, height=64):
    pixels = bytes(
        (x * 255 // (width - 1)) for y in range(height) for x in range(width)
    )
    return Image.frombytes("L", (width, height), pixels).convert("RGB")


def _inverted_gradient(width=64, height=64):
    pixels = bytes(
        (255 - x * 255 // (width - 1)) for y in range(height) for x in range(width)
    )
    return Image.frombytes("L", (width, height), pixels).convert("RGB")


def test_phash_hex_format():
    h = phash_hex(_gradient())
    assert re.fullmatch(r"[0-9a-f]{16}", h)


def test_phash_deterministic():
    assert phash_hex(_gradient()) == phash_hex(_gradient())


def test_phash_different_images():
    assert phash_hex(_gradient()) != phash_hex(_inverted_gradient())
