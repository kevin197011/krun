#!/usr/bin/env bash
# Copyright (c) 2026 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

set -o errexit
set -o nounset
set -o pipefail

# curl exec:
# curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/sh/config-jumpserver-ssh-timeout.sh | sudo bash
#
# Env (optional):
#   JUMPSERVER_DIR              default /opt/jumpserver
#   SECURITY_MAX_IDLE_TIME      minutes, default 480
#   SECURITY_MAX_SESSION_TIME   hours, default 24
#   CLIENT_ALIVE_INTERVAL       seconds, default 60
#   RETRY_ALIVE_COUNT_MAX       default 10
#   NGINX_PROXY_TIMEOUT         seconds, default 28800
#   HEALTH_WAIT_SECONDS         default 240
#   HEALTH_INTERVAL_SECONDS     default 10
#   BOOTSTRAP_TOKEN             override token from compose.yml

JUMPSERVER_DIR="${JUMPSERVER_DIR:-/opt/jumpserver}"
SECURITY_MAX_IDLE_TIME="${SECURITY_MAX_IDLE_TIME:-480}"
SECURITY_MAX_SESSION_TIME="${SECURITY_MAX_SESSION_TIME:-24}"
CLIENT_ALIVE_INTERVAL="${CLIENT_ALIVE_INTERVAL:-60}"
RETRY_ALIVE_COUNT_MAX="${RETRY_ALIVE_COUNT_MAX:-10}"
NGINX_PROXY_TIMEOUT="${NGINX_PROXY_TIMEOUT:-28800}"
HEALTH_WAIT_SECONDS="${HEALTH_WAIT_SECONDS:-240}"
HEALTH_INTERVAL_SECONDS="${HEALTH_INTERVAL_SECONDS:-10}"
CONTAINER_NAME=jumpserver

krun::config::jumpserver_ssh_timeout::log() {
    printf '[%s] %s\n' "$(date '+%F %T')" "$*"
}

krun::config::jumpserver_ssh_timeout::die() {
    krun::config::jumpserver_ssh_timeout::log "ERROR: $*"
    exit 1
}

krun::config::jumpserver_ssh_timeout::backup() {
    local path=$1
    [[ -f "$path" ]] || return 0
    mkdir -p "$BACKUP_DIR"
    cp -a "$path" "$BACKUP_DIR/$(basename "$path")"
    krun::config::jumpserver_ssh_timeout::log "已备份: $path -> $BACKUP_DIR/$(basename "$path")"
}

krun::config::jumpserver_ssh_timeout::read_token() {
    if [[ -n "${BOOTSTRAP_TOKEN:-}" ]]; then
        printf '%s' "$BOOTSTRAP_TOKEN"
        return
    fi
    [[ -f "$COMPOSE_FILE" ]] || krun::config::jumpserver_ssh_timeout::die "未找到 compose.yml"
    local token
    token=$(grep -E '^\s+BOOTSTRAP_TOKEN:' "$COMPOSE_FILE" | head -1 | sed -E 's/.*BOOTSTRAP_TOKEN:[[:space:]]*"?([^"]+)".*/\1/' | sed -E 's/[[:space:]]*$//')
    [[ -n "$token" ]] || krun::config::jumpserver_ssh_timeout::die "无法解析 BOOTSTRAP_TOKEN，请 export BOOTSTRAP_TOKEN=..."
    printf '%s' "$token"
}

