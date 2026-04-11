#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
CATALOG_DIR="${REPO_ROOT}/agent-packs/skills"

list_packs() {
  find "${CATALOG_DIR}" -type f -name '*.txt' | sort | while IFS= read -r file; do
    rel="${file#${CATALOG_DIR}/}"
    tier="${rel%%/*}"
    domain_file="${rel#*/}"
    domain="${domain_file%.txt}"
    printf '%s %s\n' "${tier}" "${domain}"
  done
}

usage() {
  cat <<USAGE
Usage:
  ./scripts/install-agent-pack.sh --list
  ./scripts/install-agent-pack.sh <tier> <domain|all> <project-path>

Examples:
  ./scripts/install-agent-pack.sh tier-1-opus frontend ~/code/my-app
  ./scripts/install-agent-pack.sh tier-2-sonnet all ~/code/my-app
USAGE
}

install_manifest() {
  local manifest_path="$1"
  local dest_dir="$2"
  local copied_ref_name="$3"
  local tier="$4"
  local domain="$5"

  while IFS= read -r relpath; do
    relpath="${relpath#${relpath%%[![:space:]]*}}"
    relpath="${relpath%${relpath##*[![:space:]]}}"

    [[ -z "${relpath}" ]] && continue
    [[ "${relpath}" == \#* ]] && continue

    local src="${REPO_ROOT}/${relpath}"
    if [[ ! -f "${src}" ]]; then
      echo "Missing source file from ${tier}/${domain}: ${relpath}" >&2
      exit 1
    fi

    cp "${src}" "${dest_dir}/"
    eval "${copied_ref_name}=$(( ${copied_ref_name} + 1 ))"
  done < "${manifest_path}"
}

if [[ "${1:-}" == "--list" ]]; then
  list_packs
  exit 0
fi

if [[ $# -ne 3 ]]; then
  usage
  exit 1
fi

TIER="$1"
DOMAIN="$2"
PROJECT_PATH="$3"

if [[ ! -d "${PROJECT_PATH}" ]]; then
  echo "Project path does not exist: ${PROJECT_PATH}" >&2
  exit 1
fi

TIER_DIR="${CATALOG_DIR}/${TIER}"
if [[ ! -d "${TIER_DIR}" ]]; then
  echo "Unknown tier: ${TIER}" >&2
  echo "Available tier/domain entries:" >&2
  list_packs >&2
  exit 1
fi

DEST_DIR="${PROJECT_PATH}/.claude/agents"
mkdir -p "${DEST_DIR}"

copied=0
if [[ "${DOMAIN}" == "all" ]]; then
  found=0
  for manifest in "${TIER_DIR}"/*.txt; do
    [[ -f "${manifest}" ]] || continue
    found=1
    domain_name="$(basename "${manifest}" .txt)"
    install_manifest "${manifest}" "${DEST_DIR}" copied "${TIER}" "${domain_name}"
  done

  if [[ "${found}" -eq 0 ]]; then
    echo "No domain manifests found for tier ${TIER}" >&2
    exit 1
  fi
else
  MANIFEST_PATH="${TIER_DIR}/${DOMAIN}.txt"
  if [[ ! -f "${MANIFEST_PATH}" ]]; then
    echo "Unknown domain '${DOMAIN}' for tier '${TIER}'" >&2
    echo "Available tier/domain entries:" >&2
    list_packs | awk -v t="${TIER}" '$1 == t { print }' >&2
    exit 1
  fi

  install_manifest "${MANIFEST_PATH}" "${DEST_DIR}" copied "${TIER}" "${DOMAIN}"
fi

{
  echo "tier=${TIER}"
  echo "domain=${DOMAIN}"
  echo "installed_at=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "source_repo=${REPO_ROOT}"
  echo "count=${copied}"
} > "${DEST_DIR}/_installed-pack.txt"

echo "Installed ${copied} agents from ${TIER}/${DOMAIN} to ${DEST_DIR}."
