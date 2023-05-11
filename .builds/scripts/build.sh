#!/usr/bin/env bash

# Supported platforms
platforms=(
	"aix/ppc64"
	"darwin/amd64"
	"darwin/arm64"
	"dragonfly/amd64"
	"freebsd/386"
	"freebsd/amd64"
	"freebsd/arm"
	"freebsd/arm64"
	"illumos/amd64"
	"linux/386"
	"linux/amd64"
	"linux/arm"
	"linux/arm64"
	"linux/ppc64"
	"linux/ppc64le"
	"linux/mips"
	"linux/mipsle"
	"linux/mips64"
	"linux/mips64le"
	"linux/riscv64"
	"linux/s390x"
	"netbsd/386"
	"netbsd/amd64"
	"netbsd/arm"
	"openbsd/386"
	"openbsd/amd64"
	"openbsd/arm"
	"openbsd/arm64"
	"openbsd/mips64"
	"plan9/386"
	"plan9/amd64"
	"plan9/arm"
	"solaris/amd64"
	"windows/amd64"
	"windows/386"
	"windows/arm"
	"windows/arm64"
)

# Colors
# shellcheck disable=SC2034
Black='\e[0;30m'  # Black
Red='\e[0;31m'    # Red
Green='\e[0;32m'  # Green
Yellow='\e[0;33m' # Yellow
Blue='\e[0;34m'   # Blue
Purple='\e[0;35m' # Purple
Cyan='\e[0;36m'   # Cyan
# shellcheck disable=SC2034
White='\e[0;37m' # White
Reset='\e[0m'    # Text Reset

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"

# Program settings
PROGRAM_NAME="$1"
SHOULD_GARBLE="$2"
SHOULD_HIDE_WINDOWS_CONSOLE="$3"

# If all arguments aren't set, exit 1 and print usage
if [ -z "$PROGRAM_NAME" ] || [ -z "$SHOULD_GARBLE" ] || [ -z "$SHOULD_HIDE_WINDOWS_CONSOLE" ]; then
	echo -ne "Usage: ${Yellow}$0${Reset} ${Cyan}<program_name> <should_garble> <should_hide_windows_console>${Reset}\n"
	# shellcheck disable=SC2059
	printf "\t${Cyan}program_name${Reset} ${Blue}(string)${Reset} - The name of the program to build\n"
	# shellcheck disable=SC2059
	printf "\t${Cyan}should_garble${Reset} ${Blue}(boolean)${Reset} - Whether or not to garble the program\n"
	# shellcheck disable=SC2059
	printf "\t${Cyan}should_hide_windows_console${Reset} ${Blue}(boolean)${Reset} - Whether or not to hide the windows console\n"
	# Example in grey color
	echo -ne "Example: ${Yellow}$0${Reset} ${Cyan}myprogram true true${Reset}\n"
	exit 1
fi

if [ "$SHOULD_GARBLE" = "true" ]; then
	GO_BINARY="garble -literals -tiny -seed random"
else
	GO_BINARY="go"
fi

# Explain all program arguments to user before program initialization, check if enabled, cross if not
echo -ne "${Blue}1.${Reset} Program name: ${Yellow}$PROGRAM_NAME${Reset}\n"
if [ "$SHOULD_GARBLE" = "true" ]; then
	echo -ne "${Blue}2.${Reset} Should garble: ${Green}true${Reset}\n"
else
	echo -ne "${Blue}2.${Reset} Should garble: ${Red}false${Reset}\n"
fi
if [ "$SHOULD_HIDE_WINDOWS_CONSOLE" = "true" ]; then
	echo -ne "${Blue}3.${Reset} Should hide Windows console: ${Green}true${Reset}\n"
else
	echo -ne "${Blue}3.${Reset} Should hide Windows console: ${Red}false${Reset}\n"
fi

# Check if the "garble" command exists
if [ "$SHOULD_GARBLE" = "true" ]; then
	if ! command -v garble &>/dev/null; then
		echo -ne "${Red}garble${Reset} could not be found. Please install it with ${Yellow}go install mvdan.cc/garble@latest${Reset}\n"
		exit 1
	fi
fi

calculate_file_size_in_mb() {
	# if on macOS, use gdu, otherwise use du
	if command -v gdu &>/dev/null; then
		file_size="$(gdu -b "$1" | cut -f1)"
	else
		file_size="$(du -b "$1" | cut -f1)"
	fi
	file_size_mb=$(echo "scale=2; ${file_size}/1024/1024" | bc)
	echo -ne "$file_size_mb"
}

build_time() {
	if [[ -z ${1} || ${1} -lt 60 ]]; then
		min=0
		secs="${1}"
	else
		time_mins=$(echo "scale=2; ${1}/60" | bc)
		min=$(echo "${time_mins}" | cut -d'.' -f1)
		secs="0.$(echo "${time_mins}" | cut -d'.' -f2)"
		secs=$(echo "${secs}"*60 | bc | awk '{print int($1+0.5)}')
	fi
	if [[ "$2" = "platform" ]]; then
		echo -ne "$Blue""\t(""$Cyan""${secs}""$Blue""s)""$Reset""\t" "${Cyan}$(calculate_file_size_in_mb "${3}")""$Blue"" MB""$Reset""\n"
	else
		echo -e "$Blue""Time elapsed: ""$Cyan""${min}""$Blue"" minutes and ""$Cyan""${secs}""$Blue"" seconds."
	fi
}

