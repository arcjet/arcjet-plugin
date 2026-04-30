# Arcjet Plugin for AI Coding Agents

[Arcjet](https://arcjet.com) is the runtime security platform that ships with your code. Enforce budgets, stop prompt injection, detect bots, and protect personal information with Arcjet's AI security building blocks.

The [Arcjet plugin](https://github.com/arcjet/arcjet-plugin) turns any supported AI coding agent into a security expert. It pre-loads agents with knowledge of the Arcjet security platform and automatically injects the right guidance based on what you're working on — framework-specific SDK patterns, protection rules, and best practices.

- **MCP integration** — connects to the [Arcjet MCP Server](https://docs.arcjet.com/mcp-server) for traffic analysis, request inspection, IP investigation, and remote rule management
- **CLI integration** — invokes the [Arcjet CLI](https://docs.arcjet.com/cli) for authentication, site/key setup, live request streaming, and remote rule management
- **Security-aware coding rules** — framework-specific guidance activates automatically when you work in route handlers, API endpoints, and AI/LLM code
- **Skills** — task-oriented workflows sourced from [arcjet/skills](https://github.com/arcjet/skills) for adding protection to HTTP routes and non-HTTP code paths
- **Security analyst agent** — investigates threats, analyzes traffic, and manages rules via MCP

## Installation

```bash
npx plugins add arcjet/arcjet-plugin
```

That's it. The plugin activates automatically — security guidance appears when you're working in route handlers, API endpoints, and AI/LLM code.

You can also point your agent at the [agent get started documentation](https://docs.arcjet.com/agent-get-started).

### Arcjet CLI

The plugin invokes the Arcjet CLI for authentication, site management, and live request streaming. Install it via any of:

1. `npx -y @arcjet/cli@latest <command>` — no install required, works on macOS, Linux, and Windows
2. `brew install arcjet` — Homebrew tap
3. `curl -sSfL https://arcjet.com/cli/install.sh | bash` — install script
4. [GitHub Releases archive](https://github.com/arcjet/arcjet-cli/releases) — for internal redistribution and air-gapped environments

## How It Works

After installing, guidance activates automatically. The plugin detects what you're working on and injects Arcjet expertise. Just use your AI agent as you normally would.

### Skills

The plugin's skills are sourced from [arcjet/skills](https://github.com/arcjet/skills), the canonical agent skills surface for Arcjet.

| Skill                            | Purpose                                                                                                                                                       |
| -------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `/arcjet:add-request-protection` | Add Arcjet protection to any HTTP route or endpoint — detects framework, sets up client, applies rules. Includes AI/LLM endpoint guidance (chat, completion). |
| `/arcjet:add-guard-protection`   | Add Arcjet Guard to non-HTTP code paths — AI agent tool calls, MCP tool handlers, background jobs/workers                                                     |

#### Deprecated aliases

The previous skill names are kept as deprecation aliases. Invoking them tells the user the new name and then proceeds with the canonical workflow — existing prompts, prompts in saved transcripts, and project-local references continue to work.

| Deprecated alias            | Replacement                                                                                         |
| --------------------------- | --------------------------------------------------------------------------------------------------- |
| `/arcjet:protect-route`     | `/arcjet:add-request-protection`                                                                    |
| `/arcjet:add-ai-protection` | `/arcjet:add-request-protection` (HTTP endpoints) or `/arcjet:add-guard-protection` (non-HTTP code) |

### Rules (auto-activated)

Rules provide passive guidance that activates when you work in matching files:

| Rule         | Activates on                                         | Guidance                                                                        |
| ------------ | ---------------------------------------------------- | ------------------------------------------------------------------------------- |
| SDK patterns | `**/lib/arcjet*`, `**/arcjet*`                       | Single instance, `protect()` in handlers, `withRule()`, decision handling       |
| Next.js      | `app/**/route.ts`, `app/**/page.tsx`, `pages/api/**` | Correct imports, route handlers vs pages vs server components, no middleware    |
| Express/Node | `**/server.ts`, `**/routes/**`                       | Correct adapter packages, no `app.use()` middleware, proxy config               |
| Python       | `**/*.py`, `pyproject.toml`                          | Snake_case API, enum values, async vs sync clients                              |
| AI apps      | `**/chat/**`, `**/api/chat*`, `**/api/completion*`   | Layered protection, token budgets, PII blocking, prompt injection               |
| CLI          | `**/lib/arcjet*`, `**/arcjet*`, `**/.env*`           | When to use the CLI vs MCP, `npx -y @arcjet/cli@latest` invocation, agent flags |

### MCP Tools

When connected, your agent can use the [Arcjet MCP server](https://docs.arcjet.com/mcp-server) to:

- Inspect requests and explain allow/deny decisions
- Analyze traffic patterns and detect anomalies
- Investigate suspicious IPs (geolocation, threat intelligence)
- Create, test, and promote remote rules without code changes
- Generate security briefings

The MCP server connects automatically via OAuth when the plugin is installed. You can also connect it manually from `https://api.arcjet.com/mcp`

### CLI

The plugin uses the [Arcjet CLI](https://docs.arcjet.com/cli) for capabilities that benefit from a real terminal session:

- **Authentication and site/key setup** — `arcjet auth login`, `arcjet teams list`, `arcjet sites list/create/get-key`. The CLI is the primary way to bootstrap a new project's `ARCJET_KEY`.
- **Live request streaming** — `arcjet watch --site-id <id>` is invoked by the security analyst agent during active incident response, when polling `list-requests` over MCP would be too coarse.
- **Remote rule management** — `arcjet rules create/list/promote/update/delete` for managing rules without code changes or redeployment.

No install is required. Commands are invoked as `npx -y @arcjet/cli@latest <command>`, which works on macOS, Linux, and Windows. If a local `arcjet` binary is on `PATH` (Homebrew, install script, GitHub Releases archive), the plugin uses it directly. CLI authentication uses the same browser-based device flow as `gh auth login` or `vercel login`.

Read-side analysis and rule inspection over a structured tool interface remain available on the MCP server.

### Security Analyst Agent

The security analyst agent uses MCP tools for monitoring and incident response:

- Traffic analysis and threat detection
- Remote rule management (DRY_RUN -> verify -> LIVE)
- IP investigation and blocking recommendations
- Structured security reports with prioritized action items

## Frameworks Supported

Arcjet provides SDKs for:

**JavaScript/TypeScript:** Next.js, Express, Node.js, Fastify, NestJS, SvelteKit, Remix, React Router, Astro, Nuxt, Hono, Bun, Deno

**Python:** FastAPI, Flask

## Prerequisites

- [Arcjet account](https://app.arcjet.com)
- An AI coding tool

## Links

- [Documentation](https://docs.arcjet.com)
- [AI agent guide](https://docs.arcjet.com/agent-get-started)
- [Bot list](https://arcjet.com/bot-list)
- [Pricing](https://arcjet.com/pricing)
