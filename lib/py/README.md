# lib/py 目录说明

## 结构

```
lib/py/
├── krun/                 # 核心库（不直接 curl）
│   ├── bootstrap.py      # 远程执行：下载/缓存 krun 包
│   ├── common.py         # platform、install_packages、run()
│   ├── registry.py       # SCRIPTS 注册表
│   └── handlers/
│       ├── install.py    # 安装类
│       ├── config.py     # 配置类
│       ├── ops.py        # 运维类
│       └── system.py     # init_system
├── scripts/              # 可执行入口（curl | python3）
└── generate_wrappers.py  # rake lib:py:generate
```

## 调用关系

```mermaid
flowchart LR
    scripts["scripts/*.py"] --> bootstrap["krun/bootstrap"]
    bootstrap --> registry["krun/registry"]
    registry --> handlers["krun/handlers/*"]
    handlers --> common["krun/common"]
```

- **入口** `scripts/`：只负责 bootstrap + `run_script(name)`，不含业务逻辑
- **逻辑** `handlers/`：实现具体功能，在 `registry.py` 注册
- **新增脚本**：handler → registry → `rake lib:py:generate`
