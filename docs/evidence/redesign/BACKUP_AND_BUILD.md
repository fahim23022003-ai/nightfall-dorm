# Verified source backup and local build — 11 November 2026

Feature/content commit: `f497ca105debe69934fe9fc6c0ed3c8a125d9b44`.

Executed `git push --set-upstream origin work`, exit0:

```text
To https://github.com/fahim23022003-ai/nightfall-dorm.git
   ac31768..f497ca1  work -> work
branch 'work' set up to track 'origin/work'.
```

Executed `git ls-remote origin refs/heads/work`, exit0:

```text
f497ca105debe69934fe9fc6c0ed3c8a125d9b44 refs/heads/work
```

This exactly matched local HEAD. Source, original local art, tests, screenshots and reports are backed up to the existing private branch. No force push or public release/deployment was used. This record is a documentation follow-up; final task response reports its own verified pushed tip.

## Actual local artifact hashes

EXE/ZIP are ignored local build artifacts, **not** GitHub-hosted releases. Export succeeded and Linux loaded embedded resources from an empty directory; native Windows runtime remains UNVERIFIED.

- `/workspace/NightfallDorm-CartoonRedesign-Windows-x64.zip`: 44765870 bytes; SHA256 `ee92a239e411e50f0062b6dac044c1d70d2aea0c77086ec79d633bbb3de142fa`.
- `builds/windows/NightfallDorm.exe`: 113303712 bytes; SHA256 `75856588e54b902efbe975b3491dbee4be9d70e3402dc63849b062427c07f40d`.
