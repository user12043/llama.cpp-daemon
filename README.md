# Llama.cpp Server Daemon

A user-level systemd daemon for running llama.cpp server as a persistent service on Linux. Automatically restarts on failure and starts with your user session.

## Description

This daemon manages a llama.cpp web server that exposes an HTTP API for LLM inference. It runs the server as a background service with automatic restart capabilities and systemd integration.

## Features

- Automatic startup at boot
- Automatic restart on failure
- Configurable model, context size, and server settings
- Systemd service management
- Journald logging integration

## Installation

### Step 1: Prepare your environment

Ensure llama.cpp is built and the model file exists:

```bash
# Verify llama.cpp is built
ls ~/git/llama.cpp/build/bin/llama-server

# Verify model file exists
hf download unsloth/GLM-4.7-Flash-GGUF GLM-4.7-Flash-Q4_K_M.gguf --local-dir ~/models
ls ~/models/GLM-4.7-Flash-Q4_K_M.gguf
```

### Step 2: Install the daemon

```bash
# Make install scripts executable
chmod +x install.sh uninstall.sh

# Run install script (no sudo needed)
./install.sh
```

The installation will prompt you for:
- `MODEL_PATH`: Full path to your .gguf model file
- `LLAMCPP_DIR`: Full path to your llama.cpp directory

### Step 3: Verify installation

```bash
# Check service status
systemctl --user status llama-server

# View logs
journalctl --user-unit llama-server -f
```

## Usage

### Management Scripts

You can use convenience scripts for common operations:

```bash
# Show detailed service status
./status.sh

# Monitor logs in real-time
./logs.sh
```

### Starting the service

```bash
systemctl --user start llama-server
```

### Stopping the service

```bash
systemctl --user stop llama-server
```

### Restarting the service

```bash
systemctl --user restart llama-server
```

### Enabling auto-start on login

```bash
systemctl --user enable llama-server
```

### Disabling auto-start on login

```bash
systemctl --user disable llama-server
```

### Checking service status

```bash
systemctl --user status llama-server
```

### Viewing logs

```bash
# Follow logs in real-time
journalctl --user-unit llama-server -f

# View last 100 lines
journalctl --user-unit llama-server -n 100

# Use the logs script
./logs.sh
```

## Configuration

Configuration is stored in `~/.config/systemd/user/llama-server.env`. Common values:

- `MODEL_PATH`: Path to the GGUF model file
- `HOST/PORT`: Server address and port (default: 0.0.0.0:8081)
- `CONTEXT_SIZE`: Context window size (default: 32768)
- `NGL_LEVEL`: Number of layers to offload to GPU (default: 99)
- `LLAMCPP_DIR`: Path to llama.cpp directory
- `RESTART_MODE`: Restart behavior (default: always)
- `RESTART_SECONDS`: Seconds to wait before restart (default: 5s)

### Modifying configuration

```bash
# Edit the environment file
nano ~/.config/systemd/user/llama-server.env

# Reload systemd and restart
systemctl --user daemon-reload
systemctl --user restart llama-server
```

## Troubleshooting

### Service won't start

```bash
# Check detailed logs
journalctl --user-unit llama-server -n 100 --no-pager

# Verify config file exists
ls -l ~/.config/systemd/user/llama-server.env

# Check file permissions
stat ~/.config/systemd/user/llama-server.env
```

### Model not found

Ensure MODEL_PATH in the environment file points to a valid .gguf file:

```bash
# Check if model exists
ls -l /path/to/your/model.gguf

# Verify llama.cpp binary exists
ls -l /path/to/llama.cpp/build/bin/llama-server
```

### Permission denied

Ensure your user has read access to the model file and llama.cpp directory:

```bash
# Check file permissions
ls -l /path/to/model.gguf
ls -ld /path/to/llama.cpp

# Fix permissions if needed (if needed)
chmod -R 755 /path/to/llama.cpp
chmod -R 644 /path/to/model.gguf
```

### Port already in use

Check what's using port 8081:

```bash
netstat -tulpn | grep 8081
lsof -i :8081

# Change port in environment file
nano ~/.config/systemd/user/llama-server.env
# Update PORT to a different value
systemctl --user daemon-reload
systemctl --user restart llama-server
```

## Uninstallation

### Step 1: Stop the service

```bash
sudo systemctl stop llama-server
```

### Step 2: Disable auto-start

```bash
sudo systemctl disable llama-server
```

### Step 3: Run uninstall script

```bash
sudo ./uninstall.sh
```

This removes the systemd service file and environment configuration.

## Files

- `install.sh` - Installation script
- `uninstall.sh` - Uninstallation script
- `status.sh` - Service status and configuration viewer
- `logs.sh` - Real-time log monitor
- `llama-server.service` - Systemd service definition
- `.env.template` - Environment configuration template
- `README.md` - This file

## API Access

Once running, the llama.cpp server will be available at:

- HTTP: `http://localhost:8081`
- API: `http://localhost:8081/completion`

See llama.cpp documentation for API details.
