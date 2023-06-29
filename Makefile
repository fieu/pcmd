PROGRAM_NAME=pcmd
ENTRYPOINT=pcmd.go
CGO_ENABLED=0
BUILD_PREFIX=CGO_ENABLED=${CGO_ENABLED} go build -trimpath -ldflags "-s -w"

COMMIT_SHA=$(shell git rev-parse --short HEAD)
GIT_TAG=$(shell git describe --exact-match --abbrev=0 --tags 2>/dev/null)
ifeq ($(GIT_TAG),)
    BUILD_NAME := $(PROGRAM_NAME)-$(COMMIT_SHA)
else
    BUILD_NAME := $(PROGRAM_NAME)-$(GIT_TAG)
endif

.PHONY: build
## build: build the application
build: clean
	@echo "\033[33mBuilding...\033[0m"
	${BUILD_PREFIX} -o $(PROGRAM_NAME) $(ENTRYPOINT)
	@echo "\033[32mDone.\033[0m"

.PHONY: release
## release: build the application binaries for release
release: clean
	@echo "\033[33mBuilding...\033[0m"
	@mkdir dist
	GOARCH=arm64 GOOS=darwin ${BUILD_PREFIX} -o dist/$(BUILD_NAME)-macOS-arm64 $(ENTRYPOINT)
	GOARCH=amd64 GOOS=darwin ${BUILD_PREFIX} -o dist/$(BUILD_NAME)-macOS-x86_64 $(ENTRYPOINT)
	GOARCH=386 GOOS=linux ${BUILD_PREFIX} -o dist/$(BUILD_NAME)-Linux-x86 $(ENTRYPOINT)
	GOARCH=amd64 GOOS=linux ${BUILD_PREFIX} -o dist/$(BUILD_NAME)-Linux-x86_64 $(ENTRYPOINT)
	GOARCH=arm GOOS=linux ${BUILD_PREFIX} -o dist/$(BUILD_NAME)-Linux-arm $(ENTRYPOINT)
	GOARCH=arm64 GOOS=linux ${BUILD_PREFIX} -o dist/$(BUILD_NAME)-Linux-arm64 $(ENTRYPOINT)
	GOARCH=amd64 GOOS=freebsd ${BUILD_PREFIX} -o dist/$(BUILD_NAME)-FreeBSD-x86_64 $(ENTRYPOINT)
	GOARCH=amd64 GOOS=netbsd ${BUILD_PREFIX} -o dist/$(BUILD_NAME)-Linux-x86_64 $(ENTRYPOINT)
	GOARCH=amd64 GOOS=openbsd ${BUILD_PREFIX} -o dist/$(BUILD_NAME)-OpenBSD-x86_64 $(ENTRYPOINT)
	GOARCH=amd64 GOOS=dragonfly ${BUILD_PREFIX} -o dist/$(BUILD_NAME)-DragonFly-x86_64 $(ENTRYPOINT)
	GOARCH=amd64 GOOS=plan9 ${BUILD_PREFIX} -o dist/$(BUILD_NAME)-Plan9-x86_64 $(ENTRYPOINT)
	@echo "\033[32mDone.\033[0m"

.PHONY: run
## run: runs go run main.go
run:
	go run -race ${ENTRYPOINT}

.PHONY: clean
## clean: cleans the binary
clean:
	@echo "\033[33mCleaning...\033[0m"
	@rm -rf dist/
	@echo "\033[32mDone.\033[0m"


.PHONY: test
## test: runs go test with default values
test:
	go test -v -count=1 -race ./...

.PHONY: setup
## setup: setup go modules
setup:
	@go mod init \
		&& go mod tidy \
		&& go mod vendor

.PHONY: help
## help: Prints this help message
help:
	@echo "Usage: \n"
	@sed -n 's/^##//p' ${MAKEFILE_LIST} | column -t -s ':' |  sed -e 's/^/ /'
