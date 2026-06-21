# Changelog

All notable changes to Agent Clock are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] — 2026-06-21

### Added
- Initial release.
- Shared `run-hook.sh` script that injects the real current date/time
  (local + UTC + Unix epoch) into the agent's context.
- `UserPromptSubmit` hook — re-stamps the time on every user turn.
- `SessionStart` hook — re-stamps the time on startup, resume, clear, and compact.
- Claude Code plugin manifest + marketplace catalog.
- Codex plugin manifest (with `interface`) + marketplace catalog.
- `AGENT_CLOCK_TZ` environment variable to override the timezone.
