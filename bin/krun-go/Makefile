#!/usr/bin/env bash

# Copyright (c) 2024 Kk
# MIT License: https://opensource.org/licenses/MIT

# Project configuration
BINARY_NAME := krun
SOURCE := krun.go
OUT_DIR := bin

# OS/Arch targets
TARGETS := \
  darwin/amd64 \
  darwin/arm64 \
  linux/amd64 \
  linux/arm64 \
  windows/amd64

# Default target
.PHONY: all
all: build

# Build and UPX compress
.PHONY: build
build:
	@echo "Building and compressing binaries with UPX..."
	@mkdir -p $(OUT_DIR)
	@for TARGET in $(TARGETS); do \
		OS=$${TARGET%/*}; ARCH=$${TARGET##*/}; \
		EXT=$$( [ "$$OS" = "windows" ] && echo ".exe" || echo "" ); \
		OUT=$(OUT_DIR)/$(BINARY_NAME)-$$OS-$$ARCH$$EXT; \
		echo " > $$OUT"; \
		GOOS=$$OS GOARCH=$$ARCH go build -o $$OUT $(SOURCE); \
		upx --best --lzma $$OUT || echo "⚠️ Skipped UPX (missing or failed) for $$OUT"; \
	done

# Run locally (mac/Linux)
.PHONY: run
run:
	@$(OUT_DIR)/$(BINARY_NAME)-$(shell uname | tr '[:upper:]' '[:lower:]')-$(shell go env GOARCH) $(ARGS)

# Clean up
.PHONY: clean
clean:
	@echo "Cleaning build output..."
	@rm -rf $(OUT_DIR)

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
	@echo "  make help            Show this help"
