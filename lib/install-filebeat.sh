#!/usr/bin/env bash
# Copyright (c) 2025 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

set -o errexit
set -o nounset
set -o pipefail

# curl exec:
# curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/install-filebeat.sh | bash

# vars
FILEBEAT_LOG_PATH="${FILEBEAT_LOG_PATH:-/var/log/*.log}"
# FILEBEAT_LOG_TYPE: auto-detect if not set, or specify: java | nginx | go | cpp | nodejs
# FILEBEAT_PROJECT: auto-extract from path /data/project/module, or manually specify
# FILEBEAT_MODULE: auto-extract from path /data/project/module, or manually specify
FILEBEAT_ENV="${FILEBEAT_ENV:-env}"
FILEBEAT_TYPE="${FILEBEAT_TYPE:-type}"
FILEBEAT_LOGSTASH_HOSTS="${FILEBEAT_LOGSTASH_HOSTS:-localhost:5044}"

krun::install::filebeat::sudo() {
    [[ "$(id -u 2>/dev/null || echo 1)" -eq 0 ]] && return 0
    command -v sudo >/dev/null 2>&1 && echo "sudo"
}

# run code
krun::install::filebeat::run() {
    # default debian platform
    platform='debian'
    command -v yum >/dev/null && platform='centos'
    command -v dnf >/dev/null && platform='centos'
    command -v brew >/dev/null && platform='mac'
    eval "${FUNCNAME/::run/::${platform}}"
}

# centos code
krun::install::filebeat::centos() {
    sudo="$(krun::install::filebeat::sudo)"

    if command -v filebeat >/dev/null 2>&1; then
        echo "filebeat already installed"
    else
        $sudo rpm --import https://artifacts.elastic.co/GPG-KEY-elasticsearch
        $sudo tee /etc/yum.repos.d/elastic.repo >/dev/null <<EOF
[elastic-8.x]
name=Elastic repository for 8.x packages
baseurl=https://artifacts.elastic.co/packages/8.x/yum
gpgcheck=1
gpgkey=https://artifacts.elastic.co/GPG-KEY-elasticsearch
enabled=1
autorefresh=1
type=rpm-md
EOF
        command -v dnf >/dev/null 2>&1 && $sudo dnf -y install filebeat && return
        $sudo yum -y install filebeat
    fi

    krun::install::filebeat::config
    krun::install::filebeat::start
}

# debian code
krun::install::filebeat::debian() {
    sudo="$(krun::install::filebeat::sudo)"

    if command -v filebeat >/dev/null 2>&1; then
        echo "filebeat already installed"
    else
        $sudo apt-get update -qq || true
        $sudo apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release
        curl -fsSL https://artifacts.elastic.co/GPG-KEY-elasticsearch | $sudo gpg --dearmor -o /usr/share/keyrings/elastic.gpg
        echo "deb [signed-by=/usr/share/keyrings/elastic.gpg] https://artifacts.elastic.co/packages/8.x/apt stable main" | $sudo tee /etc/apt/sources.list.d/elastic-8.x.list >/dev/null
        $sudo apt-get update -qq || true
        $sudo apt-get install -y filebeat
    fi

    krun::install::filebeat::config
    krun::install::filebeat::start
}

# mac code
krun::install::filebeat::mac() {
    if command -v filebeat >/dev/null 2>&1; then
        echo "filebeat already installed"
    else
        brew install filebeat
    fi

    krun::install::filebeat::config
    krun::install::filebeat::start
}

krun::install::filebeat::get_node_ip() {
    local node_ip
    if [[ "$(uname -s 2>/dev/null || true)" == "Darwin" ]]; then
        node_ip=$(ifconfig 2>/dev/null | grep "inet " | grep -v 127.0.0.1 | awk '{print $2}' | head -1 || echo "")
    else
        node_ip=$(hostname -I 2>/dev/null | awk '{print $1}' || \
                  ip route get 1 2>/dev/null | awk '{print $7; exit}' || \
                  ip addr show 2>/dev/null | grep "inet " | grep -v 127.0.0.1 | head -1 | awk '{print $2}' | cut -d/ -f1 || echo "")
    fi
    [[ -z "$node_ip" ]] && node_ip="unknown"
    echo "$node_ip"
}

