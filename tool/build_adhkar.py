#!/usr/bin/env python3
"""Builds assets/adhkar/curated.ar.json from tool/adhkar_spec.json.

Every hadith the file cites is read from the Arabic editions of
https://github.com/fawazahmed0/hadith-api (The Unlicense), pinned to one commit
and checked against a recorded SHA-256. Nothing religious is typed here:

* a dhikr taken from a hadith is cut out of that hadith's own text, with its
  tashkeel, between two anchor phrases;
* a Quran entry stores only a surah and ayah range. The app draws its text
  from the verified Tanzil file;
* the evidence line (collection, number, the Albani grading) is built from the
  edition's data, so a number that does not exist, or a phrase that is not in
  the hadith, stops the build.

Usage:
    python3 tool/build_adhkar.py --cache DIR          # write the file
    python3 tool/build_adhkar.py --cache DIR --check  # fail if it is stale

DIR holds the downloaded editions. Run it from the repository root.
"""

import argparse
import hashlib
import json
import re
import sys
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SPEC = ROOT / "tool" / "adhkar_spec.json"
OUT = ROOT / "assets" / "adhkar" / "curated.ar.json"
CDN = "https://cdn.jsdelivr.net/gh/fawazahmed0/hadith-api@{ref}/editions/{name}.json"

TASHKEEL = re.compile("[ؐ-ًؚ-ٰٟۖ-ۭـ]")
LETTER_FOLD = {
    "إ": "ا", "أ": "ا", "آ": "ا", "ٱ": "ا", "ى": "ي", "ة": "ه",
}
ARABIC_LETTER = re.compile("[ء-ي]")

COLLECTIONS = {
    "bukhari": "البخاري",
    "muslim": "مسلم",
    "abudawud": "أبو داود",
    "nasai": "النسائي",
    "tirmidhi": "الترمذي",
    "ibnmajah": "ابن ماجه",
}
GRADES = {
    "Sahih": "صحيح",
    "Hasan": "حسن",
    "Hasan Sahih": "حسن صحيح",
    "Sahih Lighairihi": "صحيح لغيره",
    "Hasan Lighairihi": "حسن لغيره",
    "Sahih Isnaad": "صحيح الإسناد",
    "Hasan Isnaad": "حسن الإسناد",
}
EDITION_LABEL = re.compile(r"^ara-(\w+)$")


def fold(text):
    """Letters only, folded: the form anchors are matched in."""
    out = []
    for ch in TASHKEEL.sub("", text):
        ch = LETTER_FOLD.get(ch, ch)
        if ARABIC_LETTER.match(ch):
            out.append(ch)
    return "".join(out)


def folded_with_map(text):
    """Folded letters and, for each, its index in the original text."""
    letters, index = [], []
    for i, ch in enumerate(text):
        if TASHKEEL.match(ch):
            continue
        ch = LETTER_FOLD.get(ch, ch)
        if ARABIC_LETTER.match(ch):
            letters.append(ch)
            index.append(i)
    return "".join(letters), index


def clean(text):
    """Drops the quote and bidi marks the editions put around sayings."""
    text = text.replace("‏", "").replace("‎", "")
    text = re.sub(r'\s+', " ", text)
    return text.strip(" \"'.,،؛:")


def slice_text(text, start, end):
    """The part of [text] from the [start] anchor to the end of [end]."""
    letters, index = folded_with_map(text)
    a = letters.find(fold(start))
    if a < 0:
        raise SystemExit(f"anchor not found: {start!r}")
    tail = fold(end)
    b = letters.find(tail, a)
    if b < 0:
        raise SystemExit(f"end anchor not found after start: {end!r}")
    first = index[a]
    last = index[b + len(tail) - 1] + 1
    while last < len(text) and TASHKEEL.match(text[last]):
        last += 1
    return clean(text[first:last])


class Editions:
    def __init__(self, cache, spec):
        self.cache = Path(cache)
        self.ref = spec["hadithApiRef"]
        self.expected = spec["editionSha256"]
        self.data = {}

    def get(self, name):
        if name in self.data:
            return self.data[name]
        path = self.cache / f"{name}.json"
        if not path.exists():
            self.cache.mkdir(parents=True, exist_ok=True)
            url = CDN.format(ref=self.ref, name=name)
            print(f"downloading {url}", file=sys.stderr)
            with urllib.request.urlopen(url, timeout=120) as response:
                path.write_bytes(response.read())
        raw = path.read_bytes()
        digest = hashlib.sha256(raw).hexdigest()
        if digest != self.expected.get(name):
            raise SystemExit(f"{name}: checksum {digest} is not the recorded one")
        by_number = {}
        for hadith in json.loads(raw)["hadiths"]:
            for key in ("hadithnumber", "arabicnumber"):
                if key in hadith:
                    by_number.setdefault((key, str(hadith[key])), hadith)
        self.data[name] = by_number
        return by_number

    def hadith(self, ref):
        """A hadith by {"edition", "number"}; Muslim is cited by its printed
        number (arabicnumber), the others by hadithnumber."""
        name = ref["edition"]
        key = "arabicnumber" if name == "ara-muslim" else "hadithnumber"
        found = self.get(name).get((key, str(ref["number"])))
        if found is None:
            raise SystemExit(f"{name} {ref['number']} does not exist")
        return found


