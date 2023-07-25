# Pico-SDK + Toolchain installer for macOS

- Download the arm64 variant for Apple Silicon Macs or the x86_64 variant for Intel Macs.
- Execute and follow install instructions.
- Installer will automatically setup auto-detection of newly the installed sdk and toolchain for the Raspberry Pi Pico Visual Studio Code extension.

### Download

| Supported Platform | Download (v1.5.1)           | Downloads (v1.5.0)          |
| ------------------ | --------------------------- | --------------------------- |
| macOS 11+ (arm64)  | [.pkg][v1_5_1-macos-arm64]  | [.pkg][v1_5_0-macos-arm64]  |
| macOS 11+ (x64)    | [.pkg][v1_5_1-macos-x86_64] | [.pkg][v1_5_0-macos-x86_64] |

[v1_5_1-macos-arm64]: https://github.com/paulober/pico-installer-macOS/releases/download/macOS_installer_v1/pico_sdk_1.5.1_macOS_arm64.pkg
[v1_5_1-macos-x86_64]: https://github.com/paulober/pico-installer-macOS/releases/download/macOS_installer_v1/pico_sdk_1.5.1_macOS_x86_64.pkg
[v1_5_0-macos-arm64]: https://github.com/paulober/pico-installer-macOS/releases/download/macOS_installer_v1/pico_sdk_1.5.0_macOS_arm64.pkg
[v1_5_0-macos-x86_64]: https://github.com/paulober/pico-installer-macOS/releases/download/macOS_installer_v1/pico_sdk_1.5.0_macOS_x86_arm64.pkg

### TODO

- Maybe update bundle version to a custom version for the macOS installer revision (maybe only a suffix or prefix to the pico-sdk version).

## Manually building the pkg

### Requirements

- Git and Github Cli
- Python 3.10+ in PATH
- Xcode Command Line Tools
- macOS Ventura or later (previous versions may work but are untested; must contain zsh)

### Building

```zsh
Usage: ./build.sh <pico_sdk_release_tag> <toolchain_tag> [--verbose | -v]

To build and sign set APPLE_DEVELOPER_INSTALLER_ID environment variable
before.
For example, if you have a signing identity with the identifier
"Developer ID Installer: Your Name (ABC123DEF)" set it in the variable.
```
