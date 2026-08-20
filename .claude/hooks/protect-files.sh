#!/bin/bash
# PreToolUse hook — matcher "Edit|Write"
# Blocks writes to credential and auth files.
#
# Why a hook and not a permissions rule: permission path patterns are only checked
# for Edit() and Read() — a rule on Write() is SILENTLY NEVER CONSULTED. The hook
# covers every write-capable tool regardless.
#
# exit 2 = BLOCK (exit 1 does NOT block)

set -uo pipefail
INPUT=$(cat)
FILE=$(printf '%s' "$INPUT" | jq -r '.tool_input.file_path // .tool_input.path // empty' 2>/dev/null)
[ -z "$FILE" ] && exit 0

deny() {
  echo "BLOCKED by protect-files hook: $1" >&2
  echo "Path: $FILE" >&2
  exit 2
}

case "$FILE" in
  # Environment / secrets
  *.env|*.env.*|*/.env|*/.env.*)        deny "environment files hold credentials" ;;
  */secrets/*|*/secret/*|*/.secrets/*)  deny "secrets directory" ;;
  *credentials*|*/.aws/*|*/.gcp/*)      deny "cloud credential store" ;;

  # SSH / keys
  */.ssh/*|*id_rsa*|*id_ed25519*|*.pem|*.key|*.p12|*.pfx)
                                        deny "private key material" ;;

  # Claude's own auth + config state
  */.claude.json|*/.claude/.credentials*|*/.config/anthropic/*)
                                        deny "Claude auth state — editing this can break or leak your session" ;;

  # Shell profiles (a write here executes on every future shell)
  */.bashrc|*/.bash_profile|*/.profile|*/.zshrc)
                                        deny "shell profile — a write here runs on every future shell (and can corrupt hook stdout)" ;;
esac

exit 0
