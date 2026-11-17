#!/usr/bin/env python3
"""Builds assets/quran/riwayat/<edition>.txt from the King Fahd Complex's
data file of that reading.

The source is the KFGQPC developer data ("Uthmanic <reading> data"),
mirrored at github.com/thetruetruth/quran-data-kfgqpc, pinned to the commit
in COMMIT (see docs/QURAN_SOURCES.md, section 15). Each ayah's text is kept
byte for byte. The only change is the layout: one ayah per line,

  surah|ayah|page|text|mark

where `text` is the ayah's text and `mark` its number as the source writes
it after a no-break space (a plain space in Warsh 17:110 and 28:88); the
source's `aya_text` is `text`, that space, `mark`.
`page` is the source's first page of the ayah.

Usage:
  python3 tool/build_riwaya_text.py <edition> <source json>
e.g. python3 tool/build_riwaya_text.py warsh-kfqc warshData_v10.json
"""
import hashlib
import json
import sys
from pathlib import Path

COMMIT = "281dbbe8eed1370daa5a023b6cd81655cbfd6473"
NBSP = " "


def main() -> None:
    edition, source = sys.argv[1], Path(sys.argv[2])
    rows = json.loads(source.read_text(encoding="utf-8"))
    lines = []
    for row in rows:
        text = row["aya_text"]
        # The source puts a no-break space before the number; in two Warsh
        # ayahs (17:110, 28:88) a plain space.
        separator = NBSP if NBSP in text else " "
        body, mark = text.rsplit(separator, 1)
        if not mark or not all("\u0660" <= c <= "\u0669" for c in mark):
            sys.exit(f"{row['sura_no']}:{row['aya_no']} has no number")
        if "|" in text or "\n" in text:
            sys.exit(f"{row['sura_no']}:{row['aya_no']} holds a separator")
        page = int(str(row["page"]).split("-")[0].split("–")[0])
        lines.append(f"{row['sura_no']}|{row['aya_no']}|{page}|{body}|{mark}")
    out = Path(f"assets/quran/riwayat/{edition.replace('-', '_')}.txt")
    out.parent.mkdir(parents=True, exist_ok=True)
    data = ("\n".join(lines) + "\n").encode("utf-8")
    out.write_bytes(data)
    print(f"{out}: {len(lines)} ayahs")
    print(f"  source sha256 {hashlib.sha256(source.read_bytes()).hexdigest()}")
    print(f"  output sha256 {hashlib.sha256(data).hexdigest()}")


if __name__ == "__main__":
    main()
