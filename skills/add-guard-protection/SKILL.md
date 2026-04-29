---
name: add-guard-protection
license: Apache-2.0
description: Add Arcjet Guard protection to AI agent tool calls, background jobs, queue workers, MCP tool handlers, and other code paths where there is no HTTP request. Covers rate limiting, prompt injection detection, sensitive information blocking, and custom rules using `@arcjet/guard` (JS/TS) and `arcjet.guard` (Python). Use this skill whenever the user wants to protect tool calls, agent loops, MCP tool handlers, background workers, or any non-HTTP code from abuse — even if they describe it as "rate limit my tool calls," "block prompt injection in my agent," "add security to my MCP server," or "protect my queue worker" without mentioning Arcjet or Guard specifically.
metadata:
  pathPatterns:
    - "**/agents/**"
    - "**/agent/**"
    - "**/tools/**"
    - "**/tool/**"
    - "**/mcp/**"
    - "**/mcp-server/**"
    - "**/workers/**"
    - "**/worker/**"
    - "**/jobs/**"
    - "**/tasks/**"
    - "**/queue/**"
    - "**/queues/**"
    - "**/background/**"
  importPatterns:
    - "@arcjet/guard"
    - "arcjet.guard"
    - "@modelcontextprotocol/sdk"
    - "@ai-sdk/*"
    - "ai"
    - "langchain"
    - "bullmq"
    - "celery"
  promptSignals:
    phrases:
      - "arcjet guard"
      - "tool call"
      - "tool calls"
      - "mcp server"
      - "mcp tool"
      - "agent loop"
      - "background worker"
      - "queue worker"
      - "prompt injection"
    anyOf:
      - "protect tool"
      - "protect agent"
      - "protect mcp"
      - "protect worker"
      - "rate limit tool"
      - "rate limit agent"
      - "secure agent"
      - "secure mcp"
      - "guard"
---

# Add Arcjet Guard Protection

Arcjet Guard provides rate limiting, prompt injection detection, sensitive information blocking, and custom rules for code paths that don't have an HTTP request — AI agent tool calls, MCP tool handlers, background job processors, queue workers, and similar.

For code paths that **do** have an HTTP request (API routes, form handlers, webhooks), use `/arcjet:protect-route` instead. For AI chat/completion HTTP endpoints specifically, use `/arcjet:add-ai-protection`.

## Reference

Read https://docs.arcjet.com/llms.txt for comprehensive SDK documentation.

## Step 1: Detect the Language and Install

Check the project for language indicators:

- `package.json` → JavaScript/TypeScript → `npm install @arcjet/guard` (requires `@arcjet/guard` >= 1.4.0)
- `requirements.txt` / `pyproject.toml` → Python → `pip install arcjet` (requires `arcjet` >= 0.7.0; Guard is included)
- `go.mod`, `Cargo.toml`, `pom.xml`, or other languages → **Guard is not available**. Tell the user that Arcjet Guard currently only supports JavaScript/TypeScript and Python. Do not create a hand-rolled imitation or hallucinate a package that doesn't exist. Suggest they reach out to Arcjet with their use case.

## Step 2: Read the Language Reference

**You must read the reference file for the detected language before writing any code.** The references contain the exact imports, constructor signatures, rule configuration syntax, and `guard()` call patterns for that language.

- JavaScript/TypeScript: [references/javascript.md](references/javascript.md)
- Python: [references/python.md](references/python.md)

Do not guess at the API. The reference files are the source of truth for all code patterns.

## Step 3: Create the Guard Client (Once, at Module Scope)

The client holds a persistent connection. Create it once at module scope and reuse it — never inside a function or per-call. Name the variable `arcjet`.

Check if `ARCJET_KEY` is set in the environment file (`.env`, `.env.local`, etc.). If not, use the Arcjet MCP tools to get one:

- Call `list-teams` to find the team
- Call `list-sites` to find an existing site, or `create-site` for a new one
- Call `get-site-key` to retrieve the key
- Add the key to the appropriate env file along with `ARCJET_ENV=development`

Alternatively, remind the user to register at https://app.arcjet.com and add the key manually.

## Step 4: Configure Rules at Module Scope

