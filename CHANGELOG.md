# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/), and
this project adheres to [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Added

- Arcjet CLI integration. The plugin now invokes the CLI for capabilities
  the MCP server does not expose: `arcjet watch` for live request streaming
  during incident response, and `arcjet skills install` for project-local
  skill installation. Commands run via `npx -y @arcjet/cli@latest` so no
  install is required. Setup, read-side analysis, and rule CRUD continue to
  use the MCP server.
- New `rules/arcjet-cli.mdc` rule explaining when to reach for the CLI vs
  MCP, the npx invocation pattern, and agent-friendly flags
  (`--output json`, `--fields`).

### Changed

- `agents/security-analyst.md` now uses `arcjet watch` for continuous
  monitoring during active incidents, instead of polling `list-requests`
  over MCP.
- `skills/protect-route`, `skills/add-ai-protection`, and
  `skills/add-guard-protection` now end with an optional step that runs
  `arcjet skills install` to write `ARCJET.md` into the project.

## [1.0.0] - 2026-04-08

### Added

- First version of the ArcjetPlugin following Open Plugins Specification
  v1.0.0
