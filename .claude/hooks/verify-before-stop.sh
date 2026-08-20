#!/usr/bin/env bash
# Rule 0 enforcement — Stop hook.
#
# Blocks the end of a turn when Claude claims work is done/passing/fixed but ran
# no command that could have checked it. Turns Rule 0 from a GUIDE into a RULE.
#
# Design notes (read before editing):
#   * exit 2 blocks the stop and feeds stderr back to Claude. exit 0 allows it.
#     exit 1 does NOT block (see CLAUDE.md Rule 4).
#   * This hook FAILS OPEN. Unlike the PreToolUse hooks, a crash here must not
#     trap the user in an unstoppable turn. Every unexpected condition -> exit 0.
#   * stop_hook_active guards against infinite loops: it is true when this hook
#     already forced a continuation, so we nudge at most once per turn.

PAYLOAD=$(cat)

python3 -c '
import json, re, sys, time

# --- TEMPORARY DIAGNOSTIC (remove once behaviour is confirmed) ---
import datetime
def _log(msg):
    try:
        with open("/tmp/claude-stophook-fired.txt", "a") as fh:
            fh.write(datetime.datetime.now().strftime("%H:%M:%S ") + msg + "\n")
    except Exception:
        pass
# --- end diagnostic ---

def allow(why="unknown"):
    _log("ALLOW: " + why)
    sys.exit(0)

try:
    payload = json.loads(sys.argv[1])
except Exception:
    allow("payload not JSON")

# Already nudged once this turn -- never nudge twice.
if payload.get("stop_hook_active"):
    allow("stop_hook_active guard")

path = payload.get("transcript_path")
if not path:
    allow("no transcript_path")

def scan():
    """Read the transcript and return (texts, ran_a_command), or None if unreadable."""
    try:
        with open(path, "r", encoding="utf-8") as fh:
            entries = [json.loads(line) for line in fh if line.strip()]
    except Exception:
        return None

    # Walk back to the last real user turn; everything after it is this turn.
    start = 0
    for i in range(len(entries) - 1, -1, -1):
        e = entries[i]
        if e.get("type") == "user" and not e.get("isMeta"):
            content = (e.get("message") or {}).get("content")
            # Tool results arrive as role=user; those are not a new human turn.
            if isinstance(content, str):
                start = i
                break
            if isinstance(content, list) and not any(
                isinstance(b, dict) and b.get("type") == "tool_result" for b in content
            ):
                start = i
                break

    texts = []
    ran = False
    for e in entries[start:]:
        if e.get("type") != "assistant":
            continue
        for block in (e.get("message") or {}).get("content") or []:
            if not isinstance(block, dict):
                continue
            if block.get("type") == "text":
                texts.append(block.get("text", ""))
            elif block.get("type") == "tool_use":
                # Any of these can actually observe the result of the work.
                if block.get("name") in ("Bash", "BashOutput", "Read", "Grep", "Glob"):
                    ran = True
    return texts, ran

# The turn-ending assistant text block is flushed to the transcript AFTER this
# hook fires, so the first read of a text-only turn sees nothing and the hook
# fails open -- blind to exactly the turns it exists to police. Re-read briefly
# until the text lands. Turns with tool calls are already visible on pass one.
# Stop hooks are documented to receive last_assistant_message directly in the
# payload. Prefer it: the transcript file has a known flush race (claude-code
# #74340) and goes stale after compaction (#75435, #76362). Fall back to the
# transcript scan only when the field is absent.
lam = payload.get("last_assistant_message")
if isinstance(lam, dict):
    lam = "\n".join(
        b.get("text", "") for b in (lam.get("content") or [])
        if isinstance(b, dict) and b.get("type") == "text"
    )
if not isinstance(lam, str):
    lam = ""

result = None
for _attempt in range(12):
    result = scan()
    if result is None:
        allow("transcript unreadable")
    # ran_a_command still comes from the transcript; tool_use entries are already
    # flushed by the time Stop fires, so this settles on the first pass.
    if lam.strip() or result[1] or any(t.strip() for t in result[0]):
        break
    time.sleep(0.25)

ran_a_command = result[1]
assistant_text = [lam] if lam.strip() else result[0]

if ran_a_command:
    allow("a command was run this turn")

text = "\n".join(assistant_text).lower()
if not text.strip():
    allow("no assistant text found")

# Narrow on purpose. These assert an OUTCOME, not an intention.
CLAIMS = [
    r"\ball (?:the )?(?:tests?|checks?|of them) pass",
    r"\btests? (?:now )?pass\b",
    r"\btest suite passes\b",
    r"\bit works\b",
    r"\bworks now\b",
    r"\bworking (?:now|correctly)\b",
    r"\bverified\b",
    r"\bconfirmed working\b",
    r"\bis (?:now )?fixed\b",
    r"\bbug is fixed\b",
    r"\bthe fix works\b",
    r"\bimplementation is complete\b",
    r"\bsuccessfully (?:ran|built|installed|deployed|created)\b",
]

if not any(re.search(p, text) for p in CLAIMS):
    allow("no outcome claim matched")

_log("BLOCK: claim with no verification | text_blocks=%d | text_len=%d"
     % (len(assistant_text), len(text)))
sys.stderr.write(
    "RULE 0 (verification) — this response asserts an outcome but no command was "
    "run this turn that could observe it. No Bash/Read/Grep/Glob call was made.\n\n"
    "Do ONE of the following before finishing:\n"
    "  1. Actually run the verification and report the real output, or\n"
    "  2. State plainly that the check was NOT run, and say what would be needed.\n\n"
    "Never report success from inference. Reporting a check as not-run is a "
    "perfectly acceptable outcome; claiming it passed without running it is not.\n"
)
sys.exit(2)
' "$PAYLOAD"
