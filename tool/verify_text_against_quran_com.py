#!/usr/bin/env python3
"""Cross-checks the bundled Uthmani text against Quran.com's public API.

Nothing from the API is stored. The script compares ayah by ayah and prints
the result, so a change in either source shows up. Run from the repository
root: `python3 tool/verify_text_against_quran_com.py`.

Differences that are expected and handled before comparing:
- Tanzil prefixes the basmala (4 words) to the first ayah of every surah
  except Al-Fatiha and At-Tawba; Quran.com does not.
- Quran.com writes the rub-el-hizb sign (U+06DE) inside the text; the bundled
  file does not include it.
"""
import json
import re
import sys
import urllib.request

URL = "https://api.quran.com/api/v4/quran/verses/uthmani"
LINE = re.compile(r"^(\d+)\|(\d+)\|(.+)$")


def load_tanzil(path):
    verses = {}
    with open(path, encoding="utf8") as handle:
        for line in handle:
            match = LINE.match(line.rstrip("\n"))
            if match:
                verses[(int(match[1]), int(match[2]))] = match[3]
    return verses


def main():
    tanzil = load_tanzil("assets/quran/quran-uthmani.txt")
    request = urllib.request.Request(
        URL, headers={"User-Agent": "mre-quran-verify/1.0"}
    )
    with urllib.request.urlopen(request, timeout=60) as response:
        data = json.load(response)["verses"]
    quran_com = {}
    for verse in data:
        surah, ayah = map(int, verse["verse_key"].split(":"))
        quran_com[(surah, ayah)] = verse["text_uthmani"]

    basmala_words = len(tanzil[(1, 1)].split(" "))
    different = []
    for key, text in tanzil.items():
        if key[1] == 1 and key[0] not in (1, 9):
            text = " ".join(text.split(" ")[basmala_words:])
        other = re.sub(r"\s*۞\s*", " ", quran_com[key]).strip()
        if text != other:
            different.append(key)

    print(f"ayahs: bundled {len(tanzil)}, Quran.com {len(quran_com)}")
    print(f"identical after the two documented differences: "
          f"{len(tanzil) - len(different)} of {len(tanzil)}")
    if different:
        print("different:", different[:20])
        sys.exit(1)


main()
