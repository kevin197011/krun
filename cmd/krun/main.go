// Copyright (c) 2026 kk
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

package main

import (
	"fmt"
	"io/fs"
	"os"
	"os/exec"
	"path/filepath"
	"regexp"
	"runtime"
	"sort"
	"strconv"
	"strings"

	"github.com/kevin197011/krun/lib"
)

// Injected by GoReleaser / -ldflags.
var (
	version = "dev"
	commit  = "unknown"
	date    = "unknown"
)

const banner = `______
___  /____________  ________
__  //_/_  ___/  / / /_  __ \
_  ,<  _  /   / /_/ /_  / / /
/_/|_| /_/    \__,_/ /_/ /_/
     Ops Script Runner

🚀 Krun Script Collection`

type krun struct{}

func main() {
	os.Exit(run(os.Args[1:]))
}

func run(args []string) int {
	debug := false
	showVer := false
	rest := make([]string, 0, len(args))
	for _, a := range args {
		switch a {
		case "--debug":
			debug = true
		case "--version", "-version", "-v":
			showVer = true
		default:
			rest = append(rest, a)
		}
	}

	k := &krun{}
	if showVer {
		k.showVersion()
		return 0
	}
	if len(rest) == 0 {
		k.showHelp()
		return 0
	}

	cmd := rest[0]
	switch cmd {
	case "list":
		k.showList()
	case "help":
		k.showHelp()
	case "status":
		k.showStatus()
	case "version":
		k.showVersion()
	case "languages":
		k.showLanguages()
	default:
		if _, err := strconv.Atoi(cmd); err == nil {
			k.runByNumber(cmd, debug)
			return 0
		}
		if isScriptName(cmd) || strings.HasPrefix(cmd, "sh/") || strings.HasPrefix(cmd, "ps1/") {
			k.runByName(cmd, debug)
			return 0
		}
		if resolved := k.resolveBareName(cmd); resolved != "" {
			k.runByName(resolved, debug)
			return 0
		}
		fmt.Fprintf(os.Stderr, "✗ unknown command: %s\n", cmd)
		k.showHelp()
		return 1
	}
	return 0
}

func (k *krun) ext(name string) string {
	return strings.ToLower(filepath.Ext(name))
}

func (k *krun) scriptLang(name string) string {
	switch k.ext(name) {
	case ".sh", ".bash", ".zsh", "":
		return "sh"
	case ".ps1":
		return "ps1"
	default:
		return ""
	}
}

func (k *krun) stem(name string) string {
	s := name
	for _, suf := range []string{".sh", ".ps1"} {
		s = strings.TrimSuffix(s, suf)
	}
	return strings.ReplaceAll(s, "-", "_")
}

// resolveScriptPath returns display path lib/sh|ps1/<file>.
func (k *krun) resolveScriptPath(scriptName string) string {
	if strings.Contains(scriptName, "/") {
		rel := strings.TrimPrefix(scriptName, "/")
		if strings.HasPrefix(rel, "lib/") {
			return rel
		}
		return "lib/" + rel
	}
	stem := k.stem(scriptName)
	sh, ps1 := k.getScriptList()

	if strings.HasSuffix(scriptName, ".ps1") || contains(ps1, stem+".ps1") {
		if contains(ps1, stem+".ps1") {
			return "lib/ps1/" + stem + ".ps1"
		}
	}
	for _, name := range sh {
		base := strings.ReplaceAll(strings.TrimSuffix(name, ".sh"), "-", "_")
		if base == stem {
			return "lib/sh/" + name
		}
	}
	if k.scriptLang(scriptName) == "ps1" || strings.HasSuffix(scriptName, ".ps1") {
		return "lib/ps1/" + stem + ".ps1"
	}
	if strings.HasSuffix(scriptName, ".sh") {
		return "lib/sh/" + scriptName
	}
	return "lib/sh/" + stem + ".sh"
}

func (k *krun) embedKey(libPath string) string {
	return strings.TrimPrefix(libPath, "lib/")
}

func (k *krun) getInterpreter(filename, content string) string {
	ext := k.ext(filename)
	switch {
	case ext == ".sh" || ext == ".bash" || ext == ".zsh" || ext == "":
		if commandExists("bash") {
			return "bash"
		}
	case ext == ".ps1":
		if commandExists("pwsh") {
			return "pwsh"
		}
		if commandExists("powershell") {
			return "powershell"
		}
	}
	if strings.HasPrefix(content, "#!") {
		line := strings.SplitN(content, "\n", 2)[0]
		for _, cmd := range []string{"bash", "zsh", "sh", "pwsh", "powershell"} {
			if strings.Contains(line, cmd) && commandExists(cmd) {
				return cmd
			}
		}
	}
	return ""
}

