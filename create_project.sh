#!/bin/bash
# Create Xcode project structure using xcodebuild

PROJECT_NAME="SSHTerminal"
BUNDLE_ID="com.daniel.sshterminal"

# Create the project using SwiftPM-style structure first
mkdir -p "${PROJECT_NAME}"
cd "${PROJECT_NAME}"

# Create basic structure
mkdir -p App Core/Models Core/Services Core/Repositories
mkdir -p Features/ServerList/Views Features/ServerList/ViewModels
mkdir -p Features/Terminal/Views Features/Terminal/ViewModels
mkdir -p Utilities/Extensions Resources

# Create Assets catalog
mkdir -p Resources/Assets.xcassets

echo "Project structure created"
