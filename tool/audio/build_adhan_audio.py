#!/usr/bin/env python3
"""Builds the adhan recordings from tool/audio/adhan_sources.json.

Each source is downloaded once into --cache and must match its SHA-256.
Then it is cut, cleaned, and evened out the same way:

  1. cut to the recording's own part (start/end in the sources file),
  2. rumble below 80 Hz removed (handling noise, air conditioning, hum),
  3. silence at both ends removed, so the adhan starts at once,
  4. loudness set to -16 LUFS integrated, true peak -1.5 dBTP (EBU R128,
     measured first, then applied linearly so the voice keeps its dynamics),
  5. a 30 ms fade in and a 400 ms fade out, so nothing clicks,
  6. mono AAC in an .m4a, without the source's tags or cover art.

A recording with an "iosClip" also gives iOS its notification sound: its
first 29.5 seconds (iOS plays at most 30), faded out, as IMA ADPCM in a .caf,
in assets/adhan/ios (bundled for iOS only).

Bundled recordings go to android/app/src/main/res/raw at 64 kb/s; the others
go to --media (the files of the media repository) at 96 kb/s. The catalogue
assets/adhan/voices.json is written from the results, with each file's size
and SHA-256, so the app checks every download.

--serve says where the app downloads the voices that are not bundled:
"media" (the cleaned files, once the media repository is published at
--base) or "source" (each recording's own file where it was found, as it is,
with that file's SHA-256), which works before the media repository exists.

Needs ffmpeg and ffprobe. Run from the repository root:

  python3 tool/audio/build_adhan_audio.py --cache <folder> \
      --media app_assets/media --base <https URL of the media repository>
"""

import argparse
import hashlib
import json
import pathlib
import subprocess
import sys
import urllib.request

ROOT = pathlib.Path(__file__).resolve().parents[2]
SOURCES = ROOT / "tool/audio/adhan_sources.json"
RAW = ROOT / "android/app/src/main/res/raw"
CATALOG = ROOT / "assets/adhan/voices.json"
IOS = ROOT / "assets/adhan/ios"
USER_AGENT = "MushafiBuild/1.0 (adhan audio build tool)"


