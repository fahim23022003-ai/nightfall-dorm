# Nightfall Dorm development

Use Godot 4.x and GDScript; current verified engine is 4.6.3. This is an original game: do not copy Haunted Dorm assets or reuse Willow Hearth code. Keep values data-driven in Catalog, game rules in model components, and presentation in Game/GameInterface. Avoid introducing paid assets, network runtime dependencies or unrelated features.

Each Codex task is already isolated. Use the existing repository checkout, not an extra Git worktree unless the user requests it. Before editing inspect status and preserve existing work. Run headless import, model tests, fixed-seed simulations and scene smoke after rule changes. Use writable XDG directories in restricted cloud sessions (README). Check command exit status and Godot error output; report failed, unrun and graphical checks honestly. Screenshots require a real display. Do not publish or deploy without explicit user permission.

For parallel work assign one primary production owner, QA ownership of tests/report, reference ownership of parity documents, and visual auditor ownership of visual/limitation reports. Coordinate changes rather than editing the same files concurrently.
