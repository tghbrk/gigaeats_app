# Scripts Directory

This directory contains build and deployment scripts for the GigaEats Flutter application.

## Available Scripts

### Web Build Scripts
- **`build_web.bat`** - Windows batch script to build the Flutter web application
- **`build_web.sh`** - Unix/Linux shell script to build the Flutter web application

### Web Serve Scripts
- **`serve_web.bat`** - Windows batch script to serve the Flutter web application locally
- **`serve_web.sh`** - Unix/Linux shell script to serve the Flutter web application locally

## Usage

### Building for Web
```bash
# On Windows
scripts/build_web.bat

# On Unix/Linux/macOS
chmod +x scripts/build_web.sh
scripts/build_web.sh
```

### Serving Locally
```bash
# On Windows
scripts/serve_web.bat

# On Unix/Linux/macOS
chmod +x scripts/serve_web.sh
scripts/serve_web.sh
```

## Prerequisites

- Flutter SDK installed and configured
- Web development tools enabled (`flutter config --enable-web`)
- For serving: A local web server (scripts may use `python -m http.server` or similar)

## Notes

- These scripts are designed to work from the project root directory
- Make sure to run `flutter pub get` before building
- Web builds are optimized for production deployment
- Serve scripts are intended for local development and testing
