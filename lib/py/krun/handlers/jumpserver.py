"""JumpServer: SSH idle timeout fix."""

from __future__ import annotations

import os
import re
import shutil
import subprocess
import time
from datetime import datetime
from pathlib import Path

from krun.common import has_cmd, require_root

CONTAINER_NAME = "jumpserver"

MOUNTS = (
    "./config/koko/config.yml:/opt/koko/config.yml:ro",
    "./config/nginx/includes/koko.conf:/etc/nginx/includes/koko.conf:ro",
    "./config/nginx/includes/core.conf:/etc/nginx/includes/core.conf:ro",
    "./config/nginx/includes/lion.conf:/etc/nginx/includes/lion.conf:ro",
)


def _log(msg: str) -> None:
    print(f"[{datetime.now():%F %T}] {msg}")


def _die(msg: str) -> None:
    _log(f"ERROR: {msg}")
    raise SystemExit(1)


def _env_int(name: str, default: int) -> int:
    raw = os.environ.get(name)
    return int(raw) if raw else default


def _backup(path: Path, backup_dir: Path) -> None:
    if not path.is_file():
        return
    backup_dir.mkdir(parents=True, exist_ok=True)
    dest = backup_dir / path.name
    shutil.copy2(path, dest)
    _log(f"已备份: {path} -> {dest}")


def _read_bootstrap_token(compose_file: Path) -> str:
    token = os.environ.get("BOOTSTRAP_TOKEN", "").strip()
    if token:
        return token
    if not compose_file.is_file():
        _die("未找到 compose.yml，无法读取 BOOTSTRAP_TOKEN")
    text = compose_file.read_text(encoding="utf-8")
    match = re.search(r'^\s+BOOTSTRAP_TOKEN:\s*"?([^"\n]+)"?', text, re.M)
    if not match:
        _die("无法从 compose.yml 解析 BOOTSTRAP_TOKEN，请手动 export BOOTSTRAP_TOKEN=...")
    return match.group(1)


def _patch_compose(
    compose_file: Path,
    backup_dir: Path,
    *,
    idle_min: int,
    session_hr: int,
) -> None:
    _log("步骤 1/5: 修改 compose.yml")
    if not compose_file.is_file():
        _die(f"compose.yml 不存在: {compose_file}")
    _backup(compose_file, backup_dir)

    text = compose_file.read_text(encoding="utf-8")
    if re.search(r"^\s*SECURITY_MAX_IDLE_TIME:", text, re.M):
        text = re.sub(
            r'^(\s*SECURITY_MAX_IDLE_TIME:\s*).*$',
            rf'\1"{idle_min}"',
            text,
            count=1,
            flags=re.M,
        )
        _log(f"  已更新 SECURITY_MAX_IDLE_TIME={idle_min}")
    else:
        block = (
            f'      # SSH/终端闲置超时（分钟），默认 30 分钟\n'
            f'      SECURITY_MAX_IDLE_TIME: "{idle_min}"\n'
            f'      # 单次会话最大在线时长（小时），默认 24 小时\n'
            f'      SECURITY_MAX_SESSION_TIME: "{session_hr}"'
        )
        text = re.sub(
            r"(SESSION_EXPIRE_AT_BROWSER_CLOSE:.*\n)",
            rf"\1{block}\n",
            text,
            count=1,
        )
        _log(f"  已添加 SECURITY_MAX_IDLE_TIME={idle_min}, SECURITY_MAX_SESSION_TIME={session_hr}")

    if re.search(r"^\s*SECURITY_MAX_SESSION_TIME:", text, re.M):
        text = re.sub(
            r'^(\s*SECURITY_MAX_SESSION_TIME:\s*).*$',
            rf'\1"{session_hr}"',
            text,
            count=1,
            flags=re.M,
        )

    for mount in MOUNTS:
        if mount in text:
            _log(f"  volume 已存在: {mount}")
            continue
        text = re.sub(
            r"(- \./config/jumpserver:/opt/jumpserver/config\n)",
            rf"\1      - {mount}\n",
            text,
            count=1,
        )
        _log(f"  已添加 volume: {mount}")

    compose_file.write_text(text, encoding="utf-8")


