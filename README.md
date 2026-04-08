# Arcjet Plugin for AI Coding Agents

[Arcjet](https://arcjet.com) is the runtime policy engine for AI features. Authorize tools, control budgets, and protect against spam and bots. A developer-first approach to securing AI applications.

This plugin makes your AI coding agent an Arcjet security expert. It provides:

- **MCP integration** — connects to the Arcjet API for traffic analysis, request inspection, IP investigation, and remote rule management
- **Security-aware coding rules** — framework-specific guidance activates automatically when you work in route handlers, API endpoints, and AI/LLM code
- **Skills** — task-oriented workflows for adding protection to routes and securing AI endpoints
- **Security analyst agent** — investigates threats, analyzes traffic, and manages rules via MCP

## Installation

```bash
npx plugins add arcjet/arcjet-plugin
```

That's it. The plugin activates automatically — security guidance appears when you're working in route handlers, API endpoints, and AI/LLM code.

You can also point your agent at the [agent get started documentation](https://docs.arcjet.com/agent-get-started).

## How It Works

After installing, guidance activates automatically. The plugin detects what you're working on and injects Arcjet expertise. Just use your AI agent as you normally would.

### Skills

| Skill                       | Purpose                                                                                       |
| --------------------------- | --------------------------------------------------------------------------------------------- |
| `/arcjet:protect-route`     | Add Arcjet protection to any route handler — detects framework, sets up client, applies rules |
| `/arcjet:add-ai-protection` | Add prompt injection detection, PII blocking, and token budget rate limiting to AI endpoints  |

### Rules (auto-activated)

Rules provide passive guidance that activates when you work in matching files:

| Rule         | Activates on                                         | Guidance                                                                     |
| ------------ | ---------------------------------------------------- | ---------------------------------------------------------------------------- |
| SDK patterns | `**/lib/arcjet*`, `**/arcjet*`                       | Single instance, `protect()` in handlers, `withRule()`, decision handling    |
| Next.js      | `app/**/route.ts`, `app/**/page.tsx`, `pages/api/**` | Correct imports, route handlers vs pages vs server components, no middleware |
| Express/Node | `**/server.ts`, `**/routes/**`                       | Correct adapter packages, no `app.use()` middleware, proxy config            |
| Python       | `**/*.py`, `pyproject.toml`                          | Snake_case API, enum values, async vs sync clients                           |
| AI apps      | `**/chat/**`, `**/api/chat*`, `**/api/completion*`   | Layered protection, token budgets, PII blocking, prompt injection            |

### MCP Tools

When connected, your agent can use the [Arcjet MCP server](https://docs.arcjet.com/mcp-server) to:

- Inspect requests and explain allow/deny decisions
- Analyze traffic patterns and detect anomalies
- Investigate suspicious IPs (geolocation, threat intelligence)
- Create, test, and promote remote rules without code changes
- Generate security briefings

The MCP server connects automatically via OAuth when the plugin is installed. You can also connect it manually from `https://api.arcjet.com/mcp`

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
