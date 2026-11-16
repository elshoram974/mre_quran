#!/usr/bin/env python3
"""Builds assets/quran/svg/<edition>_manifest.json for one reading.

The app downloads Mushaf pages (SVG artwork and ayah-polygon JSON) one at a
time while reading, or all at once as the two release archives, and checks
every file against this manifest. So the manifest is generated from the
source archives and never edited by hand.

Usage:
  python3 tool/build_svg_manifest.py hafs-kfqc hafs-kfqc-svg.zip hafs-kfqc-json.zip

The edition is one of hafs-kfqc, shubah-kfqc, warsh-kfqc, qalon-kfqc and
douri-kfqc. Both archives are that edition's assets of the quran-ws/quran-svg
release named below (see docs/QURAN_SOURCES.md, section 14). The archives may
have any file name on disk; the manifest records the names of the release.
"""
import gzip
import hashlib
import json
import sys
import zipfile
from pathlib import Path

VERSION = "v1.1.1"
COMMIT = "b4155f07e4aea087d2c458069acff9f7c7e749f6"
EDITIONS = ("hafs-kfqc", "shubah-kfqc", "warsh-kfqc", "qalon-kfqc", "douri-kfqc")
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
    edition = sys.argv[1]
    if edition not in EDITIONS:
        sys.exit(f"unknown edition {edition!r}; one of {', '.join(EDITIONS)}")
    svg_archive, json_archive = Path(sys.argv[2]), Path(sys.argv[3])
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
        "edition": edition,
        "version": VERSION,
        "commit": COMMIT,
        "base": f"https://cdn.quran.ws/svg/pages/{VERSION}/{edition}",
        # Size of every page together as kept on the device (gzip).
        "packedBytes": packed,
        # The whole Mushaf in two files, for the offline download.
        "archives": [
            {
                "name": f"{edition}-{kind}.zip",
                "url": f"{RELEASE}/{edition}-{kind}.zip",
                "sha256": hashlib.sha256(archive.read_bytes()).hexdigest(),
                "bytes": archive.stat().st_size,
            }
            for kind, archive in (("svg", svg_archive), ("json", json_archive))
        ],
        # One entry per page, in order: [svg SHA-256, json SHA-256, bytes].
        "pages": pages,
    }
    out = Path(f"assets/quran/svg/{edition.replace('-', '_')}_manifest.json")
    out.write_text(json.dumps(manifest, separators=(",", ":")) + "\n")
    print(f"{out}: {len(pages)} pages, {sum(p[2] for p in pages)} bytes")


if __name__ == "__main__":
    main()
