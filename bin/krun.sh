#!/usr/bin/env bash
# Copyright (c) 2023 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

set -o errexit
set -o nounset
set -o pipefail

# Configuration
readonly KRUN_UA="Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/103.0.0.0 Safari/537.36"
readonly KRUN_BASE_URL="https://raw.githubusercontent.com/kevin197011/krun/main"
readonly KRUN_LIST_URL="${KRUN_BASE_URL}/resources/krun.json"

# Supported interpreters
declare -A INTERPRETERS=(
    [".sh"]="bash"
    [".bash"]="bash"
    [".zsh"]="zsh"
    [".py"]="python3 python"
    [".python"]="python3 python"
    [".rb"]="ruby"
    [".ruby"]="ruby"
    [".pl"]="perl"
    [".perl"]="perl"
    [".js"]="node"
    [".javascript"]="node"
    [".lua"]="lua"
    [".r"]="Rscript"
    [".R"]="Rscript"
    [".php"]="php"
    [".swift"]="swift"
    [".groovy"]="groovy"
    [".scala"]="scala"
    [".ps1"]="powershell pwsh"
    [".fish"]="fish"
)

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Get HTTP content
http_get() {
    local url="$1"
    if command_exists curl; then
        curl -fsSL -H "User-Agent: $KRUN_UA" "$url"
    elif command_exists wget; then
        wget -qO- --header="User-Agent: $KRUN_UA" "$url"
    else
        echo "Error: Neither curl nor wget is available" >&2
        exit 1
    fi
}

# Get file extension
get_file_extension() {
    local filename="$1"
    echo "${filename##*.}" | tr '[:upper:]' '[:lower:]'
}

# Detect interpreter from shebang
detect_interpreter_from_shebang() {
    local content="$1"
    local first_line=$(echo "$content" | head -1)

    if [[ "$first_line" =~ ^#! ]]; then
        local shebang="${first_line#\#!}"
        case "$shebang" in
        *python3*) echo "python3" ;;
        *python*) echo "python" ;;
        *ruby*) echo "ruby" ;;
        *perl*) echo "perl" ;;
        *node*) echo "node" ;;
        *bash*) echo "bash" ;;
        *zsh*) echo "zsh" ;;
        *fish*) echo "fish" ;;
        *lua*) echo "lua" ;;
        *php*) echo "php" ;;
        *) echo "" ;;
        esac
    fi
}

# Get appropriate interpreter
get_interpreter() {
    local filename="$1"
    local content="$2"
    local ext=".$(get_file_extension "$filename")"

    # Try interpreters from extension
    if [[ -n "${INTERPRETERS[$ext]:-}" ]]; then
        for interpreter in ${INTERPRETERS[$ext]}; do
            if command_exists "$interpreter"; then
                echo "$interpreter"
                return
            fi
        done
    fi

    # Try shebang detection
    if [[ -n "$content" ]]; then
        local shebang_interpreter=$(detect_interpreter_from_shebang "$content")
        if [[ -n "$shebang_interpreter" ]] && command_exists "$shebang_interpreter"; then
            echo "$shebang_interpreter"
            return
        fi
    fi

    # Default fallback
    if [[ "$ext" == "" || "$ext" == ".sh" || "$ext" == ".bash" ]]; then
        echo "bash"
    fi
}

# Check if name is a script file
is_script_name() {
    local name="$1"
    [[ "$name" =~ \.(sh|py|rb|pl|js|lua|r|php|swift|groovy|scala|ps1|fish|bash|zsh|python|ruby|perl|javascript)$ ]]
}

# Get script list
get_script_list() {
    http_get "$KRUN_LIST_URL" | sed 's/\[//g;s/\]//g;s/"//g;s/,/\n/g' | tr -d ' '
}

# Group scripts by language
group_scripts_by_language() {
    local scripts=("$@")
    declare -A groups

    for script in "${scripts[@]}"; do
        local ext=".$(get_file_extension "$script")"
        case "$ext" in
        .sh | .bash | .zsh | .fish)
            groups[shell]+="$script "
            ;;
        .py | .python)
            groups[python]+="$script "
            ;;
        .rb | .ruby)
            groups[ruby]+="$script "
            ;;
        .pl | .perl)
            groups[perl]+="$script "
            ;;
        .js | .javascript)
            groups[javascript]+="$script "
            ;;
        *)
            groups[other]+="$script "
            ;;
        esac
    done

    # Print grouped scripts
    local num=1
    for lang in shell python ruby perl javascript other; do
        if [[ -n "${groups[$lang]:-}" ]]; then
            echo ""
            echo "  ${lang^^} Scripts:"
            for script in ${groups[$lang]}; do
                printf "    - [%d] %s\n" $num "$script"
                ((num++))
            done
        fi
    done
}

