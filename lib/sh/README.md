# lib/sh — standalone bash scripts

Each `*.sh` is a **full bash implementation** (not a Python wrapper). Naming matches Python stems: `init_system.sh` ↔ `init_system.py`.

Logic in `lib/sh` and `lib/py` is maintained separately. Prefer editing the language you execute.

## Curl

```bash
curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/sh/init_system.sh | sudo bash
```

## Notes

- Bootstrap without Python: `install_python3.sh`
- Offline node_exporter: `install_node_exporter_offline.sh`
