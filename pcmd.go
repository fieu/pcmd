package main

import (
	"bufio"
	"fmt"
	"io"
	"math/rand"
	"os"
	"os/exec"
	"sync"

	"gopkg.in/yaml.v2"
)

type Command struct {
	Name    string `yaml:"name"`
	Command string `yaml:"command"`
}

type CommandRunner struct {
	name    string
	command string
}

type ColorManager struct {
	colors   []int
	colorMux sync.Mutex
}

func NewColorManager() *ColorManager {
	return &ColorManager{
		colors: make([]int, 0),
	}
}

func (cm *ColorManager) GetColor() int {
	cm.colorMux.Lock()
	defer cm.colorMux.Unlock()

	hardcodedColors := []int{32, 33, 34, 35, 36, 91, 92, 93, 94, 95, 96} // 11 possible different colors

	if len(cm.colors) == 0 {
		cm.colors = make([]int, len(hardcodedColors))
		copy(cm.colors, hardcodedColors)
		rand.Shuffle(len(cm.colors), func(i, j int) {
			cm.colors[i], cm.colors[j] = cm.colors[j], cm.colors[i]
		})
	}

	colorCode := cm.colors[len(cm.colors)-1]
	cm.colors = cm.colors[:len(cm.colors)-1]
	return colorCode
}

func (c *CommandRunner) run(colorManager *ColorManager) {
	colorCode := colorManager.GetColor()
	prefix := fmt.Sprintf("\033[%dm[%s]\033[0m", colorCode, c.name) // Color formatted prefix
	cmd := exec.Command("sh", "-c", c.command)

	// Create a pipe for capturing stderr
	stderrPipe, err := cmd.StderrPipe()
	if err != nil {
		fmt.Println("Error creating stderr pipe:", err)
		return
	}

	// Create a pipe for capturing stdout
	stdoutPipe, err := cmd.StdoutPipe()
	if err != nil {
		fmt.Println("Error creating stdout pipe:", err)
		return
	}

	// Start the command
	if err := cmd.Start(); err != nil {
		fmt.Println("Error starting command:", err)
		return
	}

	// Create a scanner for reading stdout
	scanner := bufio.NewScanner(stdoutPipe)
	for scanner.Scan() {
		line := scanner.Text()
		fmt.Printf("%s %s\n", prefix, line)
	}

	// Create a scanner for reading stderr
	errScanner := bufio.NewScanner(stderrPipe)
	for errScanner.Scan() {
		line := errScanner.Text()
		_, err := fmt.Fprintf(os.Stderr, "%s %s\n", prefix, line)
		if err != nil {
			fmt.Println("Error writing to stderr:", err)
			return
		}
	}

	// Wait for the command to finish
	if err := cmd.Wait(); err != nil {
		fmt.Printf("%s \033[%dmfinished with error: %s\033[0m\n", prefix, colorCode, err)
	} else {
		fmt.Printf("%s \033[%dmfinished with exit code 0\033[0m\n", prefix, colorCode)
	}
}

func runCommands(commands []*Command) {
	var wg sync.WaitGroup
	colorManager := NewColorManager()

	defer wg.Wait()

	for _, cmd := range commands {
		wg.Add(1)
		go func(cmd *Command) {
			defer wg.Done()
			runner := &CommandRunner{name: cmd.Name, command: cmd.Command}
			runner.run(colorManager)
			fmt.Println()
		}(cmd)
	}
}

func main() {
	file, err := os.Open("pcmd.yml")
	if err != nil {
		fmt.Println("Error opening pcmd.yml file:", err)
		return
	}
	defer func(file *os.File) {
		err := file.Close()
		if err != nil {
			fmt.Println("Error closing pcmd.yml file:", err)
		}
	}(file)

	yamlData, err := io.ReadAll(file)
	if err != nil {
		fmt.Println("Error reading pcmd.yml file:", err)
		return
	}

	var commands []*Command
	err = yaml.Unmarshal(yamlData, &commands)
	if err != nil {
		fmt.Println("Error decoding pcmd.yml file:", err)
		return
	}

	runCommands(commands)
}