# List available scripts
krun_list() {
    echo "🚀 Krun Multi-Language Script Collection"
    echo "=================================================="

    local scripts
    readarray -t scripts < <(get_script_list)
    local total_scripts=${#scripts[@]}

    # Language icons
    local -A lang_icons=(
        ["shell"]="🐚"
        ["python"]="🐍"
        ["ruby"]="💎"
        ["perl"]="🐪"
        ["javascript"]="🟨"
        ["other"]="📄"
    )

    # Display summary
    echo ""
    echo "📊 Total Scripts: $total_scripts"

    # Count active categories
    local active_categories=0
    local -A groups

    for script in "${scripts[@]}"; do
        local ext=".$(get_file_extension "$script")"
        case "$ext" in
        .sh | .bash | .zsh | .fish)
            groups[shell]+="$script "
            ;;
        .py | .python)
            groups[python]+="$script "
            ;;
        .rb | .ruby)
            groups[ruby]+="$script "
            ;;
        .pl | .perl)
            groups[perl]+="$script "
            ;;
        .js | .javascript)
            groups[javascript]+="$script "
            ;;
        *)
            groups[other]+="$script "
            ;;
        esac
    done

    # Count non-empty groups
    for lang in shell python ruby perl javascript other; do
        if [[ -n "${groups[$lang]:-}" ]]; then
            ((active_categories++))
        fi
    done

    echo "📁 Categories: $active_categories"
    echo ""

    # Print grouped scripts
    local num=1
    for lang in shell python ruby perl javascript other; do
        if [[ -n "${groups[$lang]:-}" ]]; then
            local icon="${lang_icons[$lang]}"
            local script_count=$(echo "${groups[$lang]}" | wc -w)
            echo "${icon} ${lang^^} Scripts ($script_count files)"
            echo "────────────────────────────────────────"
            for script in ${groups[$lang]}; do
                printf "    [%2d] %s\n" $num "$script"
                ((num++))
            done
            echo ""
        fi
    done

    echo "💡 Usage: krun <number> or krun <script_name>"
    echo "🔍 Debug: krun <number> --debug"
    echo "=================================================="
}

