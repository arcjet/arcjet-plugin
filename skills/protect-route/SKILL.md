---
name: protect-route
license: Apache-2.0
description: "Deprecated alias for add-request-protection. Add security protection to a server-side route or endpoint — rate limiting, bot detection, email validation, and abuse prevention. Prefer /arcjet:add-request-protection."
metadata:
  author: arcjet
  internal: true
---

# Deprecated — Use `/arcjet:add-request-protection`

`/arcjet:protect-route` has been renamed to `/arcjet:add-request-protection`. The new skill includes the same route protection plus integrated CLI workflows for authentication, site/key setup, remote rule management, and traffic verification.

## Instructions for the agent

1. **Tell the user:** "`/arcjet:protect-route` is deprecated. Use `/arcjet:add-request-protection` instead — it has the same behavior plus integrated CLI setup and verification."
2. Then proceed by following the `/arcjet:add-request-protection` skill (`skills/add-request-protection/SKILL.md`) for the rest of the workflow. Do not duplicate its content here — read and follow that skill directly.
