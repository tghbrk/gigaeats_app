#!/bin/bash

echo "Starting GigaEats Web Server..."
echo

if [ ! -f "build/web/index.html" ]; then
    echo "Error: Web build not found!"
    echo "Please run ./build_web.sh first."
    echo
    exit 1
fi

echo "Serving GigaEats at http://localhost:8080"
echo "Press Ctrl+C to stop the server"
echo

cd build/web
python -m http.server 8080
