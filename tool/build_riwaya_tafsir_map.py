#!/usr/bin/env python3
"""Maps each ayah of the other readings to the Hafs ayah(s) it is, for the tafsir.

Al-Tafsir Al-Muyassar explains the Hafs text, ayah by ayah. The readings of
Warsh, Qalun and Al-Duri count some ayahs differently (Warsh's Al Imran 1 is
Hafs's 1 and 2; Warsh does not count Al-Fatiha's basmala), so an ayah's
number alone does not say which tafsir explains it. Shu'bah counts as Hafs.

Each surah's ayahs of a reading are aligned with the Hafs ayahs by their
words (Gale-Church style: one to one, one to two, two to one, one to three,
three to one, or a skipped ayah, scored by how alike the letters are, with
vowels and hamza seats left out), within a band around the diagonal.

Writes assets/quran/riwayat/<edition>_hafs.txt with one line per ayah that
is not Hafs's ayah of the same number: `surah|ayah|hafs,hafs`. An ayah that
is only part of a Hafs ayah takes the Hafs ayah the one before it ended in. A reading
whose every ayah is its Hafs namesake gets no file. Run from the repository
root; it prints each file's SHA-256 for MushafEditions.

  python3 tool/build_riwaya_tafsir_map.py
"""

import collections
import hashlib
import pathlib
import re

ROOT = pathlib.Path(__file__).resolve().parents[1]
HAFS = ROOT / "assets/quran/kfgqpc/tafseerMouaser_v03.txt"
RIWAYAT = ROOT / "assets/quran/riwayat"
EDITIONS = ["warsh", "qalon", "douri", "shubah"]
MOVES = [(1, 1, 0.0), (1, 2, 0.3), (2, 1, 0.3), (1, 3, 0.6), (3, 1, 0.6),
         (0, 1, 1.0), (1, 0, 1.0)]
BAND = 24


def skeleton(text):
    text = re.sub("[^ء-يٱ]", "", text)
    text = re.sub("[ءآأإاٱىيئ"
                  "وؤ]", "", text)
    return text.replace("ة", "ه")


def likeness(a, b):
    grams_a = collections.Counter(a[i:i + 2] for i in range(len(a) - 1))
    grams_b = collections.Counter(b[i:i + 2] for i in range(len(b) - 1))
    total = sum(grams_a.values()) + sum(grams_b.values())
    return 2 * sum((grams_a & grams_b).values()) / total if total else 1.0


def align(reading, hafs):
    n, m = len(reading), len(hafs)
    cost = {(0, 0): 0.0}
    back = {}
    for i in range(n + 1):
        middle = round(i * m / n) if n else 0
        for j in range(max(0, middle - BAND), min(m, middle + BAND) + 1):
            here = cost.get((i, j))
            if here is None:
                continue
            for a, b, penalty in MOVES:
                if i + a > n or j + b > m:
                    continue
                step = penalty
                if a and b:
                    step += 3 * (1 - likeness("".join(reading[i:i + a]),
                                              "".join(hafs[j:j + b])))
                key = (i + a, j + b)
                if here + step < cost.get(key, float("inf")):
                    cost[key] = here + step
                    back[key] = (i, j)
    result = [[] for _ in range(n)]
    i, j = n, m
    while (i, j) != (0, 0):
        pi, pj = back[(i, j)]
        for x in range(pi, i):
            result[x] = list(range(pj + 1, j + 1))
        i, j = pi, pj
    return result


def main():
    hafs = collections.defaultdict(list)
    for line in HAFS.read_text(encoding="utf-8").split("\n")[1:]:
        if line:
            cells = line.split("\t")
            hafs[int(cells[3])].append(skeleton(cells[10]))
    for edition in EDITIONS:
        reading = collections.defaultdict(list)
        for line in (RIWAYAT / f"{edition}_kfqc.txt").read_text(
                encoding="utf-8").split("\n"):
            parts = line.split("|")
            if len(parts) == 5:
                reading[int(parts[0])].append(skeleton(parts[3]))
        lines = []
        for surah in range(1, 115):
            found_all = align(reading[surah], hafs[surah])
            # An ayah that is only a part of a Hafs ayah (Al-Duri's 18:84 is
            # the end of Hafs's 18:86) matches none whole: it is explained
            # with the Hafs ayah the one before it ended in.
            for index, found in enumerate(found_all):
                if not found:
                    before = found_all[index - 1] if index else []
                    found_all[index] = before[-1:] or [1]
            for ayah, found in enumerate(found_all, 1):
                if found != [ayah]:
                    lines.append(f"{surah}|{ayah}|{','.join(map(str, found))}")
        target = RIWAYAT / f"{edition}_hafs.txt"
        if not lines:
            target.unlink(missing_ok=True)
            print(f"{edition}: every ayah is its Hafs namesake; no file")
            continue
        target.write_text("\n".join(lines) + "\n", encoding="utf-8")
        digest = hashlib.sha256(target.read_bytes()).hexdigest()
        print(f"{edition}: {len(lines)} ayahs mapped  {digest}")


if __name__ == "__main__":
    main()
