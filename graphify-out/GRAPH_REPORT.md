# Graph Report - krun  (2026-07-02)

## Corpus Check
- 103 files · ~24,125 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 368 nodes · 405 edges · 101 communities (98 shown, 3 thin omitted)
- Extraction: 91% EXTRACTED · 9% INFERRED · 0% AMBIGUOUS · INFERRED: 35 edges (avg confidence: 0.8)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `2f89af5e`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- [[_COMMUNITY_Community 0|Community 0]]
- [[_COMMUNITY_Community 1|Community 1]]
- [[_COMMUNITY_Community 2|Community 2]]
- [[_COMMUNITY_Community 3|Community 3]]
- [[_COMMUNITY_Community 4|Community 4]]
- [[_COMMUNITY_Community 5|Community 5]]
- [[_COMMUNITY_Community 6|Community 6]]
- [[_COMMUNITY_Community 7|Community 7]]
- [[_COMMUNITY_Community 8|Community 8]]
- [[_COMMUNITY_Community 9|Community 9]]
- [[_COMMUNITY_Community 10|Community 10]]
- [[_COMMUNITY_Community 11|Community 11]]
- [[_COMMUNITY_Community 12|Community 12]]
- [[_COMMUNITY_Community 13|Community 13]]
- [[_COMMUNITY_Community 14|Community 14]]
- [[_COMMUNITY_Community 16|Community 16]]

## God Nodes (most connected - your core abstractions)
1. `SystemInit` - 30 edges
2. `require_root()` - 17 edges
3. `Krun - 运维自动化脚本工具集` - 14 edges
4. `install_packages()` - 12 edges
5. `write_text()` - 12 edges
6. `curl_pipe()` - 8 edges
7. `has_cmd()` - 8 edges
8. `常见问题` - 8 edges
9. `run()` - 7 edges
10. `write_if_changed()` - 6 edges

## Surprising Connections (you probably didn't know these)
- `_prometheus_exporter()` --calls--> `write_if_changed()`  [INFERRED]
  lib/py/krun/registry.py → lib/py/krun/common.py
- `_prometheus_exporter()` --calls--> `service_enable()`  [INFERRED]
  lib/py/krun/registry.py → lib/py/krun/common.py
- `config_timezone()` --calls--> `require_root()`  [INFERRED]
  lib/py/krun/handlers/config.py → lib/py/krun/common.py
- `config_fstab_guide()` --calls--> `require_root()`  [INFERRED]
  lib/py/krun/handlers/config.py → lib/py/krun/common.py
- `deploy_node_exporter()` --calls--> `require_root()`  [INFERRED]
  lib/py/krun/handlers/ops.py → lib/py/krun/common.py

## Communities (101 total, 3 thin omitted)

### Community 0 - "Community 0"
Cohesion: 0.17
Nodes (6): has_cmd(), main(), read_os_release(), run(), SystemInit, write_text()

### Community 1 - "Community 1"
Cohesion: 0.14
Nodes (22): install_awscli(), install_base_packages(), install_cloud_cli(), install_cursor_cli(), install_devbox(), install_docker(), install_github_tool(), install_pkg() (+14 more)

