#!/usr/bin/env bash
set -euo pipefail

# Sync the canonical GitHub Pages repo (eonewg.github.io) to the custom-domain
# mirror repo (eeeone.me), while preserving the mirror-only CNAME file.
#
# Usage:
#   ./scripts/sync-custom-domain-mirror.sh
#   ./scripts/sync-custom-domain-mirror.sh --no-push
#   MIRROR_DIR=/path/to/eeeone.me ./scripts/sync-custom-domain-mirror.sh

OWNER="eonewg"
MIRROR_REPO="${OWNER}/eeeone.me"
CUSTOM_DOMAIN="eeeone.me"
DEFAULT_MIRROR_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/../eeeone.me"
MIRROR_DIR="${MIRROR_DIR:-$DEFAULT_MIRROR_DIR}"
NO_PUSH=0

for arg in "$@"; do
  case "$arg" in
    --no-push) NO_PUSH=1 ;;
    -h|--help)
      sed -n '1,18p' "$0"
      exit 0
      ;;
    *) echo "Unknown argument: $arg" >&2; exit 2 ;;
  esac
done

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || { echo "Missing required command: $1" >&2; exit 127; }
}
require_cmd git
require_cmd rsync
require_cmd python3

if command -v gh >/dev/null 2>&1; then
  HAS_GH=1
else
  HAS_GH=0
fi

SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$SOURCE_DIR"

remote_url="$(git remote get-url origin 2>/dev/null || true)"
if [[ "$remote_url" != *"github.com/${OWNER}/eonewg.github.io"* ]]; then
  echo "Refusing to run: source repo does not look like ${OWNER}/eonewg.github.io" >&2
  echo "Current origin: ${remote_url:-<none>}" >&2
  exit 1
fi

if [[ -f CNAME ]]; then
  echo "Refusing to sync: source repo should not contain CNAME." >&2
  echo "Keep custom domain binding only in ${MIRROR_REPO}." >&2
  exit 1
fi

if [[ -n "$(git status --porcelain)" ]]; then
  echo "Refusing to sync: source repo has uncommitted changes." >&2
  git status --short
  exit 1
fi

if [[ ! -d "$MIRROR_DIR/.git" ]]; then
  if [[ "$HAS_GH" -eq 1 ]]; then
    mkdir -p "$(dirname "$MIRROR_DIR")"
    gh repo clone "$MIRROR_REPO" "$MIRROR_DIR"
  else
    echo "Mirror repo missing and gh is unavailable: $MIRROR_DIR" >&2
    exit 1
  fi
fi

cd "$MIRROR_DIR"
mirror_remote="$(git remote get-url origin 2>/dev/null || true)"
if [[ "$mirror_remote" != *"github.com/${OWNER}/eeeone.me"* ]]; then
  echo "Refusing to run: mirror repo does not look like ${MIRROR_REPO}" >&2
  echo "Current mirror origin: ${mirror_remote:-<none>}" >&2
  exit 1
fi

if [[ -n "$(git status --porcelain)" ]]; then
  echo "Refusing to sync: mirror repo has uncommitted changes." >&2
  git status --short
  exit 1
fi

git pull --ff-only

cd "$SOURCE_DIR"
source_sha="$(git rev-parse --short HEAD)"

# Copy everything except source repo internals and files that should not be mirrored.
# CNAME is mirror-owned and is written explicitly below.
rsync -a --delete \
  --exclude='.git/' \
  --exclude='CNAME' \
  "$SOURCE_DIR/" "$MIRROR_DIR/"

printf '%s\n' "$CUSTOM_DOMAIN" > "$MIRROR_DIR/CNAME"

cd "$MIRROR_DIR"

# Keep mirror commit identity local to this repo.
git config user.name "Eone"
git config user.email "yizeee@126.com"

git add -A
if git diff --cached --quiet; then
  echo "Mirror already up to date with source ${source_sha}."
else
  git commit -m "Sync homepage from eonewg.github.io (${source_sha})"
  if [[ "$NO_PUSH" -eq 0 ]]; then
    git push origin main
  else
    echo "--no-push set; commit created locally but not pushed."
  fi
fi

echo "Mirror status:"
git status --short --branch

if [[ "$HAS_GH" -eq 1 ]]; then
  echo "Pages status:"
  gh api repos/${MIRROR_REPO}/pages --jq '{status,cname,html_url,https_enforced}' 2>/dev/null || true
fi
