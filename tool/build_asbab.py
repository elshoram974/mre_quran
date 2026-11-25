#!/usr/bin/env python3
"""Builds the occasions of revelation (asbab al-nuzul) the app bundles.

Source: Al-Wahidi's «أسباب نزول القرآن», as Quranpedia (الموسوعة القرآنية,
https://quranpedia.net) publishes it: the dump asbab-book-2919.json.gz,
version 2026-08-10, under the Quranpedia data licence (version 2026-11-24):
free to use inside apps; republishing the data as a dataset needs a credit
with a link and the dump's version. See docs/QURAN_SOURCES.md.

The dump is downloaded once into --cache and must match its SHA-256. The text
is kept word for word: only its markup goes. Line breaks become new lines,
the spans around quoted ayahs and the bold go (the quotes keep their own
﴿ ﴾, by which the app finds and colours them). A passage that serves several
ayahs is stored once; each ayah names its passages by number.

Output: assets/quran/asbab/wahidi.json.gz, a gzip of
  {"source", "version", "sourceSha256", "texts": [...], "ayahs": [[surah, ayah,
  [text, ...]], ...]}
in the order of the Mushaf.

Run from the repository root:

  python3 tool/build_asbab.py --cache <folder>
"""

import argparse
import gzip
import hashlib
import json
import pathlib
import re
import sys
import urllib.request

ROOT = pathlib.Path(__file__).resolve().parents[1]
OUT = ROOT / "assets/quran/asbab/wahidi.json.gz"
URL = "https://quranpedia.net/dumps/asbab-book-2919.json.gz"
SHA256 = "d1831b1e5af18dce182fb5a29ea374029a6427d35f16ff327385addd7486f7c9"
VERSION = "2026-08-10"


def plain(html):
    """The text of [html] without its markup, its lines kept."""
    text = html.replace("\r\n", "\n").replace("\r", "\n")
    text = re.sub(r"<br\s*/?>", "\n", text)
    text = re.sub(r"</?(span|strong)\b[^>]*>", "", text)
    if re.search(r"<[a-zA-Z/]", text):
        sys.exit(f"unexpected markup in: {text[:120]}")
    lines = [line.strip() for line in text.split("\n")]
    text = "\n".join(lines)
    text = re.sub(r"\n{3,}", "\n\n", text)
    return text.strip()


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--cache", type=pathlib.Path, required=True)
    options = parser.parse_args()
    options.cache.mkdir(parents=True, exist_ok=True)
    source = options.cache / "asbab-book-2919.json.gz"
    if not source.exists():
        request = urllib.request.Request(URL, headers={"User-Agent": "MREQuran build"})
        with urllib.request.urlopen(request) as response:
            source.write_bytes(response.read())
    actual = hashlib.sha256(source.read_bytes()).hexdigest()
    if actual != SHA256:
        sys.exit(f"{source}: SHA-256 {actual}, expected {SHA256}")
    dump = json.loads(gzip.decompress(source.read_bytes()))
    if dump["license"]["version"] != VERSION:
        sys.exit(f"dump version {dump['license']['version']}, expected {VERSION}")

    texts = []
    numbers = {}
    ayahs = []
    for entry in sorted(dump["ayahs"], key=lambda e: (e["surah"], e["ayah"])):
        refs = []
        for content in entry["content"]:
            text = plain(content["text"])
            if text not in numbers:
                numbers[text] = len(texts)
                texts.append(text)
            refs.append(numbers[text])
        ayahs.append([entry["surah"], entry["ayah"], refs])

    data = {
        "source": URL,
        "version": VERSION,
        "sourceSha256": SHA256,
        "texts": texts,
        "ayahs": ayahs,
    }
    raw = json.dumps(data, ensure_ascii=False, separators=(",", ":")).encode()
    OUT.parent.mkdir(parents=True, exist_ok=True)
    # Fixed mtime, so the same input always gives the same bytes.
    OUT.write_bytes(gzip.compress(raw, compresslevel=9, mtime=0))
    print(f"{OUT.relative_to(ROOT)}  {OUT.stat().st_size:,} bytes  "
          f"{hashlib.sha256(OUT.read_bytes()).hexdigest()}  "
          f"{len(ayahs)} ayahs, {len(texts)} passages")


if __name__ == "__main__":
    main()
