#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
MANIFEST_DIR="${REPO_ROOT}/agent-packs/manifests"

list_packs() {
  find "${MANIFEST_DIR}" -maxdepth 1 -type f -name '*.txt' -printf '%f\n' \
    | sed 's/\.txt$//' \
    | sort
}

usage() {
  cat <<USAGE
Usage:
  bash scripts/install-agent-pack.sh --list
  bash scripts/install-agent-pack.sh <pack-name> <project-path>
USAGE
}

if [[ "${1:-}" == "--list" ]]; then
  list_packs
  exit 0
fi

if [[ $# -ne 2 ]]; then
  usage
  exit 1
fi

PACK_NAME="$1"
PROJECT_PATH="$2"
MANIFEST_PATH="${MANIFEST_DIR}/${PACK_NAME}.txt"

if [[ ! -f "${MANIFEST_PATH}" ]]; then
  echo "Unknown pack: ${PACK_NAME}" >&2
  echo "Available packs:" >&2
  list_packs >&2
  exit 1
fi

if [[ ! -d "${PROJECT_PATH}" ]]; then
  echo "Project path does not exist: ${PROJECT_PATH}" >&2
  exit 1
fi

DEST_DIR="${PROJECT_PATH}/.claude/agents"
mkdir -p "${DEST_DIR}"

copied=0
while IFS= read -r relpath; do
  [[ -z "${relpath}" ]] && continue

  src="${REPO_ROOT}/${relpath}"
  if [[ ! -f "${src}" ]]; then
    echo "Missing source file from manifest: ${relpath}" >&2
    exit 1
  fi

  cp "${src}" "${DEST_DIR}/"
  copied=$((copied + 1))
done < "${MANIFEST_PATH}"

{
  echo "pack=${PACK_NAME}"
  echo "installed_at=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "source_repo=${REPO_ROOT}"
  echo "count=${copied}"
} > "${DEST_DIR}/_installed-pack.txt"

echo "Installed pack '${PACK_NAME}' to ${DEST_DIR} (${copied} agents)."
