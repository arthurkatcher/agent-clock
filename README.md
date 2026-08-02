# 🕐 Agent Clock

**Give your coding agent an accurate clock.**

Agent Clock injects the real current date and time into your agent's context on
**every prompt** — and again at **session start / resume** — so it never reasons
from a timestamp frozen when the session began.

[![Claude Code](https://img.shields.io/badge/Claude_Code-plugin-D97757)](https://code.claude.com/docs/en/plugins)
[![Codex](https://img.shields.io/badge/Codex-plugin-111111)](https://developers.openai.com/codex)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Hooks](https://img.shields.io/badge/mechanism-UserPromptSubmit_%2B_SessionStart-blue)](#how-it-works)

![agent-clock demo — the hook injecting the real current time](assets/demo.gif)

---

## The problem

AI coding agents have no live clock. They learn the time once — usually at
session start — and then carry that stale value for the rest of the session.

Leave a session open overnight and come back in the morning, and the agent still
thinks it's last night. Ask it to log a timestamp, schedule something, calculate
"how long ago," or reason about a deadline, and it quietly uses the wrong time.

## The fix

Agent Clock is a tiny lifecycle hook that runs `date` on your machine and feeds
the result back into the model's context **right before it reads your message** —
on every single turn. The agent always sees the real wall-clock time.

```
You type a message
   → [UserPromptSubmit fires] → runs `date` on your machine
   → "Current real-world date and time, refreshed this turn: Sunday, June 21, 2026 …"
   → injected into context
   → the agent answers using the correct time, every turn
```

Because it re-fires on every submission (and on session resume), the
overnight-staleness problem is structurally impossible.

---

## Install

### Claude Code

```text
/plugin marketplace add arthurkatcher/agent-clock
/plugin install agent-clock@agent-clock
```

Then `/reload-plugins` (or restart). That's it — no config required.

### Codex

```text
codex plugin marketplace add arthurkatcher/agent-clock
```

Then run `codex`, open `/plugins`, find **agent-clock**, and install it. Codex
will ask you to **trust** the hook on first run (review it via `/hooks`) — approve
it, then start a new thread.

> Codex hooks require `[features] hooks = true` (the default in recent versions).

---

## How it works

Agent Clock registers on the only two lifecycle events that make sense for a
clock — both of which let a hook **inject context the model can read**:

| Event | When it fires | Why it's here |
| :-- | :-- | :-- |
| `UserPromptSubmit` | Every time you send a message | The core fix — re-stamps the time on every turn, so it's never stale |
| `SessionStart` | On `startup`, `resume`, `clear`, `compact` | Re-stamps the time the moment you reopen a session (the overnight case) |

Both Claude Code and Codex inject a hook's stdout into the model's context for
these events. Agent Clock simply prints a one-line, unambiguous timestamp:

```
Current real-world date and time, refreshed this turn:
Sunday, June 21, 2026 at 13:14:07 CEST (UTC 2026-06-21T11:14:07Z, Unix 1781954047).
```

It includes the local time **and** UTC **and** the Unix epoch, so the agent can
reason about timezones and durations without guessing.

### What it does *not* do

Prompt-submission hooks in both Claude Code and Codex are **append-only** — they
add context alongside your message; they cannot rewrite the text you typed. Agent
Clock never touches your prompt. It adds a timestamp line and nothing else.

---

## Configuration

Zero config by default — it uses your machine's local timezone.

To pin a specific timezone regardless of machine settings, set an environment
variable before launching your agent:

```bash
export AGENT_CLOCK_TZ="Europe/Belgrade"   # or "UTC", "America/New_York", …
```

---

## Repository layout

A single shared script drives both harnesses. Everything tool-specific lives in
thin wrapper files — the script itself is never duplicated.

```
agent-clock/
├── .claude-plugin/marketplace.json      # Claude Code marketplace catalog
├── .agents/plugins/marketplace.json     # Codex marketplace catalog
└── plugins/agent-clock/
    ├── .claude-plugin/plugin.json        # Claude Code manifest
    ├── .codex-plugin/plugin.json         # Codex manifest (+ interface)
    ├── hooks/
    │   ├── hooks.json                    # Claude Code hook config
    │   └── hooks-codex.json              # Codex hook config
    └── scripts/
        └── run-hook.sh                   # The shared hook script (date → context)
```

---

## Requirements

- A POSIX shell with `date` (every Linux/macOS install has this).
- Claude Code, or Codex with hooks enabled.

## License

[MIT](LICENSE) © Arthur Katcher
