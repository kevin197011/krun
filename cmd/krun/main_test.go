// Copyright (c) 2026 kk
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

package main

import "testing"

func TestStemAndLang(t *testing.T) {
	k := &krun{}
	if g := k.stem("install-docker"); g != "install_docker" {
		t.Fatalf("stem=%q", g)
	}
	if k.scriptLang("x.sh") != "sh" || k.scriptLang("x.ps1") != "ps1" {
		t.Fatal("lang")
	}
}