def sha256(path: pathlib.Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as file:
        for chunk in iter(lambda: file.read(1 << 20), b""):
            digest.update(chunk)
    return digest.hexdigest()


def fetch(url: str, target: pathlib.Path, expected: str) -> None:
    if not target.exists():
        request = urllib.request.Request(url, headers={"User-Agent": USER_AGENT})
        with urllib.request.urlopen(request, timeout=120) as response:
            target.write_bytes(response.read())
    actual = sha256(target)
    if actual != expected:
        sys.exit(f"{target.name}: SHA-256 {actual}, expected {expected}")


def run(*args: str) -> str:
    result = subprocess.run(args, capture_output=True, text=True)
    if result.returncode != 0:
        sys.exit(f"{args[0]} failed:\n{result.stderr[-2000:]}")
    return result.stderr


def duration(path: pathlib.Path) -> float:
    out = subprocess.run(
        ["ffprobe", "-v", "error", "-show_entries", "format=duration",
         "-of", "csv=p=0", str(path)],
        capture_output=True, text=True, check=True,
    ).stdout
    return float(out.strip())


def build(source: pathlib.Path, recording: dict, loudness: dict,
          target: pathlib.Path, bitrate: str, work: pathlib.Path) -> None:
    cut = work / f"{recording['id']}.cut.wav"
    window = []
    if "start" in recording:
        window += ["-ss", str(recording["start"])]
    if "end" in recording:
        window += ["-to", str(recording["end"])]
    trim = ("silenceremove=start_periods=1:start_threshold=-50dB:"
            "start_silence=0.05")
    run("ffmpeg", "-y", "-v", "error", *window, "-i", str(source), "-vn",
        "-ac", "1", "-ar", "44100",
        "-af", f"highpass=f=80,{trim},areverse,{trim},areverse",
        str(cut))
    level = (f"I={loudness['integrated']}:TP={loudness['truePeak']}:"
             f"LRA={loudness['range']}")
    report = run("ffmpeg", "-v", "info", "-i", str(cut), "-af",
                 f"loudnorm={level}:print_format=json", "-f", "null", "-")
    # loudnorm prints its measurement as the last JSON block.
    measured = json.loads(report[report.rindex("{"):report.rindex("}") + 1])
    length = duration(cut)
    fade_out = max(0.0, length - 0.4)
    run("ffmpeg", "-y", "-v", "error", "-i", str(cut), "-af",
        f"loudnorm={level}:linear=true"
        f":measured_I={measured['input_i']}"
        f":measured_TP={measured['input_tp']}"
        f":measured_LRA={measured['input_lra']}"
        f":measured_thresh={measured['input_thresh']}"
        f":offset={measured['target_offset']},"
        f"afade=t=in:d=0.03,afade=t=out:st={fade_out:.3f}:d=0.4,"
        "aresample=44100",
        "-ac", "1", "-c:a", "aac", "-b:a", bitrate,
        "-map_metadata", "-1", "-fflags", "+bitexact", "-flags:a", "+bitexact",
        "-movflags", "+faststart", str(target))


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    parser.add_argument("--cache", required=True, type=pathlib.Path)
    parser.add_argument("--media", required=True, type=pathlib.Path)
    parser.add_argument("--base", default="",
                        help="https address the media folder is served from")
    parser.add_argument("--serve", choices=["media", "source"],
                        default="source")
    options = parser.parse_args()
    if options.serve == "media" and not options.base.startswith("https://"):
        sys.exit("--serve media needs an https --base")
    base = options.base.rstrip("/") + "/"
    spec = json.loads(SOURCES.read_text())
    options.cache.mkdir(parents=True, exist_ok=True)
    work = options.cache / "work"
    work.mkdir(exist_ok=True)
    (options.media / "adhan").mkdir(parents=True, exist_ok=True)

    voices = []
    for recording in spec["recordings"]:
        source = options.cache / f"{recording['sha256'][:16]}.src"
        fetch(recording["url"], source, recording["sha256"])
        bundled = recording.get("bundled")
        if bundled:
            target = RAW / f"{bundled}.m4a"
            build(source, recording, spec["loudness"], target, "64k", work)
        else:
            target = options.media / "adhan" / f"{recording['id']}.m4a"
            build(source, recording, spec["loudness"], target, "96k", work)
        clip = recording.get("iosClip")
        if clip:
            IOS.mkdir(parents=True, exist_ok=True)
            sound = IOS / f"{clip}.caf"
            run("ffmpeg", "-y", "-v", "error", "-i", str(target), "-t", "29.5",
                "-af", "afade=t=out:st=27.5:d=2", "-ac", "1", "-ar", "22050",
                "-c:a", "adpcm_ima_qt", "-map_metadata", "-1",
                "-fflags", "+bitexact", str(sound))
            print(f"{sound.relative_to(ROOT)}  {sound.stat().st_size:>9,} bytes"
                  f"  {duration(sound):6.1f} s  {sha256(sound)}")
        print(f"{target.relative_to(ROOT) if target.is_relative_to(ROOT) else target}"
              f"  {target.stat().st_size:>9,} bytes  {duration(target):6.1f} s"
              f"  {sha256(target)}")
        if recording["kind"] == "dua":
            continue
        voice = {
            "id": recording["id"],
            "kind": recording["kind"],
            "title": recording["title"],
            "place": recording["place"],
            "bytes": target.stat().st_size,
            "sha256": sha256(target),
            "source": recording["source"],
            # The rights in these recordings are being asked for; see
            # docs/AUDIO_SOURCES.md before a release.
            "license": recording.get(
                "license",
                {"name": "Permission pending", "url": recording["source"]}),
            "credit": recording["credit"],
        }
        if bundled:
            voice["builtIn"] = True
        elif options.serve == "media":
            voice["url"] = f"{base}adhan/{recording['id']}.m4a"
            voice["extension"] = "m4a"
        else:
            # The recording's own file, unchanged, checked by its SHA-256.
            voice["url"] = recording["url"]
            voice["extension"] = recording["url"].rsplit(".", 1)[-1].lower()
            voice["bytes"] = source.stat().st_size
            voice["sha256"] = recording["sha256"]
        voices.append(voice)

    CATALOG.write_text(
        json.dumps({"schema": 2, "voices": voices}, ensure_ascii=False,
                   indent=2) + "\n")
    print(f"wrote {CATALOG.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