### Community 2 - "Community 2"
Cohesion: 0.08
Nodes (24): code:block1 (______), code:bash (krun list), code:bash (# 1. 在 krun/handlers/ 添加逻辑), code:bash (# 一键安装（自动检测平台并安装依赖）), code:bash (# Docker 安装), code:bash (# 克隆仓库), Krun - 运维自动化脚本工具集, Python 模块职责 (+16 more)

### Community 3 - "Community 3"
Cohesion: 0.12
Nodes (14): config_disk_data(), config_fstab_guide(), config_locale(), config_rpm_repo(), config_ssh_harden(), config_ssh_keys(), config_timezone(), disable_firewall_selinux() (+6 more)

### Community 4 - "Community 4"
Cohesion: 0.16
Nodes (8): _cache_stale(), _fetch(), _read_version(), _remote_version(), setup(), main(), _prometheus_exporter(), run_script()

### Community 5 - "Community 5"
Cohesion: 0.15
Nodes (13): code:bash (# 立即强制刷新), code:bash (# 重新运行安装脚本即可（会自动下载最新版本）), code:bash (# 使用 krun 工具查看脚本列表), code:bash (# 删除安装目录), code:bash (# 是的，install.sh 会自动检测并安装所需依赖：), Q: curl 执行报 ModuleNotFoundError？, Q: 如何卸载 krun？, Q: 如何更新 krun 工具？ (+5 more)

### Community 6 - "Community 6"
Cohesion: 0.31
Nodes (9): check_ip_quality(), _grade_latency(), NodeResult, _parse_targets(), _ping_avg(), _print_report(), Network quality checks against public service nodes., IP_TARGETS=地区:IP:描述,... 覆盖默认节点；仅 IP 则用自定义标签。 (+1 more)

### Community 7 - "Community 7"
Cohesion: 0.38
Nodes (8): krun::install::centos(), krun::install::debian(), krun::install::install_binary(), krun::install::install_deps_centos(), krun::install::install_deps_debian(), krun::install::install_deps_mac(), krun::install::install_from_package(), krun::install::mac()

### Community 8 - "Community 8"
Cohesion: 0.20
Nodes (10): code:block2 (krun/), code:mermaid (flowchart TB), code:mermaid (sequenceDiagram), code:mermaid (sequenceDiagram), code:mermaid (flowchart LR), 核心特性, 目录结构, 调用流程 (+2 more)

### Community 9 - "Community 9"
Cohesion: 0.22
Nodes (9): code:bash (# 1. 安装 krun 工具), code:bash (# 修复 Rocky Linux 9 的 IPv6 源导致的包管理器问题), code:bash (krun install_docker.py), code:bash (# 自动格式化并挂载数据盘到 /data), Kubernetes 环境搭建, Rocky Linux 9 修复 IPv6 源问题, 使用示例, 新服务器初始化 (+1 more)

### Community 10 - "Community 10"
Cohesion: 0.48
Nodes (5): krun::install::python3::centos(), krun::install::python3::common(), krun::install::python3::debian(), krun::install::python3::mac(), krun::install::python3::verify_installation()

### Community 11 - "Community 11"
Cohesion: 0.67
Nodes (3): _fetch_version(), prefetch_path(), Ensure sys.path contains lib/py (local) or ~/.cache/krun/py (remote).

### Community 12 - "Community 12"
Cohesion: 0.50
Nodes (3): code:block1 (lib/py/), code:mermaid (flowchart LR), lib/py layout

## Knowledge Gaps
- **37 isolated node(s):** `sh`, `py`, `code:block1 (______)`, `code:block2 (krun/)`, `code:mermaid (flowchart TB)` (+32 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **3 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `Krun - 运维自动化脚本工具集` connect `Community 2` to `Community 8`, `Community 9`, `Community 5`?**
  _High betweenness centrality (0.020) - this node is a cross-community bridge._
- **Why does `require_root()` connect `Community 3` to `Community 1`?**
  _High betweenness centrality (0.013) - this node is a cross-community bridge._
- **Why does `_prometheus_exporter()` connect `Community 4` to `Community 1`, `Community 3`?**
  _High betweenness centrality (0.012) - this node is a cross-community bridge._
- **Are the 13 inferred relationships involving `require_root()` (e.g. with `config_rpm_repo()` and `config_timezone()`) actually correct?**
  _`require_root()` has 13 INFERRED edges - model-reasoned connections that need verification._
- **Are the 4 inferred relationships involving `install_packages()` (e.g. with `install_zsh()` and `install_pkg()`) actually correct?**
  _`install_packages()` has 4 INFERRED edges - model-reasoned connections that need verification._
- **What connects `sh`, `py`, `Krun Python core: bootstrap, registry, handlers.` to the rest of the system?**
  _43 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Community 1` be split into smaller, more focused modules?**
  _Cohesion score 0.13756613756613756 - nodes in this community are weakly interconnected._