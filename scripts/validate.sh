#!/usr/bin/env bash
# Validates the structural integrity of the plugin:
#   - JSON files are valid
#   - plugin.json has required fields
#   - SKILL.md files have valid YAML frontmatter with required fields
#   - .mdc rule files have valid YAML frontmatter with required fields
#   - Agent .md files have valid YAML frontmatter with required fields
#   - Marketplace catalogs exist, plugin names match, and source paths resolve

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

# --- Marketplace catalogs ---
echo ""
echo "=== Validating marketplace catalogs ==="

ROOT_PLUGIN_JSON=".plugin/plugin.json"
CURSOR_PLUGIN_JSON=".cursor-plugin/plugin.json"
CURSOR_MARKETPLACE=".cursor-plugin/marketplace.json"
CODEX_MARKETPLACE=".agents/plugins/marketplace.json"
NESTED_PLUGIN_DIR="plugins/arcjet"
NESTED_CURSOR_PLUGIN="$NESTED_PLUGIN_DIR/.cursor-plugin/plugin.json"
NESTED_CODEX_PLUGIN="$NESTED_PLUGIN_DIR/.codex-plugin/plugin.json"

# Root host manifests must remain so npx plugins add / Claude Code keep working
for f in "$ROOT_PLUGIN_JSON" ".claude-plugin/plugin.json" "$CURSOR_PLUGIN_JSON" ".mcp.json" "mcp.json"; do
  if [ ! -f "$f" ]; then
    error "$f not found — required at repo root for Open Plugins / Claude / local Cursor"
  else
    ok "$f (root host file)"
  fi
done

if [ ! -d "skills" ] || [ ! -d "rules" ] || [ ! -d "agents" ]; then
  error "root skills/, rules/, and agents/ must remain at the repo root"
else
  ok "root skills/, rules/, and agents/ present"
fi

