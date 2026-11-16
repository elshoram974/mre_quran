#!/usr/bin/env python3
"""Builds assets/quran/svg/hafs_kfqc_manifest.json.

The app downloads Mushaf pages (SVG artwork and ayah-polygon JSON) one at a
time while reading, or all at once as the two release archives, and checks
every file against this manifest. So the manifest is generated from the
source archives and never edited by hand.

Usage:
  python3 tool/build_svg_manifest.py hafs-kfqc-svg.zip hafs-kfqc-json.zip

Both archives are assets of the quran-ws/quran-svg release named below (see
docs/QURAN_SOURCES.md, section 14).
"""
import gzip
import hashlib
import json
import sys
import zipfile
from pathlib import Path

VERSION = "v1.1.1"
COMMIT = "b4155f07e4aea087d2c458069acff9f7c7e749f6"
BASE = f"https://cdn.quran.ws/svg/pages/{VERSION}/hafs-kfqc"
RELEASE = f"https://github.com/quran-ws/quran-svg/releases/download/{VERSION}"
PAGES = 604


def pages_of(archive: Path, extension: str) -> list[bytes]:
    """The 604 page files of [archive], in page order."""
    with zipfile.ZipFile(archive) as bundle:
        by_name = {Path(name).name: name for name in bundle.namelist()}
        return [
            bundle.read(by_name[f"{number:03d}.{extension}"])
            for number in range(1, PAGES + 1)
        ]


def main() -> None:
    svg_archive, json_archive = Path(sys.argv[1]), Path(sys.argv[2])
    pages = []
    packed = 0
    for svg, layout in zip(
        pages_of(svg_archive, "svg"), pages_of(json_archive, "json")
    ):
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
        # The whole Mushaf in two files, for the offline download.
        "archives": [
            {
                "name": archive.name,
                "url": f"{RELEASE}/{archive.name}",
                "sha256": hashlib.sha256(archive.read_bytes()).hexdigest(),
                "bytes": archive.stat().st_size,
            }
            for archive in (svg_archive, json_archive)
        ],
        # One entry per page, in order: [svg SHA-256, json SHA-256, bytes].
        "pages": pages,
    }
    out = Path("assets/quran/svg/hafs_kfqc_manifest.json")
    out.write_text(json.dumps(manifest, separators=(",", ":")) + "\n")
    print(f"{out}: {len(pages)} pages, {sum(p[2] for p in pages)} bytes")


if __name__ == "__main__":
    main()
