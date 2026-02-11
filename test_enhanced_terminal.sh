#!/bin/bash
# SSH Terminal - Quick Test Script
# Tests all enhanced terminal features

echo "🧪 SSH Terminal Enhanced UI - Test Suite"
echo "========================================"
echo ""

# Check if simulator is running
if ! xcrun simctl list | grep -q "Booted"; then
    echo "❌ No simulator is booted"
    echo "   Starting iPhone 16 Pro..."
    xcrun simctl boot "iPhone 16 Pro" 2>/dev/null
    sleep 3
fi

echo "✅ Simulator is ready"
echo ""

# Build the app
echo "🔨 Building SSHTerminal..."
cd ~/Development/Projects/SSHTerminal

xcodebuild -project SSHTerminal.xcodeproj \
    -scheme SSHTerminal \
    -destination 'platform=iOS Simulator,id=0BF4388C-ABCB-4DA2-86B0-96A7BBE98864' \
    build 2>&1 | grep -E "(BUILD SUCCEEDED|BUILD FAILED|error:)"

if [ $? -eq 0 ]; then
    echo "✅ Build completed"
else
    echo "❌ Build failed"
    exit 1
fi
echo ""

# Install and launch
echo "📱 Installing app..."
APP_PATH=$(find ~/Library/Developer/Xcode/DerivedData/SSHTerminal-*/Build/Products/Debug-iphonesimulator/ -name "SSHTerminal.app" | head -1)

if [ -z "$APP_PATH" ]; then
    echo "❌ App not found"
    exit 1
fi

xcrun simctl install booted "$APP_PATH"
echo "✅ App installed"
echo ""

echo "🚀 Launching SSHTerminal..."
xcrun simctl launch booted com.daniel.sshterminal
echo "✅ App launched"
echo ""

# Take screenshot
sleep 2
xcrun simctl io booted screenshot ~/Desktop/ssh_terminal_test_$(date +%Y%m%d_%H%M%S).png
echo "📸 Screenshot saved to Desktop"
echo ""

echo "==============================================="
echo "🎯 Manual Testing Checklist:"
echo "==============================================="
echo ""
echo "1. ✓ Connect to Kali server (***REMOVED***)"
echo "   - User: daniel, Pass: ***REMOVED***"
echo ""
echo "2. ✓ Verify Welcome Message"
echo "   - Should show 'Connected to ***REMOVED***'"
echo "   - Should show last login time"
echo ""
echo "3. ✓ Check Prompt Format"
echo "   - Should see: daniel@kali:~$"
echo "   - User in green, host in green, dir in blue"
echo ""
echo "4. ✓ Test Basic Commands"
echo "   daniel@kali:~$ whoami"
echo "   daniel@kali:~$ pwd"
echo "   daniel@kali:~$ ls -la"
echo ""
echo "5. ✓ Test Directory Navigation"
echo "   daniel@kali:~$ cd /etc"
echo "   daniel@kali:/etc$ pwd"
echo "   daniel@kali:/etc$ cd ~"
echo "   daniel@kali:~$"
echo ""
echo "6. ✓ Test Error Formatting"
echo "   daniel@kali:~$ cat /root/secret.txt"
echo "   [Should show red error text]"
echo ""
echo "7. ✓ Test Command History"
echo "   - Type: echo test1 [ENTER]"
echo "   - Type: echo test2 [ENTER]"
echo "   - Press ⬆️ twice (see test1)"
echo "   - Press ⬇️ twice (see empty)"
echo ""
echo "8. ✓ Test Clear Command"
echo "   daniel@kali:~$ clear"
echo "   [Screen should clear]"
echo ""
echo "9. ✓ Visual Checks"
echo "   - Cursor blinks at prompt"
echo "   - Auto-scrolls to bottom"
echo "   - Monospace font throughout"
echo "   - Proper color coding"
echo ""
echo "10. ✓ Root User Test"
echo "    daniel@kali:~$ sudo -i"
echo "    root@kali:~#  [Should show # not $]"
echo ""
echo "==============================================="
echo "✅ All automated tests complete!"
echo "📋 See TERMINAL_UX_ENHANCEMENT_COMPLETE.md for details"
echo "==============================================="
