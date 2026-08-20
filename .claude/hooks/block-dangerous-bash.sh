#!/bin/bash
# PreToolUse hook — matcher "Bash"
# Blocks destructive commands. Every pattern here maps to a documented incident.
#
# CONTRACT (verified against official docs 2026-08-01):
#   exit 0 = allow
#   exit 2 = BLOCK, stderr is fed back to Claude as the reason
#   exit 1 = does NOT block (common mistake — never use it here)
#
# This runs BEFORE the permission check in every mode, including bypass modes.

set -uo pipefail
INPUT=$(cat)
CMD=$(printf '%s' "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null)
[ -z "$CMD" ] && exit 0

deny() {
  echo "BLOCKED by block-dangerous-bash hook: $1" >&2
  echo "Command: $CMD" >&2
  echo "If this is genuinely intended, run it yourself or edit ~/.claude/hooks/block-dangerous-bash.sh" >&2
  exit 2
}

# --- rm -rf against root, home, or a bare tilde -------------------------------
# Knight-class blast radius. Reported real case: `rm -rf tests/ patches/ plan/ ~/`
# — the trailing ~/ is what a naive "rm -rf /" blocklist misses.
if printf '%s' "$CMD" | grep -Eq '(^|[;&|]|\s)rm[[:space:]]+(-[a-zA-Z]*[rR][a-zA-Z]*[fF][a-zA-Z]*|-[a-zA-Z]*[fF][a-zA-Z]*[rR][a-zA-Z]*)[[:space:]]+.*(/[[:space:]]*$|~[[:space:]]*/?[[:space:]]*$|\$HOME|/\*)'; then
  deny "rm -rf targeting root, home, or a glob-all path"
fi

# --- git history / worktree destruction --------------------------------------
# GitHub issues #34327, #17190, #7232 (destroyed uncommitted work), #55024.
if printf '%s' "$CMD" | grep -Eq 'git[[:space:]]+reset[[:space:]]+(--hard|--merge[[:space:]]+.*--hard)'; then
  deny "git reset --hard destroys uncommitted work (issues #34327, #17190, #7232)"
fi
if printf '%s' "$CMD" | grep -Eq 'git[[:space:]]+push([[:space:]]+[^[:space:]]+)*[[:space:]]+(--force|-f)([[:space:]]|$)'; then
  deny "git push --force rewrites remote history (use --force-with-lease deliberately, yourself)"
fi
if printf '%s' "$CMD" | grep -Eq 'git[[:space:]]+clean[[:space:]]+-[a-zA-Z]*[fdx]'; then
  deny "git clean -f permanently deletes untracked files"
fi
if printf '%s' "$CMD" | grep -Eq 'git[[:space:]]+checkout[[:space:]]+.*[[:space:]]--[[:space:]]+\.[[:space:]]*$|git[[:space:]]+restore[[:space:]]+\.[[:space:]]*$'; then
  deny "this silently overwrites ALL unstaged changes (issue #55024: 14 files lost)"
fi
if printf '%s' "$CMD" | grep -Eq 'git[[:space:]]+branch[[:space:]]+-D[[:space:]]'; then
  deny "git branch -D force-deletes an unmerged branch"
fi

# --- pipe-to-shell -----------------------------------------------------------
if printf '%s' "$CMD" | grep -Eq '(curl|wget)[^|]*\|[[:space:]]*(sudo[[:space:]]+)?(ba)?sh'; then
  deny "piping a download straight into a shell executes unreviewed remote code"
fi

# --- permission blowout ------------------------------------------------------
if printf '%s' "$CMD" | grep -Eq 'chmod[[:space:]]+(-[a-zA-Z]+[[:space:]]+)*777'; then
  deny "chmod 777 makes files world-writable"
fi

# --- credential exfiltration shapes -----------------------------------------
if printf '%s' "$CMD" | grep -Eq '(cat|head|tail|less|more)[[:space:]]+[^|;]*(\.env|id_rsa|\.pem|credentials)[^|;]*\|[[:space:]]*(curl|wget|nc)'; then
  deny "reading a credential file directly into a network command"
fi

exit 0
