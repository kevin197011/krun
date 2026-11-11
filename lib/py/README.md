# lib/py — standalone Python scripts

Each `*.py` here is a **complete** runnable script (same layout as `lib/sh` / `lib/ps1`).

## Run

```bash
python3 lib/py/install_git.py
./bin/krun install_git.py

curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/py/install_git.py | sudo python3
```

## Structure (per script)

- Copyright + curl one-liner
- Helpers inlined when needed
- `centos()` / `debian()` / `mac()` → `common()`
- `main()` entry

## Add a script

1. Copy `templates/python.py.erb` → `lib/py/<action>_<name>.py`
2. Fill `common()`
3. `rake lib:manifest`
