#!/bin/bash

# Create basic Xcode project structure using xcodeproj gem or manual approach
# Since we have the files, let's use xcodebuild to create a simple project

PROJECT_DIR="$(pwd)"
PROJECT_NAME="SSHTerminal"

# Check if we have xcodegen
if command -v xcodegen &> /dev/null; then
    echo "Using xcodegen to create project..."
    xcodegen generate
    exit 0
fi

# Fallback: Create project manually using Xcode command line
echo "Creating Xcode project using xcodebuild..."

# Create a basic project using swift package
cd "$PROJECT_DIR"

# Alternative: Use Xcode to create project
osascript <<APPLESCRIPT
tell application "Xcode"
    activate
end tell

tell application "System Events"
    tell process "Xcode"
        keystroke "n" using {command down, shift down}
        delay 1
    end tell
end tell
APPLESCRIPT

