#!/usr/bin/env python3
"""Builds the Hisn al-Muslim chapters of the Adhkar tab, with verified evidence.

Writes assets/adhkar/hisn.ar.json and assets/adhkar/hisn_manifest.json.

The chapter list, the order of the duas, and their repeat counts come from the
structure of Hisn al-Muslim (read from rn0x/Adhkar-json, used here only as an
index: its dua text is a search key and is never copied). A dua is kept only
when the same words are found in a hadith of the Arabic editions of
https://github.com/fawazahmed0/hadith-api (The Unlicense), and then:

* the words shown are cut out of that hadith's own text, with its tashkeel;
* the evidence line (collection, number, Albani grading) is built from the
  edition's data;
* a hadith outside Bukhari and Muslim must carry a sahih or hasan grading by
  Al-Albani in the data; a hadith he weakened is never used.

A dua with no such hadith is left out, and the build lists what was left out.
Chapters that have a hand-checked version (tool/adhkar_spec.json) are skipped.

Usage (from the repository root):
    python3 tool/build_hisn.py --cache DIR --hisn path/to/adhkar.json
    python3 tool/build_hisn.py --cache DIR --hisn path/to/adhkar.json --check
"""

import argparse
import difflib
import hashlib
import json
import re
import sys
import unicodedata
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import build_adhkar as base  # noqa: E402

ROOT = base.ROOT
CONFIG = ROOT / "tool" / "hisn_config.json"
OUT_ENTRIES = ROOT / "assets" / "adhkar" / "hisn.ar.json"
OUT_MANIFEST = ROOT / "assets" / "adhkar" / "hisn_manifest.json"
EDITIONS = ["bukhari", "muslim", "abudawud", "tirmidhi", "nasai", "ibnmajah"]
SAHIHAYN = {"bukhari", "muslim"}
# A dua is kept only when its words are in a hadith almost letter for letter,
# and make up nearly the whole entry (not a sentence about the dua).
MIN_RATIO = 0.97
MIN_COVER = 0.85
MIN_LETTERS = 14
# A sentence that starts like a narration or a ruling is not something to say.
NARRATIVE_FIRST = {"من", "اذا", "يكبر", "كان", "رايت", "قال", "يقول", "جعل", "طاف", "ركب"}
NARRATIVE_PAIRS = {"ما من"}


def split_entry(text):
    """(dua, rest): the dua itself, and the instructions around it.

    The dua is inside (( )) when present, else the text without bracketed
    instructions. Instructions such as (three times) or [begin with the right
    foot] are dropped from [rest] too, so only real sentences around the dua
    (a narration, a description) count against it.
    """
    text = text.strip()
    inner = re.search(r"\(\((.*?)\)\)", text, flags=re.S)
    if inner:
        dua = inner.group(1)
        rest = text[: inner.start()] + " " + text[inner.end() :]
    else:
        bare = text.strip(" .،")
        if bare.startswith("(") and bare.endswith(")"):
            text = bare[1:-1]
        dua, rest = text, ""
    dua = re.sub(r"\[[^\]]*\]", "", dua)
    dua = re.sub(r"\([^()]*\)", "", dua)
    rest = re.sub(r"\[[^\]]*\]|\([^()]*\)", "", rest)
    return dua, rest


def printed_number(edition, hadith):
    """The number a book is cited by, or None when the data has none."""
    if edition == "muslim":
        number = hadith.get("arabicnumber")
        return None if number is None else int(str(number).split(".")[0])
    return int(str(hadith["hadithnumber"]).split(".")[0])


def acceptable(edition, hadith):
    """Sahihayn always; the rest only with a sahih or hasan Albani grading."""
    if printed_number(edition, hadith) is None:
        return False
    if edition in SAHIHAYN:
        return True
    for grade in hadith.get("grades", []):
        if grade["name"] == "Al-Albani":
            return grade["grade"] in base.GRADES
    return False


