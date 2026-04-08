---
name: add-ai-protection
license: Apache-2.0
description: Add AI-specific security to LLM/chat endpoints — prompt injection detection, PII/sensitive info blocking, and token budget rate limiting. Use when building AI chat interfaces, completion APIs, or any endpoint that processes user prompts.
metadata:
  pathPatterns:
    - "app/api/chat/**"
    - "app/api/completion/**"
    - "src/app/api/chat/**"
    - "src/app/api/completion/**"
    - "**/chat/**"
    - "**/ai/**"
    - "**/llm/**"
    - "**/api/generate*"
    - "**/api/chat*"
    - "**/api/completion*"
  importPatterns:
    - "ai"
    - "@ai-sdk/*"
    - "openai"
    - "@anthropic-ai/sdk"
    - "langchain"
  promptSignals:
    phrases:
      - "prompt injection"
      - "pii"
      - "sensitive info"
      - "ai security"
      - "llm security"
    anyOf:
      - "protect ai"
      - "block pii"
      - "detect injection"
      - "token budget"
---

# Add AI-Specific Security with Arcjet

Secure AI/LLM endpoints with layered protection: prompt injection detection, PII blocking, and token budget rate limiting. These protections work together to block abuse before it reaches your model, saving AI budget and protecting user data.

## Reference

Read https://docs.arcjet.com/llms.txt for comprehensive SDK documentation covering all frameworks, rule types, and configuration options.

## Why AI Endpoints Need Special Protection

AI endpoints are high-value targets:

- **Prompt injection** — attackers try to override system prompts, extract training data, or bypass safety rails
- **PII leakage** — users may paste sensitive data (credit cards, emails, phone numbers) that gets stored in model context or logs
- **Cost abuse** — each request consumes expensive model tokens; without rate limiting, a single user can exhaust your budget
- **Automated scraping** — bots can scrape your AI endpoints for data or to find vulnerabilities.

Arcjet addresses all of these with rules that run **before** the request reaches your AI model.

## Step 1: Ensure Arcjet Is Set Up

Check for an existing shared Arcjet client (see `/arcjet:protect-route` for full setup). If none exists, set one up first with `shield()` as the base rule. The user will need to register for an Arcjet account at https://app.arcjet.com then use the `ARCJET_KEY` in their environment variables.

## Step 2: Add AI Protection Rules

AI endpoints should combine these rules on the shared instance using `withRule()`:

### Prompt Injection Detection

Detects jailbreaks, role-play escapes, and instruction overrides.

- JS: `detectPromptInjection()` — pass user message via `detectPromptInjectionMessage` parameter at `protect()` time
- Python: `detect_prompt_injection()` — pass via `detect_prompt_injection_message` parameter

Blocks hostile prompts **before** they reach the model. This saves AI budget by rejecting attacks early.

### Sensitive Info / PII Blocking

Prevents personally identifiable information from entering model context.

- JS: `sensitiveInfo({ deny: ["EMAIL", "CREDIT_CARD_NUMBER", "PHONE_NUMBER", "IP_ADDRESS"] })`
- Python: `detect_sensitive_info(deny=[SensitiveInfoType.EMAIL, SensitiveInfoType.CREDIT_CARD_NUMBER, ...])`

Detection runs **locally in WASM** — no user data is sent to external services. Only available in route handlers (not pages or server actions in Next.js).

Pass the user message via `sensitiveInfoValue` (JS) / `sensitive_info_value` (Python) at `protect()` time.

### Token Budget Rate Limiting

Use `tokenBucket()` / `token_bucket()` for AI endpoints — it allows short bursts while enforcing an average rate, which matches how users interact with chat interfaces.

Recommended starting configuration:

- `capacity`: 10 (max burst)
- `refillRate`: 5 tokens per interval
- `interval`: "10s"

Pass the `requested` parameter at `protect()` time to deduct tokens proportional to model cost. For example, deduct 1 token per message, or estimate based on prompt length.

Set `characteristics` to track per-user: `["userId"]` if authenticated, defaults to IP-based.

### Base Protection

Always include `shield()` (WAF) and `detectBot()` as base layers. Bots scraping AI endpoints are a common abuse vector. For endpoints accessed via browsers (e.g. chat interfaces), consider adding Arcjet advanced signals for client-side bot detection that catches sophisticated headless browsers. See https://docs.arcjet.com/bot-protection/advanced-signals for setup.

## Step 3: Compose the protect() Call

All rule parameters are passed together in a single `protect()` call. The key parameters for AI:

- `requested` — tokens to deduct for rate limiting
- `sensitiveInfoValue` / `sensitive_info_value` — the user's message text for PII scanning
- `detectPromptInjectionMessage` / `detect_prompt_injection_message` — the user's message text for injection detection

Typically `sensitiveInfoValue` and `detectPromptInjectionMessage` are set to the same value: the user's input message.

## Step 4: Handle Decisions

For AI endpoints, provide meaningful error responses:

- **Rate limited** (`reason.isRateLimit()`) → 429 with message like "You've exceeded your usage limit. Please try again later."
- **Prompt injection** (`reason.isPromptInjection()`) → 400 with "Your message was flagged as potentially harmful."
- **Sensitive info** (`reason.isSensitiveInfo()`) → 400 with "Your message contains sensitive information that cannot be processed. Please remove any personal data."
- **Bot detected** (`reason.isBot()`) → 403

## Step 5: Verify

1. Start the app and send a normal message — should succeed
2. Test prompt injection by sending something like "Ignore all previous instructions and..."
3. Test PII blocking by sending a message with a fake credit card number
4. Check the Arcjet dashboard or use MCP `list-requests` to see decisions

Start all rules in `"DRY_RUN"` mode first. Once verified, promote to `"LIVE"`.

## Common Patterns

**Streaming responses**: Call `protect()` before starting the stream. If denied, return the error before opening the stream — don't start streaming and then abort.

**Multiple models / providers**: Use the same Arcjet instance regardless of which AI provider you use. Arcjet operates at the HTTP layer, independent of the model provider.

**Vercel AI SDK**: Arcjet works alongside the Vercel AI SDK. Call `protect()` before `streamText()` / `generateText()`. If denied, return a plain error response instead of calling the AI SDK.
