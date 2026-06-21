#!/usr/bin/env bash
#
# agent-clock — inject the real current date/time into the agent's context.
#
# Fires on UserPromptSubmit (every turn) and SessionStart (startup/resume), so
# the agent always reasons from the real wall-clock time instead of a timestamp
# frozen when the session began. This is the single, shared script used by both
# the Claude Code and the Codex plugin manifests.
#
# Contract:
#   - Reads the hook event JSON on stdin (may be empty on some events).
#   - Emits the current time as context on stdout and exits 0.
#   - Output form depends on the event, because the two harnesses differ:
#       * UserPromptSubmit -> PLAIN TEXT on stdout. Claude Code does NOT honor
#         hookSpecificOutput.additionalContext for this event (it only injects
#         plain stdout); Codex also accepts plain stdout here. Using JSON would
#         silently drop the per-turn timestamp on Claude Code.
#       * SessionStart (and other context events) -> hookSpecificOutput JSON,
#         which both Claude Code and Codex honor.
#
# Optional config:
#   AGENT_CLOCK_TZ   Override the timezone (e.g. "Europe/Belgrade", "UTC").
#                    Defaults to the machine's local timezone.

set -euo pipefail

# Read the hook payload from stdin (tolerate an empty / missing payload).
input="$(cat 2>/dev/null || true)"

# Recover the event name so we echo it back in the matching hookSpecificOutput.
# Pure-bash parse (no jq dependency); falls back to UserPromptSubmit if absent.
event="$(printf '%s' "$input" \
  | grep -o '"hook_event_name"[[:space:]]*:[[:space:]]*"[^"]*"' \
  | head -n1 \
  | sed 's/.*"\([^"]*\)"$/\1/' || true)"
[ -n "${event:-}" ] || event="UserPromptSubmit"

# Honor an explicit timezone override, otherwise use the machine's local zone.
if [ -n "${AGENT_CLOCK_TZ:-}" ]; then
  export TZ="$AGENT_CLOCK_TZ"
fi

now_local="$(date '+%A, %B %d, %Y at %H:%M:%S %Z')"
now_utc="$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
epoch="$(date '+%s')"

context="Current real-world date and time, refreshed this turn: ${now_local} (UTC ${now_utc}, Unix ${epoch}). Treat this as the authoritative present moment; do not infer the current date or time of day from earlier messages or from model training data."

# Emit the context using the form the firing event honors on BOTH harnesses.
# The date fields contain no JSON-special characters, so a direct printf is safe.
if [ "$event" = "UserPromptSubmit" ]; then
  # Plain stdout: Claude Code injects it as context (it ignores additionalContext
  # for UserPromptSubmit), and Codex adds plain stdout as developer context too.
  printf '%s\n' "$context"
else
  # SessionStart and other context events: additionalContext JSON works on both.
  printf '{"hookSpecificOutput":{"hookEventName":"%s","additionalContext":"%s"}}\n' \
    "$event" "$context"
fi
