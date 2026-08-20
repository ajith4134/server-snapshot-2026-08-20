---
name: youtube-video
description: Extracts and reads YouTube video content — timestamped transcript plus sampled frames read as images. Use when the user provides a YouTube link, asks what a video says or shows, or when a task requires understanding a talk, tutorial, or screen recording. Handles videos with no captions via local Whisper transcription.
---

# Understanding YouTube videos

## Why not just fetch the page

WebFetch on a YouTube URL returns metadata at best and **0 bytes of transcript**.
The caption `baseUrl` carries `exp=xpe` — YouTube's proof-of-origin (PO) token gate.
Gated requests return **HTTP 200 with an empty body**, so a naive scraper reports no
error and silently produces nothing.

There is no clean workaround without running YouTube's BotGuard JS. `yt-dlp`
resolves the player JS itself and is unaffected. **A stdlib scraper was built and
tested against this — it fails on exactly this gate. Do not rebuild it.**

Guessing a video's content from its title or description is never acceptable.

## Usage

```
ytgrab "<url>"                      # transcript + frames (default: 1 frame/60s, max 40)
ytgrab "<url>" --every 20           # denser frames — code/slide-heavy videos
ytgrab "<url>" --max-frames 48      # raise the cap for dense material
ytgrab "<url>" --no-frames          # transcript only — talking-head videos
ytgrab "<url>" -o ./notes/topic     # explicit output directory
ytgrab "<url>" --whisper-model medium   # better audio transcription (no-caption case)
ytgrab "<url>" --no-whisper         # disable the audio fallback
```

Output directory contains:

| File | Contents |
|---|---|
| `transcript.md` | timestamped transcript — **what was SAID** |
| `frames/` | sampled JPEGs — **what was SHOWN** (slides, terminal, code) |
| `meta.json` | title, channel, duration, caption availability |
| `README.md` | frame → timestamp map |

## Then read BOTH parts

Read `transcript.md`, **then Read the frames as images.** A video is not understood
from the transcript alone — screen recordings, slides and code demos carry content
the audio never states. Match frame timestamps to transcript headings to reconstruct
the flow.

If prompt cards or slides flash by faster than the sampling interval, extract
targeted timestamps at full resolution from the already-downloaded video rather than
re-running the whole job:

```
ffmpeg -loglevel error -ss <seconds> -i video.mp4 -frames:v 1 -vf "scale=1100:-1" -q:v 4 out.jpg
```

## Rules

1. **Request ONE subtitle language.** Several variants at once trips YouTube's rate
   limiter → HTTP 429. `ytgrab` already does this.
2. **No captions is a real case.** `ytgrab` falls back to local Whisper automatically
   and says so. If that also fails, the frames are the only content — read all of
   them and tell the user the audio was unavailable.
3. **Long videos: widen the interval, don't drop content.** `--max-frames` (default
   40) widens sampling automatically. For dense material, raise the cap instead of
   silently sampling too coarsely.
4. **Report what was actually obtained** — cue count and frame count. Never imply
   fuller understanding than the artifacts support.
5. **Never turn a half-loaded page into a permanent rule.** Show the user the summary
   and get confirmation before writing anything derived from a video into CLAUDE.md.

## Tooling (installed user-space, no root)

- `~/.local/bin/yt-dlp` — self-contained binary; resolves player JS, beats the PO gate
- `~/.local/bin/ffmpeg` — static build (also `ffprobe`); frame extraction
- `~/.local/bin/ytgrab` — the wrapper
- `~/.venvs/media/` — venv holding `faster-whisper`

Whisper: default model `small`; `medium`/`large-v3` for accuracy, `tiny`/`base` for
speed (~30× realtime on CPU at `base`).

If `yt-dlp` starts failing on YouTube changes: `yt-dlp -U`

## Known traps (both verified 2026-08-01, both auto-handled)

**1. Whisper VAD can silently discard everything.** `vad_filter=True` can drop
*every* segment on music-heavy or unusual audio while still reporting success.
`ytgrab` auto-retries with VAD off when a pass returns zero cues. **Do not remove
that retry.**

**2. HTTP 403 on the video stream → zero frames.** Some videos reject the default
player client, so frames come back empty while the transcript succeeds. `ytgrab`
auto-retries with `player_client=android,web_safari`, then `ios`. **If frames are
ever 0 while the transcript worked, this is the first thing to check.**

## Not worth retrying

The `mcp-youtube-transcript` MCP server installs but is **broken upstream**
(`ImportError: FastMCP`). It also does transcripts only — no frames — so `ytgrab`
supersedes it regardless.
