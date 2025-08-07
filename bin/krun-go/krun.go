// Copyright (c) 2024 Kk
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

package main

import (
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"os"
	"os/exec"
	"path/filepath"
	"regexp"
	"strconv"
	"strings"
	"syscall"
)

// ASCII art banner
const BANNER = `______
___  /____________  ________
__  //_/_  ___/  / / /_  __ \
_  ,<  _  /   / /_/ /_  / / /
/_/|_| /_/    \__,_/ /_/ /_/
       Multi-Language Script Runner

🚀 Krun Multi-Language Script Collection`

// Supported interpreters by file extension
var INTERPRETERS = map[string]string{
	".sh":         "bash",
	".bash":       "bash",
	".zsh":        "zsh",
	".py":         "python3",
	".python":     "python3",
	".rb":         "ruby",
	".ruby":       "ruby",
	".pl":         "perl",
	".perl":       "perl",
	".js":         "node",
	".javascript": "node",
	".lua":        "lua",
	".r":          "Rscript",
	".R":          "Rscript",
	".php":        "php",
	".swift":      "swift",
	".groovy":     "groovy",
	".scala":      "scala",
	".ps1":        "powershell",
	".fish":       "fish",
}

// Language icons for display
var LANG_ICONS = map[string]string{
	"shell":      "🐚",
	"python":     "🐍",
	"ruby":       "💎",
	"perl":       "🐪",
	"javascript": "🟨",
	"other":      "📄",
}

// Krun struct to hold methods
type Krun struct {
	userAgent string
	baseURL   string
}

// NewKrun creates a new Krun instance
func NewKrun() *Krun {
	return &Krun{
		userAgent: "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36",
		baseURL:   "https://raw.githubusercontent.com/kevin197011/krun/main",
	}
}

// commandExists checks if command exists in system
func (k *Krun) commandExists(command string) bool {
	cmd := exec.Command("which", command)
	cmd.Stdout = nil
	cmd.Stderr = nil
	return cmd.Run() == nil
}

// getExtension returns the file extension
func (k *Krun) getExtension(filename string) string {
	return strings.ToLower(filepath.Ext(filename))
}

// getInterpreter determines the appropriate interpreter for a file
func (k *Krun) getInterpreter(filename, content string) string {
	ext := k.getExtension(filename)

	// Try extension-based detection
	if interpreter, exists := INTERPRETERS[ext]; exists {
		if k.commandExists(interpreter) {
			return interpreter
		}
	}

	// Try shebang detection
	if content != "" && strings.HasPrefix(content, "#!") {
		lines := strings.Split(content, "\n")
		shebang := strings.TrimSpace(lines[0][2:])
		for _, cmd := range []string{"python3", "python", "ruby", "perl", "node", "bash", "zsh"} {
			if strings.Contains(shebang, cmd) && k.commandExists(cmd) {
				return cmd
			}
		}
	}

	// Default fallback
	if ext == "" || ext == ".sh" || ext == ".bash" {
		return "bash"
	}

	return ""
}

// downloadScript downloads script content from GitHub
func (k *Krun) downloadScript(scriptName string) string {
	url := fmt.Sprintf("%s/lib/%s", k.baseURL, scriptName)
	return k.get(url)
}

// getScriptList returns the list of available scripts
func (k *Krun) getScriptList() []string {
	url := fmt.Sprintf("%s/resources/krun.json", k.baseURL)
	content := k.get(url)
	var scripts []string
	json.Unmarshal([]byte(content), &scripts)
	return scripts
}

// groupScripts groups scripts by language
func (k *Krun) groupScripts(scripts []string) map[string][]string {
	groups := map[string][]string{
		"shell":      {},
		"python":     {},
		"ruby":       {},
		"perl":       {},
		"javascript": {},
		"other":      {},
	}

	for _, script := range scripts {
		ext := k.getExtension(script)
		switch ext {
		case ".sh", ".bash", ".zsh":
			groups["shell"] = append(groups["shell"], script)
		case ".py", ".python":
			groups["python"] = append(groups["python"], script)
		case ".rb", ".ruby":
			groups["ruby"] = append(groups["ruby"], script)
		case ".pl", ".perl":
			groups["perl"] = append(groups["perl"], script)
		case ".js", ".javascript":
			groups["javascript"] = append(groups["javascript"], script)
		default:
			groups["other"] = append(groups["other"], script)
		}
	}

	return groups
}

