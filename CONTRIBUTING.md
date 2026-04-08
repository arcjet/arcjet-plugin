# Contributing to Arcjet Plugin

Thanks for your interest in contributing to the Arcjet plugin for AI coding agents.

## Plugin Specification

This plugin follows the [Open Plugins Specification v1.0.0](https://open-plugins.com/plugin-builders/specification). Key structural requirements:

- **Manifest** at `.plugin/plugin.json` — must include `name`, `version`, `description`, `author`, `license`, and `logo`
- **Rules** in `rules/` as `.mdc` files with YAML frontmatter (`description`, `globs`, `alwaysApply`)
- **Skills** in `skills/<name>/SKILL.md` with YAML frontmatter (`name`, `description`)
- **Agents** in `agents/` as `.md` files with YAML frontmatter (`name`, `description`)
- **MCP servers** in `.mcp.json` at the repo root
- **Assets** in `assets/` (logo, etc.)

## Directory Structure

```
.plugin/plugin.json        # Plugin manifest
rules/*.mdc                # Auto-activated coding guidance
skills/*/SKILL.md          # Task-oriented workflows
agents/*.md                # Agent definitions
.mcp.json                  # MCP server configuration
scripts/                   # Tooling (validation, etc.)
assets/                    # Static assets
```

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

## License

By contributing, you agree that your contributions will be licensed under the [Apache License 2.0](LICENSE).
