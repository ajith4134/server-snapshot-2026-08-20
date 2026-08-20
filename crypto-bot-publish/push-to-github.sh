#!/usr/bin/env bash
# Publishes the staged archive to github.com/ajith4134/crypto-bot (private).
# Everything here is already on disk; this script only does the git work that
# the auto-mode classifier refuses to run unattended.
set -euo pipefail

PUBLISH_DIR=/home/anushadudekula71/crypto-bot-publish
SOURCE_REPO=/home/anushadudekula71/trading-system
REMOTE_URL=https://github.com/ajith4134/crypto-bot.git

cd "$PUBLISH_DIR"

echo "==> 1/6  git init"
if [ ! -d .git ]; then
  git init -q -b main
fi
git config user.name  "Ajith D"
git config user.email "ajithd747@gmail.com"

echo "==> 2/6  commit research, video notes, Claude config  (114 MB, may take a minute)"
git add -A
git commit -q -m "Archive research, video notes, Instagram sources and Claude config

54 research and design documents, 7 YouTube video note sets with transcripts and
frames, the full Instagram raw capture (817 frames, 9 reels), reference images,
and the global CLAUDE.md rules plus persistent memory files.

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>"

echo "==> 3/6  graft trading-system history into trading-system/"
git remote remove trading-system 2>/dev/null || true
git remote add trading-system "$SOURCE_REPO"
git fetch -q trading-system
git subtree add --prefix=trading-system trading-system/master

echo "==> 4/6  bring the Layer 0 branch across with all 45 commits"
git fetch -q trading-system worktree-layer0-raw-capture:layer0-raw-capture

echo "==> 5/6  make sure the private repo exists"
if ! gh repo view ajith4134/crypto-bot >/dev/null 2>&1; then
  gh repo create ajith4134/crypto-bot --private \
    --description "Trading system research, design decisions, video notes and Layer 0 capture"
fi

echo "==> 6/6  push main and layer0-raw-capture"
git remote remove origin 2>/dev/null || true
git remote add origin "$REMOTE_URL"
git push -u origin main
git push origin layer0-raw-capture

echo
echo "Done.  https://github.com/ajith4134/crypto-bot"
git -C "$PUBLISH_DIR" log --oneline -3
