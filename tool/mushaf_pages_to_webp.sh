#!/usr/bin/env bash
# Downloads the printed Mushaf page PNGs and converts them to lossless WebP,
# for hosting the pages yourself. Nothing here is bundled into the app.
#
# Usage: tool/mushaf_pages_to_webp.sh OUT_DIR [light|dark|both] [FIRST] [LAST]
# Needs curl, cwebp (brew install webp), and shasum.
# Output: OUT_DIR/{light,dark}/p{N}.webp and OUT_DIR/SHA256SUMS.
# Source and licence notes: docs/QURAN_SOURCES.md, section 12.
set -euo pipefail

out="${1:?usage: $0 OUT_DIR [light|dark|both] [FIRST] [LAST]}"
which="${2:-both}"
first="${3:-1}"
last="${4:-604}"
base='https://cdn.jsdelivr.net/gh/SakinaDevGroup/mushaf-madani-cdn@main'

command -v cwebp >/dev/null || { echo 'cwebp not found: brew install webp' >&2; exit 1; }
case "$which" in
  both) themes=(light dark) ;;
  light | dark) themes=("$which") ;;
  *) echo "unknown theme set: $which" >&2; exit 1 ;;
esac

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

for theme in "${themes[@]}"; do
  mkdir -p "$out/$theme"
  for ((page = first; page <= last; page++)); do
    target="$out/$theme/p$page.webp"
    [[ -s "$target" ]] && continue
    png="$tmp/p$page.png"
    for attempt in 1 2 3; do
      if curl -sfL --retry 2 -o "$png" "$base/$theme/p$page.png" &&
        [[ "$(head -c 4 "$png" | xxd -p)" == '89504e47' ]]; then
        break
      fi
      # The CDN sometimes answers with an error page; wait and try again.
      [[ $attempt == 3 ]] && { echo "failed: $theme p$page" >&2; exit 1; }
      sleep 2
    done
    cwebp -quiet -lossless -z 9 "$png" -o "$target"
    echo "$theme p$page"
  done
done

(cd "$out" && find . -name '*.webp' | sort | xargs shasum -a 256 > SHA256SUMS)
echo "done: $(find "$out" -name '*.webp' | wc -l | tr -d ' ') files in $out"
