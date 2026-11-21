#!/usr/bin/env python3
"""Convierte la captura XWD ZPixmap de Xvfb a PNG, sin dependencias externas."""
import pathlib
import struct
import sys
import zlib

source, destination = map(pathlib.Path, sys.argv[1:])
data = source.read_bytes()
header = struct.unpack(">25I", data[:100])
size, version, fmt, depth, width, height = header[:6]
byte_order, bits, stride = header[7], header[11], header[12]
masks = header[14:17]
colors = header[19]
if version != 7 or fmt != 2 or bits not in (24, 32) or header[6] != 0:
    raise ValueError("Formato XWD no admitido")
pixels = data[size + colors * 12:]
if len(pixels) < stride * height:
    raise ValueError("Captura truncada")


def channel(pixel, mask):
    shift = (mask & -mask).bit_length() - 1
    return ((pixel & mask) >> shift) * 255 // (mask >> shift)


rows = bytearray()
step = bits // 8
for y in range(height):
    rows.append(0)
    for x in range(width):
        offset = y * stride + x * step
        pixel = int.from_bytes(pixels[offset:offset + step],
                               "little" if byte_order == 0 else "big")
        rows.extend(channel(pixel, mask) for mask in masks)


def chunk(kind, payload):
    return (struct.pack(">I", len(payload)) + kind + payload
            + struct.pack(">I", zlib.crc32(kind + payload)))


destination.write_bytes(
    b"\x89PNG\r\n\x1a\n"
    + chunk(b"IHDR", struct.pack(">2I5B", width, height, 8, 2, 0, 0, 0))
    + chunk(b"IDAT", zlib.compress(rows))
    + chunk(b"IEND", b"")
)
