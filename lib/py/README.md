# lib/py — standalone Python scripts

Each file under `scripts/` is a **complete** runnable script (same idea as `lib/sh` / `lib/ps1`).

```
lib/py/
├── README.md
└── scripts/
    ├── install_git.py
    ├── init_system.py
    └── …
```

## Run

```bash
# local
python3 lib/py/scripts/install_git.py
./bin/krun install_git.py

# remote
curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/py/scripts/install_git.py | sudo python3
```

No `registry` / `handlers` / `bootstrap` package. Open the file → see the logic.

## Structure (per script)

- Copyright + curl one-liner
- Small helpers (`platform` / `run` / `install_packages` / …) inlined when needed
- `centos()` / `debian()` / `mac()` → `common()`
- `main()` entry

## Add a script

1. Copy [templates/python.py.erb](../../templates/python.py.erb) → `scripts/<action>_<name>.py` (or hand-write)
2. Fill `common()` (and platform overrides if needed)
3. `rake lib:manifest`
