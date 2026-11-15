#!/usr/bin/env python3
"""Builds assets/quran/svg/hafs_kfqc_manifest.json.

The app downloads Mushaf pages (SVG artwork and ayah-polygon JSON) on demand
and checks each file against this manifest, so the manifest is generated from
the source files and never edited by hand.

Usage:
  python3 tool/build_svg_manifest.py <folder with 001.svg … 604.json>

The folder holds the Hafs pages of quran-ws/quran-svg at the version and
commit named below (see docs/QURAN_SOURCES.md, section 14).
"""
import gzip
import hashlib
import json
import sys
from pathlib import Path

VERSION = "v1.1.1"
COMMIT = "b4155f07e4aea087d2c458069acff9f7c7e749f6"
BASE = f"https://cdn.quran.ws/svg/pages/{VERSION}/hafs-kfqc"
PAGES = 604


def main() -> None:
    folder = Path(sys.argv[1])
    pages = []
    packed = 0
    for number in range(1, PAGES + 1):
        svg = (folder / f"{number:03d}.svg").read_bytes()
        layout = (folder / f"{number:03d}.json").read_bytes()
        # What the page takes on the device, where files are kept gzipped.
        packed += len(gzip.compress(svg)) + len(gzip.compress(layout))
        pages.append(
            [
                hashlib.sha256(svg).hexdigest(),
                hashlib.sha256(layout).hexdigest(),
                len(svg) + len(layout),
            ]
        )
    manifest = {
        "edition": "hafs-kfqc",
        "version": VERSION,
        "commit": COMMIT,
        "base": BASE,
        # Size of every page together as kept on the device (gzip).
        "packedBytes": packed,
        # One entry per page, in order: [svg SHA-256, json SHA-256, bytes].
        "pages": pages,
    }
    out = Path("assets/quran/svg/hafs_kfqc_manifest.json")
    out.write_text(json.dumps(manifest, separators=(",", ":")) + "\n")
    print(f"{out}: {len(pages)} pages, {sum(p[2] for p in pages)} bytes")


if __name__ == "__main__":
    main()
