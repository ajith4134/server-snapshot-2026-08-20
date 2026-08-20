#!/usr/bin/env bash
# Commit and push every repo on this box, refusing on anything that looks like a
# credential.
#
# Rule 9: work that exists only on this VM is one failed disk from gone, and the
# VM has already been rebooted once with nothing set to bring it back.
#
# Two things are deliberately NOT copied, and both are correct:
#
#   ~/.claude uses an ALLOWLIST, not an ignore-list. It holds a live OAuth
#   token, full conversation transcripts and ~532 MB of plugin cache. Everything
#   is ignored and each safe path is admitted by name, because an ignore-list
#   leaks the first thing nobody thought to exclude.
#
#   ~/capture is not in git at all. It is a multi-gigabyte binary archive
#   growing at ~3.4 GB/day, and committing it would make every future clone
#   carry it. It is also the ONE thing here that genuinely cannot be
#   reconstructed - see the warning this script prints.
#
# Usage:  ~/.claude/push-all-repos.sh ["commit message"]
set -uo pipefail

REPOS=(
  "$HOME/trading-system"
  "$HOME/research"
  "$HOME/.claude"
)

MESSAGE=${1:-"chore: sync working tree"}
FAILED=0

# Credential *shapes*, not the words. Grepping for "password" finds prose;
# these find the thing itself.
SECRET_PATTERN='gh[pousr]_[A-Za-z0-9]{16,}|AKIA[0-9A-Z]{16}|sk-ant-[A-Za-z0-9-]{20,}|BEGIN [A-Z ]*PRIVATE KEY|xox[baprs]-[A-Za-z0-9-]{10,}'

for repo in "${REPOS[@]}"; do
  name=$(basename "$repo")
  [ -d "$repo/.git" ] || { printf '  %-16s SKIP (not a git repo)\n' "$name"; continue; }

  staged=$(git -C "$repo" status --porcelain)
  unpushed=$(git -C "$repo" log --oneline @{u}.. 2>/dev/null | wc -l)

  if [ -z "$staged" ] && [ "$unpushed" -eq 0 ]; then
    printf '  %-16s clean\n' "$name"
    continue
  fi

  if [ -n "$staged" ]; then
    git -C "$repo" add -A
    # Scan what is actually about to be committed, not the working tree: a
    # secret in an ignored file is not going anywhere, and scanning it would
    # refuse pushes forever for no reason.
    if git -C "$repo" diff --cached | grep -qE "$SECRET_PATTERN"; then
      printf '  %-16s REFUSED - credential shape in staged diff\n' "$name"
      git -C "$repo" reset -q
      FAILED=1
      continue
    fi
    git -C "$repo" commit -q -m "$MESSAGE" || true
  fi

  if git -C "$repo" push -q origin HEAD 2>/dev/null; then
    printf '  %-16s pushed\n' "$name"
  else
    printf '  %-16s PUSH FAILED (no network, or no auth)\n' "$name"
    FAILED=1
  fi
done

# The archive is the one irreplaceable thing on this box and the one thing git
# must not hold. Say so every run rather than letting its absence read as
# "everything is backed up".
if [ -d "$HOME/capture/raw" ]; then
  size=$(du -sh "$HOME/capture" 2>/dev/null | cut -f1)
  printf '\n  NOTE  ~/capture (%s) is NOT in GitHub and must not be.\n' "$size"
  printf '        It is also unbackfillable - a lost day of market data is lost\n'
  printf '        permanently. It needs object storage, not a repo.\n'
fi

exit "$FAILED"