def _koko_config(
    js_dir: Path,
    backup_dir: Path,
    compose_file: Path,
    *,
    alive_interval: int,
    retry_max: int,
) -> None:
    _log("步骤 2/5: 创建 KoKo 配置")
    token = _read_bootstrap_token(compose_file)
    koko_file = js_dir / "config/koko/config.yml"
    _backup(koko_file, backup_dir)
    content = f"""# KoKo SSH 组件配置
CORE_HOST: http://127.0.0.1:8080
BOOTSTRAP_TOKEN: {token}

# 向 SSH 客户端发送心跳间隔（秒），防止网络/NAT 超时断开
CLIENT_ALIVE_INTERVAL: {alive_interval}
# 心跳重试次数
RETRY_ALIVE_COUNT_MAX: {retry_max}
"""
    koko_file.parent.mkdir(parents=True, exist_ok=True)
    koko_file.write_text(content, encoding="utf-8")
    _log(f"  已写入: {koko_file}")


def _nginx_ws(timeout: int) -> str:
    return f"""location /ws/ {{
    proxy_pass http://core:8080;
    proxy_buffering off;
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection "upgrade";
    proxy_set_header Host $host;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_ignore_client_abort on;
    proxy_connect_timeout {timeout};
    proxy_send_timeout {timeout};
    proxy_read_timeout {timeout};
    send_timeout {timeout};
}}
"""


def _nginx_proxy_location(path: str, upstream: str, *, timeout: int) -> str:
    return f"""location {path} {{
    proxy_pass {upstream};
    proxy_buffering off;
    proxy_http_version 1.1;
    proxy_request_buffering off;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection "upgrade";
    proxy_set_header Host $host;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_ignore_client_abort on;
    proxy_connect_timeout {timeout};
    proxy_send_timeout {timeout};
    proxy_read_timeout {timeout};
    send_timeout {timeout};
}}
"""


def _nginx_configs(js_dir: Path, backup_dir: Path, *, timeout: int) -> None:
    _log("步骤 3/5: 创建 Nginx 长超时配置")
    nginx_dir = js_dir / "config/nginx/includes"
    nginx_dir.mkdir(parents=True, exist_ok=True)

    koko = _nginx_proxy_location("/koko/", "http://koko:5000", timeout=timeout)
    lion = _nginx_proxy_location("/lion/", "http://lion:8081", timeout=timeout)
    core = f"""location /static/ {{
    root /opt/jumpserver/data/;
}}

location /private-media/ {{
    internal;
    alias /opt/jumpserver/data/media/;
}}

{_nginx_ws(timeout)}
location ~ ^/(core|api|media)/ {{
    proxy_pass http://core:8080;
    proxy_set_header Host $http_host;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_ignore_client_abort on;
    proxy_connect_timeout {timeout};
    proxy_send_timeout {timeout};
    proxy_read_timeout {timeout};
    send_timeout {timeout};
}}
"""

    for name, content in (("koko.conf", koko), ("core.conf", core), ("lion.conf", lion)):
        path = nginx_dir / name
        _backup(path, backup_dir)
        path.write_text(content, encoding="utf-8")

    _log(f"  已写入: {nginx_dir}/koko.conf, core.conf, lion.conf")


def _container_status() -> str:
    proc = subprocess.run(
        [
            "docker", "inspect", CONTAINER_NAME,
            "--format={{if .State.Health}}{{.State.Health.Status}}{{else}}{{.State.Status}}{{end}}",
        ],
        capture_output=True,
        text=True,
        check=False,
    )
    return proc.stdout.strip() or "missing"


def _restart(js_dir: Path, *, wait_sec: int, interval: int) -> None:
    _log("步骤 4/5: 重启 JumpServer 容器")
    if not has_cmd("docker"):
        _die("缺少命令: docker")
    subprocess.run(
        ["docker", "compose", "up", "-d", CONTAINER_NAME],
        cwd=js_dir,
        check=False,
    )
    _log(f"  已执行: docker compose up -d {CONTAINER_NAME}")

    elapsed = 0
    status = "unknown"
    while elapsed < wait_sec:
        status = _container_status()
        _log(f"  健康检查: {status} ({elapsed}s/{wait_sec}s)")
        if status == "healthy":
            _log("  JumpServer 已就绪")
            return
        if status in {"missing", "exited"}:
            _die(f"容器未正常运行，请检查: docker logs {CONTAINER_NAME}")
        time.sleep(interval)
        elapsed += interval
    _die(f"等待健康检查超时 ({wait_sec}s)，当前状态: {status}")


def _docker_exec(args: list[str]) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        ["docker", "exec", CONTAINER_NAME, *args],
        capture_output=True,
        text=True,
        check=False,
    )


