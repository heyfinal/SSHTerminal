# AI Setup Guide for SSHTerminal

This guide will help you set up the AI command conversion feature that powers natural language → bash translation.

## Quick Start

### Option 1: Local Setup (Recommended for Mac/Linux)

Run the automated setup script:

```bash
cd SSHTerminal
./setup_ollama.sh
```

This will:
1. ✅ Install Ollama (if not present)
2. ✅ Download DeepSeek Coder 6.7B model (~4GB)
3. ✅ Start the Ollama service
4. ✅ Test AI functionality
5. ✅ Configure endpoint

**Time:** ~10-15 minutes (mostly download time)

### Option 2: Remote Server Setup (Kali, Ubuntu, Raspberry Pi)

For running Ollama on a remote server:

```bash
cd SSHTerminal
./setup_ollama_remote.sh
```

You'll be prompted for:
- Server hostname/IP
- SSH username
- SSH port (default 22)

The script will install and configure everything remotely.

**Time:** ~10-15 minutes + network latency

## Manual Setup

If you prefer manual installation:

### 1. Install Ollama

**macOS:**
```bash
curl -fsSL https://ollama.com/install.sh | sh
```

**Linux:**
```bash
curl -fsSL https://ollama.com/install.sh | sh
```

**Kali Linux:**
```bash
curl -fsSL https://ollama.com/install.sh | sh
sudo systemctl enable ollama
sudo systemctl start ollama
```

### 2. Download Model

```bash
ollama pull deepseek-coder:6.7b
```

**Model sizes:**
- `deepseek-coder:6.7b` - 3.8GB (recommended)
- `dolphin-mistral:7b-v2.8` - 4.1GB (alternative)
- `tinyllama:latest` - 637MB (fast, less accurate)

### 3. Test the Model

```bash
ollama run deepseek-coder:6.7b "Convert to bash: show disk space"
```

Expected output: `df -h`

### 4. Configure SSHTerminal

Edit `SSHTerminal/Core/Services/CommandAIService.swift`:

```swift
// Local server
private let ollamaEndpoint = "http://localhost:11434/api/generate"

// Remote server
private let ollamaEndpoint = "http://YOUR_SERVER_IP:11434/api/generate"
```

### 5. Rebuild App

```bash
cd SSHTerminal
xcodebuild -scheme SSHTerminal clean build
```

## Remote Server Configuration

### Kali Linux Setup (Detailed)

```bash
# SSH into your Kali server
ssh user@your-server-ip

# Install Ollama
curl -fsSL https://ollama.com/install.sh | sh

# Enable autostart
sudo systemctl enable ollama
sudo systemctl start ollama

# Pull model
ollama pull deepseek-coder:6.7b

# Configure firewall
sudo ufw allow 11434/tcp

# Test
curl http://localhost:11434/api/tags
```

### Verify Remote Access

From your Mac:
```bash
# Test connection
curl http://YOUR_SERVER_IP:11434/api/tags

# Test AI
curl -X POST http://YOUR_SERVER_IP:11434/api/generate \
  -H "Content-Type: application/json" \
  -d '{
    "model": "deepseek-coder:6.7b",
    "prompt": "Convert to bash: show disk space",
    "stream": false
  }' | jq -r '.response'
```

Expected: `df -h`

## Troubleshooting

### Ollama not starting

**macOS:**
```bash
# Check if running
pgrep ollama

# Start manually
ollama serve
```

**Linux:**
```bash
# Check status
systemctl status ollama

# View logs
journalctl -u ollama -f

# Restart
sudo systemctl restart ollama
```

### Model not responding

```bash
# List models
ollama list

# Re-pull model
ollama pull deepseek-coder:6.7b

# Test directly
ollama run deepseek-coder:6.7b "test"
```

### Network issues

```bash
# Check if port is open
netstat -an | grep 11434

# Test local connection
curl http://localhost:11434/api/tags

# Test remote connection
curl http://YOUR_SERVER_IP:11434/api/tags
```

### Firewall blocking

**UFW (Ubuntu/Debian):**
```bash
sudo ufw allow 11434/tcp
sudo ufw reload
```

**Firewalld (RHEL/CentOS):**
```bash
sudo firewall-cmd --permanent --add-port=11434/tcp
sudo firewall-cmd --reload
```

**Kali Linux:**
```bash
sudo ufw allow 11434/tcp
```

## Performance Tips

### Speed Optimization

1. **Use faster models for real-time:**
   ```bash
   ollama pull tinyllama:latest  # 637MB, very fast
   ```

2. **Adjust temperature:**
   ```swift
   "temperature": 0.1  // Lower = more deterministic
   ```

3. **Reduce token count:**
   ```swift
   "num_predict": 30  // Shorter responses
   ```

### Resource Usage

**Model Memory Requirements:**
- `deepseek-coder:6.7b` - 4GB RAM
- `dolphin-mistral:7b-v2.8` - 4GB RAM
- `tinyllama:latest` - 1GB RAM

**Recommended Hardware:**
- CPU: 4+ cores
- RAM: 8GB+ (16GB ideal)
- Storage: 10GB+ free space

## Alternative Models

### For Command Generation

```bash
# Best for code/commands
ollama pull deepseek-coder:6.7b

# Good for general tasks
ollama pull dolphin-mistral:7b-v2.8

# Fast but less accurate
ollama pull tinyllama:latest
```

### For Chat/Explanation

```bash
# Better for conversations
ollama pull llama2:7b

# Uncensored responses
ollama pull dolphin-mistral:7b-v2.8
```

## Advanced Configuration

### Running Multiple Models

```bash
ollama pull deepseek-coder:6.7b  # For commands
ollama pull llama2:7b             # For chat
ollama pull nomic-embed-text      # For embeddings
```

### Custom System Prompts

Edit `CommandAIService.swift`:

```swift
let prompt = """
You are a bash expert. Convert natural language to shell commands.
Rules:
- Reply with ONLY the command
- No explanations or markdown
- Use modern Linux utilities

User request: \(input)
"""
```

### GPU Acceleration

If your server has NVIDIA GPU:

```bash
# Install NVIDIA Container Toolkit
distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | sudo apt-key add -
curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | sudo tee /etc/apt/sources.list.d/nvidia-docker.list

sudo apt-get update
sudo apt-get install -y nvidia-docker2
sudo systemctl restart docker

# Run Ollama with GPU
docker run -d --gpus=all -v ollama:/root/.ollama -p 11434:11434 --name ollama ollama/ollama
```

## Monitoring

### Check Ollama Status

```bash
# Service status
systemctl status ollama

# Resource usage
top -p $(pgrep ollama)

# Logs
journalctl -u ollama -f
```

### Test Performance

```bash
# Measure response time
time curl -X POST http://localhost:11434/api/generate \
  -d '{"model":"deepseek-coder:6.7b","prompt":"test","stream":false}'
```

## Support

- **Ollama Documentation**: https://ollama.com/docs
- **DeepSeek Coder**: https://github.com/deepseek-ai/DeepSeek-Coder
- **SSHTerminal Issues**: https://github.com/heyfinal/SSHTerminal/issues

## FAQ

**Q: Do I need internet after setup?**  
A: No, models run completely offline once downloaded.

**Q: Can I use multiple servers?**  
A: Yes, modify the endpoint in `CommandAIService.swift` or add server selection UI.

**Q: How much does this cost?**  
A: $0. Ollama and all models are free and open source.

**Q: Can I use other models?**  
A: Yes! Any Ollama-compatible model works. Update the `model` field in the code.

**Q: Is my data sent anywhere?**  
A: No. All processing happens locally on your server.
