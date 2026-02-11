#!/bin/bash
# Quick test script for SSHTerminal

SIMULATOR_ID="0BF4388C-ABCB-4DA2-86B0-96A7BBE98864"
APP_PATH="/Users/daniel/Library/Developer/Xcode/DerivedData/SSHTerminal-fmapfhpdmeruwgafcvuxgvjxevik/Build/Products/Debug-iphonesimulator/SSHTerminal.app"

echo "📱 Booting simulator..."
xcrun simctl boot "$SIMULATOR_ID" 2>/dev/null || echo "Simulator already booted"

echo "🚀 Installing app..."
xcrun simctl install "$SIMULATOR_ID" "$APP_PATH"

echo "▶️  Launching app..."
xcrun simctl launch "$SIMULATOR_ID" com.daniel.sshterminal

echo "✅ App launched successfully!"
echo "Check the simulator to interact with the app."