krun::config::jumpserver_ssh_timeout::patch_compose() {
    krun::config::jumpserver_ssh_timeout::log "步骤 1/5: 修改 compose.yml"
    [[ -f "$COMPOSE_FILE" ]] || krun::config::jumpserver_ssh_timeout::die "compose.yml 不存在: $COMPOSE_FILE"
    krun::config::jumpserver_ssh_timeout::backup "$COMPOSE_FILE"

    if grep -qE '^\s*SECURITY_MAX_IDLE_TIME:' "$COMPOSE_FILE"; then
        sed -i -E "s|([[:space:]]*SECURITY_MAX_IDLE_TIME:[[:space:]]*).*|\\1\"${SECURITY_MAX_IDLE_TIME}\"|" "$COMPOSE_FILE"
        krun::config::jumpserver_ssh_timeout::log "  已更新 SECURITY_MAX_IDLE_TIME=${SECURITY_MAX_IDLE_TIME}"
    else
        # insert after SESSION_EXPIRE_AT_BROWSER_CLOSE
        local tmp
        tmp=$(mktemp)
        awk -v idle="$SECURITY_MAX_IDLE_TIME" -v sess="$SECURITY_MAX_SESSION_TIME" '
            { print }
            /SESSION_EXPIRE_AT_BROWSER_CLOSE:/ && !done {
                print "      # SSH/终端闲置超时（分钟），默认 30 分钟"
                print "      SECURITY_MAX_IDLE_TIME: \"" idle "\""
                print "      # 单次会话最大在线时长（小时），默认 24 小时"
                print "      SECURITY_MAX_SESSION_TIME: \"" sess "\""
                done=1
            }
        ' "$COMPOSE_FILE" >"$tmp"
        mv "$tmp" "$COMPOSE_FILE"
        krun::config::jumpserver_ssh_timeout::log "  已添加 SECURITY_MAX_IDLE_TIME=${SECURITY_MAX_IDLE_TIME}, SECURITY_MAX_SESSION_TIME=${SECURITY_MAX_SESSION_TIME}"
    fi

    if grep -qE '^\s*SECURITY_MAX_SESSION_TIME:' "$COMPOSE_FILE"; then
        sed -i -E "s|([[:space:]]*SECURITY_MAX_SESSION_TIME:[[:space:]]*).*|\\1\"${SECURITY_MAX_SESSION_TIME}\"|" "$COMPOSE_FILE"
    fi

    local mounts=(
        "./config/koko/config.yml:/opt/koko/config.yml:ro"
        "./config/nginx/includes/koko.conf:/etc/nginx/includes/koko.conf:ro"
        "./config/nginx/includes/core.conf:/etc/nginx/includes/core.conf:ro"
        "./config/nginx/includes/lion.conf:/etc/nginx/includes/lion.conf:ro"
    )
    local mount
    for mount in "${mounts[@]}"; do
        if grep -Fq "$mount" "$COMPOSE_FILE"; then
            krun::config::jumpserver_ssh_timeout::log "  volume 已存在: $mount"
            continue
        fi
        local tmp
        tmp=$(mktemp)
        awk -v m="$mount" '
            { print }
            /- \.\/config\/jumpserver:\/opt\/jumpserver\/config/ && !done {
                print "      - " m
                done=1
            }
        ' "$COMPOSE_FILE" >"$tmp"
        mv "$tmp" "$COMPOSE_FILE"
        krun::config::jumpserver_ssh_timeout::log "  已添加 volume: $mount"
    done
}

krun::config::jumpserver_ssh_timeout::koko_config() {
    krun::config::jumpserver_ssh_timeout::log "步骤 2/5: 创建 KoKo 配置"
    local token koko_file
    token=$(krun::config::jumpserver_ssh_timeout::read_token)
    koko_file="${JUMPSERVER_DIR}/config/koko/config.yml"
    krun::config::jumpserver_ssh_timeout::backup "$koko_file"
    mkdir -p "$(dirname "$koko_file")"
    cat >"$koko_file" <<EOF
# KoKo SSH 组件配置
CORE_HOST: http://127.0.0.1:8080
BOOTSTRAP_TOKEN: ${token}

# 向 SSH 客户端发送心跳间隔（秒），防止网络/NAT 超时断开
CLIENT_ALIVE_INTERVAL: ${CLIENT_ALIVE_INTERVAL}
# 心跳重试次数
RETRY_ALIVE_COUNT_MAX: ${RETRY_ALIVE_COUNT_MAX}
EOF
    krun::config::jumpserver_ssh_timeout::log "  已写入: $koko_file"
}

