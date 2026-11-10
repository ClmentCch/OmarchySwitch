# OmarchySwitch - top-level build entry points.
#
# Everything real lives in scripts/ and build/scripts/; this Makefile only
# provides short, discoverable names. Run `make help` for the list.
#
# Root-requiring targets are marked; they never touch a block device
# implicitly.

SHELL := /usr/bin/env bash
.DEFAULT_GOAL := help

DIST_DIR   := dist
OUTPUT_DIR := build/output
VERSION    := $(shell cat VERSION)
ZIP        := $(DIST_DIR)/OmarchySwitch-Base-v$(VERSION).zip
ROOTFS     ?= $(OUTPUT_DIR)/rootfs
IMAGE      ?= $(OUTPUT_DIR)/omarchyswitch-$(VERSION).img
SD_DEVICE  ?=

.PHONY: help config validate syntax lint package fetch rootfs switchroot omarchy desktop image install clean distclean

help: ## Show available targets
	@printf 'OmarchySwitch %s\n\n' "$(VERSION)"
	@awk 'BEGIN {FS = ":.*## "} /^[a-zA-Z_-]+:.*## / {printf "  \033[1m%-12s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

config: ## Print the effective configuration
	@scripts/lib/common.sh --print-config 2>/dev/null || bash -c 'set -a; source configs/omarchyswitch.conf; [ -f configs/local.conf ] && source configs/local.conf; set +a; env | grep -E "^(DISTRO|TARGET|ALARM|OMARCHY|HEKATE|SWITCHROOT|BOOT|ROOT|IMAGE)" | sort'

validate: ## Static repository checks (no root, no network)
	@./scripts/validate-architecture.sh

syntax: ## Bash syntax check on every shell script
	@find . -name '*.sh' -not -path './.git/*' -print0 | xargs -0 -n1 bash -n
	@echo 'syntax: ok'

lint: ## shellcheck every shell script (requires shellcheck)
	@command -v shellcheck >/dev/null || { echo 'shellcheck is not installed' >&2; exit 1; }
	@find . -name '*.sh' -not -path './.git/*' -print0 | xargs -0 shellcheck -x

fetch: ## Fetch pinned upstream sources (Omarchy, hekate)
	@./build/scripts/fetch-upstreams.sh

rootfs: ## Bootstrap the Arch Linux ARM64 rootfs (root, network)
	@sudo ./scripts/build-rootfs.sh --output '$(ROOTFS)'

switchroot: ## Integrate verified Switchroot components (root)
	@sudo ./scripts/integrate-switchroot.sh --rootfs '$(ROOTFS)'

omarchy: ## Integrate Omarchy packages and configurations (root)
	@sudo ./scripts/integrate-omarchy.sh --rootfs '$(ROOTFS)'

desktop: ## Apply desktop configuration overlays (root)
	@sudo ./scripts/install-desktop.sh --rootfs '$(ROOTFS)'

image: ## Build the bootable SD image from a prepared rootfs (root)
	@sudo ./scripts/build-image.sh --rootfs '$(ROOTFS)' --output '$(IMAGE)'

package: ## Build the release archive in dist/
	@./scripts/package-release.sh

install: ## Write the image to a block device: make install SD_DEVICE=/dev/sdX
	@test -n '$(SD_DEVICE)' || { echo 'usage: make install SD_DEVICE=/dev/sdX' >&2; exit 2; }
	@sudo ./installer/scripts/install.sh --device '$(SD_DEVICE)' --image '$(IMAGE)'

clean: ## Remove generated archives and images
	@rm -rf '$(DIST_DIR)'
	@rm -f '$(OUTPUT_DIR)'/*.img
	@echo 'clean: done'

distclean: clean ## Also remove build sources and rootfs trees
	@rm -rf '$(OUTPUT_DIR)' build/src build/cache omarchy/upstream/src
	@echo 'distclean: done'