def _verify() -> None:
    _log("步骤 5/5: 验证配置")

    _log("  [env] 容器环境变量:")
    proc = _docker_exec(["env"])
    env_lines = [ln for ln in proc.stdout.splitlines() if ln.startswith("SECURITY_MAX_")]
    if not env_lines:
        _die("未找到 SECURITY_MAX_* 环境变量")
    for ln in env_lines:
        print(f"    {ln}")

    _log("  [django] 运行时安全策略:")
    django = _docker_exec([
        "/opt/jumpserver/.venv/bin/python3", "-c",
        "import os,django;os.environ.setdefault('DJANGO_SETTINGS_MODULE','jumpserver.settings');"
        "import sys;sys.path.insert(0,'/opt/jumpserver/apps');django.setup();"
        "from django.conf import settings;"
        "print('SECURITY_MAX_IDLE_TIME:',settings.SECURITY_MAX_IDLE_TIME);"
        "print('SECURITY_MAX_SESSION_TIME:',settings.SECURITY_MAX_SESSION_TIME)",
    ])
    for ln in django.stdout.splitlines():
        print(f"    {ln}")

    _log("  [koko] 心跳配置:")
    koko = _docker_exec(["grep", "-E", "CLIENT_ALIVE|RETRY_ALIVE", "/opt/koko/config.yml"])
    for ln in koko.stdout.splitlines():
        print(f"    {ln}")

    _log("  [nginx] 代理超时:")
    nginx = _docker_exec([
        "grep", "-h", "proxy_read_timeout",
        "/etc/nginx/includes/koko.conf",
        "/etc/nginx/includes/core.conf",
        "/etc/nginx/includes/lion.conf",
    ])
    for ln in nginx.stdout.splitlines()[:3]:
        print(f"    {ln}")

    if _docker_exec(["curl", "-sf", "http://localhost/api/health/"]).returncode == 0:
        _log("  [api] /api/health/ OK")
    else:
        _die("API 健康检查失败")
    _log("验证完成")


def config_jumpserver_ssh_timeout() -> None:
    """Fix JumpServer SSH/Web terminal idle disconnect (~30 min default)."""
    require_root()

    js_dir = Path(os.environ.get("JUMPSERVER_DIR", "/opt/jumpserver"))
    compose_file = js_dir / "compose.yml"
    backup_dir = js_dir / "backups" / datetime.now().strftime("%Y%m%d_%H%M%S")

    idle_min = _env_int("SECURITY_MAX_IDLE_TIME", 480)
    session_hr = _env_int("SECURITY_MAX_SESSION_TIME", 24)
    alive_interval = _env_int("CLIENT_ALIVE_INTERVAL", 60)
    retry_max = _env_int("RETRY_ALIVE_COUNT_MAX", 10)
    nginx_timeout = _env_int("NGINX_PROXY_TIMEOUT", 28800)
    wait_sec = _env_int("HEALTH_WAIT_SECONDS", 240)
    interval = _env_int("HEALTH_INTERVAL_SECONDS", 10)

    _log("开始修复 JumpServer SSH 闲置超时问题")
    _log(f"工作目录: {js_dir}")

    if not js_dir.is_dir():
        _die(f"JumpServer 目录不存在: {js_dir}")
    if not compose_file.is_file():
        _die(f"compose.yml 不存在: {compose_file}")

    _patch_compose(compose_file, backup_dir, idle_min=idle_min, session_hr=session_hr)
    _koko_config(
        js_dir, backup_dir, compose_file,
        alive_interval=alive_interval, retry_max=retry_max,
    )
    _nginx_configs(js_dir, backup_dir, timeout=nginx_timeout)
    _restart(js_dir, wait_sec=wait_sec, interval=interval)
    _verify()

    print(f"""
========================================
JumpServer SSH 闲置超时修复完成
========================================
目录:               {js_dir}
备份目录:           {backup_dir}
闲置超时:           {idle_min} 分钟
会话最大时长:       {session_hr} 小时
SSH 心跳间隔:       {alive_interval} 秒
Nginx 代理超时:     {nginx_timeout} 秒

注意:
  1. 请重新建立 SSH/Web 连接后再测试（旧连接仍按旧规则）
  2. 若管理界面「系统设置 -> 安全设置」修改了闲置时间，会覆盖环境变量
  3. 调整参数后重新运行本脚本即可，例如:
       SECURITY_MAX_IDLE_TIME=720 krun config_jumpserver_ssh_timeout
""")
