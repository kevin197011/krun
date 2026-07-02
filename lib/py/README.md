# lib/py layout

```
lib/py/
├── krun/                 # core library (not curl entrypoints)
│   ├── bootstrap.py      # remote cache for curl | python3
│   ├── common.py         # platform, packages, run(), etc.
│   ├── registry.py       # script name -> handler
│   └── handlers/         # install / config / ops / system logic
├── scripts/              # thin entrypoints (curl | python3)
│   ├── install_docker.py
│   └── ...
└── generate_wrappers.py  # dev tool: rake lib:py:generate
```

- **curl / krun** run files under `scripts/`
- **logic** lives in `krun/handlers/`; register in `krun/registry.py`
- add a script: handler → `registry.py` → `rake lib:py:generate`