# Show status
krun_status() {
    echo "Krun ready!"
    echo "Supported interpreters:"

    for ext in "${!INTERPRETERS[@]}"; do
        local available=()
        for interpreter in ${INTERPRETERS[$ext]}; do
            if command_exists "$interpreter"; then
                available+=("$interpreter")
            fi
        done
        if [[ ${#available[@]} -gt 0 ]]; then
            printf "  %s: %s\n" "$ext" "$(
                IFS=', '
                echo "${available[*]}"
            )"
        fi
    done
}

# Show version
krun_version() {
    echo "Krun Multi-Language Script Runner v2.0 (Shell)"
    echo "Copyright (c) 2023 kk"
    echo "MIT License"
}

# Show supported languages
krun_languages() {
    echo "Supported script languages and extensions:"
    echo ""

    declare -A lang_map=(
        ["Shell/Bash"]=".sh .bash .zsh .fish"
        ["Python"]=".py .python"
        ["Ruby"]=".rb .ruby"
        ["Perl"]=".pl .perl"
        ["JavaScript (Node.js)"]=".js .javascript"
        ["Lua"]=".lua"
        ["R"]=".r .R"
        ["PHP"]=".php"
        ["Swift"]=".swift"
        ["Groovy"]=".groovy"
        ["Scala"]=".scala"
        ["PowerShell"]=".ps1"
    )

    for lang in "${!lang_map[@]}"; do
        local exts=(${lang_map[$lang]})
        local available_interpreters=()

        for ext in "${exts[@]}"; do
            if [[ -n "${INTERPRETERS[$ext]:-}" ]]; then
                for interpreter in ${INTERPRETERS[$ext]}; do
                    if command_exists "$interpreter"; then
                        available_interpreters+=("$interpreter")
                        break
                    fi
                done
            fi
        done

        local status="✗"
        local interpreters_str="Not available"
        if [[ ${#available_interpreters[@]} -gt 0 ]]; then
            status="✓"
            interpreters_str=$(
                IFS=', '
                echo "${available_interpreters[*]}"
            )
        fi

        printf "  %s %s: %s (%s)\n" "$status" "$lang" "${lang_map[$lang]}" "$interpreters_str"
    done
}

# Show help
krun_help() {
    cat <<'EOF'
Krun Multi-Language Script Runner

Usage:
  krun list                    - List all available scripts
  krun <number>                - Execute script by number
  krun <script_name>           - Execute script by name
  krun <number|script> --debug - Show script content and debug info
  krun status                  - Show system status and available interpreters
  krun languages               - Show supported languages
  krun version                 - Show version information
  krun help                    - Show this help message

Examples:
  krun 1                       - Execute first script
  krun hello-world.sh          - Execute hello-world.sh
  krun install-python3.py      - Execute Python script
  krun config-system.rb        - Execute Ruby script
  krun 5 --debug               - Show debug info for script #5
EOF
}

# Get script URL
get_script_url() {
    local opt="$1"
    local script_name

    if [[ "$opt" =~ ^[0-9]+$ ]]; then
        local scripts
        readarray -t scripts < <(get_script_list)
        local index=$((opt - 1))
        if [[ $index -ge 0 && $index -lt ${#scripts[@]} ]]; then
            script_name="${scripts[$index]}"
        else
            echo "Error: Invalid script number: $opt" >&2
            exit 1
        fi
    else
        script_name="$opt"
    fi

    echo "${KRUN_BASE_URL}/lib/${script_name}"
}

# Debug script
krun_debug() {
    local opt="$1"
    local url=$(get_script_url "$opt")
    local filename=$(basename "$url")
    local content=$(http_get "$url")

    echo "=== Script Debug Information ==="
    echo "Filename: $filename"
    echo "URL: $url"
    echo "File extension: .$(get_file_extension "$filename")"

    local interpreter=$(get_interpreter "$filename" "$content")
    echo "Detected interpreter: ${interpreter:-'Unknown'}"

    local shebang_interpreter=$(detect_interpreter_from_shebang "$content")
    if [[ -n "$shebang_interpreter" ]]; then
        echo "Shebang interpreter: $shebang_interpreter"
    fi

    echo ""
    echo "=== Script Content ==="
    echo "$content"
}

# Execute script
krun_execute() {
    local opt="$1"
    local url=$(get_script_url "$opt")
    local filename=$(basename "$url")

    # Download script content
    local content=$(http_get "$url")

    # Determine interpreter
    local interpreter=$(get_interpreter "$filename" "$content")

    if [[ -z "$interpreter" ]]; then
        echo "Error: Cannot determine interpreter for $filename" >&2
        exit 1
    fi

    # Create temporary file
    local tmp_file=$(mktemp --suffix=".$(get_file_extension "$filename")")
    trap "rm -f '$tmp_file'" EXIT

    # Write content to temporary file
    echo "$content" >"$tmp_file"
    chmod +x "$tmp_file"

    # Execute with appropriate interpreter
    echo "Executing $filename with $interpreter..."
    "$interpreter" "$tmp_file"
}

# Main function
main() {
    if [[ $# -lt 1 ]]; then
        krun_help
        exit 0
    fi

    local command="$1"

    case "$command" in
    list)
        krun_list
        ;;
    help)
        krun_help
        ;;
    status)
        krun_status
        ;;
    version)
        krun_version
        ;;
    languages)
        krun_languages
        ;;
    *)
        if [[ "$command" =~ ^[0-9]+$ ]] || is_script_name "$command"; then
            local debug_mode=false
            if [[ $# -ge 2 && "$2" == "--debug" ]]; then
                debug_mode=true
            fi

            if [[ "$debug_mode" == true ]]; then
                krun_debug "$command"
            else
                krun_execute "$command"
            fi
        else
            echo "Error: Unknown command '$command'" >&2
            krun_help
            exit 1
        fi
        ;;
    esac
}

# Run main function
main "$@"
