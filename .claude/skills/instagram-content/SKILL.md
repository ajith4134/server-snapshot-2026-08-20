---
name: instagram-content
description: Extract and read Instagram posts, carousels, and reels — images, video frames, spoken audio via Whisper, and captions. Use when given an instagram.com/p/ or instagram.com/reel/ link, when asked what an Instagram post says or shows, or when caption-only fetching returned nothing useful. WebFetch alone recovers captions at best and returns nothing for image carousels.
---

# Reading Instagram content

**WebFetch on an Instagram URL is not enough.** At best it returns the caption; for image carousels
it returns Instagram branding and nothing else. The substance of a carousel is in the images and the
substance of a reel is in the video and audio — neither is reachable that way.

Two tools, chosen by content type. Both verified working 2026-08-01, **no login required.**

## Reels and video → `ytgrab`

```
ytgrab "<reel-url>" --every 3 --max-frames 8 -o ./out
```

Produces `transcript.md` (Whisper), `frames/`, `meta.json`. Then **read both** — the transcript for
what was said, the frames for what was shown.

> ⚠️ **`--every 3` is mandatory for reels.** The default is `--every 60`, and Instagram reports
> `duration=NA` → 0. A 17-second reel at the default interval yields **zero frames** while the
> transcript succeeds. That symptom is this bug, not the YouTube 403 player-client trap.

Reels have no published captions, so `ytgrab` falls back to local Whisper automatically and says so.
This works — a 17s reel produced 6 cues / 537 chars of real spoken content.

## Posts and image carousels → `instaloader`

`yt-dlp` **cannot** do this — it is a video tool and returns `No video formats found!` per carousel
item. `gallery-dl` hangs on Instagram (no output, times out; likely auth or rate-limit backoff).

```
instaloader --no-video-thumbnails --no-metadata-json --no-compress-json \
  --dirname-pattern=./out -- -<SHORTCODE>
```

Note the argument form: **`-- -<SHORTCODE>`** — the leading `--` ends option parsing and the post
shortcode is prefixed with `-`. The shortcode is the `p/XXXX` segment of the URL.

Produces one `.jpg` per carousel slide plus a `.txt` caption file. **Then Read each image** — the
content is in them.

> ⚠️ **Do NOT pass `--no-videos`. Carousels mix image and video slides**, and `--no-videos` drops the
> video ones **silently** — no warning, no gap in the numbering you would notice, just a slide that
> never existed as far as you can tell.
>
> **Verified failure, 2026-08-02:** a 6-slide carousel downloaded as `_1,_2,_4,_5,_6,_7`. Slide 3 was
> a video and vanished. It was one of the five libraries the post was *about* — the single slide
> naming `py-pde` and its use for Dupire local-vol and Fokker-Planck PDEs. The gap is only visible if
> you check the filename sequence for holes.
>
> **Always check for numbering holes** after download:
> ```
> ls out/*.jpg | sed 's/.*_\([0-9]*\)\.jpg/\1/' | sort -n | tr '\n' ' '
> ```

### Recovering video slides from a carousel

`instaloader` writes them as `.mp4` alongside the `.jpg` slides. Extract frames and read those:

```
for v in out/*.mp4; do
  ffmpeg -nostdin -loglevel error -i "$v" -vf fps=1/3 -frames:v 8 "out/frames/f_%02d.jpg"
done
```

The frames carry the slide's text — this is how the missing `py-pde` slide was recovered in full.

## Caption only, when that is all you need

```
yt-dlp --no-warnings -J --flat-playlist "<url>"
```

The `description` field holds the full caption. Faster than either tool above when the images and
video do not matter.

## When a link genuinely cannot be read

Some posts are unreachable anonymously. The signature is exact:

```
ERROR: [Instagram] <shortcode>: Instagram sent an empty media response.
```

That is login-gating or removal at Instagram's end, **not a tool bug** — retrying through a second
path (`yt-dlp` direct + `ffmpeg` instead of `ytgrab`) reproduces it. Measured 2026-08-02: **6 of 57
links** failed this way, and no anonymous method reached them. Say so plainly and ask for a
signed-in screenshot; do not keep retrying, and never infer the content from the URL or title.

## What to expect

**Measured over 57 links, 2026-08-02: 49 read at media level** (144 carousel images, 445 video
frames, 19 Whisper transcripts), 2 caption-only, 6 unrecoverable. Roughly **8 carried anything
actionable.**

**Caption-only assessment is not reading the post, and it produces false conclusions.** Two
documented errors from doing so:

- A post recorded as *"gated behind a comment, the material is not in the post"* had **all 30
  formulas printed in its images.**
- Four posts recorded as *"independent convergence on our architecture"* turned out to be **one
  marketing account posting the same fabricated template** under rotating names, with invented
  GitHub repos and mockup dashboards.

**The reliable filter, now well evidenced: posts that teach something are specific,
mechanism-level, and make no profit claim.** Every post leading with a return figure or a dashboard
was fabricated or unverifiable.

**Verify falsifiable claims rather than repeating them.** Named repos, star counts, versions and
licences are all cheap to check — `gh search repos`, `gh repo view`, `curl pypi.org/pypi/<pkg>/json`.
Doing this is what exposed the fabricated account.

Carousels are usually the highest-value type: reference charts, formula sheets, API snippets and
architecture diagrams that caption text does not describe at all.

## Installation (already done)

`uv tool install instaloader` — `~/.local/bin/instaloader`, v1.32.9.
`yt-dlp`, `ffmpeg`, `ytgrab`, and the `faster-whisper` venv were already present.

`gallery-dl` was installed and **did not work** for this; left in place but do not reach for it first.
