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
	"net/url"
	"os"
	"os/exec"
	"path/filepath"
	"regexp"
	"strconv"
	"strings"
	"syscall"
)

// User-Agent string
const UA = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/103.0.0.0 Safari/537.36"

// ASCII art banner
const BANNER = `______
___  /____________  ________
__  //_/_  ___/  / / /_  __ \
_  ,<  _  /   / /_/ /_  / / /
/_/|_| /_/    \__,_/ /_/ /_/
       Multi-Language Script Runner`

// Supported interpreters map
var INTERPRETERS = map[string][]string{
	".sh":         {"bash"},
	".bash":       {"bash"},
	".zsh":        {"zsh"},
	".py":         {"python3", "python"},
	".python":     {"python3", "python"},
	".rb":         {"ruby"},
	".ruby":       {"ruby"},
	".pl":         {"perl"},
	".perl":       {"perl"},
	".js":         {"node"},
	".javascript": {"node"},
	".lua":        {"lua"},
	".r":          {"Rscript"},
	".R":          {"Rscript"},
	".php":        {"php"},
	".swift":      {"swift"},
	".groovy":     {"groovy"},
	".scala":      {"scala"},
	".ps1":        {"powershell", "pwsh"},
	".fish":       {"fish"},
}

// Krun struct to hold methods
type Krun struct{}

// Run executes the main functionality based on arguments
func (k *Krun) Run(args []string) {
	if len(args) < 2 {
		k.Help()
		return
	}

	command := args[1]

	switch command {
	case "list":
		k.List()
	case "help":
		k.Help()
	case "status":
		k.Status()
	case "version":
		k.Version()
	case "languages":
		k.Languages()
	default:
		if match, _ := regexp.MatchString(`^\d+$`, command); match {
			opt, _ := strconv.Atoi(command)
			debugMode := len(args) >= 3 && args[2] == "--debug"
			if debugMode {
				k.Debug(opt)
			} else {
				k.RunScript(opt)
			}
		} else if k.IsScriptName(command) {
			debugMode := len(args) >= 3 && args[2] == "--debug"
			if debugMode {
				k.Debug(command)
			} else {
				k.RunScript(command)
			}
		} else {
			fmt.Printf("Error: Unknown command '%s'\n", command)
			k.Help()
		}
	}
}

// IsScriptName checks if the name looks like a script file
func (k *Krun) IsScriptName(name string) bool {
	pattern := `.*\.(sh|py|rb|pl|js|lua|r|php|swift|groovy|scala|ps1|fish|bash|zsh|python|ruby|perl|javascript)$`
	match, _ := regexp.MatchString(pattern, name)
	return match
}

// GetFileExtension returns the file extension
func (k *Krun) GetFileExtension(filename string) string {
	ext := filepath.Ext(filename)
	return strings.ToLower(ext)
}

// DetectInterpreterFromShebang detects interpreter from shebang line
func (k *Krun) DetectInterpreterFromShebang(content string) string {
	lines := strings.Split(content, "\n")
	if len(lines) > 0 && strings.HasPrefix(lines[0], "#!") {
		shebang := strings.TrimSpace(lines[0][2:])
		if strings.Contains(shebang, "python3") {
			return "python3"
		} else if strings.Contains(shebang, "python") {
			return "python"
		} else if strings.Contains(shebang, "ruby") {
			return "ruby"
		} else if strings.Contains(shebang, "perl") {
			return "perl"
		} else if strings.Contains(shebang, "node") {
			return "node"
		} else if strings.Contains(shebang, "bash") {
			return "bash"
		} else if strings.Contains(shebang, "zsh") {
			return "zsh"
		} else if strings.Contains(shebang, "fish") {
			return "fish"
		} else if strings.Contains(shebang, "lua") {
			return "lua"
		} else if strings.Contains(shebang, "php") {
			return "php"
		}
	}
	return ""
}

// GetInterpreter determines the appropriate interpreter for a file
func (k *Krun) GetInterpreter(filename, content string) string {
	ext := k.GetFileExtension(filename)

	// Try to find interpreter from extension
	if interpreters, exists := INTERPRETERS[ext]; exists {
		for _, interpreter := range interpreters {
			if k.CommandExists(interpreter) {
				return interpreter
			}
		}
	}

	// Try to detect from shebang
	if content != "" {
		shebangInterpreter := k.DetectInterpreterFromShebang(content)
		if shebangInterpreter != "" && k.CommandExists(shebangInterpreter) {
			return shebangInterpreter
		}
	}

	// Default fallback
	if ext == "" || ext == ".sh" || ext == ".bash" {
		return "bash"
	}

	return ""
}

