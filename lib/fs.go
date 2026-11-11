// Copyright (c) 2026 kk
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

// Package lib embeds all ops scripts into the krun binary (no network fetch).
package lib

import "embed"

// Scripts holds lib/sh and lib/ps1 at build time.
//
//go:embed all:sh all:ps1
var Scripts embed.FS
