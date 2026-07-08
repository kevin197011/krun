# lib/sh — shell entrypoints

Most `*.sh` files here are **generated thin wrappers**. They only ensure `python3` exists, then run the matching `lib/py/scripts/*.py` (local path or curl).

Do not hand-edit generated wrappers. Run:

```bash
rake lib:sh:generate
# or both:
rake lib:generate
```

## Native (hand-maintained)

| Script | Why native |
|--------|------------|
| `install-python3.sh` | Bootstrap when Python is missing |
| `install-node-exporter-offline.sh` | Offline tarball install (no GitHub) |

## Curl

```bash
curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/sh/init-system.sh | sudo bash
# equivalent to:
curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/py/scripts/init_system.py | sudo python3
```
