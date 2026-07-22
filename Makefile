.PHONY: help clean clean-godot setup-godot build-godot-headers setup-apple build-apple package

# ============================================================================
# Directory Configuration
# ============================================================================
ROOT_DIR := $(shell pwd)

GODOT_DIR        = $(ROOT_DIR)/godot
SOURCE_DIR       = $(ROOT_DIR)/source
IOS_SOURCE_DIR   = $(SOURCE_DIR)/ios/att
ADDONS_DIR       = $(ROOT_DIR)/addons/godotx_att

IOS_PLUGINS_DIR  = $(ROOT_DIR)/ios/plugins

# ============================================================================
# Module Configuration
# ============================================================================
APPLE_MODULE      = att
APPLE_MODULE_NAME = ATT

# ============================================================================
# Build Configuration
# ============================================================================
BUILD_CONFIGS    = Debug Release
APPLE_SDK_ARCHS  = iphoneos/arm64 iphonesimulator/arm64 iphonesimulator/x86_64

# ============================================================================
# Version Configuration
# ============================================================================
GODOT_VERSION = 4.7-stable
GODOT_REPO    = https://github.com/godotengine/godot.git

# ============================================================================
# Help
# ============================================================================

help:
	@echo "Godotx ATT Build System"
	@echo "================================"
	@echo ""
	@echo "Available targets:"
	@echo "  setup-godot         - Clone/update Godot source (required for compilation)"
	@echo "  build-godot-headers - Generate Godot headers (required for iOS plugin compilation)"
	@echo "  setup-apple         - Generate Xcode project via XcodeGen"
	@echo "  build-apple         - Build iOS ATT plugin (GodotxATT xcframework + .gdip)"
	@echo "  package             - Create distribution package (godotx_att.zip)"
	@echo "  clean               - Clean build artifacts"
	@echo "  clean-godot         - Remove Godot source"

# ============================================================================
# Godot Setup Targets
# ============================================================================

setup-godot:
	@echo "====================================================================="
	@echo "Setting up Godot source code..."
	@echo "====================================================================="
	@echo ""
	@if [ -d "$(GODOT_DIR)" ]; then \
		echo "→ Godot directory already exists"; \
		cd $(GODOT_DIR) && \
		echo "  • Fetching latest changes..." && \
		git fetch origin && \
		echo "  • Checking out $(GODOT_VERSION)..." && \
		git checkout $(GODOT_VERSION) && \
		git pull origin $(GODOT_VERSION) && \
		cd ..; \
		echo "  ✓ Godot updated to $(GODOT_VERSION)"; \
	else \
		echo "→ Cloning Godot repository..."; \
		git clone --depth 1 --branch $(GODOT_VERSION) $(GODOT_REPO) $(GODOT_DIR) && \
		echo "  ✓ Godot $(GODOT_VERSION) cloned successfully"; \
	fi
	@echo ""
	@echo "====================================================================="
	@echo "✓ Godot source ready!"
	@echo "====================================================================="

build-godot-headers: setup-godot
	@echo "====================================================================="
	@echo "Building Godot headers..."
	@echo "====================================================================="
	@echo ""
	@echo "→ Generating iOS headers with scons..."
	@cd $(GODOT_DIR) && scons platform=ios target=template_release
	@echo ""
	@echo "====================================================================="
	@echo "✓ Godot headers generated!"
	@echo "====================================================================="

# ============================================================================
# Apple (iOS) ATT Targets
# ============================================================================

setup-apple: setup-godot
	@echo "====================================================================="
	@echo "Setting up Apple (iOS) ATT module..."
	@echo "====================================================================="
	@echo ""
	@echo "→ Setting up $(APPLE_MODULE) (Godotx$(APPLE_MODULE_NAME))..."
	@(cd $(IOS_SOURCE_DIR) && \
		echo "  • Creating build directory..." && \
		rm -rf build && mkdir -p build && \
		touch build/.gdignore && \
		echo "  • Generating Xcode project via XcodeGen..." && \
		xcodegen generate -s project.yml -p build/)
	@echo ""
	@echo "====================================================================="
	@echo "✓ Apple ATT module setup complete!"
	@echo "====================================================================="

