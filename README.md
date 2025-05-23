# krun

A lightweight script management and execution tool that allows you to run predefined scripts remotely from a GitHub repository.

## Features

- Run scripts directly from GitHub without saving them locally
- Support for multiple scripting languages:
  - Bash/Shell
  - Perl
  - Ruby
  - Python
- Simple command-line interface
- List available scripts
- Run scripts by number or name

## Installation

```bash
# Default installation
curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/deploy.sh | bash

# Custom installation path
export deploy_path="/your/custom/path"
curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/deploy.sh | bash
```

## Usage

### List Available Scripts

```bash
$ krun list
  Krun Script List:
    - [1] config-acme.sh
    - [2] config-fstab.sh
    - [3] config-locales.sh
    - [4] config-ssh.sh
    - [5] config-system.sh
    - [6] config-vagrant-ssh.sh
    - [7] config-vim.sh
    - [8] hello-world.sh
    ...
```

### Run a Script by Number

```bash
$ krun 8
hello world
```

### Run a Script by Name

```bash
$ krun hello-world.sh
hello world
```

### Debug Mode

View the script content without executing it:

```bash
$ krun 8 --debug
# Script content will be displayed
```

### Help

```bash
$ krun help
  Usage: krun [list | help | <number> | <number> --debug ]
```

## How It Works

krun fetches scripts from the GitHub repository and executes them in a temporary location, cleaning up after execution. This allows for centralized script management with distributed execution.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.