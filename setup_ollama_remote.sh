#!/bin/bash
# Remote Ollama Setup for SSHTerminal
# Sets up Ollama on a remote server with SSH tunnel (secure by default)

set -e

BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}SSHTerminal — Remote Ollama Setup${NC}"
echo

# Get server details
echo "Enter remote server details:"
read -p "Hostname/IP: " REMOTE_HOST
read -p "SSH User: " REMOTE_USER
read -p "SSH Port (default 22): " REMOTE_PORT
REMOTE_PORT=${REMOTE_PORT:-22}

echo
echo -e "${BLUE}Connecting to $REMOTE_USER@$REMOTE_HOST:$REMOTE_PORT...${NC}"

# Create remote setup script — installs Ollama but does NOT open firewall
REMOTE_SCRIPT=$(cat << 'REMOTESCRIPT'
#!/bin/bash
set -e

echo "Checking system..."

if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
else
    echo "Cannot detect OS"
    exit 1
fi

echo "Installing Ollama..."

if ! command -v ollama &> /dev/null; then
    curl -fsSL https://ollama.com/install.sh | sh
else
    echo "Ollama already installed"
fi

echo "Starting Ollama service (localhost only)..."
if command -v systemctl &> /dev/null; then
    sudo systemctl enable ollama
    sudo systemctl start ollama
else
    OLLAMA_HOST=127.0.0.1 nohup ollama serve > /tmp/ollama.log 2>&1 &
    sleep 3
fi

echo "Pulling DeepSeek Coder model (~4GB, may take several minutes)..."
ollama pull deepseek-coder:6.7b

echo "Testing Ollama..."
curl -s http://localhost:11434/api/tags | head -20

echo
echo "Setup complete! Ollama is listening on localhost:11434 only."
echo "Use an SSH tunnel from your client to access it securely."
echo
echo "Available models:"
ollama list

REMOTESCRIPT
)

# Execute on remote server
echo "$REMOTE_SCRIPT" | ssh -p "$REMOTE_PORT" "$REMOTE_USER@$REMOTE_HOST" 'bash -s'

if [ $? -eq 0 ]; then
    echo
    echo -e "${GREEN}Remote Setup Complete!${NC}"
    echo
    echo "Ollama is running on the remote server (localhost only — not exposed to the network)."
    echo
    echo -e "${YELLOW}To connect from SSHTerminal, start an SSH tunnel:${NC}"
    echo
    echo "  ssh -L 11434:localhost:11434 -p $REMOTE_PORT $REMOTE_USER@$REMOTE_HOST"
    echo
    echo "Then in SSHTerminal AI Settings, set:"
    echo "  Host: localhost"
    echo "  Port: 11434"
    echo
    echo "The tunnel encrypts all traffic between your device and the Ollama server."
    echo
else
    echo -e "${RED}Setup failed. Check the error messages above.${NC}"
    exit 1
fi