krun::config::jumpserver_ssh_timeout::nginx_configs() {
    krun::config::jumpserver_ssh_timeout::log "步骤 3/5: 创建 Nginx 长超时配置"
    local nginx_dir="${JUMPSERVER_DIR}/config/nginx/includes"
    local t=$NGINX_PROXY_TIMEOUT
    mkdir -p "$nginx_dir"

    krun::config::jumpserver_ssh_timeout::backup "${nginx_dir}/koko.conf"
    cat >"${nginx_dir}/koko.conf" <<EOF
location /koko/ {
    proxy_pass http://koko:5000;
    proxy_buffering off;
    proxy_http_version 1.1;
    proxy_request_buffering off;
    proxy_set_header Upgrade \$http_upgrade;
    proxy_set_header Connection "upgrade";
    proxy_set_header Host \$host;
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    proxy_ignore_client_abort on;
    proxy_connect_timeout ${t};
    proxy_send_timeout ${t};
    proxy_read_timeout ${t};
    send_timeout ${t};
}
EOF

    krun::config::jumpserver_ssh_timeout::backup "${nginx_dir}/lion.conf"
    cat >"${nginx_dir}/lion.conf" <<EOF
location /lion/ {
    proxy_pass http://lion:8081;
    proxy_buffering off;
    proxy_http_version 1.1;
    proxy_request_buffering off;
    proxy_set_header Upgrade \$http_upgrade;
    proxy_set_header Connection "upgrade";
    proxy_set_header Host \$host;
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    proxy_ignore_client_abort on;
    proxy_connect_timeout ${t};
    proxy_send_timeout ${t};
    proxy_read_timeout ${t};
    send_timeout ${t};
}
EOF

    krun::config::jumpserver_ssh_timeout::backup "${nginx_dir}/core.conf"
    cat >"${nginx_dir}/core.conf" <<EOF
location /static/ {
    root /opt/jumpserver/data/;
}

location /private-media/ {
    internal;
    alias /opt/jumpserver/data/media/;
}

location /ws/ {
    proxy_pass http://core:8080;
    proxy_buffering off;
    proxy_http_version 1.1;
    proxy_set_header Upgrade \$http_upgrade;
    proxy_set_header Connection "upgrade";
    proxy_set_header Host \$host;
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    proxy_ignore_client_abort on;
    proxy_connect_timeout ${t};
    proxy_send_timeout ${t};
    proxy_read_timeout ${t};
    send_timeout ${t};
}
location ~ ^/(core|api|media)/ {
    proxy_pass http://core:8080;
    proxy_set_header Host \$http_host;
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    proxy_ignore_client_abort on;
    proxy_connect_timeout ${t};
    proxy_send_timeout ${t};
    proxy_read_timeout ${t};
    send_timeout ${t};
}
EOF
    krun::config::jumpserver_ssh_timeout::log "  已写入: ${nginx_dir}/koko.conf, core.conf, lion.conf"
}

krun::config::jumpserver_ssh_timeout::container_status() {
    docker inspect "$CONTAINER_NAME" \
        --format='{{if .State.Health}}{{.State.Health.Status}}{{else}}{{.State.Status}}{{end}}' \
        2>/dev/null || echo missing
}

krun::config::jumpserver_ssh_timeout::restart() {
    krun::config::jumpserver_ssh_timeout::log "步骤 4/5: 重启 JumpServer 容器"
    command -v docker >/dev/null || krun::config::jumpserver_ssh_timeout::die "缺少命令: docker"
    (
        cd "$JUMPSERVER_DIR"
        docker compose up -d "$CONTAINER_NAME"
    )
    krun::config::jumpserver_ssh_timeout::log "  已执行: docker compose up -d $CONTAINER_NAME"

    local elapsed=0 status=unknown
    while ((elapsed < HEALTH_WAIT_SECONDS)); do
        status=$(krun::config::jumpserver_ssh_timeout::container_status)
        krun::config::jumpserver_ssh_timeout::log "  健康检查: ${status} (${elapsed}s/${HEALTH_WAIT_SECONDS}s)"
        [[ "$status" == "healthy" ]] && {
            krun::config::jumpserver_ssh_timeout::log "  JumpServer 已就绪"
            return 0
        }
        [[ "$status" == "missing" || "$status" == "exited" ]] &&
            krun::config::jumpserver_ssh_timeout::die "容器未正常运行，请检查: docker logs $CONTAINER_NAME"
        sleep "$HEALTH_INTERVAL_SECONDS"
        elapsed=$((elapsed + HEALTH_INTERVAL_SECONDS))
    done
    krun::config::jumpserver_ssh_timeout::die "等待健康检查超时 (${HEALTH_WAIT_SECONDS}s)，当前状态: $status"
}