class Index:
    def __init__(self, cache, spec):
        self.books = {}
        for name in EDITIONS:
            path = Path(cache) / f"ara-{name}.json"
            if not path.exists():
                raise SystemExit(f"missing {path}; run build_adhkar.py first")
            digest = hashlib.sha256(path.read_bytes()).hexdigest()
            if digest != spec["editionSha256"][f"ara-{name}"]:
                raise SystemExit(f"ara-{name}: checksum {digest} differs")
            hadiths = []
            for hadith in json.loads(path.read_text(encoding="utf-8"))["hadiths"]:
                if hadith["text"] and acceptable(name, hadith):
                    letters, index = base.folded_with_map(hadith["text"])
                    hadiths.append((hadith, letters, index))
            self.books[name] = hadiths

    def find(self, query):
        """Hadiths holding [query], best first: (ratio, edition, hadith, text)."""
        k = min(10, len(query) // 2)
        head, tail = query[:k], query[-k:]
        found = []
        for name, hadiths in self.books.items():
            for hadith, letters, index in hadiths:
                i = letters.find(head)
                if i < 0:
                    continue
                j = letters.find(tail, i)
                if j < 0:
                    continue
                window = letters[i : j + k]
                if len(window) > len(query) * 1.8:
                    continue
                ratio = difflib.SequenceMatcher(
                    None, query, window, autojunk=False
                ).ratio()
                if ratio < MIN_RATIO:
                    continue
                text = hadith["text"]
                last = index[j + k - 1] + 1
                while last < len(text) and base.TASHKEEL.match(text[last]):
                    last += 1
                found.append(
                    (ratio, name, hadith, base.clean(text[index[i] : last]))
                )
        found.sort(
            key=lambda f: (
                -round(f[0], 2),
                f[1] not in SAHIHAYN,
                abs(len(f[3]) - len(query)),
            )
        )
        return found


def clean_title(title, overrides, chapter):
    if str(chapter) in overrides:
        return overrides[str(chapter)]
    title = base.TASHKEEL.sub("", unicodedata.normalize("NFKC", title))
    return re.sub(r"\s+", " ", title).strip()


def build(cache, hisn_path):
    config = json.loads(CONFIG.read_text(encoding="utf-8"))
    spec = json.loads(base.SPEC.read_text(encoding="utf-8"))
    raw = Path(hisn_path).read_bytes()
    if hashlib.sha256(raw).hexdigest() != config["hisnIndexSha256"]:
        raise SystemExit("the Hisn index file is not the recorded one")
    chapters = json.loads(raw)
    editions = base.Editions(cache, spec)
    index = Index(cache, spec)
    skipped = set(config["skipChapters"])
    entries, collections, left_out = [], [], []
    for chapter in chapters:
        number = chapter["id"]
        if number in skipped:
            continue
        kept = []
        seen = set()
        for item in chapter["array"]:
            dua, rest = split_entry(item["text"])
            query = base.fold(dua)
            if len(query) < MIN_LETTERS:
                left_out.append((number, item["id"], "too short to match safely"))
                continue
            found = index.find(query)
            if not found:
                left_out.append((number, item["id"], "no hadith in the six books"))
                continue
            if len(query) < MIN_COVER * (len(query) + len(base.fold(rest))):
                left_out.append((number, item["id"], "describes the dua, is not the dua"))
                continue
            words = found[0][3]
            lead = [base.fold(word) for word in words.split()[:2]]
            if lead[0] in NARRATIVE_FIRST or " ".join(lead) in NARRATIVE_PAIRS:
                left_out.append((number, item["id"], "a narration or ruling, not a dua"))
                continue
            key = base.fold(words)
            if key in seen:
                continue
            seen.add(key)
            refs, grade_line = [], []
            for ratio, name, hadith, _ in found[:3]:
                refs.append(
                    {
                        "edition": f"ara-{name}",
                        "number": str(
                            hadith.get("arabicnumber")
                            if name == "muslim"
                            else hadith["hadithnumber"]
                        ),
                    }
                )
            count = item["count"]
            order = number * 100 + len(kept) + 1
            entries.append(
                {
                    "order": order,
                    "content": words,
                    "count": count,
                    "count_description": spec["countLabels"][str(count)],
                    "fadl": "",
                    "source": base.evidence_line(editions, refs, ""),
                    "type": number,
                    "audio": "",
                    "hadith_text": base.clean(editions.hadith(refs[0])["text"]),
                    "explanation_of_hadith_vocabulary": "",
                }
            )
            kept.append(order)
        for manual in config["manual"]:
            if manual["variant"] != number:
                continue
            order = number * 100 + len(kept) + 1
            built = base.entry_for(editions, spec, manual, order)
            if base.fold(built["content"]) in seen:
                continue
            entries.append(built)
            kept.append(order)
        if not kept:
            continue
        collections.append(
            {
                "id": f"hisn_{number}",
                "title": {
                    "ar": clean_title(chapter["category"], config["titles"], number)
                },
                "group": config["groups"].get(str(number), config["defaultGroup"]),
                "icon": "generic",
                "file": "hisn.ar.json",
                "variants": [number],
            }
        )
    entries_json = json.dumps(entries, ensure_ascii=False, indent=2) + "\n"
    digest = hashlib.sha256(entries_json.encode()).hexdigest()
    for collection in collections:
        collection["sha256"] = digest
    manifest = {"schema": 1, "collections": collections}
    manifest_json = json.dumps(manifest, ensure_ascii=False, indent=2) + "\n"
    return entries_json, manifest_json, left_out, digest


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--cache", required=True)
    parser.add_argument("--hisn", required=True)
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    entries, manifest, left_out, digest = build(args.cache, args.hisn)
    if args.check:
        stale = (
            not OUT_ENTRIES.exists()
            or OUT_ENTRIES.read_text(encoding="utf-8") != entries
            or OUT_MANIFEST.read_text(encoding="utf-8") != manifest
        )
        if stale:
            raise SystemExit("the Hisn files are out of date")
        print("up to date")
        return
    OUT_ENTRIES.write_text(entries, encoding="utf-8")
    OUT_MANIFEST.write_text(manifest, encoding="utf-8")
    kept = len(json.loads(entries))
    print(f"wrote {kept} duas in {len(json.loads(manifest)['collections'])} chapters")
    print("sha256", digest)
    print(f"left out {len(left_out)}:")
    for chapter, item, why in left_out:
        print(f"  chapter {chapter} item {item}: {why}")


if __name__ == "__main__":
    main()
