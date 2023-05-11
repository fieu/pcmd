# pcmd
![](https://raw.githubusercontent.com/fieu/pcmd/master/demo.gif)

**pcmd** is a Go program that executes commands defined in a YAML file concurrently, with colorful output for each command.

This program was made to simplify the process of running multiple long-running commands concurrently, while still being able to distinguish between the output of each command.

## Installation

Install pcmd either through the GitHub releases page or by building from source.

### GitHub Releases:

Download the latest release from the GitHub [releases](https://github.com/fieu/pcmd/releases) page and extract the binary for your system.

### Go Install:
1. Run `go install github.com/fieu/pcmd@latest`
2. The binary will be installed to `$GOPATH/bin` (e.g. `~/go/bin`)

### Building from Source:
1. Clone the repository using `git clone https://github.com/fieu/pcmd.git`
2. Build the binary using `go build`
3. Move the binary to a directory in your `PATH` (e.g. `/usr/local/bin`)
4. Make the binary executable using `chmod +x pcmd`

## Usage

To use pcmd, create a YAML file (`pcmd.yml`) with the following structure:

```yaml
- name: System Log
  command: tail -f /var/log/system.log
- name: WiFi
  command: tail -f /var/log/wifi.log
```

Each command consists of a `name` and a `command` field. Customize the commands as per your requirements.

Once you have the YAML file set up, run pcmd using the following command in the same directory as the YAML file:

```shell
pcmd
```

pcmd will read the YAML file, execute the commands concurrently, and display the output with colorful prefixes for each command.

Both stdout and stderr are displayed in the output. If a program exits, pcmd will display the exit code.

## Contributing

Contributions are welcome! If you find any issues or have suggestions, please open an issue or a pull request.

## License

pcmd is licensed under the MIT License. See [LICENSE](https://github.com/fieu/pcmd/blob/master/LICENSE) for more information.