# Contributing to Arcjet Plugin

Thanks for your interest in contributing to the Arcjet plugin for AI coding agents.

## Plugin Specification

This repo ships one plugin for several hosts. Each host has its own manifest location and catalog rules. Keep those contracts separate — do not assume one host's file layout works for another.

| Host                                | Manifest                     | Catalog                                              | Docs                                                                       |
| ----------------------------------- | ---------------------------- | ---------------------------------------------------- | -------------------------------------------------------------------------- |
| `npx plugins add` / Open Plugin CLI | `.plugin/plugin.json`        | none required (CLI also accepts a marketplace index) | [plugins npm](https://www.npmjs.com/package/plugins)                       |
| Claude Code                         | `.claude-plugin/plugin.json` | not shipped here                                     | [Claude Code plugins](https://docs.claude.com/en/docs/claude-code/plugins) |
| Cursor                              | `.cursor-plugin/plugin.json` | `.cursor-plugin/marketplace.json`                    | [Cursor plugins](https://cursor.com/docs/reference/plugins)                |
| ChatGPT / Codex                     | `.codex-plugin/plugin.json`  | `.agents/plugins/marketplace.json`                   | [Package your plugin](https://developers.openai.com/plugins/build/plugins) |

[Agent Plugins 1.0.0](https://open-plugins.com/plugin-builders/specification) (the current document at the old Open Plugins URL) is a different contract: a root `plugin.json` with required `$schema`, no `logo`, and `mcp.json` with `$schema` plus `type: "streamable-http"` for remote MCP. This repo does **not** add a root `plugin.json`, because Cursor treats that file as the Agent Plugin format (skills + MCP only) and would compete with the richer `.cursor-plugin/plugin.json` (rules, agents, skills, MCP). `npx plugins add` still installs from `.plugin/plugin.json`.

Key structural requirements:

- **Manifests** at `.plugin/plugin.json`, `.claude-plugin/plugin.json`, and `.cursor-plugin/plugin.json` — identity fields (`name`, `version`, `description`, `author`, `license`, `logo`) stay in sync except where a host schema forbids a field
- **Cursor `plugin.json`** — `logo` is `assets/logo.svg` (no `./`). `author` is only `name` and `email` (Cursor's schema rejects `author.url`)
- **Codex `plugin.json`** — `skills` and `mcpServers` are `./`-prefixed paths; install-surface copy lives under `interface`
- **Rules** in `rules/` as `.mdc` files with YAML frontmatter (`description`, `globs`, `alwaysApply`)
- **Skills** in `skills/<name>/SKILL.md` with YAML frontmatter (`name`, `description`)
- **Agents** in `agents/` as `.md` files with YAML frontmatter (`name`, `description`)
- **MCP** — one server at `https://api.arcjet.com/mcp`. Cursor reads `mcp.json`; Claude / Codex / Open Plugin CLI read `.mcp.json`. The wrapped key is `mcpServers` (Codex's loader; the published Codex docs example that uses `mcp_servers` is wrong)
- **Assets** in `assets/` (logo, etc.)

Canonical skills live in [arcjet/skills](https://github.com/arcjet/skills) and are vendored under `skills/arcjet/` (via the inbound root symlink). Do not rewrite that tree. Deprecated alias skill directories stay as-is.

## Marketplace layout

Cursor and ChatGPT/Codex add **marketplaces** (a git repo that catalogs plugins), not a lone plugin URL.

| Host            | Catalog                            | Plugin directory                                                                                                                                                                                                           |
| --------------- | ---------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Cursor          | `.cursor-plugin/marketplace.json`  | `plugins/arcjet/` — `metadata.pluginRoot` is `plugins`, `source` is the bare name `arcjet` (documented [pluginRoot](https://cursor.com/docs/reference/plugins) prefix; Cursor 2.6 rejects `source: "."` and `./` prefixes) |
| ChatGPT / Codex | `.agents/plugins/marketplace.json` | `./plugins/arcjet` — `source.path` must start with `./` and stay inside the marketplace root                                                                                                                               |

`plugins/arcjet/` is the **self-contained** plugin those catalogs load. Cursor, Codex, and Agent Plugins all require component paths to resolve inside the plugin root (Cursor: no `..`; Codex: stay inside the plugin root; Agent Plugins §4.1 rejects outbound symlinks). The payload therefore lives in `plugins/arcjet/`. Repo-root `skills/`, `rules/`, `agents/`, `assets/`, `mcp.json`, and `.mcp.json` are **inbound** symlinks so `npx plugins add` and Claude Code still see the original root paths.

```
plugins/arcjet/                 # catalogued plugin (self-contained)
  .plugin/plugin.json
  .claude-plugin/plugin.json
  .cursor-plugin/plugin.json    # logo: assets/logo.svg; no author.url
  .codex-plugin/plugin.json     # skills: ./skills/; mcpServers: ./.mcp.json
  skills/ rules/ agents/ assets/
  mcp.json
  .mcp.json

skills -> plugins/arcjet/skills
rules -> plugins/arcjet/rules
agents -> plugins/arcjet/agents
assets -> plugins/arcjet/assets
mcp.json -> plugins/arcjet/mcp.json
.mcp.json -> plugins/arcjet/.mcp.json
```

Do not point `plugins/arcjet/skills` back at `../../skills`. That escapes the plugin root.

`npx plugins add` discovers a marketplace index before a root plugin. If it picks up `.cursor-plugin/marketplace.json`, it installs `plugins/arcjet/`, which is why that directory also has `.plugin/plugin.json` and `.claude-plugin/plugin.json`.

This is marketplace registration for agent apps only. Do not publish to cursor.com/marketplace or add a ChatGPT App (`.app.json` / Apps Directory).

## Directory Structure

```
.plugin/plugin.json                 # Open Plugin CLI / npx plugins add
.claude-plugin/plugin.json          # Claude Code
.cursor-plugin/plugin.json          # Cursor (local load)
.cursor-plugin/marketplace.json     # Cursor marketplace catalog
.agents/plugins/marketplace.json    # ChatGPT / Codex marketplace catalog
plugins/arcjet/                     # Self-contained plugin the catalogs load
skills -> plugins/arcjet/skills     # inbound symlink for root-path installs
rules -> plugins/arcjet/rules
agents -> plugins/arcjet/agents
assets -> plugins/arcjet/assets
.mcp.json -> plugins/arcjet/.mcp.json
mcp.json -> plugins/arcjet/mcp.json
scripts/                            # Tooling (validation, etc.)
```

When updating any manifest or MCP config, update all copies so the tools stay in sync — including the copies under `plugins/arcjet/`.

## Development Setup

Open this repo in a devcontainer (VS Code or GitHub Codespaces) — it installs all tooling automatically. Alternatively, install [dprint](https://dprint.dev/) manually.

## Formatting

All JSON, Markdown, and `.mdc` files are formatted with [dprint](https://dprint.dev/):

```bash
dprint fmt     # Format all files
dprint check   # Check without modifying (used in CI)
```

Configuration is in `dprint.json`.

## Validation

Run the structural validation script before submitting changes:

```bash
bash scripts/validate.sh
```

This checks:

- JSON files are valid
- `plugin.json` has all required fields and valid semver
- Skills have `SKILL.md` with `name` and `description` frontmatter
- Rules have `.mdc` files with `description` and `globs` frontmatter
- Agents have `.md` files with `name` and `description` frontmatter
- `.mcp.json` defines at least one server with a `url` or `command`
- Marketplace catalogs exist, plugin names match, and `source` / `source.path` resolve
- `plugins/arcjet/` is self-contained; root `skills/` / `rules/` / `agents/` are inbound symlinks

## Adding a Rule

1. Create `rules/<name>.mdc` with frontmatter:

   ```yaml
   ---
   description: What this rule provides
   alwaysApply: false
   globs:
     - "**/<pattern>"
   ---
   ```

2. Write concise, opinionated guidance in the body. Include a `Ref:` link to relevant docs.
3. Run `bash scripts/validate.sh` and `dprint check`.

## Adding a Skill

1. Create `skills/<name>/SKILL.md` with frontmatter:

   ```yaml
   ---
   name: skill-name
   license: Apache-2.0
   description: What this skill does and when to use it
   metadata:
     pathPatterns:
       - "relevant/**/globs"
     importPatterns:
       - "relevant-package"
     promptSignals:
       phrases:
         - "trigger phrase"
   ---
   ```

2. Write step-by-step instructions in the body. Skills should be self-contained — the agent follows them without prior context.
3. Run `bash scripts/validate.sh` and `dprint check`.

## Adding an Agent

1. Create `agents/<name>.md` with frontmatter:

   ```yaml
   ---
   name: agent-name
   description: What this agent does
   ---
   ```

2. Define the agent's role, capabilities, workflow, and output format in the body.
3. Run `bash scripts/validate.sh` and `dprint check`.

## CI

Pull requests run two checks (see `.github/workflows/lint.yml`):

- **dprint format check** — ensures all files are formatted
- **Plugin structure validation** — runs `scripts/validate.sh`

Both must pass before merging.

## Guidelines

- Keep rule and skill content concise and opinionated — agents work better with clear directives than hedged suggestions
- Always include `Ref: https://docs.arcjet.com/llms.txt` in rules so agents can fetch full docs when needed
- Test skills by running them in an AI coding agent against a real project e.g. `claude --plugin-dir ./arcjet-plugin`
- Start new protection rules in `DRY_RUN` mode guidance — never suggest `LIVE` as a default

## Skill Writing References

When creating or improving skills, follow the guidance at [agentskills.io](https://agentskills.io):

- [Best practices](https://agentskills.io/skill-creation/best-practices) — scoping, context efficiency, gotchas sections, code templates, and calibrating control
- [Optimizing descriptions](https://agentskills.io/skill-creation/optimizing-descriptions) — writing descriptions that trigger reliably on relevant prompts
- [Evaluating skills](https://agentskills.io/skill-creation/evaluating-skills) — test cases, grading, and iterating on output quality

## License

By contributing, you agree that your contributions will be licensed under the [Apache License 2.0](LICENSE).
