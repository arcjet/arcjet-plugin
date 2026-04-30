---
name: add-ai-protection
license: Apache-2.0
description: "Deprecated alias. Use /arcjet:add-request-protection for HTTP AI/LLM endpoints (chat, completion routes) or /arcjet:add-guard-protection for non-HTTP code (agent tool calls, MCP handlers, background workers). Covers prompt injection detection, PII blocking, and token budget rate limiting."
metadata:
  author: arcjet
  internal: true
---

# Deprecated — Use `/arcjet:add-request-protection` or `/arcjet:add-guard-protection`

`/arcjet:add-ai-protection` has been split into two canonical skills:

- **`/arcjet:add-request-protection`** — for HTTP routes serving AI/LLM endpoints (chat, completion, generation). Covers prompt injection detection, PII blocking, token budget rate limiting, and bot/shield protection at the HTTP layer.
- **`/arcjet:add-guard-protection`** — for non-HTTP code (AI agent tool calls, MCP tool handlers, background jobs, queue workers). Same protections via `@arcjet/guard` / `arcjet.guard`.

## Instructions for the agent

1. **Tell the user:** "`/arcjet:add-ai-protection` is deprecated. Use `/arcjet:add-request-protection` for HTTP AI endpoints, or `/arcjet:add-guard-protection` for non-HTTP code (agent tool calls, MCP handlers, background workers)."
2. **Pick the right replacement based on context:**
   - If the file under consideration is an HTTP route handler (e.g. `app/api/chat/route.ts`, `pages/api/completion.ts`, FastAPI/Flask endpoint) → follow `/arcjet:add-request-protection` (`skills/add-request-protection/SKILL.md`) and use its "AI / LLM Endpoints" section.
   - If the file is a tool handler, MCP server handler, agent loop, queue worker, or other non-HTTP code path → follow `/arcjet:add-guard-protection` (`skills/add-guard-protection/SKILL.md`).
   - If unclear, ask the user which context applies before proceeding.
3. Do not duplicate the canonical skill content here — read and follow the chosen skill directly.
