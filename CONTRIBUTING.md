# Contributing to Arcjet Plugin

Thanks for your interest in contributing to the Arcjet plugin for AI coding agents.

## Plugin Specification

This plugin follows the [Open Plugins Specification v1.0.0](https://open-plugins.com/plugin-builders/specification) and is also compatible with [Claude Code](https://docs.claude.com/en/docs/claude-code/plugins), [Cursor](https://cursor.com/docs/reference/plugins), and [ChatGPT / Codex](https://developers.openai.com/plugins/build/plugins). To support each host, the manifest and MCP config are duplicated into each tool's expected location. Key structural requirements:

- **Manifest** at `.plugin/plugin.json` (Open Plugins), `.claude-plugin/plugin.json` (Claude Code), and `.cursor-plugin/plugin.json` (Cursor) — these root copies must stay in sync and include `name`, `version`, `description`, `author`, `license`, and `logo`
- **Cursor logo path** — in `.cursor-plugin/plugin.json` only, `logo` must be `assets/logo.svg` (no `./` prefix). Other hosts may keep `./assets/logo.svg`
- **Rules** in `rules/` as `.mdc` files with YAML frontmatter (`description`, `globs`, `alwaysApply`)
- **Skills** in `skills/<name>/SKILL.md` with YAML frontmatter (`name`, `description`)
- **Agents** in `agents/` as `.md` files with YAML frontmatter (`name`, `description`)
- **MCP servers** in `.mcp.json` (Open Plugins / Claude Code / Codex) and `mcp.json` (Cursor) at the repo root — both must stay in sync and reuse `https://api.arcjet.com/mcp`
- **Assets** in `assets/` (logo, etc.)
- **Cursor marketplace catalog** at `.cursor-plugin/marketplace.json`
- **ChatGPT / Codex marketplace catalog** at `.agents/plugins/marketplace.json`

Canonical skills live in [arcjet/skills](https://github.com/arcjet/skills) and are vendored under `skills/arcjet/`. Do not move or rewrite that tree. Deprecated alias skill directories stay as-is.

## Marketplace layout

Cursor and ChatGPT/Codex add **marketplaces** (a git repo that catalogs plugins), not a lone plugin URL. Those hosts clone this repo and read a catalog:

| Host            | Catalog                            | Plugin directory the catalog points at                                       |
| --------------- | ---------------------------------- | ---------------------------------------------------------------------------- |
| Cursor          | `.cursor-plugin/marketplace.json`  | `plugins/arcjet/` (`metadata.pluginRoot` is `plugins`, `source` is `arcjet`) |
| ChatGPT / Codex | `.agents/plugins/marketplace.json` | `./plugins/arcjet` (`source.path`, `./`-prefixed)                            |

The plugin payload that `npx plugins add arcjet/arcjet-plugin` and Claude Code install still lives at the **repo root** (`skills/`, `rules/`, `agents/`, `.plugin/`, `.claude-plugin/`, `.cursor-plugin/plugin.json`, `.mcp.json`, `mcp.json`). Do not move those root paths.

Cursor 2.6 rejects marketplace `source: "."` and `./`-prefixed sources. It wants a catalog plus a nested plugin directory with a bare `source` name, and it discovers components inside that directory. ChatGPT/Codex similarly resolve `source.path` to a plugin folder that contains `.codex-plugin/plugin.json`.

`plugins/arcjet/` is that nested plugin directory. It has its own host manifests and **symlinks** back to the root trees so we do not duplicate skills, rules, agents, assets, or MCP config:

```
plugins/arcjet/
  .cursor-plugin/plugin.json   # Cursor identity (logo: assets/logo.svg)
  .codex-plugin/plugin.json    # Codex identity + skills: ./skills, mcpServers: ./.mcp.json
  skills -> ../../skills
  rules -> ../../rules
  agents -> ../../agents
  assets -> ../../assets
  mcp.json -> ../../mcp.json
  .mcp.json -> ../../.mcp.json
```

Keep those as symlinks. Do not copy `skills/` into `plugins/arcjet/`.

This is marketplace registration for agent apps only. Do not publish to cursor.com/marketplace or add a ChatGPT App (`.app.json` / Apps Directory).

## Directory Structure

```
.plugin/plugin.json                 # Plugin manifest (Open Plugins)
.claude-plugin/plugin.json          # Plugin manifest (Claude Code)
.cursor-plugin/plugin.json          # Plugin manifest (Cursor, local / npx)
.cursor-plugin/marketplace.json     # Cursor marketplace catalog
.agents/plugins/marketplace.json    # ChatGPT / Codex marketplace catalog
plugins/arcjet/                     # Nested plugin for marketplace importers
rules/*.mdc                         # Auto-activated coding guidance
skills/*/SKILL.md                   # Task-oriented workflows
agents/*.md                         # Agent definitions
.mcp.json                           # MCP server configuration (Open Plugins / Claude Code / Codex)
mcp.json                            # MCP server configuration (Cursor)
scripts/                            # Tooling (validation, etc.)
assets/                             # Static assets
```

When updating any manifest or MCP config, update all copies so the tools stay in sync — including `plugins/arcjet/.cursor-plugin/plugin.json` and `plugins/arcjet/.codex-plugin/plugin.json`.

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
- Nested `plugins/arcjet/` content is symlinked (not a second skill tree)

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