# Cursor plugin.json logo must not use a ./ prefix
if [ -f "$CURSOR_PLUGIN_JSON" ]; then
  cursor_logo=$(node -e "
    const p = JSON.parse(require('fs').readFileSync(process.argv[1], 'utf8'));
    process.stdout.write(p.logo || '');
  " "$CURSOR_PLUGIN_JSON" 2>/dev/null || true)
  if [ -z "$cursor_logo" ]; then
    error "$CURSOR_PLUGIN_JSON — missing logo"
  elif [[ "$cursor_logo" == ./* ]]; then
    error "$CURSOR_PLUGIN_JSON — logo must not use a ./ prefix (got: $cursor_logo)"
  elif [ ! -f "$cursor_logo" ]; then
    error "$CURSOR_PLUGIN_JSON — logo file not found: $cursor_logo"
  else
    ok "$CURSOR_PLUGIN_JSON logo ($cursor_logo)"
  fi
fi

if [ ! -f "$CURSOR_MARKETPLACE" ]; then
  error "$CURSOR_MARKETPLACE not found"
else
  node -e "
    const fs = require('fs');
    const path = require('path');
    const file = process.argv[1];
    const marketplace = JSON.parse(fs.readFileSync(file, 'utf8'));
    const fail = (msg) => { console.error(msg); process.exit(1); };
    const kebab = /^[a-z0-9]([a-z0-9-]*[a-z0-9])?$/;
    const pluginName = /^[a-z0-9]([a-z0-9.-]*[a-z0-9])?$/;

    if (typeof marketplace.name !== 'string' || !kebab.test(marketplace.name)) {
      fail(file + ' — name must be lowercase kebab-case');
    }
    if (!marketplace.owner || typeof marketplace.owner.name !== 'string' || !marketplace.owner.name) {
      fail(file + ' — owner.name is required');
    }
    if (typeof marketplace.owner.email !== 'string' || !marketplace.owner.email) {
      fail(file + ' — owner.email is required');
    }
    if (!Array.isArray(marketplace.plugins) || marketplace.plugins.length === 0) {
      fail(file + ' — plugins must be a non-empty array');
    }

    const pluginRoot = marketplace.metadata && marketplace.metadata.pluginRoot;
    if (pluginRoot !== undefined) {
      if (typeof pluginRoot !== 'string' || pluginRoot.length === 0) {
        fail(file + ' — metadata.pluginRoot must be a relative path');
      }
      if (pluginRoot === '.' || pluginRoot.startsWith('./') || pluginRoot.startsWith('/') || pluginRoot.includes('..')) {
        fail(file + ' — metadata.pluginRoot must be a bare relative path (no ./, no ..): ' + pluginRoot);
      }
      if (!fs.statSync(pluginRoot).isDirectory()) {
        fail(file + ' — metadata.pluginRoot is not a directory: ' + pluginRoot);
      }
    }

    const seen = new Set();
    for (const [index, entry] of marketplace.plugins.entries()) {
      const label = file + ' plugins[' + index + ']';
      if (!entry || typeof entry !== 'object') fail(label + ' must be an object');
      if (typeof entry.name !== 'string' || !pluginName.test(entry.name)) {
        fail(label + '.name must be lowercase kebab-case');
      }
      if (seen.has(entry.name)) fail(label + ' — duplicate plugin name: ' + entry.name);
      seen.add(entry.name);

      if (typeof entry.source !== 'string' || entry.source.length === 0) {
        fail(label + '.source must be a string path');
      }
      if (entry.source === '.' || entry.source.startsWith('./') || entry.source.startsWith('/') || entry.source.includes('..')) {
        fail(label + '.source must be a bare directory name (Cursor 2.6 rejects \".\" and ./ prefixes): ' + entry.source);
      }

      const resolved = pluginRoot ? path.join(pluginRoot, entry.source) : entry.source;
      if (!fs.existsSync(resolved) || !fs.statSync(resolved).isDirectory()) {
        fail(label + '.source does not resolve to a directory: ' + resolved);
      }
      const manifestPath = path.join(resolved, '.cursor-plugin', 'plugin.json');
      if (!fs.existsSync(manifestPath)) {
        fail(label + ' — missing ' + manifestPath);
      }
      const plugin = JSON.parse(fs.readFileSync(manifestPath, 'utf8'));
      if (plugin.name !== entry.name) {
        fail(label + ' — marketplace name \"' + entry.name + '\" does not match ' + manifestPath + ' name \"' + plugin.name + '\"');
      }
      if (typeof plugin.logo === 'string' && plugin.logo.startsWith('./')) {
        fail(manifestPath + ' — logo must not use a ./ prefix (got: ' + plugin.logo + ')');
      }
      if (typeof plugin.logo === 'string') {
        const logoPath = path.join(resolved, plugin.logo);
        if (!fs.existsSync(logoPath)) {
          fail(manifestPath + ' — logo file not found: ' + plugin.logo);
        }
      }
      for (const component of ['skills', 'rules', 'agents']) {
        const componentPath = path.join(resolved, component);
        if (!fs.existsSync(componentPath)) {
          fail(label + ' — resolved plugin is missing ' + component + '/');
        }
      }
      const mcpPath = path.join(resolved, 'mcp.json');
      if (!fs.existsSync(mcpPath)) {
        fail(label + ' — resolved plugin is missing mcp.json');
      }
    }
  " "$CURSOR_MARKETPLACE" && ok "$CURSOR_MARKETPLACE" || error "$CURSOR_MARKETPLACE — invalid marketplace catalog"
fi

if [ ! -f "$CODEX_MARKETPLACE" ]; then
  error "$CODEX_MARKETPLACE not found"
else
  node -e "
    const fs = require('fs');
    const path = require('path');
    const file = process.argv[1];
    const marketplace = JSON.parse(fs.readFileSync(file, 'utf8'));
    const fail = (msg) => { console.error(msg); process.exit(1); };
    const pluginName = /^[a-z0-9]([a-z0-9.-]*[a-z0-9])?$/;

    if (typeof marketplace.name !== 'string' || !marketplace.name) {
      fail(file + ' — name is required');
    }
    if (!marketplace.interface || typeof marketplace.interface.displayName !== 'string' || !marketplace.interface.displayName) {
      fail(file + ' — interface.displayName is required');
    }
    if (!Array.isArray(marketplace.plugins) || marketplace.plugins.length === 0) {
      fail(file + ' — plugins must be a non-empty array');
    }

    const seen = new Set();
    for (const [index, entry] of marketplace.plugins.entries()) {
      const label = file + ' plugins[' + index + ']';
      if (!entry || typeof entry !== 'object') fail(label + ' must be an object');
      if (typeof entry.name !== 'string' || !pluginName.test(entry.name)) {
        fail(label + '.name must be lowercase kebab-case');
      }
      if (seen.has(entry.name)) fail(label + ' — duplicate plugin name: ' + entry.name);
      seen.add(entry.name);

      let sourcePath = null;
      if (typeof entry.source === 'string') {
        sourcePath = entry.source;
      } else if (entry.source && typeof entry.source.path === 'string') {
        sourcePath = entry.source.path;
      }
      if (!sourcePath) fail(label + '.source.path is required');
      if (!sourcePath.startsWith('./')) {
        fail(label + '.source.path must be relative to the marketplace root and start with ./ (got: ' + sourcePath + ')');
      }
      if (sourcePath.includes('..')) {
        fail(label + '.source.path must stay inside the marketplace root: ' + sourcePath);
      }

      const resolved = path.normalize(sourcePath);
      if (!fs.existsSync(resolved) || !fs.statSync(resolved).isDirectory()) {
        fail(label + '.source.path does not resolve to a directory: ' + sourcePath);
      }
      const manifestPath = path.join(resolved, '.codex-plugin', 'plugin.json');
      if (!fs.existsSync(manifestPath)) {
        fail(label + ' — missing ' + manifestPath);
      }
      const plugin = JSON.parse(fs.readFileSync(manifestPath, 'utf8'));
      if (plugin.name !== entry.name) {
        fail(label + ' — marketplace name \"' + entry.name + '\" does not match ' + manifestPath + ' name \"' + plugin.name + '\"');
      }
      if (typeof plugin.skills !== 'string' || !plugin.skills.startsWith('./')) {
        fail(manifestPath + ' — skills must be a ./ relative path');
      }
      const skillsPath = path.join(resolved, plugin.skills);
      if (!fs.existsSync(skillsPath)) {
        fail(manifestPath + ' — skills path does not resolve: ' + plugin.skills);
      }
      if (typeof plugin.mcpServers !== 'string' || !plugin.mcpServers.startsWith('./')) {
        fail(manifestPath + ' — mcpServers must be a ./ relative path to .mcp.json');
      }
      const mcpPath = path.join(resolved, plugin.mcpServers);
      if (!fs.existsSync(mcpPath)) {
        fail(manifestPath + ' — mcpServers path does not resolve: ' + plugin.mcpServers);
      }
    }
  " "$CODEX_MARKETPLACE" && ok "$CODEX_MARKETPLACE" || error "$CODEX_MARKETPLACE — invalid marketplace catalog"
fi

# Nested plugin must symlink shared trees (do not duplicate skills/)
if [ -d "$NESTED_PLUGIN_DIR" ]; then
  for component in skills rules agents assets; do
    link="$NESTED_PLUGIN_DIR/$component"
    if [ ! -L "$link" ]; then
      error "$link must be a symlink to ../../$component (do not duplicate the $component tree)"
      continue
    fi
    target=$(readlink "$link")
    if [ "$target" != "../../$component" ]; then
      error "$link must point at ../../$component (got: $target)"
    elif [ ! -e "$link" ]; then
      error "$link is a broken symlink"
    else
      ok "$link -> $target"
    fi
  done
  for mcp in mcp.json .mcp.json; do
    link="$NESTED_PLUGIN_DIR/$mcp"
    if [ ! -e "$link" ]; then
      error "$link not found"
    else
      ok "$link"
    fi
  done
else
  error "$NESTED_PLUGIN_DIR not found"
fi

# Nested Cursor identity should match the root Cursor manifest
if [ -f "$CURSOR_PLUGIN_JSON" ] && [ -f "$NESTED_CURSOR_PLUGIN" ]; then
  if cmp -s "$CURSOR_PLUGIN_JSON" "$NESTED_CURSOR_PLUGIN"; then
    ok "Cursor plugin.json copies match"
  else
    error "$NESTED_CURSOR_PLUGIN must stay in sync with $CURSOR_PLUGIN_JSON"
  fi
fi

# Nested Codex identity should match the Open Plugins name/version
if [ -f "$ROOT_PLUGIN_JSON" ] && [ -f "$NESTED_CODEX_PLUGIN" ]; then
  node -e "
    const root = JSON.parse(require('fs').readFileSync(process.argv[1], 'utf8'));
    const codex = JSON.parse(require('fs').readFileSync(process.argv[2], 'utf8'));
    for (const field of ['name', 'version', 'description', 'license']) {
      if (root[field] !== codex[field]) {
        console.error(process.argv[2] + ' — ' + field + ' does not match ' + process.argv[1]);
        process.exit(1);
      }
    }
  " "$ROOT_PLUGIN_JSON" "$NESTED_CODEX_PLUGIN" && ok "$NESTED_CODEX_PLUGIN identity" || error "$NESTED_CODEX_PLUGIN — identity does not match $ROOT_PLUGIN_JSON"
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
