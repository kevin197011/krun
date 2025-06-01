#!/usr/bin/env bash
# Copyright (c) 2023 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

set -o errexit
set -o nounset
set -o pipefail

# curl exec:
# curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/install-openjdk.sh | bash

# vars
java_version=${java_version:-11}

# run code
krun::install::openjdk::run() {
    # default debian platform
    platform='debian'
    # command -v apt >/dev/null && platform='debian'
    command -v yum >/dev/null && platform='centos'
    command -v brew >/dev/null && platform='mac'
    eval "${FUNCNAME/::run/::${platform}}"
}

# centos code
krun::install::openjdk::centos() {
    echo "Installing OpenJDK ${java_version} on CentOS/RHEL..."

    # Install OpenJDK
    yum install -y java-${java_version}-openjdk java-${java_version}-openjdk-devel

    krun::install::openjdk::common
}

# debian code
krun::install::openjdk::debian() {
    echo "Installing OpenJDK ${java_version} on Debian/Ubuntu..."

    # Update package lists
    apt-get update

    # Install OpenJDK
    apt-get install -y openjdk-${java_version}-jdk openjdk-${java_version}-jre

    krun::install::openjdk::common
}

# mac code
krun::install::openjdk::mac() {
    echo "Installing OpenJDK ${java_version} on macOS..."

    if ! command -v brew >/dev/null 2>&1; then
        echo "Homebrew is required for OpenJDK installation on macOS"
        return 1
    fi

    # Install OpenJDK via Homebrew
    case $java_version in
    8)
        brew install --cask adoptopenjdk8
        ;;
    11)
        brew install openjdk@11
        ;;
    17)
        brew install openjdk@17
        ;;
    21)
        brew install openjdk@21
        ;;
    *)
        brew install openjdk
        ;;
    esac

    krun::install::openjdk::common
}

# common code
krun::install::openjdk::common() {
    echo "Configuring OpenJDK..."

    # Verify Java installation
    if ! command -v java >/dev/null 2>&1; then
        echo "✗ Java command not found after installation"
        return 1
    fi

    echo "✓ Java installed successfully"
    java -version

    # Configure JAVA_HOME
    krun::install::openjdk::configure_java_home

    # Verify javac (compiler)
    if command -v javac >/dev/null 2>&1; then
        echo "✓ Java compiler (javac) is available"
        javac -version
    else
        echo "⚠ Java compiler (javac) not found"
    fi

    # Test Java functionality
    krun::install::openjdk::test_java

    echo ""
    echo "=== OpenJDK Installation Summary ==="
    echo "Java version: $(java -version 2>&1 | head -1)"
    echo "Java home: ${JAVA_HOME:-'Not set'}"
    echo "Java executable: $(which java)"
    echo "Javac executable: $(which javac 2>/dev/null || echo 'Not found')"
    echo ""
    echo "Common Java commands:"
    echo "  java -version          - Show Java version"
    echo "  javac HelloWorld.java  - Compile Java source"
    echo "  java HelloWorld        - Run Java class"
    echo "  java -jar app.jar      - Run JAR file"
    echo ""
    echo "OpenJDK is ready to use!"
}

# Configure JAVA_HOME environment variable
krun::install::openjdk::configure_java_home() {
    echo "Configuring JAVA_HOME..."

    local java_home=""

    # Find JAVA_HOME based on platform
    if [[ "$(uname)" == "Darwin" ]]; then
        # macOS
        if command -v /usr/libexec/java_home >/dev/null 2>&1; then
            java_home=$(/usr/libexec/java_home 2>/dev/null)
        fi
    else
        # Linux
        local java_path=$(readlink -f $(which java) 2>/dev/null)
        if [[ -n "$java_path" ]]; then
            # Remove /bin/java from the path
            java_home="${java_path%/bin/java}"
            # For OpenJDK packages, go up one more level
            if [[ "$java_home" =~ jre$ ]]; then
                java_home="${java_home%/jre}"
            fi
        fi

        # Common OpenJDK locations
        if [[ -z "$java_home" ]] || [[ ! -d "$java_home" ]]; then
            local possible_homes=(
                "/usr/lib/jvm/java-${java_version}-openjdk"
                "/usr/lib/jvm/java-${java_version}-openjdk-amd64"
                "/usr/lib/jvm/openjdk-${java_version}"
                "/usr/lib/jvm/java-1.${java_version}.0-openjdk"
                "/usr/lib/jvm/default-java"
            )

            for home in "${possible_homes[@]}"; do
                if [[ -d "$home" ]]; then
                    java_home="$home"
                    break
                fi
            done
        fi
    fi

    if [[ -n "$java_home" ]] && [[ -d "$java_home" ]]; then
        echo "Found JAVA_HOME: $java_home"

        # Set for current session
        export JAVA_HOME="$java_home"

        # Add to shell profiles
        local shell_profiles=(
            "$HOME/.bashrc"
            "$HOME/.bash_profile"
            "$HOME/.zshrc"
            "$HOME/.profile"
        )

        for profile in "${shell_profiles[@]}"; do
            if [[ -f "$profile" ]]; then
                if ! grep -q "JAVA_HOME" "$profile" 2>/dev/null; then
                    echo "" >>"$profile"
                    echo "# Java environment" >>"$profile"
                    echo "export JAVA_HOME=\"$java_home\"" >>"$profile"
                    echo "export PATH=\"\$JAVA_HOME/bin:\$PATH\"" >>"$profile"
                    echo "✓ Added JAVA_HOME to $profile"
                else
                    echo "✓ JAVA_HOME already configured in $profile"
                fi
            fi
        done

        echo "✓ JAVA_HOME configured: $java_home"
    else
        echo "⚠ Could not determine JAVA_HOME automatically"
        echo "Please set JAVA_HOME manually:"
        echo "  export JAVA_HOME=/path/to/java"
        echo "  export PATH=\$JAVA_HOME/bin:\$PATH"
    fi
}

# Test Java installation
krun::install::openjdk::test_java() {
    echo "Testing Java installation..."

    # Create a simple test program
    local test_dir="/tmp/java-test-$$"
    mkdir -p "$test_dir"
    cd "$test_dir"

    cat >HelloWorld.java <<EOF
public class HelloWorld {
    public static void main(String[] args) {
        System.out.println("Hello, OpenJDK!");
        System.out.println("Java version: " + System.getProperty("java.version"));
        System.out.println("Java vendor: " + System.getProperty("java.vendor"));
        System.out.println("Java home: " + System.getProperty("java.home"));
    }
}
EOF

    # Test compilation
    if javac HelloWorld.java 2>/dev/null; then
        echo "✓ Java compilation successful"

        # Test execution
        if java HelloWorld 2>/dev/null | grep -q "Hello, OpenJDK!"; then
            echo "✓ Java execution successful"
            java HelloWorld
        else
            echo "✗ Java execution failed"
        fi
    else
        echo "✗ Java compilation failed"
    fi

    # Clean up
    cd /
    rm -rf "$test_dir"
}

# run main
krun::install::openjdk::run "$@"
