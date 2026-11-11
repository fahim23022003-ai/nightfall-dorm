# Codex Cloud setup

Use the existing `/workspace/nightfall-dorm` checkout. Each cloud task is already isolated; do not create a Git worktree unless explicitly requested.

Godot 4.6.3 stable is installed at `/usr/local/bin/godot` on the validated machine. No external assets, package dependencies, credentials, database or network services are required to develop or run this project. Future machines need a compatible Godot 4 installation.

Run the complete check from the checkout:

```sh
bash tools/check.sh
```

The wrapper sets writable XDG data, configuration and cache directories under `/workspace` unless the caller has supplied them. It imports the project, runs production-model assertions, UI scene tests, twelve deterministic match simulations, and main-scene startup. It preserves command failures and checks logs for engine/script errors. Generated logs are under ignored `artifacts/`.

For interactive play, use a graphical display and run:

```sh
export XDG_DATA_HOME=/workspace/runtime-data
export XDG_CONFIG_HOME=/workspace/runtime-config
export XDG_CACHE_HOME=/workspace/runtime-cache
mkdir -p "$XDG_DATA_HOME" "$XDG_CONFIG_HOME" "$XDG_CACHE_HOME"
godot --path /workspace/nightfall-dorm
```

See [GRAPHICAL_TESTING.md](GRAPHICAL_TESTING.md) for the software-display setup used for captured screenshots. Live display processes must restart in a new cloud task; installed files alone do not preserve them.

The onboarding draft API returned `INVALID_ARGUMENT` on configuration reads and could not confirm a draft save during this task. These instructions are retained in the repository as a fallback. Repository files and current-machine validation do not establish that a reusable environment configuration was saved or published.
