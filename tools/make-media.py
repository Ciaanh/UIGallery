"""Generates the white, alpha-only art in media/ (never shipped itself).

    python tools/make-media.py

Every image is 256x256, 32-bit uncompressed TGA, white with the shape in the alpha channel, so
examples tint it with SetVertexColor / SetStatusBarColor. Edges are anti-aliased over one pixel.
"""
import math
import os
import struct

SIZE = 256
CENTER = (SIZE - 1) / 2
OUT = os.path.join(os.path.dirname(__file__), "..", "media")


def coverage(distance_inside):
    """0..1 alpha from a signed distance (positive inside the shape), 1px ramp."""
    return max(0.0, min(1.0, distance_inside + 0.5))


def write_tga(name, alpha_at):
    pixels = bytearray()
    for y in range(SIZE):
        for x in range(SIZE):
            a = int(round(255 * alpha_at(x - CENTER, CENTER - y)))
            pixels += bytes((255, 255, 255, a))  # BGRA
    # id length, no colour map, type 2 (true colour), colour map spec, origin, size, 32 bpp,
    # descriptor 0x28 = 8 alpha bits + top-left origin.
    header = struct.pack("<BBBHHBHHHHBB", 0, 0, 2, 0, 0, 0, 0, 0, SIZE, SIZE, 32, 0x28)
    with open(os.path.join(OUT, name), "wb") as f:
        f.write(header + pixels)


RING_OUTER, RING_INNER = 120, 98


def ring(x, y):
    r = math.hypot(x, y)
    return min(coverage(RING_OUTER - r), coverage(r - RING_INNER))


if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    write_tga("ring.tga", ring)
    print("media/: ring.tga")