// CommandExists checks if a command exists in the system
func (k *Krun) CommandExists(command string) bool {
	cmd := exec.Command("which", command)
	cmd.Stdout = nil
	cmd.Stderr = nil
	err := cmd.Run()
	return err == nil
}

// GroupScriptsByLanguage groups scripts by their language/extension
func (k *Krun) GroupScriptsByLanguage(scripts []string) map[string][]string {
	groups := map[string][]string{
		"shell":      {},
		"python":     {},
		"ruby":       {},
		"perl":       {},
		"javascript": {},
		"other":      {},
	}

	for _, script := range scripts {
		ext := k.GetFileExtension(script)
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

// List lists available scripts grouped by language
func (k *Krun) List() {
	fmt.Println("🚀 Krun Multi-Language Script Collection")
	fmt.Println("==================================================")

	scripts := k.ListScripts()
	groupedScripts := k.GroupScriptsByLanguage(scripts)
	totalScripts := len(scripts)
	num := 1

	// Language icons mapping
	langIcons := map[string]string{
		"shell":      "🐚",
		"python":     "🐍",
		"ruby":       "💎",
		"perl":       "🐪",
		"javascript": "🟨",
		"other":      "📄",
	}

	// Display summary
	fmt.Printf("\n📊 Total Scripts: %d\n", totalScripts)

	activeGroups := 0
	for _, scriptList := range groupedScripts {
		if len(scriptList) > 0 {
			activeGroups++
		}
	}
	fmt.Printf("📁 Categories: %d\n\n", activeGroups)

	for _, lang := range []string{"shell", "python", "ruby", "perl", "javascript", "other"} {
		scriptList := groupedScripts[lang]
		if len(scriptList) > 0 {
			icon := langIcons[lang]
			fmt.Printf("%s %s Scripts (%d files)\n", icon, strings.ToUpper(lang), len(scriptList))
			fmt.Println("────────────────────────────────────────")
			for _, script := range scriptList {
				fmt.Printf("    [%2d] %s\n", num, script)
				num++
			}
			fmt.Println()
		}
	}

	fmt.Println("💡 Usage: krun <number> or krun <script_name>")
	fmt.Println("🔍 Debug: krun <number> --debug")
	fmt.Println("==================================================")
}

// Status prints the status and available interpreters
func (k *Krun) Status() {
	fmt.Println("Krun ready!")
	fmt.Println("Supported interpreters:")
	for ext, interpreters := range INTERPRETERS {
		var available []string
		for _, interpreter := range interpreters {
			if k.CommandExists(interpreter) {
				available = append(available, interpreter)
			}
		}
		if len(available) > 0 {
			fmt.Printf("  %s: %s\n", ext, strings.Join(available, ", "))
		}
	}
}

// Version prints version information
func (k *Krun) Version() {
	fmt.Println(BANNER)
	fmt.Println("\nv2.0 (Go)")
	fmt.Println("Copyright (c) 2023 kk")
	fmt.Println("MIT License")
}

// Languages shows supported languages
func (k *Krun) Languages() {
	fmt.Println("Supported script languages and extensions:")
	fmt.Println("")

	langMap := map[string][]string{
		"Shell/Bash":           {".sh", ".bash", ".zsh", ".fish"},
		"Python":               {".py", ".python"},
		"Ruby":                 {".rb", ".ruby"},
		"Perl":                 {".pl", ".perl"},
		"JavaScript (Node.js)": {".js", ".javascript"},
		"Lua":                  {".lua"},
		"R":                    {".r", ".R"},
		"PHP":                  {".php"},
		"Swift":                {".swift"},
		"Groovy":               {".groovy"},
		"Scala":                {".scala"},
		"PowerShell":           {".ps1"},
	}

	for lang, exts := range langMap {
		var availableInterpreters []string
		for _, ext := range exts {
			if interpreters, exists := INTERPRETERS[ext]; exists {
				for _, interpreter := range interpreters {
					if k.CommandExists(interpreter) {
						availableInterpreters = append(availableInterpreters, interpreter)
						break
					}
				}
			}
		}

		status := "✗"
		interpretersStr := "Not available"
		if len(availableInterpreters) > 0 {
			status = "✓"
			interpretersStr = strings.Join(availableInterpreters, ", ")
		}

		fmt.Printf("  %s %s: %s (%s)\n", status, lang, strings.Join(exts, ", "), interpretersStr)
	}
}

// Help prints the help message
func (k *Krun) Help() {
	fmt.Println(BANNER)
	fmt.Println("\nUsage:")
	fmt.Println("  krun list                    - List all available scripts")
	fmt.Println("  krun <number>                - Execute script by number")
	fmt.Println("  krun <script_name>           - Execute script by name")
	fmt.Println("  krun <number|script> --debug - Show script content and debug info")
	fmt.Println("  krun status                  - Show system status and available interpreters")
	fmt.Println("  krun languages               - Show supported languages")
	fmt.Println("  krun version                 - Show version information")
	fmt.Println("  krun help                    - Show this help message")
	fmt.Println("")
	fmt.Println("Examples:")
	fmt.Println("  krun 1                       - Execute first script")
	fmt.Println("  krun hello-world.sh          - Execute hello-world.sh")
	fmt.Println("  krun install-python3.py      - Execute Python script")
	fmt.Println("  krun config-system.rb        - Execute Ruby script")
	fmt.Println("  krun 5 --debug               - Show debug info for script #5")
}

// Debug prints the script content for debugging
func (k *Krun) Debug(opt interface{}) {
	u := k.Url(opt)
	parsedUrl, _ := url.Parse(u)
	filename := parsedUrl.Path[strings.LastIndex(parsedUrl.Path, "/")+1:]
	content := k.Get(u)

	fmt.Println("=== Script Debug Information ===")
	fmt.Printf("Filename: %s\n", filename)
	fmt.Printf("URL: %s\n", u)
	fmt.Printf("File extension: %s\n", k.GetFileExtension(filename))

	interpreter := k.GetInterpreter(filename, content)
	fmt.Printf("Detected interpreter: %s\n", interpreter)

	shebangInterpreter := k.DetectInterpreterFromShebang(content)
	if shebangInterpreter != "" {
		fmt.Printf("Shebang interpreter: %s\n", shebangInterpreter)
	}

	fmt.Println("\n=== Script Content ===")
	fmt.Println(content)
}

// RunScript executes the script with appropriate interpreter
func (k *Krun) RunScript(opt interface{}) {
	u := k.Url(opt)
	parsedUrl, _ := url.Parse(u)
	filename := parsedUrl.Path[strings.LastIndex(parsedUrl.Path, "/")+1:]

	// Download script content
	content := k.Get(u)

	// Determine interpreter
	interpreter := k.GetInterpreter(filename, content)

	if interpreter == "" {
		fmt.Printf("Error: Cannot determine interpreter for %s\n", filename)
		return
	}

	// Create temporary file
	tmpFile, err := os.CreateTemp("", "krun-*"+k.GetFileExtension(filename))
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

	// Make file executable
	if err := os.Chmod(tmpFile.Name(), 0755); err != nil {
		fmt.Printf("Error making file executable: %v\n", err)
		return
	}

	// Execute with appropriate interpreter
	fmt.Printf("Executing %s with %s...\n", filename, interpreter)

	cmd := exec.Command(interpreter, tmpFile.Name())
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	cmd.Stdin = os.Stdin

	err = cmd.Run()
	if err != nil {
		if exitError, ok := err.(*exec.ExitError); ok {
			if status, ok := exitError.Sys().(syscall.WaitStatus); ok {
				os.Exit(status.ExitStatus())
			}
		}
		fmt.Printf("Error executing script: %v\n", err)
	}
}

// Url returns the URL for the given option
func (k *Krun) Url(opt interface{}) string {
	var sh string
	if v, ok := opt.(int); ok {
		sh = k.ListScripts()[v-1]
	} else if v, ok := opt.(string); ok {
		sh = v
	}
	return fmt.Sprintf("https://raw.githubusercontent.com/kevin197011/krun/main/lib/%s", sh)
}

// ListScripts returns the list of scripts
func (k *Krun) ListScripts() []string {
	url := "https://raw.githubusercontent.com/kevin197011/krun/main/resources/krun.json"
	content := k.Get(url)
	var scripts []string
	json.Unmarshal([]byte(content), &scripts)
	return scripts
}

// Get performs an HTTP GET request and returns the response body as a string
func (k *Krun) Get(url string) string {
	client := &http.Client{}
	req, _ := http.NewRequest("GET", url, nil)
	req.Header.Set("User-Agent", UA)
	resp, err := client.Do(req)
	if err != nil {
		panic(err)
	}
	defer resp.Body.Close()

	body, _ := io.ReadAll(resp.Body)
	return string(body)
}

func main() {
	k := &Krun{}
	k.Run(os.Args)
}
