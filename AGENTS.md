# PVC migration design team rules

## Mission
Design a safe approach for migrating Kubernetes/OpenShift workloads from existing PVC-backed storage to a new provided HNAS-backed StorageClass, namespace by namespace.

Automation is assumed to be initiated from a remote workstation using Ansible.

The team's current deliverable is a **reviewable design package**, not a production implementation and not an executed migration.

## Minimal fixed constraints
- Scope is Kubernetes/OpenShift PVC migration.
- Target storage is a provided HNAS StorageClass.
- Migration sequencing is namespace by namespace.
- Automation is triggered from a remote workstation through Ansible.
- The team must stop after producing a design package for review.

## Deliberate non-instructions
The team is not being told:
- which programming language to use
- whether the final solution should be a CLI, operator, playbook set, or hybrid
- the copy mechanism
- the exact workflow shape
- the final artifact structure

Those must be explored and justified during brainstorming and design.

## Phase gate
The team must work in this order:
1. discovery and framing
2. brainstorming and option generation
3. design comparison and trade-offs
4. recommended design package
5. wait for human review

No implementation beyond lightweight notes, sketches, diagrams, pseudocode, or document scaffolding unless explicitly approved later.

## Output expectations
The design package should capture:
1. problem framing
2. assumptions
3. discovered constraints
4. design options
5. trade-offs
6. key risks and mitigations
7. recommended approach
8. operator workflow concept
9. validation concept
10. open questions requiring review
11. explicit non-goals

## Coordination
- The parent session is the control room.
- The lead keeps a short status board with streams: framing, options, risks, recommendation, review pack.
- Specialists should first report findings and alternatives, not jump directly to implementation.
- Parallel workers should avoid editing the same files.

## Safety and realism
- Treat data safety and operational clarity as primary requirements.
- Distinguish facts from assumptions.
- Call out where application-specific handling may be required.
- Any shell command that could change cluster state must remain approval-gated.
- Do not commit or push from agents.

## Handoff format
Each specialist response must include:
1. Facts observed
2. Assumptions made
3. Options considered
4. Risks or blockers
5. Recommendation or next question
6. Whether the output is brainstorming, design candidate, or review-ready