build-apple: setup-apple
	@echo "====================================================================="
	@echo "Building Apple (iOS) ATT module..."
	@echo "====================================================================="
	@echo ""
	@echo "→ Building $(APPLE_MODULE) (Godotx$(APPLE_MODULE_NAME))..."
	@(cd $(IOS_SOURCE_DIR) && \
		rm -rf $(IOS_PLUGINS_DIR)/$(APPLE_MODULE) && \
		mkdir -p $(IOS_PLUGINS_DIR)/$(APPLE_MODULE) && \
		for config in $(BUILD_CONFIGS); do \
			config_lower=$$(echo $$config | tr '[:upper:]' '[:lower:]'); \
			echo "  • Building $$config configuration..."; \
			echo "    - Cleaning $$config..." && \
			xcodebuild clean -project build/Godotx$(APPLE_MODULE_NAME).xcodeproj \
				-scheme Godotx$(APPLE_MODULE_NAME) \
				-configuration $$config && \
			for sdk_arch in $(APPLE_SDK_ARCHS); do \
				sdk=$$(echo $$sdk_arch | cut -d/ -f1); \
				arch=$$(echo $$sdk_arch | cut -d/ -f2); \
				echo "    - Building $$config for $$sdk ($$arch)..." && \
				xcodebuild \
					-project build/Godotx$(APPLE_MODULE_NAME).xcodeproj \
					-scheme Godotx$(APPLE_MODULE_NAME) \
					-sdk $$sdk \
					-arch $$arch \
					-configuration $$config \
					SKIP_INSTALL=NO \
					BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
					CODE_SIGNING_ALLOWED=NO \
					CODE_SIGNING_REQUIRED=NO || exit 1; \
			done && \
			echo "    - Creating universal simulator library..." && \
			mkdir -p build/bin/$$config_lower-simulator && \
			lipo -create \
				build/bin/$$config_lower-iphonesimulator-arm64/libGodotx$(APPLE_MODULE_NAME).a \
				build/bin/$$config_lower-iphonesimulator-x86_64/libGodotx$(APPLE_MODULE_NAME).a \
				-output build/bin/$$config_lower-simulator/libGodotx$(APPLE_MODULE_NAME).a && \
			cp -r build/bin/$$config_lower-iphonesimulator-arm64/include build/bin/$$config_lower-simulator && \
			echo "    - Creating $$config XCFramework..." && \
			xcodebuild -create-xcframework \
				-library build/bin/$$config_lower-iphoneos-arm64/libGodotx$(APPLE_MODULE_NAME).a \
				-headers build/bin/$$config_lower-iphoneos-arm64/include \
				-library build/bin/$$config_lower-simulator/libGodotx$(APPLE_MODULE_NAME).a \
				-headers build/bin/$$config_lower-simulator/include \
				-output $(IOS_PLUGINS_DIR)/$(APPLE_MODULE)/Godotx$(APPLE_MODULE_NAME).$$config_lower.xcframework && \
			echo "    ✓ $$config build complete"; \
		done && \
		echo "    - Cleaning temporary build artifacts..." && \
		rm -rf bin && \
		rm -rf build && \
		echo "  • Copying .gdip file to output..." && \
		cp att.gdip $(IOS_PLUGINS_DIR)/$(APPLE_MODULE)/ && \
		echo "  ✓ ATT module build complete (Debug + Release)" \
	)
	@echo ""
	@echo "====================================================================="
	@echo "✓ Apple ATT module built successfully!"
	@echo "====================================================================="

# ============================================================================
# Package Target
# ============================================================================

package:
	@echo "====================================================================="
	@echo "Creating package..."
	@echo "====================================================================="
	@echo ""
	@echo "→ Creating package directory..."
	@rm -rf godotx_att
	@mkdir -p godotx_att
	@echo "→ Copying addons..."
	@cp -a addons godotx_att/
	@echo "→ Copying iOS plugin..."
	@cp -a ios godotx_att/
	@echo "→ Copying license and readme..."
	@cp -a LICENSE godotx_att/
	@cp -a README.md godotx_att/
	@echo "→ Creating zip archive..."
	@zip -ry godotx_att.zip godotx_att
	@echo ""
	@echo "====================================================================="
	@echo "✓ Package created: godotx_att.zip"
	@echo "====================================================================="

# ============================================================================
# Clean Targets
# ============================================================================

clean:
	@echo "====================================================================="
	@echo "Cleaning build artifacts..."
	@echo "====================================================================="
	@echo ""
	@echo "→ Cleaning iOS ATT..."
	@rm -rf $(IOS_PLUGINS_DIR)/$(APPLE_MODULE)
	@rm -rf $(IOS_SOURCE_DIR)/build
	@echo ""
	@echo "====================================================================="
	@echo "✓ Clean complete!"
	@echo "====================================================================="

clean-godot:
	@echo "====================================================================="
	@echo "Removing Godot source..."
	@echo "====================================================================="
	@echo ""
	@if [ -d "$(GODOT_DIR)" ]; then \
		echo "→ Removing Godot directory..."; \
		rm -rf $(GODOT_DIR); \
		echo "  ✓ Godot source removed"; \
	else \
		echo "  • Godot directory does not exist"; \
	fi
	@echo ""
	@echo "====================================================================="
	@echo "✓ Done!"
	@echo "====================================================================="
