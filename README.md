# OpenCode PVC migration design team kit

This kit sets up an OpenCode control room for an intentionally **lightly constrained** mission:

Explore and design a safe way to migrate Kubernetes/OpenShift PVC-backed workloads to a provided HNAS-backed StorageClass, namespace by namespace, using automation that runs from a remote workstation through Ansible.

The team must **not build or execute the final migration solution yet**. The first mission is:
1. brainstorm
2. identify options and risks
3. converge on a design
4. produce a review package
5. stop and wait for human review before implementation

## What is included
- `opencode.json` with specialized agents
- `AGENTS.md` with scope, constraints, and stage gates
- prompts for lead, planner, reviewer, tester, explorer, and platform-expert
- `scripts/setup-worktrees.sh` to create isolated worktrees
- `scripts/start-opencode-team.sh` to launch a tmux control room
- `tui.json` with simple ergonomic keybinds

## Team layout
- `lead` pane: coordination, brainstorming flow, synthesis
- `brainstorm` pane: open option generation and architecture exploration
- `platform` pane: Kubernetes/OpenShift/Linux/Ansible/storage specialist
- `review` pane: challenge assumptions, risk, and operator experience

## Design-first operating model
The team should receive only these firm constraints:
- platform scope: Kubernetes/OpenShift PVC migration to a new provided HNAS StorageClass
- migrations happen namespace by namespace
- automation is initiated from a remote workstation through Ansible
- the team is producing a design package for review, not a production implementation

Everything else should be discovered, debated, and justified by the team.

## Expected first-phase outputs
- problem framing and assumptions
- option space and alternatives
- risks and unknowns
- design decision candidates
- proposed operator workflow
- validation approach
- open questions for review
- recommendation, with rationale

## Review package
The goal of phase 1 is a reviewable design pack such as:
- `docs/brainstorm-notes.md`
- `docs/design-options.md`
- `docs/proposed-architecture.md`
- `docs/open-questions.md`
- `docs/review-checklist.md`
- `docs/non-goals.md`

## Install into a repo
Copy these files into the repo root:
- `opencode.json`
- `tui.json`
- `AGENTS.md`
- `prompts/`
- `scripts/`

Then run:

```bash
chmod +x scripts/*.sh
scripts/setup-worktrees.sh /path/to/your/repo
scripts/start-opencode-team.sh /path/to/your/repo-team
```

## Worktree names
The setup script creates these worktrees:
- `lead`
- `brainstorm`
- `platform`
- `review`

## Suggested first prompt for the lead pane
```text
You are leading a design-first session.
Scope: design a safe approach for namespace-by-namespace migration of PVC-backed workloads to a provided HNAS StorageClass in Kubernetes/OpenShift, with automation initiated from a remote workstation via Ansible.
Do not lock into a tool or implementation too early.
Run this in stages:
1. brainstorm the option space
2. identify assumptions and unknowns
3. compare alternatives and trade-offs
4. converge on a recommended design
5. produce a review pack
6. stop and wait for approval before implementation
Require every specialist to separate facts, assumptions, risks, and recommendations.
```
