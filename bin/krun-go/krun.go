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
	"regexp"
	"strconv"
	"strings"
)

// User-Agent string
const UA = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/103.0.0.0 Safari/537.36"

// Krun struct to hold methods
type Krun struct{}

// Run executes the main functionality based on arguments
func (k *Krun) Run(args []string) {
	if len(args) < 2 {
		k.Help()
		return
	}
	switch args[1] {
	case "list":
		k.List()
	case "help":
		k.Help()
	case "status":
		k.Status()
	default:
		if match, _ := regexp.MatchString(`^\d+$`, args[1]); match {
			opt, _ := strconv.Atoi(args[1])
			if len(args) == 3 && args[2] == "--debug" {
				k.Debug(opt)
				return
			}
			k.RunScript(opt)
		} else if match, _ := regexp.MatchString(`.*\.sh$`, args[1]); match {
			opt := args[1]
			if len(args) == 3 && args[2] == "--debug" {
				k.Debug(opt)
				return
			}
			k.RunScript(opt)
		} else {
			k.Help()
		}
	}
}

// List lists available scripts
func (k *Krun) List() {
	fmt.Println("  Krun Script List:")
	scripts := k.ListScripts()
	for i, script := range scripts {
		fmt.Printf("    - [%d] %s\n", i+1, script)
	}
}

// Status prints the status
func (k *Krun) Status() {
	fmt.Println("Krun ready!")
}

// Help prints the help message
func (k *Krun) Help() {
	fmt.Println("  Usage: krun [list | help | <number> | <number> --debug ]")
}

// Debug prints the script content for debugging
func (k *Krun) Debug(opt interface{}) {
	url := k.Url(opt)
	content := k.Get(url)
	fmt.Println(content)
}

// RunScript executes the script
func (k *Krun) RunScript(opt interface{}) {
	u := k.Url(opt)
	parsedUrl, _ := url.Parse(u)
	sh := parsedUrl.Path[strings.LastIndex(parsedUrl.Path, "/")+1:]

	tmpFile := fmt.Sprintf("/tmp/%s", sh)
	content := k.Get(u)
	os.WriteFile(tmpFile, []byte(content), 0755)

	cmd := exec.Command("bash", tmpFile)
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	cmd.Run()
	os.Remove(tmpFile)
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