// executeScript executes a script
func (k *Krun) executeScript(scriptName string) {
	content := k.downloadScript(scriptName)
	interpreter := k.getInterpreter(scriptName, content)

	if interpreter == "" {
		fmt.Printf("Error: Cannot determine interpreter for %s\n", scriptName)
		return
	}

	// Create temporary file
	tmpFile, err := os.CreateTemp("", "krun-*"+k.getExtension(scriptName))
	if err != nil {
		fmt.Printf("Error creating temporary file: %v\n", err)
		return
	}
	defer os.Remove(tmpFile.Name())

	// Write content to temporary file
	if _, err := tmpFile.WriteString(content); err != nil {
		fmt.Printf("Error writing to temporary file: %v\n", err)
		return
	}
	tmpFile.Close()

	// Make file executable and run
	if err := os.Chmod(tmpFile.Name(), 0755); err != nil {
		fmt.Printf("Error making file executable: %v\n", err)
		return
	}

	fmt.Printf("Executing %s with %s...\n", scriptName, interpreter)

	cmd := exec.Command(interpreter, tmpFile.Name())
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	cmd.Stdin = os.Stdin

	if err := cmd.Run(); err != nil {
		if exitError, ok := err.(*exec.ExitError); ok {
			if status, ok := exitError.Sys().(syscall.WaitStatus); ok {
				os.Exit(status.ExitStatus())
			}
		}
		fmt.Printf("Error executing script: %v\n", err)
	}
}

// debugScript shows debug information for script
func (k *Krun) debugScript(scriptName string) {
	content := k.downloadScript(scriptName)
	interpreter := k.getInterpreter(scriptName, content)

	fmt.Println("=== Script Debug Information ===")
	fmt.Printf("Filename: %s\n", scriptName)
	fmt.Printf("Extension: %s\n", k.getExtension(scriptName))
	fmt.Printf("Interpreter: %s\n", interpreter)
	fmt.Println("\n=== Script Content ===")
	fmt.Println(content)
}

// showList shows list of available scripts
func (k *Krun) showList() {
	fmt.Println(BANNER)
	fmt.Println(strings.Repeat("=", 50))

	scripts := k.getScriptList()
	groups := k.groupScripts(scripts)

	fmt.Printf("\n📊 Total Scripts: %d\n", len(scripts))
	activeGroups := 0
	for _, scriptList := range groups {
		if len(scriptList) > 0 {
			activeGroups++
		}
	}
	fmt.Printf("📁 Categories: %d\n\n", activeGroups)

	num := 1
	for _, lang := range []string{"shell", "python", "ruby", "perl", "javascript", "other"} {
		scriptList := groups[lang]
		if len(scriptList) > 0 {
			icon := LANG_ICONS[lang]
			fmt.Printf("%s %s Scripts (%d files)\n", icon, strings.ToUpper(lang), len(scriptList))
			fmt.Println(strings.Repeat("─", 40))
			for _, script := range scriptList {
				fmt.Printf("    [%2d] %s\n", num, script)
				num++
			}
			fmt.Println()
		}
	}

	fmt.Println("💡 Usage: krun <number> or krun <script_name>")
	fmt.Println("🔍 Debug: krun <number> --debug")
}

// showStatus shows system status
func (k *Krun) showStatus() {
	fmt.Println("Krun ready!")
	fmt.Println("Available interpreters:")
	for ext, interpreter := range INTERPRETERS {
		if k.commandExists(interpreter) {
			fmt.Printf("  %s: %s\n", ext, interpreter)
		}
	}
}

