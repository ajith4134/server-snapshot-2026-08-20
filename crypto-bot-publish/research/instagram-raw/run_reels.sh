#!/usr/bin/env bash
# Batch-extract Instagram reels: transcript (Whisper fallback) + sampled frames.
export PATH="$HOME/.local/bin:$PATH"
SP=/tmp/claude-1001/-home-anushadudekula71/0a15b275-e446-4894-8c28-f6b077d94775/scratchpad/reels
mkdir -p "$SP"
STATUS="$SP/_status.txt"
: > "$STATUS"

REELS="
Da8E8_sDtBx DacDmnGsQsy Da4XlSfhtNo Dasuyqan5n7 DatQIOQTcwT Da0BA-GRGN1
DXZX8JYDZZt Dau64tdyY4n DYSAzzpAZH9 DVaB4VAEhMf Dak-8k6oNeA DaTsmSOzl3c
DW4yP9HgWv- DYW1yX6AIKX DYNEuorDrLy DYU0dMcpBFP DZ2eqaZInfk DVRWC25DDid
DZ9xV72I54p DZ7bTCtoc3s DV_w-fRDEGI DZ7lPp6slQl DZwTzBwhHXS DT1WyeYjEnL
"
# batch-1 links that returned captions but whose video/audio was never read
EXTRA="Da0EeF1DTZ- DYB671CtuaQ Da_kNEjNt9f Da1XG9qgd4E DaqrnR3j8oM DatgKiljpXS"

run_one() {
  local sc="$1" kind="$2" url="$3"
  local out="$SP/$sc"
  mkdir -p "$out"
  timeout 300 ytgrab "$url" --every 3 --max-frames 8 -o "$out" >"$out/_log.txt" 2>&1
  local rc=$?
  local cues=0 chars=0 frames=0
  if [ -f "$out/transcript.md" ]; then
    chars=$(wc -c < "$out/transcript.md")
    cues=$(grep -cE '^\[' "$out/transcript.md" 2>/dev/null || echo 0)
  fi
  frames=$(ls "$out"/frames/*.jpg 2>/dev/null | wc -l)
  printf '%-14s %-5s rc=%-3s cues=%-4s chars=%-6s frames=%s\n' "$sc" "$kind" "$rc" "$cues" "$chars" "$frames" >> "$STATUS"
}

for sc in $REELS; do run_one "$sc" reel "https://www.instagram.com/reel/$sc/"; done
for sc in $EXTRA; do run_one "$sc" b1 "https://www.instagram.com/p/$sc/"; done

echo "DONE $(wc -l < "$STATUS") processed" >> "$STATUS"
