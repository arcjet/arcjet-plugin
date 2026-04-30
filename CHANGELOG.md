# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/), and
this project adheres to [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Added

- Arcjet CLI integration. The plugin now invokes the CLI for capabilities
  the MCP server does not expose: `arcjet watch` for live request streaming
  during incident response, plus authentication, site/key setup, and remote
  rule management. Commands run via `npx -y @arcjet/cli@latest` so no
  install is required. Read-side analysis and rule inspection remain
  available on the MCP server.
- New `rules/arcjet-cli.mdc` rule explaining when to reach for the CLI vs
  MCP, the npx invocation pattern, and agent-friendly flags
  (`--output json`, `--fields`).
- New `skills/add-request-protection/` skill — the canonical name for HTTP
  route protection, replacing `skills/protect-route` and the HTTP slice of
  `skills/add-ai-protection`. Sourced from
  [arcjet/skills](https://github.com/arcjet/skills) and includes integrated
  CLI workflows for authentication, site setup, decision verification
  (`arcjet watch`), and remote rule management.

### Changed

- `agents/security-analyst.md` now uses `arcjet watch` for continuous
  monitoring during active incidents, instead of polling `list-requests`
  over MCP.
- `skills/add-guard-protection/` synced with the canonical version from
  [arcjet/skills](https://github.com/arcjet/skills), including refreshed
  `references/javascript.md` and `references/python.md`.
- `skills/protect-route/` and `skills/add-ai-protection/` are now
  deprecation aliases. Invoking them instructs the agent to tell the user
  the canonical replacement (`/arcjet:add-request-protection` or
  `/arcjet:add-guard-protection`) and then proceed with that skill. The
  alias directories are preserved so saved transcripts and existing
  workflows continue to resolve.
- README updated to reflect the canonical skill names, link
  [arcjet/skills](https://github.com/arcjet/skills) as the source of truth,
  and document the CLI install methods (npx, Homebrew, install script,
  GitHub Releases archive).

## [1.0.0] - 2026-04-08

### Added

- First version of the ArcjetPlugin following Open Plugins Specification
  v1.0.0
