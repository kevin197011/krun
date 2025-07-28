#!/usr/bin/env bash

# Copyright (c) 2024 Kk
# MIT License: https://opensource.org/licenses/MIT

# Project configuration
BINARY_NAME := krun
SOURCE := krun.go
OUT_DIR := '.'

# OS/Arch targets
TARGETS := darwin/amd64 darwin/arm64 linux/amd64 linux/arm64

# Default target
.PHONY: all
all: build

# Build and UPX compress
.PHONY: build
build:
	@echo "Building and compressing binaries with UPX..."
	@mkdir -p $(OUT_DIR)
	@for target in $(TARGETS); do \
		os=$$(echo $$target | cut -d/ -f1); \
		arch=$$(echo $$target | cut -d/ -f2); \
		ext=$$( [ "$$os" = "windows" ] && echo ".exe" || echo "" ); \
		out="$(OUT_DIR)/$(BINARY_NAME)-$$os-$$arch$$ext"; \
		echo " > $$out"; \
		GOOS=$$os GOARCH=$$arch go build -o $$out $(SOURCE); \
		upx --best --lzma $$out || echo "⚠️ Skipped UPX (missing or failed) for $$out"; \
	done

# Run locally (mac/Linux)
.PHONY: run
run:
	@$(OUT_DIR)/$(BINARY_NAME)-$(shell uname | tr '[:upper:]' '[:lower:]')-$(shell go env GOARCH) $(ARGS)

# Clean up
.PHONY: clean
clean:
	@echo "Cleaning build output..."
	@rm -rf $(OUT_DIR)/$(BINARY_NAME)-*

# Example usage
.PHONY: example
example: build
	@echo "Running example..."
	@$(OUT_DIR)/$(BINARY_NAME)-$(shell uname | tr '[:upper:]' '[:lower:]')-$(shell go env GOARCH) list

# Help
.PHONY: help
help:
	@echo "Usage:"
	@echo "  make build           Build & compress for all platforms"
	@echo "  make run ARGS=\"...\"  Run on local platform"
	@echo "  make clean           Clean binaries"
	@echo "  make example         Run 'list' example on local"
	@echo "  make help            Show this help message"