def collection_of(edition):
    return COLLECTIONS[EDITION_LABEL.match(edition).group(1)]


def whole_number(number):
    return str(number).split(".")[0]


def evidence_line(editions, refs, note):
    """One line naming each collection once, with its numbers, and the Albani
    grading when the edition has one. A weak grading stops the build."""
    numbers = {}
    gradings = []
    for ref in refs:
        hadith = editions.hadith(ref)
        name = collection_of(ref["edition"])
        numbers.setdefault(name, []).append(int(whole_number(ref["number"])))
        for grade in hadith.get("grades", []):
            if grade["name"] != "Al-Albani":
                continue
            if grade["grade"] not in GRADES:
                raise SystemExit(f"{ref}: graded {grade['grade']!r} by Al-Albani")
            gradings.append(GRADES[grade["grade"]])
    parts = [
        f"{name} ({'، '.join(str(n) for n in sorted(set(values)))})"
        for name, values in numbers.items()
    ]
    line = "أخرجه " + "، و".join(parts) + "."
    if gradings:
        line += " قال الألباني: " + gradings[0] + "."
    if note:
        line += " " + note
    return line


def entry_for(editions, spec, item, order):
    count = item["count"]
    refs = item.get("evidence", [])
    out = {
        "order": order,
        "content": "",
        "count": count,
        "count_description": spec["countLabels"][str(count)],
        "fadl": "",
        "source": "",
        "type": item["variant"],
        "audio": "",
        "hadith_text": "",
        "explanation_of_hadith_vocabulary": "",
    }
    if "when" in item:
        out["when"] = item["when"]
    if "label" in item:
        out["label"] = item["label"]
    if "quran" in item:
        out["quran"] = item["quran"]
        if not item["quran"]["ranges"]:
            raise SystemExit(f"{item['id']}: no ayah range")
    elif "text" in item:
        text = item["text"]
        if "literal" in text:
            out["content"] = text["literal"]
        else:
            hadith = editions.hadith(text["from"])
            out["content"] = slice_text(hadith["text"], text["start"], text["end"])
    if "virtue" in item:
        virtue = item["virtue"]
        hadith = editions.hadith(virtue["from"])
        out["fadl"] = slice_text(hadith["text"], virtue["start"], virtue["end"])
    # Every cited hadith must really contain the phrase it is cited for.
    for check in item.get("mustContain", []):
        hadith = editions.hadith(check["from"])
        if fold(check["phrase"]) not in fold(hadith["text"]):
            raise SystemExit(f"{item['id']}: {check['phrase']!r} not in {check['from']}")
    if not refs and "quran" not in item:
        raise SystemExit(f"{item['id']}: no evidence")
    if refs:
        out["source"] = evidence_line(editions, refs, item.get("note", ""))
        out["hadith_text"] = clean(editions.hadith(refs[0])["text"])
    else:
        out["source"] = item["note"]
    return out


def build(cache):
    spec = json.loads(SPEC.read_text(encoding="utf-8"))
    editions = Editions(cache, spec)
    entries = []
    seen = set()
    for item in spec["entries"]:
        order = item["variant"] * 100 + item["order"]
        if order in seen:
            raise SystemExit(f"{item['id']}: order {order} is used twice")
        seen.add(order)
        entries.append(entry_for(editions, spec, item, order))
        if item.get("verified"):
            print(f"note: {item['id']} is {item['verified']}", file=sys.stderr)
    return json.dumps(entries, ensure_ascii=False, indent=2) + "\n"


def update_manifest(digest):
    """Records the new checksum in assets/adhkar/manifest.json."""
    path = ROOT / "assets" / "adhkar" / "manifest.json"
    manifest = json.loads(path.read_text(encoding="utf-8"))
    changed = 0
    for collection in manifest["collections"]:
        if collection["file"] == OUT.name and collection["sha256"] != digest:
            collection["sha256"] = digest
            changed += 1
    if changed:
        path.write_text(
            json.dumps(manifest, ensure_ascii=False, indent=2) + "\n",
            encoding="utf-8",
        )
        print(f"updated {changed} checksum(s) in {path.name}")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--cache", required=True)
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    built = build(args.cache)
    if args.check:
        if not OUT.exists() or OUT.read_text(encoding="utf-8") != built:
            raise SystemExit(f"{OUT} is out of date")
        print("up to date")
        return
    OUT.write_text(built, encoding="utf-8")
    digest = hashlib.sha256(built.encode()).hexdigest()
    print(f"wrote {OUT} ({len(json.loads(built))} entries)")
    print("sha256", digest)
    update_manifest(digest)


if __name__ == "__main__":
    main()
