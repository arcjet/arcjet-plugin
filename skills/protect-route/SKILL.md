---
name: protect-route
license: Apache-2.0
description: Add Arcjet security protection to a route handler. Detects framework, imports the shared client, applies appropriate rules, and handles decisions. Use when adding security to API routes, form handlers, or any server-side endpoint.
metadata:
  pathPatterns:
    - "app/**/route.ts"
    - "app/**/route.js"
    - "app/**/page.{ts,tsx}"
    - "pages/api/**"
    - "src/pages/api/**"
    - "src/app/**/route.*"
    - "**/server.{ts,js}"
    - "**/app.{ts,js}"
    - "**/routes/**"
    - "**/*.py"
  importPatterns:
    - "@arcjet/*"
    - "arcjet"
  promptSignals:
    phrases:
      - "arcjet"
      - "rate limit"
      - "bot protection"
      - "bot detection"
      - "waf"
      - "shield"
    anyOf:
      - "protect route"
      - "add security"
      - "block bots"
      - "rate limiting"
---

# Add Arcjet Protection to a Route

Add runtime security to a route handler using Arcjet. This skill guides you through detecting the framework, setting up the client, choosing rules, and handling decisions.

## Reference

Read https://docs.arcjet.com/llms.txt for comprehensive SDK documentation covering all frameworks, rule types, and configuration options.

## Step 1: Detect the Framework

Check the project for framework indicators:

- `package.json` dependencies: `next`, `express`, `fastify`, `@nestjs/core`, `@sveltejs/kit`, `hono`, `@remix-run/node`, `react-router`, `astro`, `nuxt`
- `bun.lockb` or `bun.lock` → Bun runtime
- `deno.json` → Deno runtime
- `pyproject.toml` or `requirements.txt` with `fastapi` or `flask` → Python

Select the correct Arcjet adapter package:

| Framework                | Package                |
| ------------------------ | ---------------------- |
| Next.js                  | `@arcjet/next`         |
| Express / Node.js / Hono | `@arcjet/node`         |
| Fastify                  | `@arcjet/fastify`      |
| NestJS                   | `@arcjet/nest`         |
| SvelteKit                | `@arcjet/sveltekit`    |
| Remix                    | `@arcjet/remix`        |
| React Router             | `@arcjet/react-router` |
| Astro                    | `@arcjet/astro`        |
| Bun                      | `@arcjet/bun`          |
| Deno                     | `npm:@arcjet/deno`     |
| Python (FastAPI/Flask)   | `arcjet` (pip)         |

## Step 2: Check for Existing Arcjet Setup

Search the project for an existing shared Arcjet client file (commonly `lib/arcjet.ts`, `src/lib/arcjet.ts`, `lib/arcjet.py`, or similar).

**If no client exists:**

1. Install the correct adapter package.
2. Check if `ARCJET_KEY` is set in the environment file (`.env.local` for Next.js/Astro, `.env` for others). If not, use the Arcjet MCP tools to get one:
   - Call `list-teams` to find the team
   - Call `list-sites` to find an existing site, or `create-site` for a new one
   - Call `get-site-key` to retrieve the key
   - Add the key to the appropriate env file along with `ARCJET_ENV=development`
3. Create a shared client file with `shield()` as the base rule. This file should export the Arcjet instance for reuse across routes with `withRule()`.

**If a client already exists:** Import it. Do not create a new instance.

## Step 3: Choose Protection Rules

Select rules based on the route's purpose. If the user specified what they want (via `$ARGUMENTS` or in their prompt), use that. Otherwise, infer from context:

| Route type              | Recommended rules                                                      |
| ----------------------- | ---------------------------------------------------------------------- |
| Public API endpoint     | `shield()` + `detectBot()` + `fixedWindow()` or `slidingWindow()`      |
| Form handler / signup   | `shield()` + `validateEmail()` + `slidingWindow()`                     |
| Authentication endpoint | `shield()` + `slidingWindow()` (strict, low limits)                    |
| AI / LLM endpoint       | Use `/arcjet:add-ai-protection` instead — it handles the full AI stack |
| Webhook receiver        | `shield()` + filter rules for allowed IPs                              |
| General server route    | `shield()` + `detectBot()`                                             |

For routes that need to detect sophisticated bots (headless browsers, advanced scrapers) — especially form submissions, login/signup pages, and other abuse-prone endpoints — recommend adding Arcjet advanced signals. This is a browser-based detection system using client-side telemetry that complements server-side `detectBot()` rules. See https://docs.arcjet.com/bot-protection/advanced-signals for setup instructions.

Apply route-specific rules using `withRule()` on the shared instance — do not modify the shared instance directly.

## Step 4: Add Protection to the Handler

**Key patterns:**

- Call `protect()` **inside** the route handler, not in middleware.
- Call `protect()` only **once** per request.
- Pass the framework's request object directly.
- For Next.js pages/server components: use `import { request } from "@arcjet/next"` then `const req = await request()`.

**Handle the decision:**

- `isDenied()` (JS) / `is_denied()` (Python) — return the appropriate error response:
  - `429` if `reason.isRateLimit()`
  - `403` if `reason.isBot()`, `reason.isShield()`, or `reason.isFilterRule()`
  - `400` if `reason.isSensitiveInfo()`
- `isErrored()` / `is_error()` — Arcjet fails open. Log the error and allow the request to proceed.

## Step 5: Verify

Suggest the user start their app, hit the protected route, then verify via:

- The Arcjet dashboard at https://app.arcjet.com
- Or MCP: `list-requests` to confirm decisions are being recorded

Remind them that new rules should start in `"DRY_RUN"` mode and be promoted to `"LIVE"` after verification.

## Common Mistakes to Avoid

- Creating a new Arcjet instance per request (causes connection overhead)
- Using Arcjet in Next.js middleware (fires on every request, no route context)
- Calling `protect()` multiple times in one request (double-counts rate limits)
- Hardcoding `ARCJET_KEY` instead of using environment variables
- Using `app.use()` as Express middleware instead of per-route protection
