#!/bin/bash
# Ollama AI Setup Script for SSHTerminal
# Installs and configures Ollama with DeepSeek Coder model

set -e

BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}"
cat << "EOF"
                                                   
          |    |                   o          |    
,---.,---.|---.|--- ,---.,---.,-.-..,---.,---.|    
`---.`---.|   ||    |---'|    | | |||   |,---||    
`---'`---'`   '`---'`---'`    ` ' '``   '`---^`---'
                                                   
   ___  _ _                        ___ ___ 
  / _ \| | | __ _ _ __ ___   __ _ / __/ __|
 | | | | | |/ _` | '_ ` _ \ / _` | (__\__ \
 | |_| | | | (_| | | | | | | (_| |\___|___/
  \___/|_|_|\__,_|_| |_| |_|\__,_|
  
  AI Setup for SSHTerminal
EOF
echo -e "${NC}"

echo -e "${BLUE}This script will:${NC}"
echo "  1. Install Ollama (if not present)"
echo "  2. Pull DeepSeek Coder 6.7B model"
echo "  3. Configure endpoint for SSHTerminal"
echo "  4. Test AI command conversion"
echo

# Detect OS
detect_os() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macos"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if [ -f /etc/debian_version ]; then
            echo "debian"
        elif [ -f /etc/redhat-release ]; then
            echo "redhat"
        elif [ -f /etc/arch-release ]; then
            echo "arch"
        else
            echo "linux"
        fi
    else
        echo "unknown"
    fi
}

OS=$(detect_os)

# Check if Ollama is installed
check_ollama() {
    if command -v ollama &> /dev/null; then
        echo -e "${GREEN}✓ Ollama is already installed${NC}"
        return 0
    else
        echo -e "${YELLOW}! Ollama not found${NC}"
        return 1
    fi
}

# Install Ollama
install_ollama() {
    echo -e "${BLUE}Installing Ollama...${NC}"
    
    case $OS in
        macos)
            echo "Downloading Ollama for macOS..."
            curl -fsSL https://ollama.com/install.sh | sh
            ;;
        debian|linux)
            echo "Installing Ollama for Linux..."
            curl -fsSL https://ollama.com/install.sh | sh
            ;;
        *)
            echo -e "${RED}Unsupported OS. Please install manually from https://ollama.com${NC}"
            exit 1
            ;;
    esac
    
    echo -e "${GREEN}✓ Ollama installed${NC}"
}

# Start Ollama service
start_ollama() {
    echo -e "${BLUE}Starting Ollama service...${NC}"
    
    case $OS in
        macos)
            # On macOS, Ollama runs as an app
            if ! pgrep -x "ollama" > /dev/null; then
                open -a Ollama 2>/dev/null || ollama serve &
                sleep 3
            fi
            ;;
        debian|linux)
            # On Linux, start as systemd service or background process
            if systemctl is-active --quiet ollama 2>/dev/null; then
                echo "Ollama service already running"
            else
                sudo systemctl start ollama 2>/dev/null || ollama serve &
                sleep 3
            fi
            ;;
    esac
    
    echo -e "${GREEN}✓ Ollama service started${NC}"
}

# Pull DeepSeek Coder model
pull_model() {
    echo -e "${BLUE}Pulling DeepSeek Coder 6.7B model (this may take 5-10 minutes)...${NC}"
    
    if ollama list | grep -q "deepseek-coder:6.7b"; then
        echo -e "${GREEN}✓ Model already present${NC}"
    else
        ollama pull deepseek-coder:6.7b
        echo -e "${GREEN}✓ Model downloaded${NC}"
    fi
}

# Test AI functionality
test_ai() {
    echo -e "${BLUE}Testing AI command conversion...${NC}"
    
    TEST_PROMPT='Convert this to a bash command. Reply with ONLY the command, no explanation:\n\nshow me disk space'
    
    RESULT=$(ollama run deepseek-coder:6.7b "$TEST_PROMPT" 2>/dev/null | head -1)
    
    if [[ "$RESULT" == *"df"* ]]; then
        echo -e "${GREEN}✓ AI test successful!${NC}"
        echo -e "  Input:  'show me disk space'"
        echo -e "  Output: '$RESULT'"
    else
        echo -e "${YELLOW}⚠ AI test gave unexpected result: $RESULT${NC}"
    fi
}

# Configure SSHTerminal app
configure_app() {
    echo -e "${BLUE}Configuring SSHTerminal app...${NC}"
    
    # Detect local IP
    if [[ "$OS" == "macos" ]]; then
        LOCAL_IP=$(ipconfig getifaddr en0 2>/dev/null || echo "localhost")
    else
        LOCAL_IP=$(hostname -I | awk '{print $1}' 2>/dev/null || echo "localhost")
    fi
    
    echo -e "${GREEN}✓ Ollama endpoint: http://$LOCAL_IP:11434${NC}"
    echo
    echo -e "${YELLOW}Note: Update the app's CommandAIService.swift if needed:${NC}"
    echo -e "  private let ollamaEndpoint = \"http://$LOCAL_IP:11434/api/generate\""
}

# Main installation flow
main() {
    echo -e "${BLUE}Starting setup...${NC}"
    echo
    
    # Check/install Ollama
    if ! check_ollama; then
        read -p "Install Ollama now? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            install_ollama
        else
            echo -e "${RED}Ollama is required. Exiting.${NC}"
            exit 1
        fi
    fi
    
    # Start service
    start_ollama
    
    # Pull model
    echo
    read -p "Download DeepSeek Coder 6.7B model (~4GB)? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        pull_model
    else
        echo -e "${YELLOW}Skipping model download. You'll need to run: ollama pull deepseek-coder:6.7b${NC}"
    fi
    
    # Test
    echo
    if ollama list | grep -q "deepseek-coder:6.7b"; then
        test_ai
    fi
    
    # Configure
    echo
    configure_app
    
    # Success
    echo
    echo -e "${GREEN}═══════════════════════════════════════${NC}"
    echo -e "${GREEN}    Setup Complete! 🎉${NC}"
    echo -e "${GREEN}═══════════════════════════════════════${NC}"
    echo
    echo "Your Ollama server is running and ready to use with SSHTerminal!"
    echo
    echo "Available commands:"
    echo "  ollama list              # List downloaded models"
    echo "  ollama run deepseek-coder:6.7b  # Test the model"
    echo "  ollama serve             # Start server manually"
    echo
    echo "SSHTerminal will automatically connect to:"
    echo "  http://localhost:11434"
    echo
}

main
