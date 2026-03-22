#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="${1:-$(pwd)}"
REPO_ROOT="$(cd "$REPO_ROOT" && pwd)"
TEAM_ROOT="${2:-${REPO_ROOT}-team}"

mkdir -p "$TEAM_ROOT"
cd "$REPO_ROOT"

ensure_branch() {
  local branch="$1"
  if git show-ref --verify --quiet "refs/heads/$branch"; then
    :
  else
    git branch "$branch"
  fi
}

create_worktree() {
  local name="$1"
  local branch="$2"
  local path="$TEAM_ROOT/$name"
  ensure_branch "$branch"
  if [ -d "$path/.git" ] || git worktree list | grep -q "[[:space:]]$path$"; then
    echo "worktree exists: $path"
  else
    git worktree add "$path" "$branch"
  fi
}

create_worktree lead feature/pvc-design-lead
create_worktree brainstorm feature/pvc-design-brainstorm
create_worktree platform feature/pvc-design-platform
create_worktree review feature/pvc-design-review

echo "Created or verified worktrees under: $TEAM_ROOT"
printf '%s\n' \
  "$TEAM_ROOT/lead" \
  "$TEAM_ROOT/brainstorm" \
  "$TEAM_ROOT/platform" \
  "$TEAM_ROOT/review"
