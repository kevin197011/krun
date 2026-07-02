# scripts/ — generated entrypoints only

Do not edit `*.py` here by hand. Run `rake lib:py:generate`.

Each file is a thin stub:

```
scripts/foo.py          # curl URL + SCRIPT name
    ↓ prefetch (inline) # stage 1: sys.path
    ↓ krun.entry.main   # stage 2: bootstrap cache
    ↓ krun.registry     # stage 3: dispatch handler
    ↓ krun/handlers/    # business logic
```

| Layer | Module | Role |
|-------|--------|------|
| 1 | `krun/prefetch.py` | Put krun on `sys.path` (curl pipe) |
| 2 | `krun/bootstrap.py` | Download/sync cached `krun/` |
| 3 | `krun/entry.py` | `main(script)` unified entry |
| 4 | `krun/registry.py` | Name → handler |
| 5 | `krun/handlers/*` | Implementation |