krun::install::filebeat::detect_log_type() {
    local log_path="$FILEBEAT_LOG_PATH"
    local detected_type="java"

    # 根据路径关键词检测
    case "$log_path" in
        *nginx*|*/nginx/*|*access.log*|*error.log*)
            detected_type="nginx"
            ;;
        *go*|*/go/*|*golang*)
            detected_type="go"
            ;;
        *cpp*|*/cpp/*|*c++*|*/c++/*)
            detected_type="cpp"
            ;;
        *nodejs*|*/nodejs/*|*node*|*/node/*|*npm*)
            detected_type="nodejs"
            ;;
        *java*|*/java/*|*jvm*|*spring*|*tomcat*|*jetty*)
            detected_type="java"
            ;;
    esac

    # 如果路径检测未确定，尝试读取文件内容检测
    if [[ "$detected_type" == "java" ]] && [[ "$log_path" != *"*"* ]]; then
        local first_file
        first_file=$(echo "$log_path" | sed 's/\*.*//' | head -1)
        if [[ -f "$first_file" ]] && [[ -r "$first_file" ]]; then
            local sample
            sample=$(head -5 "$first_file" 2>/dev/null | head -1 || echo "")
            # Nginx 访问日志格式检测
            if echo "$sample" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+.*\[.*\].*".*".*[0-9]+.*".*"'; then
                detected_type="nginx"
            # Java 堆栈跟踪检测
            elif echo "$sample" | grep -qE '^(Exception|Error|at |java\.|javax\.)'; then
                detected_type="java"
            # Go 日志格式检测（通常包含时间戳和级别）
            elif echo "$sample" | grep -qE '^[0-9]{4}-[0-9]{2}-[0-9]{2}.*(INFO|ERROR|WARN|DEBUG|FATAL)'; then
                detected_type="go"
            # Node.js 日志检测
            elif echo "$sample" | grep -qE '(npm|node|express|koa)'; then
                detected_type="nodejs"
            fi
        fi
    fi

    echo "$detected_type"
}

krun::install::filebeat::extract_project_module() {
    local log_path="$FILEBEAT_LOG_PATH"
    local project=""
    local module=""

    # 从路径 /data/project/module 中提取
    if echo "$log_path" | grep -qE '^/data/[^/]+/[^/]+'; then
        # 提取 /data/project/module 格式
        project=$(echo "$log_path" | sed -E 's|^/data/([^/]+)/.*|\1|' | head -1)
        module=$(echo "$log_path" | sed -E 's|^/data/[^/]+/([^/]+)/.*|\1|' | head -1)
    elif echo "$log_path" | grep -qE '/data/[^/]+/[^/]+'; then
        # 路径中包含 /data/project/module
        project=$(echo "$log_path" | sed -E 's|.*/data/([^/]+)/.*|\1|' | head -1)
        module=$(echo "$log_path" | sed -E 's|.*/data/[^/]+/([^/]+)/.*|\1|' | head -1)
    fi

    # 如果提取失败，尝试查找实际存在的目录
    if [[ -z "$project" ]] || [[ -z "$module" ]]; then
        local path_without_wildcard
        path_without_wildcard=$(echo "$log_path" | sed 's|/\*.*||' | sed 's|\*.*||')
        if [[ -d "$path_without_wildcard" ]]; then
            local real_path
            real_path=$(cd "$path_without_wildcard" 2>/dev/null && pwd || echo "$path_without_wildcard")
            if echo "$real_path" | grep -qE '/data/[^/]+/[^/]+'; then
                project=$(echo "$real_path" | sed -E 's|.*/data/([^/]+)/.*|\1|' | head -1)
                module=$(echo "$real_path" | sed -E 's|.*/data/[^/]+/([^/]+)/.*|\1|' | head -1)
            fi
        fi
    fi

    # 如果仍未提取到，使用环境变量或默认值
    if [[ -z "$project" ]]; then
        project="${FILEBEAT_PROJECT:-project}"
    fi
    if [[ -z "$module" ]]; then
        module="${FILEBEAT_MODULE:-module}"
    fi

    echo "$project|$module"
}

