#!/usr/bin/env bash
set -euo pipefail

BASE_URL="https://raw.githubusercontent.com/valentinesamuel/claude-skills/main"

# ── colours ──────────────────────────────────────────────────────────────────
BOLD="\033[1m"; GREEN="\033[0;32m"; CYAN="\033[0;36m"; YELLOW="\033[0;33m"; RESET="\033[0m"
ok()   { echo -e "  ${GREEN}✓${RESET} $*"; }
warn() { echo -e "  ${YELLOW}⚠${RESET} $*" >&2; }
hdr()  { echo -e "\n${BOLD}${CYAN}$*${RESET}"; }

# ── usage ─────────────────────────────────────────────────────────────────────
usage() {
  cat <<USAGE
Usage:
  curl -fsSL ${BASE_URL}/scripts/install.sh | bash -s -- [project-path]
  bash install.sh [project-path]

Installs the Distinguished Engineer orchestration system into a project's
.claude/ directory. Runs interactively to select domain packs.

If project-path is omitted, you will be prompted.
USAGE
}

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  usage; exit 0
fi

# ── dependency check ──────────────────────────────────────────────────────────
if ! command -v curl &>/dev/null; then
  echo "  Error: curl is required but not installed." >&2
  exit 1
fi

# ── resolve project path ──────────────────────────────────────────────────────
if [[ $# -ge 1 ]]; then
  PROJECT_PATH="$1"
else
  echo ""
  read -rp "  Project path: " PROJECT_PATH </dev/tty
fi

PROJECT_PATH="${PROJECT_PATH/#\~/$HOME}"

if [[ ! -d "${PROJECT_PATH}" ]]; then
  echo "  Error: directory does not exist: ${PROJECT_PATH}" >&2
  exit 1
fi

AGENTS_DEST="${PROJECT_PATH}/.claude/agents"
SKILLS_DEST="${PROJECT_PATH}/.claude/skills"

# ── fetch helper ──────────────────────────────────────────────────────────────
# fetch_file <relative-path> <dest-file>
fetch_file() {
  local rel="$1"
  local dest="$2"
  local url="${BASE_URL}/${rel}"
  mkdir -p "$(dirname "${dest}")"
  if ! curl -fsSL -o "${dest}" "${url}" 2>/dev/null; then
    warn "Could not fetch ${rel} — skipping"
    return 1
  fi
  ok "$(basename "${dest}")"
  return 0
}

# ── domain definitions ────────────────────────────────────────────────────────
DOMAIN_KEYS=(backend frontend infrastructure devops observability security specialized)
DOMAIN_LABELS=(
  "Backend          (api-designer, backend-developer, microservices-architect, event-driven, websocket)"
  "Frontend         (fullstack-engineer, frontend-developer, nextjs-developer, react-specialist)"
  "Infrastructure   (cloud-architect, database-admin, platform-engineer)"
  "DevOps           (devops-engineer, deployment-engineer, sre-engineer)"
  "Observability    (performance-engineer, error-detective)"
  "Security         (security-engineer, security-auditor, penetration-tester, compliance-auditor)"
  "Specialized      (architect-reviewer, debugger, docker-expert, typescript-pro)"
)

# Skills to install per domain (bash 3.2-compatible — no associative arrays)
DOMAIN_SKILLS_backend="api-design-patterns microservices-design database-optimization golang-idioms redis-patterns postgres-optimization"
DOMAIN_SKILLS_frontend="api-design-patterns authentication-patterns performance-optimization"
DOMAIN_SKILLS_infrastructure="monitoring-observability database-optimization postgres-optimization"
DOMAIN_SKILLS_devops="monitoring-observability"
DOMAIN_SKILLS_observability="monitoring-observability performance-optimization"
DOMAIN_SKILLS_security="security-hardening authentication-patterns"
DOMAIN_SKILLS_specialized=""

# ── domain multi-select menu ──────────────────────────────────────────────────
declare -a SELECTED
for i in "${!DOMAIN_KEYS[@]}"; do SELECTED[$i]=0; done

print_menu() {
  hdr "Select domain packs  (toggle number, Enter to confirm)"
  echo ""
  for i in "${!DOMAIN_KEYS[@]}"; do
    if [[ "${SELECTED[$i]}" -eq 1 ]]; then
      echo -e "  ${GREEN}[x]${RESET} $((i+1)). ${DOMAIN_LABELS[$i]}"
    else
      echo  "  [ ] $((i+1)). ${DOMAIN_LABELS[$i]}"
    fi
  done
  echo ""
  echo "  Enter numbers to toggle (e.g. 1 3), or press Enter to confirm:"
}

while true; do
  clear 2>/dev/null || true
  hdr "Distinguished Engineer Setup  (remote install)"
  echo -e "  Target: ${BOLD}${PROJECT_PATH}${RESET}"
  print_menu
  read -rp "  > " input </dev/tty

  [[ -z "${input}" ]] && break

  for token in ${input}; do
    if [[ "${token}" =~ ^[0-9]+$ ]] && (( token >= 1 && token <= ${#DOMAIN_KEYS[@]} )); then
      idx=$((token - 1))
      SELECTED[$idx]=$(( 1 - SELECTED[$idx] ))
    fi
  done
done

# ── install ───────────────────────────────────────────────────────────────────
mkdir -p "${AGENTS_DEST}" "${SKILLS_DEST}"

agent_count=0
skill_count=0

# 1. Always install orchestration agents
hdr "Installing orchestration agents"
for rel in \
    "distinguished-engineer/SKILL.md" \
    "oracle/SKILL.md" \
    "operator/SKILL.md"; do

  dir_name="$(basename "$(dirname "${rel}")")"
  dest="${AGENTS_DEST}/${dir_name}.md"
  if fetch_file "${rel}" "${dest}"; then (( agent_count++ )) || true; fi
done

# 2. Install selected domain packs
hdr "Installing domain agents"

for i in "${!DOMAIN_KEYS[@]}"; do
  [[ "${SELECTED[$i]}" -eq 0 ]] && continue
  domain="${DOMAIN_KEYS[$i]}"

  manifest_url="${BASE_URL}/agent-packs/skills/tier-1-opus/${domain}.txt"
  manifest="$(curl -fsSL "${manifest_url}" 2>/dev/null)" || {
    warn "Could not fetch manifest for domain: ${domain}"
    continue
  }

  while IFS= read -r line; do
    line="${line#"${line%%[![:space:]]*}"}"
    line="${line%"${line##*[![:space:]]}"}"
    [[ -z "${line}" || "${line}" == \#* ]] && continue
    dest="${AGENTS_DEST}/$(basename "${line}")"
    if fetch_file "${line}" "${dest}"; then (( agent_count++ )) || true; fi
  done <<< "${manifest}"
done

# 3. Install pattern skills for selected domains
hdr "Installing reference skills"

skills_to_install=()
_add_skill() {
  local s="$1"
  local x
  for x in "${skills_to_install[@]+"${skills_to_install[@]}"}"; do
    [[ "$x" == "$s" ]] && return 0
  done
  skills_to_install+=("$s")
}

for i in "${!DOMAIN_KEYS[@]}"; do
  [[ "${SELECTED[$i]}" -eq 0 ]] && continue
  domain="${DOMAIN_KEYS[$i]}"
  varname="DOMAIN_SKILLS_${domain}"
  for skill_name in ${!varname}; do
    _add_skill "${skill_name}"
  done
done

if [[ "${#skills_to_install[@]}" -gt 0 ]]; then
  _add_skill "websocket-realtime"
fi

# Vercel skill if frontend selected
if [[ "${SELECTED[1]:-0}" -eq 1 ]]; then
  if fetch_file "vercel-react-best-practices/SKILL.md" "${SKILLS_DEST}/vercel-react-best-practices.md"; then
    (( skill_count++ )) || true
  fi
fi

for skill_name in "${skills_to_install[@]+"${skills_to_install[@]}"}"; do
  if fetch_file "skills/${skill_name}/SKILL.md" "${SKILLS_DEST}/${skill_name}.md"; then
    (( skill_count++ )) || true
  fi
done

# 4. Write manifest
{
  echo "installed_at=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "source=remote:${BASE_URL}"
  echo "agents=${agent_count}"
  echo "skills=${skill_count}"
  echo "domains=$(for i in "${!DOMAIN_KEYS[@]}"; do [[ "${SELECTED[$i]}" -eq 1 ]] && printf '%s ' "${DOMAIN_KEYS[$i]}"; done)"
} > "${AGENTS_DEST}/_setup-manifest.txt"

# ── summary ───────────────────────────────────────────────────────────────────
hdr "Done"
echo ""
echo -e "  ${BOLD}Agents${RESET}  → ${PROJECT_PATH}/.claude/agents/   (${agent_count} files)"
echo -e "  ${BOLD}Skills${RESET}  → ${PROJECT_PATH}/.claude/skills/    (${skill_count} files)"
echo ""
echo -e "  ${BOLD}Workflow:${RESET}"
echo "  1. /distinguished-engineer <your problem>"
echo "  2. Review artifacts in .claude/artifacts/"
echo "  3. /operator execute phases <N> from plan.md"
echo ""
