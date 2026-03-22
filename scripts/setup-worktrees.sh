#!/usr/bin/env bash
set -Eeuo pipefail

REPO_ROOT="${1:-$(pwd)}"
TARGET_ROOT="${2:-}"

REPO_ROOT="$(cd "$REPO_ROOT" && pwd)"

die() {
  echo "ERROR: $*" >&2
  exit 1
}

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || die "required command not found: $1"
}

is_git_repo() {
  git -C "$1" rev-parse --is-inside-work-tree >/dev/null 2>&1
}

worktree_registered() {
  local path="$1"
  git -C "$REPO_ROOT" worktree list --porcelain | awk '/^worktree /{print $2}' | grep -Fx "$path" >/dev/null 2>&1
}

ensure_branch_exists() {
  local branch="$1"
  if git -C "$REPO_ROOT" show-ref --verify --quiet "refs/heads/$branch"; then
    return 0
  fi
  git -C "$REPO_ROOT" branch "$branch"
}

ensure_worktree() {
  local name="$1"
  local branch="$2"
  local path="$TARGET_ROOT/$name"

  echo "==> Ensuring worktree: $name"
  echo "    branch: $branch"
  echo "    path:   $path"

  ensure_branch_exists "$branch"

  # Case 1: directory exists and is already a git worktree
  if [ -d "$path" ] && is_git_repo "$path"; then
    echo "    existing git worktree found, keeping it"
    return 0
  fi

  # Case 2: git already knows this worktree path
  if worktree_registered "$path"; then
    echo "    worktree registered in git metadata"
    if [ ! -d "$path" ]; then
      echo "    directory missing, repairing registration"
      git -C "$REPO_ROOT" worktree repair "$path" 2>/dev/null || true
    fi
    return 0
  fi

  # Case 3: plain leftover directory exists
  if [ -e "$path" ]; then
    echo "    removing stale directory: $path"
    rm -rf "$path"
  fi

  git -C "$REPO_ROOT" worktree add "$path" "$branch"
}

need_cmd git

is_git_repo "$REPO_ROOT" || die "not a git repository: $REPO_ROOT"

if [ -z "$TARGET_ROOT" ]; then
  TARGET_ROOT="$(dirname "$REPO_ROOT")/$(basename "$REPO_ROOT")-team"
fi

mkdir -p "$TARGET_ROOT"

git -C "$REPO_ROOT" worktree prune

ensure_worktree "lead"       "feature/pvc-design-lead"
ensure_worktree "brainstorm" "feature/pvc-design-brainstorm"
ensure_worktree "platform"   "feature/pvc-design-platform"
ensure_worktree "review"     "feature/pvc-design-review"

echo
echo "Worktrees ready under: $TARGET_ROOT"
git -C "$REPO_ROOT" worktree list