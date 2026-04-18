#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
PACK_DIR="${REPO_ROOT}/agent-packs/skills/tier-1-opus"
AGENTS_DIR="${REPO_ROOT}/agents"
SKILLS_DIR="${REPO_ROOT}/skills"
VERCEL_SKILL="${REPO_ROOT}/vercel-react-best-practices"

# ── colours ──────────────────────────────────────────────────────────────────
BOLD="\033[1m"; GREEN="\033[0;32m"; CYAN="\033[0;36m"; RESET="\033[0m"
ok()  { echo -e "  ${GREEN}✓${RESET} $*"; }
hdr() { echo -e "\n${BOLD}${CYAN}$*${RESET}"; }

# ── usage ─────────────────────────────────────────────────────────────────────
usage() {
  cat <<USAGE
Usage:
  ./scripts/setup.sh [project-path]

Installs the Distinguished Engineer orchestration system into a project's
.claude/ directory. Runs interactively to select domain packs.

If project-path is omitted, you will be prompted.
USAGE
}

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  usage; exit 0
fi

# ── resolve project path ──────────────────────────────────────────────────────
if [[ $# -ge 1 ]]; then
  PROJECT_PATH="$1"
else
  echo ""
  read -rp "  Project path: " PROJECT_PATH
fi

PROJECT_PATH="${PROJECT_PATH/#\~/$HOME}"

if [[ ! -d "${PROJECT_PATH}" ]]; then
  echo "  Error: directory does not exist: ${PROJECT_PATH}" >&2
  exit 1
fi

AGENTS_DEST="${PROJECT_PATH}/.claude/agents"
SKILLS_DEST="${PROJECT_PATH}/.claude/skills"

# ── domain multi-select ───────────────────────────────────────────────────────
# Maps display label → pack file basename (matches tier-1-opus/*.txt)
# Plus "specialized" which has no pack file — we install all agents/specialized/
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

# Skills to copy per domain (space-separated skill dir names from skills/)
declare -A DOMAIN_SKILLS
DOMAIN_SKILLS[backend]="api-design-patterns microservices-design database-optimization golang-idioms redis-patterns postgres-optimization"
DOMAIN_SKILLS[frontend]="api-design-patterns authentication-patterns performance-optimization"
DOMAIN_SKILLS[infrastructure]="monitoring-observability database-optimization postgres-optimization"
DOMAIN_SKILLS[devops]="monitoring-observability"
DOMAIN_SKILLS[observability]="monitoring-observability performance-optimization"
DOMAIN_SKILLS[security]="security-hardening authentication-patterns"
DOMAIN_SKILLS[specialized]=""

# Selection state: 0 = off, 1 = on
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
  hdr "Distinguished Engineer Setup"
  echo -e "  Target: ${BOLD}${PROJECT_PATH}${RESET}"
  print_menu
  read -rp "  > " input

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
skills_installed=()

# 1. Always install orchestration agents
hdr "Installing orchestration agents"
for skill_file in \
    "${REPO_ROOT}/distinguished-engineer/SKILL.md" \
    "${REPO_ROOT}/oracle/SKILL.md" \
    "${REPO_ROOT}/operator/SKILL.md"; do

  dir_name="$(basename "$(dirname "${skill_file}")")"
  dest_name="${dir_name}.md"
  cp "${skill_file}" "${AGENTS_DEST}/${dest_name}"
  ok "${dest_name}"
  (( agent_count++ )) || true
done

# 2. Install selected domain packs
hdr "Installing domain agents"

install_file() {
  local relpath="$1"
  relpath="${relpath#"${relpath%%[![:space:]]*}"}"
  relpath="${relpath%"${relpath##*[![:space:]]}"}"
  [[ -z "${relpath}" || "${relpath}" == \#* ]] && return 0

  local src="${REPO_ROOT}/${relpath}"
  if [[ ! -f "${src}" ]]; then
    echo "  Warning: missing file ${relpath}, skipping." >&2
    return 0
  fi
  cp "${src}" "${AGENTS_DEST}/"
  ok "$(basename "${src}")"
  (( agent_count++ )) || true
}

for i in "${!DOMAIN_KEYS[@]}"; do
  [[ "${SELECTED[$i]}" -eq 0 ]] && continue
  domain="${DOMAIN_KEYS[$i]}"

  if [[ "${domain}" == "specialized" ]]; then
    for f in "${AGENTS_DIR}/specialized/"*.md; do
      [[ -f "${f}" ]] || continue
      cp "${f}" "${AGENTS_DEST}/"
      ok "$(basename "${f}")"
      (( agent_count++ )) || true
    done
  else
    pack="${PACK_DIR}/${domain}.txt"
    if [[ -f "${pack}" ]]; then
      while IFS= read -r line; do
        install_file "${line}"
      done < "${pack}"
    fi
  fi
done

# 3. Install pattern skills for selected domains
hdr "Installing reference skills"

# Collect unique skills across selected domains
declare -A skill_set
for i in "${!DOMAIN_KEYS[@]}"; do
  [[ "${SELECTED[$i]}" -eq 0 ]] && continue
  domain="${DOMAIN_KEYS[$i]}"
  for skill_name in ${DOMAIN_SKILLS[$domain]:-}; do
    skill_set["${skill_name}"]=1
  done
done

# Always install websocket-realtime (useful with backend/infra)
if [[ "${#skill_set[@]}" -gt 0 ]]; then
  skill_set[websocket-realtime]=1
fi

# Install vercel skill if frontend selected
if [[ "${SELECTED[1]:-0}" -eq 1 ]] && [[ -f "${VERCEL_SKILL}/SKILL.md" ]]; then
  cp "${VERCEL_SKILL}/SKILL.md" "${SKILLS_DEST}/vercel-react-best-practices.md"
  ok "vercel-react-best-practices.md"
  (( skill_count++ )) || true
  skills_installed+=("vercel-react-best-practices")
fi

for skill_name in "${!skill_set[@]}"; do
  src_skill="${SKILLS_DIR}/${skill_name}/SKILL.md"
  if [[ -f "${src_skill}" ]]; then
    cp "${src_skill}" "${SKILLS_DEST}/${skill_name}.md"
    ok "${skill_name}.md"
    (( skill_count++ )) || true
    skills_installed+=("${skill_name}")
  fi
done

# 4. Write manifest
{
  echo "installed_at=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "source_repo=${REPO_ROOT}"
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
