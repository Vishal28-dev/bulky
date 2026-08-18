# ─── bulky Makefile ───────────────────────────────────────────────────────────
# Usage:
#   make windows      Build release .exe for Windows (run on Windows)
#   make macos        Build release .app for macOS
#   make windows-dbg  Build debug Windows build
#   make macos-dbg    Build debug macOS build
#   make run          Run the app in debug mode (platform auto-detected)
#   make analyze      Run Dart static analysis
#   make test         Run unit tests
#   make clean        Remove all build artifacts
#   make pubs         flutter pub get
#   make codegen      Re-run drift / build_runner code generation
#   make dist-macos   Zip the macOS release .app (this machine)
#   make dist         Alias for dist-macos on Darwin; Windows zips come from CI

FLUTTER     := flutter
BUILD_DIR   := build
DIST_DIR    := dist
APP_NAME    := bulky
VERSION     := $(shell grep '^version:' pubspec.yaml | awk '{print $$2}' | tr -d '\r')

.PHONY: all windows macos windows-dbg macos-dbg run analyze test clean pubs codegen dist dist-macos

# ─── Default ──────────────────────────────────────────────────────────────────
all: analyze

# ─── Dependencies ─────────────────────────────────────────────────────────────
pubs:
	@echo "📦  flutter pub get"
	$(FLUTTER) pub get

codegen: pubs
	@echo "⚙️   Running build_runner (drift code generation)"
	$(FLUTTER) pub run build_runner build --delete-conflicting-outputs

# ─── Analysis & Tests ─────────────────────────────────────────────────────────
analyze:
	@echo "🔍  Analyzing Dart code"
	$(FLUTTER) analyze --no-pub

test:
	@echo "🧪  Running tests"
	$(FLUTTER) test --no-pub

# ─── macOS ────────────────────────────────────────────────────────────────────
macos:
	@echo "🍎  Building macOS release ($(VERSION))"
	$(FLUTTER) build macos --release --no-pub
	@echo "✅  Output: build/macos/Build/Products/Release/$(APP_NAME).app"

macos-dbg:
	@echo "🍎  Building macOS debug"
	$(FLUTTER) build macos --debug --no-pub
	@echo "✅  Output: build/macos/Build/Products/Debug/$(APP_NAME).app"

# ─── Windows ──────────────────────────────────────────────────────────────────
windows:
	@echo "🪟  Building Windows release ($(VERSION))"
	$(FLUTTER) build windows --release --no-pub
	@echo "✅  Output: build/windows/x64/runner/Release/"

windows-dbg:
	@echo "🪟  Building Windows debug"
	$(FLUTTER) build windows --debug --no-pub
	@echo "✅  Output: build/windows/x64/runner/Debug/"

# ─── Run ──────────────────────────────────────────────────────────────────────
run:
	@echo "🚀  Running in debug mode"
	$(FLUTTER) run -d $(shell uname -s | sed 's/Darwin/macos/;s/Linux/linux/;s/MINGW.*/windows/')

# ─── Distribution zips ────────────────────────────────────────────────────────
# Windows cannot be built on macOS. GitHub Actions produces the Windows zip.
dist-macos: macos
	@echo "📦  Creating macOS zip"
	@mkdir -p $(DIST_DIR)
	@cd "build/macos/Build/Products/Release" && \
	  zip -r "../../../../../$(DIST_DIR)/$(APP_NAME)-$(VERSION)-macos.zip" "$(APP_NAME).app" && \
	  echo "  ✅  $(DIST_DIR)/$(APP_NAME)-$(VERSION)-macos.zip"

ifeq ($(shell uname -s),Darwin)
dist: dist-macos
else
dist: windows
	@echo "📦  Creating Windows zip"
	@mkdir -p $(DIST_DIR)
	@cd "build/windows/x64/runner" && \
	  zip -r "../../../../$(DIST_DIR)/$(APP_NAME)-$(VERSION)-windows.zip" "Release" && \
	  echo "  ✅  $(DIST_DIR)/$(APP_NAME)-$(VERSION)-windows.zip"
endif

# ─── Clean ────────────────────────────────────────────────────────────────────
clean:
	@echo "🧹  Cleaning build artifacts"
	$(FLUTTER) clean
	rm -rf $(DIST_DIR)
	@echo "✅  Done"

# ─── Help ─────────────────────────────────────────────────────────────────────
help:
	@echo ""
	@echo "  bulky $(VERSION) — build targets"
	@echo ""
	@echo "  make macos        Release .app for macOS"
	@echo "  make windows      Release .exe folder for Windows"
	@echo "  make macos-dbg    Debug .app for macOS"
	@echo "  make windows-dbg  Debug build for Windows"
	@echo "  make dist-macos   Zip macOS release into dist/"
	@echo "  make dist         Zip for this OS (macOS here; Windows on CI)"
	@echo "  make run          Run locally in debug mode"
	@echo "  make analyze      Static analysis"
	@echo "  make test         Unit tests"
	@echo "  make pubs         flutter pub get"
	@echo "  make codegen      Drift code generation"
	@echo "  make clean        Remove all build output"
	@echo ""