# common code
krun::install::filebeat::config() {
    local config_file="/etc/filebeat/filebeat.yml"
    if [[ "$(uname -s 2>/dev/null || true)" == "Darwin" ]]; then
        config_file="/usr/local/etc/filebeat/filebeat.yml"
    fi

    local sudo
    sudo="$(krun::install::filebeat::sudo)"

    local node_ip
    node_ip="$(krun::install::filebeat::get_node_ip)"

    # 自动检测日志类型（如果用户未手动指定）
    local log_type
    if [[ -n "${FILEBEAT_LOG_TYPE:-}" ]]; then
        log_type="$FILEBEAT_LOG_TYPE"
    else
        log_type="$(krun::install::filebeat::detect_log_type)"
    fi

    # 从路径提取项目名和模块名（如果未手动指定）
    local project_module
    project_module="$(krun::install::filebeat::extract_project_module)"
    local project="${project_module%%|*}"
    local module="${project_module##*|}"

    # 如果用户手动指定了环境变量，优先使用
    [[ -n "${FILEBEAT_PROJECT:-}" ]] && project="$FILEBEAT_PROJECT"
    [[ -n "${FILEBEAT_MODULE:-}" ]] && module="$FILEBEAT_MODULE"

    local multiline_config=""
    if [[ "$log_type" == "java" ]]; then
        multiline_config="
  multiline.pattern: '^[0-9]{4}-[0-9]{2}-[0-9]{2}'
  multiline.negate: true
  multiline.match: after"
    elif [[ "$log_type" == "cpp" ]]; then
        multiline_config="
  multiline.pattern: '^[0-9]{4}-[0-9]{2}-[0-9]{2}|^[A-Z][a-z]{2} [0-9]{1,2}'
  multiline.negate: true
  multiline.match: after"
    fi

    # 根据日志类型配置解析器
    local parser_config=""
    if [[ "$log_type" == "nginx" ]]; then
        # Nginx JSON 日志解析
        parser_config="
  parsers:
    - ndjson:
        keys_under_root: true
        add_error_key: true
        message_key: message"
    fi
    # 其他类型不做解析，保留原始 message 字段（filestream 默认行为）

    # 配置日期时间字段解析
    local date_processors=""
    if [[ "$log_type" == "nginx" ]]; then
        # Nginx JSON 日志：解析常见的日期时间字段
        date_processors="
  - date:
      field: time_local
      target_field: @timestamp
      layouts:
        - '02/Jan/2006:15:04:05 -0700'
        - '2006-01-02T15:04:05Z'
        - '2006-01-02 15:04:05'
        - '2006-01-02T15:04:05.000Z'
      ignore_failure: true
  - date:
      field: timestamp
      target_field: @timestamp
      layouts:
        - '2006-01-02T15:04:05Z'
        - '2006-01-02 15:04:05'
        - '2006-01-02T15:04:05.000Z'
        - '2006-01-02T15:04:05+08:00'
      ignore_failure: true
  - date:
      field: @timestamp
      target_field: @timestamp
      layouts:
        - '2006-01-02T15:04:05Z'
        - '2006-01-02 15:04:05'
        - '2006-01-02T15:04:05.000Z'
      ignore_failure: true"
    else
        # 其他类型：从 message 字段提取日期时间
        date_processors="
  - date:
      field: message
      target_field: @timestamp
      layouts:
        - '2006-01-02 15:04:05'
        - '2006-01-02T15:04:05Z'
        - '2006-01-02T15:04:05.000Z'
        - '2006-01-02T15:04:05+08:00'
        - '2006/01/02 15:04:05'
        - 'Jan 02 15:04:05'
        - '2006-01-02T15:04:05'
      ignore_failure: true"
    fi

    $sudo mkdir -p "$(dirname "$config_file")"

    $sudo tee "$config_file" >/dev/null <<EOF
filebeat.inputs:
- type: filestream
  id: default-logs
  enabled: true
  paths:
    - ${FILEBEAT_LOG_PATH}
  fields:
    log_type: ${log_type}
  fields_under_root: false${multiline_config}${parser_config}

output.logstash:
  hosts: ["${FILEBEAT_LOGSTASH_HOSTS}"]

processors:
  - add_fields:
      target: ""
      fields:
        node_ip: "${node_ip}"
        log_category: "${log_type}"
        index_name: "${project}-${FILEBEAT_ENV}-${FILEBEAT_TYPE}-${module}-%{+yyyy.MM.dd}"${date_processors}
  - add_host_metadata:
      when.not.contains.tags: forwarded
  - add_cloud_metadata: ~
  - add_docker_metadata: ~
EOF

    echo "✓ Filebeat configured: $config_file"
    echo "  Log path: $FILEBEAT_LOG_PATH"
    echo "  Log type: $log_type (auto-detected)"
    echo "  Project: $project (auto-extracted)"
    echo "  Module: $module (auto-extracted)"
    echo "  Index pattern: ${project}-${FILEBEAT_ENV}-${FILEBEAT_TYPE}-${module}-%{+yyyy.MM.dd}"
    echo "  Logstash: $FILEBEAT_LOGSTASH_HOSTS"
    echo "  Node IP: $node_ip"
}

krun::install::filebeat::start() {
    local sudo
    sudo="$(krun::install::filebeat::sudo)"

    if [[ "$(uname -s 2>/dev/null || true)" == "Darwin" ]]; then
        echo "✓ Filebeat installed. Start with: brew services start filebeat"
        return
    fi

    $sudo systemctl daemon-reload || true
    $sudo systemctl enable filebeat || true
    $sudo systemctl restart filebeat || true

    echo "✓ Filebeat started"
}

# run main
krun::install::filebeat::run "$@"
