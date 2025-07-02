# Krun - Enterprise Multi-Language Script Management System

```
______
___  /____________  ________
__  //_/_  ___/  / / /_  __ \
_  ,<  _  /   / /_/ /_  / / /
/_/|_| /_/    \__,_/ /_/ /_/
       Multi-Language Script Runner
```

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Version](https://img.shields.io/badge/version-2.0-blue.svg)](https://github.com/kevin197011/krun)

## Table of Contents

1. [Introduction](#introduction)
2. [System Architecture](#system-architecture)
3. [Core Features](#core-features)
4. [Installation Guide](#installation-guide)
5. [Usage Documentation](#usage-documentation)
6. [Script Library](#script-library)
7. [System Requirements](#system-requirements)
8. [Security Guidelines](#security-guidelines)
9. [Development Guide](#development-guide)
10. [Version History](#version-history)
11. [License](#license)

## Introduction

Krun is an enterprise-grade multi-language script management and execution system, designed to streamline DevOps workflows and system administration tasks. It provides a unified interface for managing and executing scripts across multiple programming languages while ensuring security, reliability, and ease of use.

## System Architecture

### Directory Structure
```
krun/
├── bin/                 # Executable files
│   ├── krun            # Main Python implementation
│   └── krun-go/        # Go implementation
├── lib/                 # Script library
├── config/             # Configuration files
├── resources/          # Resource files
├── templates/          # Template files
├── utils/              # Utility scripts
└── examples/           # Example files
```

### Implementation Versions
- **Python (Primary)**: Full-featured implementation
- **Go**: High-performance compiled version
- **Shell**: Dependency-free implementation
- **Ruby**: Object-oriented implementation
- **Perl**: Traditional script implementation

## Core Features

### Language Support Matrix
| Language    | Extensions                | Interpreter Requirements |
|-------------|---------------------------|-------------------------|
| Shell/Bash  | .sh, .bash, .zsh, .fish  | bash 4.0+              |
| Python      | .py, .python             | python 3.6+/2.7+       |
| Ruby        | .rb, .ruby               | ruby 2.0+              |
| Perl        | .pl, .perl               | perl 5.10+             |
| JavaScript  | .js                      | node 10.0+             |
| Lua         | .lua                     | lua 5.1+               |
| R           | .r, .R                   | R 3.0+                 |
| PHP         | .php                     | php 7.0+               |

### System Optimization Capabilities

#### Kernel Parameter Optimization
- Virtual memory management
- Network stack tuning
- File system optimization
- Security parameter configuration

#### Resource Management
- File descriptor limits
- Process limits
- Memory management
- Service control

#### Network Performance
- TCP/IP stack optimization
- BBR congestion control
- Buffer size optimization
- IP forwarding (IPv4/IPv6)

#### Storage Performance
- I/O scheduler optimization
- Mount options tuning
- Read-ahead configuration
- Disk performance tuning

## Installation Guide

### Prerequisites
- Operating System: Linux (Ubuntu 18.04+/CentOS 7+) or macOS 10.15+
- Python 3.6+ (for primary implementation)
- Git (for installation)
- Bash 4.0+ (for shell scripts)

### Standard Installation
```bash
curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/deploy.sh | bash
```

### Custom Installation
```bash
export deploy_path="/custom/path"
curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/deploy.sh | bash
```

### Manual Installation
```bash
git clone https://github.com/kevin197011/krun.git
cd krun
export PATH="$PWD/bin:$PATH"
```

## Usage Documentation

### Basic Commands
```bash
krun list                    # List available scripts
krun <number>               # Execute script by number
krun <script_name>          # Execute script by name
krun <number> --debug       # Show script debug info
krun status                 # Show system status
krun version                # Show version info
```

### Advanced Usage

#### Environment Variables
```bash
KRUN_BASE_URL="https://custom-repo.com"    # Custom repository URL
KRUN_USER_AGENT="CustomAgent/1.0"          # Custom user agent
KRUN_DEBUG=1                               # Enable debug mode
```

#### CI/CD Integration
```yaml
# GitHub Actions Example
steps:
  - uses: actions/checkout@v4
  - name: Install Krun
    run: curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/deploy.sh | bash
  - name: Execute Scripts
    run: |
      krun install-dependencies.sh
      krun setup-environment.py
```

## Script Library

### System Administration (45+ scripts)
- System configuration and optimization
- Service installation and setup
- Network configuration
- Security hardening

### Development Tools (8+ scripts)
- Language runtime installation
- Development environment setup
- Version control configuration
- Container management

### Database Management (4+ scripts)
- Database installation
- Backup and recovery
- Performance tuning
- Monitoring setup

## System Requirements

### Minimum Requirements
- CPU: 1 core
- Memory: 512MB RAM
- Storage: 1GB free space
- Network: Internet connection

### Recommended Requirements
- CPU: 2+ cores
- Memory: 2GB+ RAM
- Storage: 5GB+ free space
- Network: Stable Internet connection

## Security Guidelines

### Script Execution Security
- Isolated execution environment
- Automatic cleanup of temporary files
- Permission validation
- Error handling and rollback

### Network Security
- HTTPS for remote script fetching
- SSL certificate verification
- Custom user agent support
- Rate limiting protection

### Best Practices
1. Review scripts before execution
2. Use trusted script sources only
3. Maintain regular backups
4. Monitor system logs
5. Keep Krun updated

## Development Guide

### Contributing Guidelines
1. Fork the repository
2. Create a feature branch
3. Follow coding standards
4. Add tests if applicable
5. Submit pull request

### Script Development Standards
```bash
#!/usr/bin/env bash
# Copyright (c) 2024 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

set -o errexit
set -o nounset
set -o pipefail

# Script documentation
# Usage: script_name [options]
# Options:
#   -h, --help    Show help message
#   -v, --version Show version information

# Implementation...
```

## Version History

### v2.0 (Current)
- Multi-language support
- Enhanced UI/UX
- Intelligent interpreter detection
- System optimization features
- Performance improvements

### v1.0
- Initial release
- Basic script execution
- Shell script support
- Debug mode

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

---

**Documentation Version:** 2.0.0
**Last Updated:** 2024-02-29
**Author:** [kevin197011](https://github.com/kevin197011)
**Repository:** https://github.com/kevin197011/krun