func (k *krun) loadScript(scriptName string) (content, source string, err error) {
	libPath := k.resolveScriptPath(scriptName)
	key := k.embedKey(libPath)
	b, err := lib.Scripts.ReadFile(key)
	if err != nil {
		return "", "", fmt.Errorf("script not found in binary: %s", libPath)
	}
	return string(b), "embed:" + libPath, nil
}

func (k *krun) getScriptList() (sh, ps1 []string) {
	return listEmbedded("sh", ".sh"), listEmbedded("ps1", ".ps1")
}

func listEmbedded(dir, ext string) []string {
	entries, err := fs.ReadDir(lib.Scripts, dir)
	if err != nil {
		return nil
	}
	out := make([]string, 0, len(entries))
	for _, e := range entries {
		if e.IsDir() {
			continue
		}
		name := e.Name()
		if strings.HasSuffix(strings.ToLower(name), ext) {
			out = append(out, name)
		}
	}
	sort.Strings(out)
	return out
}

func (k *krun) allScripts() [][2]string {
	sh, ps1 := k.getScriptList()
	out := make([][2]string, 0, len(sh)+len(ps1))
	for _, n := range sh {
		out = append(out, [2]string{"sh", n})
	}
	for _, n := range ps1 {
		out = append(out, [2]string{"ps1", n})
	}
	return out
}

func (k *krun) executeScript(scriptName string) {
	resolved := k.resolveScriptPath(scriptName)
	actual := filepath.Base(resolved)

	// Batch Windows installs from embed (single extracted ps1 cannot see siblings).
	if actual == "install_windows_all.ps1" {
		k.runAllWindowsInstalls()
		return
	}

	content, source, err := k.loadScript(scriptName)
	if err != nil {
		fmt.Fprintf(os.Stderr, "✗ error: %v\n", err)
		return
	}
	interpreter := k.getInterpreter(actual, content)
	if interpreter == "" {
		fmt.Fprintf(os.Stderr, "✗ no interpreter for %s\n", scriptName)
		return
	}

	tmp, err := os.CreateTemp("", "krun-*"+filepath.Ext(actual))
	if err != nil {
		fmt.Fprintf(os.Stderr, "✗ temp: %v\n", err)
		return
	}
	defer os.Remove(tmp.Name())
	if _, err := tmp.WriteString(content); err != nil {
		tmp.Close()
		fmt.Fprintf(os.Stderr, "✗ temp write: %v\n", err)
		return
	}
	tmp.Close()
	_ = os.Chmod(tmp.Name(), 0o755)

	argv := []string{interpreter, tmp.Name()}
	if interpreter == "pwsh" || interpreter == "powershell" {
		argv = []string{interpreter, "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", tmp.Name()}
	}

	fmt.Printf("running %s (%s) [%s]\n", scriptName, interpreter, source)
	cmd := exec.Command(argv[0], argv[1:]...)
	cmd.Stdin = os.Stdin
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	cmd.Env = os.Environ()
	_ = cmd.Run()
}

func (k *krun) runAllWindowsInstalls() {
	_, ps1 := k.getScriptList()
	var list []string
	for _, name := range ps1 {
		if strings.HasPrefix(name, "install_") && name != "install_windows_all.ps1" {
			list = append(list, name)
		}
	}
	fmt.Printf("running %d Windows install scripts from embed\n", len(list))
	for _, name := range list {
		k.executeScript(name)
	}
	fmt.Println("All Windows install scripts finished.")
}

func (k *krun) debugScript(scriptName string) {
	resolved := k.resolveScriptPath(scriptName)
	actual := filepath.Base(resolved)
	content, source, err := k.loadScript(scriptName)
	if err != nil {
		fmt.Fprintf(os.Stderr, "✗ error: %v\n", err)
		return
	}
	fmt.Println("=== debug ===")
	fmt.Printf("name: %s\n", scriptName)
	fmt.Printf("path: %s\n", resolved)
	fmt.Printf("source: %s\n", source)
	fmt.Printf("interpreter: %s\n", k.getInterpreter(actual, content))
	fmt.Println("\n=== content ===")
	fmt.Println(content)
}

