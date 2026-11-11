# Nightfall Dorm development

Use Godot 4.x and GDScript; current verified engine is 4.6.3. This is an original game: do not copy Haunted Dorm assets or reuse Willow Hearth code. Keep values data-driven in Catalog, game rules in model components, and presentation in Game/GameInterface. Avoid introducing paid assets, network runtime dependencies or unrelated features.

Each Codex task is already isolated. Use the existing repository checkout, not an extra Git worktree unless the user requests it. Before editing inspect status and preserve existing work. Run headless import, model tests, fixed-seed simulations and scene smoke after rule changes. Use writable XDG directories in restricted cloud sessions (README). Check command exit status and Godot error output; report failed, unrun and graphical checks honestly. Screenshots require a real display. Do not publish or deploy without explicit user permission.

Use one main development agent for routine implementation, fixes, documentation and checkpoints. Keep four specialist roles available, but activate only the specialist needed for an independent review that adds concrete value. Do not keep all four active continuously, repeat completed reference research without new access/evidence, or launch full-project reviews for routine edits.

- Agent A — Gameplay Auditor: verified reference comparison at major gameplay milestones; distinguish reference evidence from assumptions.
- Agent B — Developer: production implementation and bug fixes; the main agent normally performs this role without a separate worker.
- Agent C — QA Tester: independent testing for major rule/AI/economy changes, unexplained failures or release candidates.
- Agent D — Visual Auditor: actual rendered inspection after important layout, input or visual changes when graphics are available; label unexecuted checks UNVERIFIED.

When delegation is justified, give each agent a bounded task and exclusive file ownership. Keep one production-code owner, send independent findings to that owner, and stop specialist work after the requested evidence is delivered. Run focused checks after small changes, the regular suite after gameplay changes, and the extended matrix at balance milestones or an explicitly requested checkpoint. Preserve previous results; repeat checks only for changes, failures, or requested fresh verification. Start future sessions by reading docs/PROGRESS_CHECKPOINT.md and inspecting Git status, rather than restarting the completed audit. Private Git backup is allowed only when explicitly authorized; verify the remote branch SHA after a push and never infer backup success from a local commit.
