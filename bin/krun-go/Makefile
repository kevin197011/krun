# Copyright (c) 2024 Kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

# Makefile for krun

# Name of the executable
BINARY_NAME := krun

# Go source file
SOURCE := krun.go

# Go module initialization
MOD_INIT := krun

# Default target
.PHONY: all
all: build

# Build the Go binary
.PHONY: build
build:
	# @echo "Initializing Go module..."
	# go mod init $(MOD_INIT)
	@echo "Building the Go binary..."
	go build -o $(BINARY_NAME) $(SOURCE)

# Run the Go program with specified arguments
.PHONY: run
run: build
	@./$(BINARY_NAME) $(ARGS)

# Clean up build artifacts
.PHONY: clean
clean:
	@echo "Cleaning up..."
	rm -f $(BINARY_NAME)

# Example usage target
.PHONY: example
example: build
	@echo "Running example..."
	@./$(BINARY_NAME) list

# Help target
.PHONY: help
help:
	@echo "Usage:"
	@echo "  make build          Build the Go binary"
	@echo "  make run ARGS=\"...\" Run the Go program with specified arguments"
	@echo "  make clean          Clean up build artifacts"
	@echo "  make example        Run an example command"
	@echo "  make help           Show this help message"