// showLanguages shows supported languages
func (k *Krun) showLanguages() {
	fmt.Println(BANNER)
	fmt.Println("\nSupported languages:")

	langMap := map[string][]string{
		"Shell/Bash": {".sh", ".bash", ".zsh"},
		"Python":     {".py", ".python"},
		"Ruby":       {".rb", ".ruby"},
		"Perl":       {".pl", ".perl"},
		"JavaScript": {".js", ".javascript"},
		"Lua":        {".lua"},
		"R":          {".r", ".R"},
		"PHP":        {".php"},
		"Swift":      {".swift"},
		"Groovy":     {".groovy"},
		"Scala":      {".scala"},
		"PowerShell": {".ps1"},
	}

	for lang, exts := range langMap {
		available := false
		for _, ext := range exts {
			if interpreter, exists := INTERPRETERS[ext]; exists && k.commandExists(interpreter) {
				available = true
				break
			}
		}
		status := "✓"
		if !available {
			status = "✗"
		}
		fmt.Printf("  %s %s\n", status, lang)
	}
}

// showHelp shows help message
func (k *Krun) showHelp() {
	fmt.Println(BANNER)
	fmt.Println("\nUsage:")
	fmt.Println("  krun list                    - List all scripts")
	fmt.Println("  krun <number>                - Execute script by number")
	fmt.Println("  krun <script_name>           - Execute script by name")
	fmt.Println("  krun <number|script> --debug - Show debug info")
	fmt.Println("  krun status                  - Show system status")
	fmt.Println("  krun languages               - Show supported languages")
	fmt.Println("  krun version                 - Show version")
	fmt.Println("  krun help                    - Show this help")
	fmt.Println("\nExamples:")
	fmt.Println("  krun 1                       - Execute first script")
	fmt.Println("  krun hello-world.sh          - Execute hello-world.sh")
	fmt.Println("  krun 5 --debug               - Debug script #5")
}

// showVersion shows version information
func (k *Krun) showVersion() {
	fmt.Println(BANNER)
	fmt.Println("\nv2.0 (Go)")
	fmt.Println("Copyright (c) 2023 kk")
	fmt.Println("MIT License")
}

// runByNumber runs script by number
func (k *Krun) runByNumber(number string, debug bool) {
	scripts := k.getScriptList()
	if num, err := strconv.Atoi(number); err == nil && num > 0 && num <= len(scripts) {
		scriptName := scripts[num-1]
		if debug {
			k.debugScript(scriptName)
		} else {
			k.executeScript(scriptName)
		}
	} else {
		fmt.Printf("Error: Script #%s not found\n", number)
	}
}

// runByName runs script by name
func (k *Krun) runByName(scriptName string, debug bool) {
	if debug {
		k.debugScript(scriptName)
	} else {
		k.executeScript(scriptName)
	}
}

// isScriptName checks if name looks like a script file
func (k *Krun) isScriptName(name string) bool {
	pattern := `.*\.(sh|py|rb|pl|js|lua|r|php|swift|groovy|scala|ps1|fish|bash|zsh|python|ruby|perl|javascript)$`
	match, _ := regexp.MatchString(pattern, name)
	return match
}

// Run executes the main functionality based on arguments
func (k *Krun) Run(args []string) {
	if len(args) < 2 {
		k.showHelp()
		return
	}

	command := args[1]
	debug := len(args) >= 3 && args[2] == "--debug"

	switch command {
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
		if match, _ := regexp.MatchString(`^\d+$`, command); match {
			k.runByNumber(command, debug)
		} else if k.isScriptName(command) {
			k.runByName(command, debug)
		} else {
			fmt.Printf("Error: Unknown command '%s'\n", command)
			k.showHelp()
		}
	}
}

// get performs an HTTP GET request and returns the response body as a string
func (k *Krun) get(url string) string {
	client := &http.Client{}
	req, _ := http.NewRequest("GET", url, nil)
	req.Header.Set("User-Agent", k.userAgent)
	resp, err := client.Do(req)
	if err != nil {
		panic(err)
	}
	defer resp.Body.Close()

	body, _ := io.ReadAll(resp.Body)
	return string(body)
}

func main() {
	k := NewKrun()
	k.Run(os.Args)
}