func (k *krun) showList() {
	fmt.Println(banner)
	fmt.Println(strings.Repeat("=", 50))
	sh, ps1 := k.getScriptList()
	all := k.allScripts()
	fmt.Printf("\n📊 total: %d (sh: %d, ps1: %d)  [embedded]\n\n", len(all), len(sh), len(ps1))
	n := 1
	if len(sh) > 0 {
		fmt.Println("🐚 shell scripts (lib/sh/)")
		fmt.Println(strings.Repeat("─", 40))
		for _, s := range sh {
			fmt.Printf("    [%2d] %s\n", n, s)
			n++
		}
		fmt.Println()
	}
	if len(ps1) > 0 {
		fmt.Println("💠 powershell scripts (lib/ps1/)")
		fmt.Println(strings.Repeat("─", 40))
		for _, s := range ps1 {
			fmt.Printf("    [%2d] %s\n", n, s)
			n++
		}
		fmt.Println()
	}
	fmt.Println("💡 usage: krun <number> | krun <script_name> | krun sh/foo.sh | krun ps1/baz.ps1")
}

func (k *krun) showStatus() {
	fmt.Println("krun ready (scripts embedded)")
	printCmd("bash")
	printCmd("pwsh")
	printCmd("powershell")
	fmt.Printf("goos/goarch: %s/%s\n", runtime.GOOS, runtime.GOARCH)
	sh, ps1 := k.getScriptList()
	fmt.Printf("embedded: sh=%d ps1=%d\n", len(sh), len(ps1))
}

func (k *krun) showLanguages() {
	fmt.Println(banner)
	fmt.Println("\nsupported:")
	fmt.Println("  ✓ shell       lib/sh/*.sh    interpreter: bash (embedded)")
	fmt.Println("  ✓ powershell  lib/ps1/*.ps1  interpreter: pwsh|powershell (embedded)")
}

func (k *krun) showHelp() {
	fmt.Println(banner)
	fmt.Println("\nusage:")
	fmt.Println("  krun list                              list scripts")
	fmt.Println("  krun <number>                          run by index")
	fmt.Println("  krun <script.sh|script.ps1>            run by name")
	fmt.Println("  krun sh/foo.sh | ps1/x.ps1             run by path")
	fmt.Println("  krun <target> --debug                  show script content")
	fmt.Println("  krun status | languages | help | version")
	fmt.Println("\nnote: all scripts are embedded — no download at runtime.")
}

func (k *krun) showVersion() {
	fmt.Println(banner)
	fmt.Printf("\nv%s\n", version)
	fmt.Printf("commit: %s  built: %s\n", commit, date)
	fmt.Println("Copyright (c) 2023-2026 kk")
	fmt.Println("MIT License")
}

func (k *krun) runByNumber(number string, debug bool) {
	items := k.allScripts()
	i, err := strconv.Atoi(number)
	if err != nil || i < 1 || i > len(items) {
		fmt.Fprintf(os.Stderr, "✗ script #%s not found\n", number)
		return
	}
	name := items[i-1][1]
	if debug {
		k.debugScript(name)
	} else {
		k.executeScript(name)
	}
}

func (k *krun) runByName(name string, debug bool) {
	if debug {
		k.debugScript(name)
	} else {
		k.executeScript(name)
	}
}

func (k *krun) resolveBareName(name string) string {
	key := k.stem(name)
	sh, ps1 := k.getScriptList()
	for _, script := range sh {
		base := strings.ReplaceAll(strings.TrimSuffix(script, ".sh"), "-", "_")
		if base == key {
			return script
		}
	}
	for _, script := range ps1 {
		base := strings.ReplaceAll(strings.TrimSuffix(script, ".ps1"), "-", "_")
		if base == key {
			return script
		}
	}
	return ""
}

func isScriptName(name string) bool {
	ok, _ := regexp.MatchString(`(?i).*\.(sh|bash|zsh|ps1)$`, name)
	return ok
}

func commandExists(cmd string) bool {
	_, err := exec.LookPath(cmd)
	return err == nil
}

func contains(list []string, want string) bool {
	for _, s := range list {
		if s == want {
			return true
		}
	}
	return false
}

func printCmd(name string) {
	if commandExists(name) {
		fmt.Printf("✓ %s\n", name)
	} else {
		fmt.Printf("✗ %s\n", name)
	}
}
