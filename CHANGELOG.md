# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/), and
this project adheres to [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Added

- Cursor and ChatGPT/Codex marketplace catalogs so this repo can be added as a
  marketplace (`agent plugin marketplace add https://github.com/arcjet/arcjet-plugin`
  and `codex plugin marketplace add arcjet/arcjet-plugin`). Catalogs live at
  `.cursor-plugin/marketplace.json` and `.agents/plugins/marketplace.json`. The
  catalogued plugin is `plugins/arcjet/`, which symlinks `skills/`, `rules/`,
  `agents/`, `assets/`, and MCP config back to the repo root so
  `npx plugins add` and Claude Code install keep using the existing root paths.
  See [#12](https://github.com/arcjet/arcjet-plugin/issues/12).

### Changed

- Plugin description now matches the current Arcjet product copy across host
  manifests, the Cursor marketplace catalog, and the README intro.
- Synced `skills/arcjet/` with
  [arcjet/skills](https://github.com/arcjet/skills) `main` at
  `ff877f0` (2026-08-15,
  [arcjet/skills#26](https://github.com/arcjet/skills/pull/26) and
  [arcjet/skills#27](https://github.com/arcjet/skills/pull/27)). The vendored
  skill now teaches current public SDK APIs: `capture()` / `flush()`,
  `registerArcjet` / `register_arcjet`, framework wrappers (Vercel AI SDK,
  Vercel Eve, Mastra, LangChain), explicit client IP, Rampart NER, nested-JSON
  metadata, threat/billing metadata, and `moderateContent` / `ModerateContent`
  graduation in JS, Go, and Python (`experimental_ModerateContent` is a
  deprecated alias). Python Guard default request timeout is 2000 ms on
  `main`. Remote Guard policies (`actor`, `inputs`, `policyInput`) stay out.
  Deprecated alias skill directories are unchanged.
- Synced `skills/arcjet/` with
  [arcjet/skills](https://github.com/arcjet/skills) `main` at
  `17c7b66` (2026-08-15). The vendored skill now covers JavaScript/TypeScript,
  Python, and Go, including new `references/guards_go.md` and
  `references/requests_go.md`. Python references note the Alpine `libgcc`
  requirement from [arcjet/skills#24](https://github.com/arcjet/skills/pull/24).
  Deprecated alias skill directories are unchanged.
- README frameworks list now includes the Go SDK (`net/http`).
- Replaced separate `add-request-protection` and `add-guard-protection` skills
  with the unified `arcjet` skill from
  [arcjet/skills](https://github.com/arcjet/skills). The unified skill covers
  both HTTP route protection and non-HTTP code paths (Guard) in a single
  workflow with shared references.
- `skills/add-request-protection/`, `skills/add-guard-protection/`,
  `skills/protect-route/`, and `skills/add-ai-protection/` are now
  deprecation stubs pointing to the unified `arcjet` skill. The alias
  directories are preserved so saved transcripts and existing workflows
  continue to resolve.
- README updated to reflect the unified skill structure.

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
