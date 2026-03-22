#!/usr/bin/env bash
set -euo pipefail

TEAM_ROOT="${1:-$(pwd)}"
TEAM_ROOT="$(cd "$TEAM_ROOT" && pwd)"
SESSION_NAME="${2:-opencode-pvc-design}"

need_dir() {
  [ -d "$1" ] || { echo "missing directory: $1" >&2; exit 1; }
}

need_dir "$TEAM_ROOT/lead"
need_dir "$TEAM_ROOT/brainstorm"
need_dir "$TEAM_ROOT/platform"
need_dir "$TEAM_ROOT/review"

if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
  echo "tmux session already exists: $SESSION_NAME"
  echo "Attach with: tmux attach -t $SESSION_NAME"
  exit 0
fi

tmux new-session -d -s "$SESSION_NAME" -c "$TEAM_ROOT/lead"
tmux rename-window -t "$SESSION_NAME":0 control-room

tmux split-window -h -t "$SESSION_NAME":0 -c "$TEAM_ROOT/brainstorm"
tmux split-window -v -t "$SESSION_NAME":0.0 -c "$TEAM_ROOT/platform"
tmux split-window -v -t "$SESSION_NAME":0.1 -c "$TEAM_ROOT/review"

tmux select-layout -t "$SESSION_NAME":0 tiled

tmux send-keys -t "$SESSION_NAME":0.0 'clear; echo "Lead pane"; echo "Suggested agent: build"; echo "Mission: run brainstorm -> design -> review pack"' C-m
tmux send-keys -t "$SESSION_NAME":0.1 'clear; echo "Brainstorm pane"; echo "Suggested agent: plan or build"; echo "Mission: generate and compare solution options without locking in too early"' C-m
tmux send-keys -t "$SESSION_NAME":0.2 'clear; echo "Platform pane"; echo "Suggested agent: platform-expert"; echo "Mission: K8s/OpenShift/HNAS/Ansible/storage realities and trade-offs"' C-m
tmux send-keys -t "$SESSION_NAME":0.3 'clear; echo "Review pane"; echo "Suggested agent: reviewer or tester"; echo "Mission: challenge assumptions and make the design review-ready"' C-m

tmux display-message -t "$SESSION_NAME":0 "Run opencode in each pane with the suggested agent."
tmux attach -t "$SESSION_NAME"
