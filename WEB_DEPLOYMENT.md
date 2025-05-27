# GigaEats Web Deployment Guide

## Overview
This guide explains how to build and deploy the GigaEats Flutter application for web.

## Prerequisites
- Flutter SDK 3.32.0 or later
- Dart 3.8.0 or later
- Web browser for testing

## Building for Web

### Option 1: Using Build Scripts
We've provided convenient build scripts:

**Windows:**
```bash
build_web.bat
```

**Linux/macOS:**
```bash
chmod +x build_web.sh
./build_web.sh
```

### Option 2: Manual Build
```bash
# Clean previous builds
flutter clean

# Get dependencies
flutter pub get

# Build for web (production)
flutter build web --release
```

## Testing Locally

After building, you can test the web application locally:

### Option 1: Using Flutter's built-in server
```bash
flutter run -d web-server --web-port 8080
```

### Option 2: Using Python's HTTP server
```bash
cd build/web
python -m http.server 8080
```

### Option 3: Using Node.js serve
```bash
cd build/web
npx serve -s . -l 8080
```

Then open http://localhost:8080 in your browser.

## Deployment

### Static Web Hosting
The built web application is a static site. Upload the contents of `build/web/` to any static web hosting service:

- **Netlify**: Drag and drop the `build/web` folder
- **Vercel**: Connect your repository and set build command to `flutter build web`
- **GitHub Pages**: Upload files to your repository's gh-pages branch
- **Firebase Hosting**: Use `firebase deploy` after configuring
- **AWS S3**: Upload files to an S3 bucket configured for static hosting

### Web Server Configuration
For proper routing with Flutter's go_router, configure your web server:

#### Apache (.htaccess)
```apache
RewriteEngine On
RewriteCond %{REQUEST_FILENAME} !-f
RewriteCond %{REQUEST_FILENAME} !-d
RewriteRule ^(.*)$ /index.html [QSA,L]
```

#### Nginx
```nginx
location / {
    try_files $uri $uri/ /index.html;
}
```

## Build Output
The web build creates the following structure in `build/web/`:
- `index.html` - Main HTML file
- `main.dart.js` - Compiled Dart code
- `flutter.js` - Flutter web engine
- `assets/` - Application assets
- `icons/` - PWA icons
- `manifest.json` - PWA manifest

## Progressive Web App (PWA)
The application is configured as a PWA with:
- App manifest for installation
- Service worker for offline functionality
- Responsive design for mobile devices

## Environment Configuration
For production deployment, consider:
- Setting up proper Firebase configuration
- Configuring API endpoints
- Setting up authentication providers
- Enabling analytics

## Troubleshooting

### Common Issues
1. **CORS errors**: Configure your backend to allow requests from your domain
2. **Routing issues**: Ensure web server is configured for SPA routing
3. **Asset loading**: Check that all assets are properly included in pubspec.yaml

### Performance Optimization
- Use `--web-renderer canvaskit` for better performance on desktop
- Use `--web-renderer html` for better compatibility on mobile
- Enable gzip compression on your web server
- Use CDN for faster asset delivery

## Security Considerations
- Use HTTPS in production
- Configure proper CORS headers
- Validate all user inputs
- Secure API endpoints
- Use environment variables for sensitive configuration