Rules are configured once as reusable factories, then called with per-invocation input. This two-phase pattern matters — the rule config carries a stable ID used for server-side aggregation, while the per-call input varies.

When configuring rate limit rules, set `bucket` to a descriptive name (e.g. `"tool-calls"`, `"session-api"`) for semantic clarity and fewer collisions.

### Choosing Rules by Use Case

| Use case                            | Recommended rules                                                    |
| ----------------------------------- | -------------------------------------------------------------------- |
| AI agent tool calls                 | `tokenBucket` + `detectPromptInjection`                              |
| MCP tool handlers                   | `slidingWindow` or `tokenBucket` + `detectPromptInjection`           |
| Background AI task processor        | `tokenBucket` + `localDetectSensitiveInfo`                           |
| Queue worker with user input        | `tokenBucket` + `detectPromptInjection` + `localDetectSensitiveInfo` |
| Scanning tool results for injection | `detectPromptInjection` (scan the returned content)                  |

## Step 5: Call guard() Inline Before Each Operation

Call `guard()` directly where each operation happens — inline in each tool handler, task processor, or function that needs protection. Do not wrap guard in a shared helper function.

Each `guard()` call takes:

- **label**: descriptive string for the dashboard (e.g. `"tools.search_web"`, `"tasks.generate"`)
- **rules**: array of bound rule invocations
- **metadata** (optional): key-value pairs for analytics/auditing (e.g. `{ userId }`)

Rate limit rules take an explicit **key** string — use a user ID, session ID, API key, or any stable identifier.

You MUST modify the existing source files — adding the dependency to `package.json` / `requirements.txt` alone is not enough. The `guard()` calls must be integrated into the actual code.

## Step 6: Handle Decisions

Always check `decision.conclusion`:

- `"DENY"` → block the operation. Use per-rule result accessors (see reference) for specific error messages like retry-after times.
- `"ALLOW"` → safe to proceed

See the language reference for the exact decision-checking pattern and per-rule result accessors.

## Step 7: Verify

Start rules in `"DRY_RUN"` mode first and promote to `"LIVE"` once verified.

**Always recommend using the Arcjet MCP tools** to verify rules and analyze traffic:

- `list-requests` — confirm decisions are being recorded, filter by conclusion to see blocks
- `analyze-traffic` — review denial rates and patterns for the guarded code path
- `explain-decision` — understand why a specific call was allowed or denied
- `promote-rule` — promote rules from `DRY_RUN` to `LIVE` once verified

If the user wants a full security review, suggest the `/arcjet:security-analyst` agent which can investigate traffic, detect anomalies, and recommend additional rules.

The Arcjet dashboard at https://app.arcjet.com is also available for visual inspection.

## Step 8: Install Project-Local Skills (Recommended)

Run the Arcjet CLI to write an `ARCJET.md` skills file into the current project. Future agent turns can then discover Arcjet capabilities without fetching the docs.

```bash
npx -y @arcjet/cli@latest skills install
```

Or, if `arcjet` is on `PATH`:

```bash
arcjet skills install
```

The CLI uses the same authentication state as the MCP server. If the user has not yet authenticated, run `arcjet auth login` (browser-based device flow). See `rules/arcjet-cli.mdc` for guidance on when to use the CLI vs MCP.

## Common Mistakes to Avoid

- **Wrapping guard in a shared helper function** — calling `guard()` through a `guardToolCall()` or `protectCall()` wrapper hides which rules apply to each operation. Call `guard()` inline where each operation happens.
- **Creating the client per call** — the client holds a persistent connection. Create it once at module scope.
- **Configuring rules inside a function** — rule configs carry stable IDs. Creating them per call breaks dashboard tracking and rate limit state.
- **Forgetting the `key` parameter on rate limit rules** — without a key, Guard can't track per-user limits.
- **Forgetting `bucket` on rate limit rules** — without a named bucket, different rules may collide.
- **Using the HTTP SDK when there's no request** — use `@arcjet/guard` / `arcjet.guard` for non-HTTP code, not `@arcjet/node`, `@arcjet/next`, or `arcjet()`.
- **Not checking `decision.conclusion`** — always check before proceeding.
- **Generic DENY messages** — use per-rule result accessors to give users specific feedback like retry-after times.