rm -rf "$SCRIPT_DIR/../../dist" || true
mkdir -p "$SCRIPT_DIR/../../dist"

# Given a list of words and their replacements, replace words in a filename
# $1: filename
# $2: list of words to replace
# $3: list of replacements
replace_words_in_filename() {
	filename="$1"

	words=(
		"amd64"
		"386"
		"linux"
		"openbsd"
		"freebsd"
		"netbsd"
		"solaris"
		"plan9"
		"dragonfly"
		"aix"
		"darwin"
		"windows"
	)

	replacements=(
		"x86_64"
		"x86"
		"Linux"
		"OpenBSD"
		"FreeBSD"
		"NetBSD"
		"Solaris"
		"Plan9"
		"DragonFly"
		"AIX"
		"macOS"
		"Windows"
	)
	for i in "${!words[@]}"; do
		filename="${filename//${words[$i]}/${replacements[$i]}}"
	done
	echo -ne "$filename"
}

x=1
start_time="$(date -u +%s)"
revision="$(git describe --tags 2>/dev/null || git rev-parse --short HEAD 2>/dev/null)"
if [[ -z ${revision} ]]; then
	revision="unknown"
fi

for platform in "${platforms[@]}"; do
	# shellcheck disable=SC2206
	platform_split=(${platform//\// })
	GOOS=${platform_split[0]}
	GOARCH=${platform_split[1]}
	output_name="$PROGRAM_NAME-$revision-$GOOS-$GOARCH"

	if [ "$GOOS" = "windows" ]; then
		output_name+=".exe"
	fi

	platform_start_time="$(date -u +%s)"
	echo -ne "${Blue}[${Purple}$(printf "%02d" $x)/${#platforms[@]}${Blue}]\t""$Cyan""Compiling binary for ""$Yellow""$GOOS/$GOARCH""$Cyan""...""$Reset"

	extra_flags=""
	tags=""
	flags="-ldflags='-s -w"
	if [ "$GOOS" = "linux" ] || [ "$GOOS" = "freebsd" ] || [ "$GOOS" = "netbsd" ] || [ "$GOOS" = "dragonfly" ] || [ "$GOOS" = "plan9" ] || [ "$GOOS" = "openbsd" ] || [ "$GOOS" = "windows" ]; then
		flags+=" -extldflags \"-static\""
		tags="-tags netgo"
	fi
	# Hide windows console if need be
	if [ "$GOOS" = "windows" ] && [ "$SHOULD_HIDE_WINDOWS_CONSOLE" = "true" ]; then
		flags+=" -H=windowsgui"
	fi
	flags+="'"
	if [ "$SHOULD_GARBLE" = "true" ]; then
		flags+=" -buildvcs=false -trimpath"
	fi
	eval CGO_ENABLED="0" GOOS="$GOOS" GOARCH="$GOARCH" "$extra_flags" "$GO_BINARY" build "$tags" "$flags" -o "dist/$output_name" "$SCRIPT_DIR/../.."
	platform_end_time="$(date -u +%s)"
	platform_elapsed="$(("$platform_end_time" - "$platform_start_time"))"
	build_time "$platform_elapsed" "platform" "dist/$output_name"

  # Rename it with more friendly naming convention
	new_name="$(replace_words_in_filename "$output_name")"
	mv "dist/$output_name" "dist/$new_name"

	# If the directory dist/compressed doesn't exist, create it
	if [ ! -d "dist/compressed" ]; then
    mkdir -p "dist/compressed"
  fi

	# Compress at maximum level the file into a .tar.gz file, however if it's a Windows .exe file, make it a .zip file. Use 7zip
	# if it's available, otherwise use tar.
	if [ "$GOOS" = "windows" ]; then
    if command -v 7z &>/dev/null; then
      cd "dist" || exit 1
      7z a -mx=9 -tzip "compressed/${new_name%.exe}.zip" "$new_name" &>/dev/null
      cd ..
    else
      cd "dist" || exit 1
      zip -9 -q "compressed/${new_name%.exe}.zip" "$new_name"
      cd ..
    fi
    # Delete file before compress
#    rm "dist/$new_name"
  else
    if command -v 7z &>/dev/null; then
      cd "dist" || exit 1
      7z a -mx=9 -ttar "compressed/$new_name.tar.gz" "$new_name" &>/dev/null
      cd ./
    else
      cd "dist" || exit 1
      GZIP=-9 tar -czf "compressed/$new_name.tar.gz" "$new_name" &>/dev/null
      cd ..
    fi
    # Delete file before compress
#    rm "dist/$new_name"
  fi

	# shellcheck disable=SC2181
	if [ $? -ne 0 ]; then
		echo -e "$Red""An error has occurred! Aborting the script execution...""$Reset"
		exit 1
	fi
	x=$((x + 1))
done
end_time="$(date -u +%s)"
# shellcheck disable=SC2004
elapsed="$(($end_time - $start_time))"
echo -e "$Green""Finished.""$Reset" "$(build_time "$elapsed")"