krun::config::jumpserver_ssh_timeout::verify() {
    krun::config::jumpserver_ssh_timeout::log "步骤 5/5: 验证配置"

    krun::config::jumpserver_ssh_timeout::log "  [env] 容器环境变量:"
    local env_out
    env_out=$(docker exec "$CONTAINER_NAME" env | grep '^SECURITY_MAX_' || true)
    [[ -n "$env_out" ]] || krun::config::jumpserver_ssh_timeout::die "未找到 SECURITY_MAX_* 环境变量"
    printf '%s\n' "$env_out" | sed 's/^/    /'

    krun::config::jumpserver_ssh_timeout::log "  [django] 运行时安全策略:"
    docker exec "$CONTAINER_NAME" /opt/jumpserver/.venv/bin/python3 -c \
        "import os,django;os.environ.setdefault('DJANGO_SETTINGS_MODULE','jumpserver.settings');import sys;sys.path.insert(0,'/opt/jumpserver/apps');django.setup();from django.conf import settings;print('SECURITY_MAX_IDLE_TIME:',settings.SECURITY_MAX_IDLE_TIME);print('SECURITY_MAX_SESSION_TIME:',settings.SECURITY_MAX_SESSION_TIME)" \
        | sed 's/^/    /' || true

    krun::config::jumpserver_ssh_timeout::log "  [koko] 心跳配置:"
    docker exec "$CONTAINER_NAME" grep -E 'CLIENT_ALIVE|RETRY_ALIVE' /opt/koko/config.yml | sed 's/^/    /' || true

    krun::config::jumpserver_ssh_timeout::log "  [nginx] 代理超时:"
    docker exec "$CONTAINER_NAME" grep -h proxy_read_timeout \
        /etc/nginx/includes/koko.conf \
        /etc/nginx/includes/core.conf \
        /etc/nginx/includes/lion.conf 2>/dev/null | head -3 | sed 's/^/    /' || true

    if docker exec "$CONTAINER_NAME" curl -sf http://localhost/api/health/ >/dev/null; then
        krun::config::jumpserver_ssh_timeout::log "  [api] /api/health/ OK"
    else
        krun::config::jumpserver_ssh_timeout::die "API 健康检查失败"
    fi
    krun::config::jumpserver_ssh_timeout::log "验证完成"
}

krun::config::jumpserver_ssh_timeout::run() {
    [[ $EUID -eq 0 ]] || krun::config::jumpserver_ssh_timeout::die "Please run as root"

    COMPOSE_FILE="${JUMPSERVER_DIR}/compose.yml"
    BACKUP_DIR="${JUMPSERVER_DIR}/backups/$(date '+%Y%m%d_%H%M%S')"

    krun::config::jumpserver_ssh_timeout::log "开始修复 JumpServer SSH 闲置超时问题"
    krun::config::jumpserver_ssh_timeout::log "工作目录: $JUMPSERVER_DIR"
    [[ -d "$JUMPSERVER_DIR" ]] || krun::config::jumpserver_ssh_timeout::die "JumpServer 目录不存在: $JUMPSERVER_DIR"
    [[ -f "$COMPOSE_FILE" ]] || krun::config::jumpserver_ssh_timeout::die "compose.yml 不存在: $COMPOSE_FILE"

    krun::config::jumpserver_ssh_timeout::patch_compose
    krun::config::jumpserver_ssh_timeout::koko_config
    krun::config::jumpserver_ssh_timeout::nginx_configs
    krun::config::jumpserver_ssh_timeout::restart
    krun::config::jumpserver_ssh_timeout::verify

    cat <<EOF

========================================
JumpServer SSH 闲置超时修复完成
========================================
目录:               ${JUMPSERVER_DIR}
备份目录:           ${BACKUP_DIR}
闲置超时:           ${SECURITY_MAX_IDLE_TIME} 分钟
会话最大时长:       ${SECURITY_MAX_SESSION_TIME} 小时
SSH 心跳间隔:       ${CLIENT_ALIVE_INTERVAL} 秒
Nginx 代理超时:     ${NGINX_PROXY_TIMEOUT} 秒

注意:
  1. 请重新建立 SSH/Web 连接后再测试（旧连接仍按旧规则）
  2. 若管理界面「系统设置 -> 安全设置」修改了闲置时间，会覆盖环境变量
  3. 调整参数后重新运行本脚本即可，例如:
       SECURITY_MAX_IDLE_TIME=720 bash config-jumpserver-ssh-timeout.sh
EOF
}

krun::config::jumpserver_ssh_timeout::run "$@"
