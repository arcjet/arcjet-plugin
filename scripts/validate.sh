#!/usr/bin/env bash
# Validates the structural integrity of the plugin:
#   - JSON files are valid
#   - plugin.json has required fields
#   - SKILL.md files have valid YAML frontmatter with required fields
#   - .mdc rule files have valid YAML frontmatter with required fields
#   - Agent .md files have valid YAML frontmatter with required fields

set -euo pipefail

errors=0
warnings=0

red="\033[0;31m"
yellow="\033[0;33m"
green="\033[0;32m"
reset="\033[0m"

error() {
  echo -e "${red}ERROR:${reset} $1"
  errors=$((errors + 1))
}

warn() {
  echo -e "${yellow}WARN:${reset} $1"
  warnings=$((warnings + 1))
}

ok() {
  echo -e "${green}OK:${reset} $1"
}

# --- JSON validation ---
echo "=== Validating JSON files ==="

validate_json() {
  local file="$1"
  # Strip single-line // comments for JSONC support (devcontainer.json etc.)
  if ! node -e "
    const raw = require('fs').readFileSync(process.argv[1], 'utf8');
    const stripped = raw.replace(/^\s*\/\/.*$/gm, '');
    JSON.parse(stripped);
  " "$file" 2>/dev/null; then
    error "$file — invalid JSON"
    return 1
  fi
  ok "$file"
  return 0
}

for f in $(find . -name '*.json' -not -path './.git/*' -not -path './node_modules/*'); do
  validate_json "$f"
done

# --- plugin.json required fields ---
echo ""
echo "=== Validating plugin.json ==="

PLUGIN_JSON=".plugin/plugin.json"
if [ ! -f "$PLUGIN_JSON" ]; then
  error "$PLUGIN_JSON not found"
else
  for field in name version description author license logo; do
    if ! node -e "
      const p = JSON.parse(require('fs').readFileSync(process.argv[1], 'utf8'));
      if (!p[process.argv[2]]) { process.exit(1); }
    " "$PLUGIN_JSON" "$field" 2>/dev/null; then
      error "$PLUGIN_JSON — missing required field: $field"
    fi
  done

  # Validate version is semver-like
  node -e "
    const p = JSON.parse(require('fs').readFileSync(process.argv[1], 'utf8'));
    if (!/^\d+\.\d+\.\d+/.test(p.version || '')) { process.exit(1); }
  " "$PLUGIN_JSON" 2>/dev/null || error "$PLUGIN_JSON — version is not valid semver"

  # Validate logo file exists
  logo=$(node -e "
    const p = JSON.parse(require('fs').readFileSync(process.argv[1], 'utf8'));
    process.stdout.write(p.logo || '');
  " "$PLUGIN_JSON" 2>/dev/null)
  if [ -n "$logo" ] && [ ! -f "$logo" ]; then
    error "$PLUGIN_JSON — logo file not found: $logo"
  fi

  ok "$PLUGIN_JSON structure"
fi

# --- Helper: check YAML frontmatter has required top-level keys ---
validate_frontmatter() {
  local file="$1"
  shift
  local required_fields=("$@")

  # Check file starts with ---
  if ! head -1 "$file" | grep -q '^---$'; then
    error "$file — missing YAML frontmatter (must start with ---)"
    return 1
  fi

  # Extract frontmatter between first two --- lines
  local frontmatter
  frontmatter=$(sed -n '2,/^---$/{ /^---$/d; p; }' "$file")

  if [ -z "$frontmatter" ]; then
    error "$file — empty YAML frontmatter"
    return 1
  fi

  # Check each required field exists as a top-level YAML key
  for field in "${required_fields[@]}"; do
    if ! echo "$frontmatter" | grep -q "^${field}:"; then
      error "$file — frontmatter missing required field: $field"
      return 1
    fi
  done

  ok "$file frontmatter"
  return 0
}

# --- Validate skills ---
echo ""
echo "=== Validating skills ==="

skill_count=0
for skill_dir in skills/*/; do
  if [ ! -f "${skill_dir}SKILL.md" ]; then
    error "${skill_dir} — missing SKILL.md"
    continue
  fi

  validate_frontmatter "${skill_dir}SKILL.md" name description

  # Check skill has content after frontmatter
  body_lines=$(sed '1,/^---$/{ /^---$/!d; }' "${skill_dir}SKILL.md" | sed '1,/^---$/d' | grep -c '[^ ]' || true)
  if [ "$body_lines" -lt 3 ]; then
    warn "${skill_dir}SKILL.md — very little content after frontmatter ($body_lines non-empty lines)"
  fi

  skill_count=$((skill_count + 1))
done

if [ "$skill_count" -eq 0 ]; then
  warn "No skills found in skills/"
else
  ok "Found $skill_count skill(s)"
fi

# --- Validate rules ---
echo ""
echo "=== Validating rules ==="

rule_count=0
for rule_file in rules/*.mdc; do
  [ -f "$rule_file" ] || continue
  validate_frontmatter "$rule_file" description globs

  # Check alwaysApply field exists
  if ! grep -q '^alwaysApply:' "$rule_file"; then
    warn "$rule_file — missing alwaysApply field (defaults may vary by tool)"
  fi

  rule_count=$((rule_count + 1))
done

if [ "$rule_count" -eq 0 ]; then
  warn "No rules found in rules/"
else
  ok "Found $rule_count rule(s)"
fi

# --- Validate agents ---
echo ""
echo "=== Validating agents ==="

agent_count=0
for agent_file in agents/*.md; do
  [ -f "$agent_file" ] || continue
  validate_frontmatter "$agent_file" name description
  agent_count=$((agent_count + 1))
done

if [ "$agent_count" -eq 0 ]; then
  warn "No agents found in agents/"
else
  ok "Found $agent_count agent(s)"
fi

# --- Validate .mcp.json ---
echo ""
echo "=== Validating .mcp.json ==="

if [ -f ".mcp.json" ]; then
  node -e "
    const m = JSON.parse(require('fs').readFileSync('.mcp.json', 'utf8'));
    if (!m.mcpServers || Object.keys(m.mcpServers).length === 0) {
      console.error('No MCP servers defined');
      process.exit(1);
    }
    for (const [name, server] of Object.entries(m.mcpServers)) {
      if (!server.url && !server.command) {
        console.error('Server ' + name + ' has no url or command');
        process.exit(1);
      }
    }
  " 2>&1 || error ".mcp.json — invalid MCP server configuration"
  ok ".mcp.json"
else
  warn ".mcp.json not found — no MCP servers configured"
fi

# --- Summary ---
echo ""
echo "================================"
if [ "$errors" -gt 0 ]; then
  echo -e "${red}FAILED${reset}: $errors error(s), $warnings warning(s)"
  exit 1
elif [ "$warnings" -gt 0 ]; then
  echo -e "${yellow}PASSED${reset} with $warnings warning(s)"
  exit 0
else
  echo -e "${green}PASSED${reset}: All checks passed"
  exit 0
fi
