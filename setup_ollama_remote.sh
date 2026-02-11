#!/bin/bash
# Remote Ollama Setup for SSHTerminal
# Sets up Ollama on a remote server (e.g., Kali, Ubuntu, Raspberry Pi)

set -e

BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}"
cat << "EOF"
                                                   
          |    |                   o          |    
,---.,---.|---.|--- ,---.,---.,-.-..,---.,---.|    
`---.`---.|   ||    |---'|    | | |||   |,---||    
`---'`---'`   '`---'`---'`    ` ' '``   '`---^`---'
                                                   
  ____                      _         ___  _ _                       
 |  _ \ ___ _ __ ___   ___ | |_ ___  / _ \| | | __ _ _ __ ___   __ _ 
 | |_) / _ \ '_ ` _ \ / _ \| __/ _ \| | | | | |/ _` | '_ ` _ \ / _` |
 |  _ <  __/ | | | | | (_) | ||  __/| |_| | | | (_| | | | | | | (_| |
 |_| \_\___|_| |_| |_|\___/ \__\___| \___/|_|_|\__,_|_| |_| |_|\__,_|
                                                                      
  Remote Server Setup
EOF
echo -e "${NC}"

# Get server details
echo "Enter remote server details:"
read -p "Hostname/IP: " REMOTE_HOST
read -p "SSH User: " REMOTE_USER
read -p "SSH Port (default 22): " REMOTE_PORT
REMOTE_PORT=${REMOTE_PORT:-22}

echo
echo -e "${BLUE}Connecting to $REMOTE_USER@$REMOTE_HOST:$REMOTE_PORT...${NC}"

# Create remote setup script
REMOTE_SCRIPT=$(cat << 'REMOTESCRIPT'
#!/bin/bash
set -e

echo "🔍 Checking system..."

# Detect OS
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
else
    echo "Cannot detect OS"
    exit 1
fi

echo "📦 Installing Ollama..."

# Install Ollama
if ! command -v ollama &> /dev/null; then
    curl -fsSL https://ollama.com/install.sh | sh
else
    echo "✓ Ollama already installed"
fi

# Start service
echo "🚀 Starting Ollama service..."
if command -v systemctl &> /dev/null; then
    sudo systemctl enable ollama
    sudo systemctl start ollama
    sudo systemctl status ollama --no-pager
else
    # Start in background
    nohup ollama serve > /tmp/ollama.log 2>&1 &
    sleep 3
fi

# Pull model
echo "📥 Pulling DeepSeek Coder model (this will take 5-10 minutes)..."
ollama pull deepseek-coder:6.7b

# Optional: Pull other useful models
read -p "Download additional models? (dolphin-mistral, tinyllama) [y/N]: " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    ollama pull dolphin-mistral:7b-v2.8
    ollama pull tinyllama:latest
fi

# Configure firewall
echo "🔒 Configuring firewall..."
if command -v ufw &> /dev/null; then
    sudo ufw allow 11434/tcp
    echo "✓ UFW rule added"
elif command -v firewall-cmd &> /dev/null; then
    sudo firewall-cmd --permanent --add-port=11434/tcp
    sudo firewall-cmd --reload
    echo "✓ Firewall rule added"
fi

# Test
echo "🧪 Testing Ollama..."
curl -s http://localhost:11434/api/tags | head -20

echo
echo "✅ Setup complete!"
echo
echo "Server is listening on: http://$(hostname -I | awk '{print $1}'):11434"
echo
echo "Available models:"
ollama list

REMOTESCRIPT
)

# Execute on remote server
echo "$REMOTE_SCRIPT" | ssh -p "$REMOTE_PORT" "$REMOTE_USER@$REMOTE_HOST" 'bash -s'

if [ $? -eq 0 ]; then
    # Get remote IP
    REMOTE_IP=$(ssh -p "$REMOTE_PORT" "$REMOTE_USER@$REMOTE_HOST" "hostname -I | awk '{print \$1}'")
    
    echo
    echo -e "${GREEN}═══════════════════════════════════════${NC}"
    echo -e "${GREEN}    Remote Setup Complete! 🎉${NC}"
    echo -e "${GREEN}═══════════════════════════════════════${NC}"
    echo
    echo "Your Ollama server is running at:"
    echo -e "${GREEN}http://$REMOTE_IP:11434${NC}"
    echo
    echo "Update your SSHTerminal app's CommandAIService.swift:"
    echo -e "${YELLOW}private let ollamaEndpoint = \"http://$REMOTE_IP:11434/api/generate\"${NC}"
    echo
    echo "Test the connection:"
    echo "curl http://$REMOTE_IP:11434/api/tags"
    echo
else
    echo -e "${RED}Setup failed. Check the error messages above.${NC}"
    exit 1
fi
