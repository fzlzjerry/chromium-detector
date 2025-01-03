# Chromium Detector

A powerful command-line tool for macOS that helps you discover and analyze all Chromium-based applications installed on your system. This includes browsers like Chrome, Edge, Brave, Opera, and Electron-based applications.

## Features

- Detects all Chromium-based applications installed on your system
- Shows detailed information including:
  - Application version
  - Installation date
  - Disk space usage
  - Bundle identifier
  - Executable path
- Beautiful command-line interface with progress indicators
- Supports both system and user Applications folders
- Detects Electron apps and other Chromium-based applications

## Installation

You can install chromium-detector using Homebrew:

```bash
brew tap fzlzjerry/chromium-detector
brew install chromium-detector
```

## Usage

Simply run the command in your terminal:

```bash
chromium-detector
```

The tool will automatically scan your system and display information about all found Chromium-based applications.

## Requirements

- macOS 12.0 or later
- Xcode 13.0 or later (for building from source)

## Building from Source

If you want to build the application from source:

1. Clone the repository
2. Run `swift build`
3. The binary will be available at `.build/debug/chromium-detector`

## License

MIT License 