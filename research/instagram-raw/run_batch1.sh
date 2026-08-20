#!/usr/bin/env bash
# Batch-1 links: images + captions via instaloader (videos ENABLED so carousel
# video-slides are not silently dropped, the DY4dxCkDa8Z py-pde failure mode).
export PATH="$HOME/.local/bin:$PATH"
SP=/tmp/claude-1001/-home-anushadudekula71/0a15b275-e446-4894-8c28-f6b077d94775/scratchpad/b1
mkdir -p "$SP"
STATUS="$SP/_status.txt"
: > "$STATUS"

# 18 batch-1 links that were caption-only, + DaprsQ4CdnU (re-fetch for full read),
# + DY4dxCkDa8Z re-fetch WITH videos to recover the missing py-pde slide.
CODES="
DbO5FVYgd19 Dbbvsvcsmbb DbPaMI1ndH2 DaNFqoYNtIQ Dax2J2LEl5G DbT9K96Afsx
DbYwC02ERkt DbYOQlSFJSZ DbXE8o_sspP DbMx1AUlBo7 DbL4zzRo7dy Da8LFnfFnqx
DbGFvV0Bwn5 Da_f158GyKd DbGYmZQiHxN DbDbx6onUOI DbKYvkCifnY DbDnA_8kcjW
DaprsQ4CdnU DY4dxCkDa8Z
"

for sc in $CODES; do
  out="$SP/$sc"
  mkdir -p "$out"
  timeout 120 instaloader --no-video-thumbnails --no-metadata-json --no-compress-json \
    --quiet --dirname-pattern="$out" -- "-$sc" >"$out/_log.txt" 2>&1
  rc=$?
  jpg=$(ls "$out"/*.jpg 2>/dev/null | wc -l)
  mp4=$(ls "$out"/*.mp4 2>/dev/null | wc -l)
  cap=$(ls "$out"/*UTC.txt 2>/dev/null | wc -l)
  printf '%-14s rc=%-3s jpg=%-3s mp4=%-3s cap=%-3s %s\n' \
    "$sc" "$rc" "$jpg" "$mp4" "$cap" "$(tail -1 "$out/_log.txt" 2>/dev/null | cut -c1-60)" >> "$STATUS"
  sleep 5
done

# Any post that yielded a video gets frames + Whisper transcript too.
for sc in $CODES; do
  out="$SP/$sc"
  if ls "$out"/*.mp4 >/dev/null 2>&1; then
    for v in "$out"/*.mp4; do
      vd="$out/frames"; mkdir -p "$vd"
      ffmpeg -nostdin -loglevel error -i "$v" -vf fps=1/3 -frames:v 8 "$vd/f_%02d.jpg" </dev/null 2>>"$out/_ff.log"
    done
    n=$(ls "$out"/frames/*.jpg 2>/dev/null | wc -l)
    echo "  frames $sc = $n" >> "$STATUS"
  fi
done

echo "DONE batch1" >> "$STATUS"
