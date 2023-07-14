# Pico-SDK + Toolchain installer for macOS

- Download the arm64 variant for Apple Silicon Macs or the x86_64 variant for Intel Macs.
- Execute and follow install instructions.
- Installer will automatically setup auto-detection of newly the installed sdk and toolchain for the Raspberry Pi Pico Visual Studio Code extension.

## Manually building the pkg

### Requirements

- Git and Github Cli
- Python 3.10+ in PATH
- Xcode Command Line Tools
- macOS Ventura or later (previous versions may work but are untested; must contain zsh)

### Building

```zsh
Usage: ./build.sh <pico_sdk_release_tag> <toolchain_tag>

To build and sign set APPLE_DEVELOPER_INSTALLER_ID environment variable
before.
For example, if you have a signing identity with the identifier
"Developer ID Installer: Your Name (ABC123DEF)" set it in the variable.
```
