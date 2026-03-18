#!/bin/bash

SERVICE_NAME="llama-server.service"
USERCONFIG_DIR="${HOME}/.config/systemd/user"
SERVICE_FILE="${USERCONFIG_DIR}/${SERVICE_NAME}"
ENV_FILE="${USERCONFIG_DIR}/llama-server.env"
INSTALL_DIR=$(dirname "$(readlink -f "$0")")
TEMPLATE_FILE="${INSTALL_DIR}/.env.template"

echo "Installing llama.cpp server daemon (user-level service)..."
echo "Usage: ./install.sh [--model PATH] [--llamacpp_dir PATH] [--host IP] [--port PORT]"
echo "Options:"
echo "  --model PATH       Path to .gguf model file or Hugging Face model ID (optional)"
echo "  --llamacpp_dir PATH Path to llama.cpp directory (optional)"
echo "  --host IP          Host IP to bind to (optional, default 0.0.0.0)"
echo "  --port PORT        Port number to bind to (optional, default 8081)"

# Parse command line arguments
MODEL_PATH=""
LLAMCPP_DIR=""
HOST=""
PORT=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --model)
            MODEL_PATH="$2"
            shift 2
            ;;
        --llamacpp_dir)
            LLAMCPP_DIR="$2"
            shift 2
            ;;
        --host)
            HOST="$2"
            shift 2
            ;;
        --port)
            PORT="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Create user systemd config directory if it doesn't exist
mkdir -p "${USERCONFIG_DIR}"

# Check if source file exists
if [ ! -f "${TEMPLATE_FILE}" ]; then
    echo "Error: ${TEMPLATE_FILE} not found"
    exit 1
fi

# Copy service file
echo "Copying service file to ${SERVICE_FILE}..."
cp "${INSTALL_DIR}/${SERVICE_NAME}" "${SERVICE_FILE}"
chmod 644 "${SERVICE_FILE}"

# Create environment file from template
echo "Creating environment file..."
cp "${TEMPLATE_FILE}" "${ENV_FILE}"

# Prompt for required values if not provided via command line
if [ -z "${MODEL_PATH}" ]; then
    read -p "Enter MODEL_PATH (path to .gguf file or Hugging Face model like 'Qwen/Qwen2.5-1.5B-Instruct'): " MODEL_PATH
fi
if [ -z "${LLAMCPP_DIR}" ]; then
    read -p "Enter LLAMCPP_DIR (path to llama.cpp directory): " LLAMCPP_DIR
fi
if [ -z "${RESTART_MODE}" ]; then
    RESTART_MODE="always"
fi
if [ -z "${RESTART_SECONDS}" ]; then
    RESTART_SECONDS="5s"
fi
if [ -z "${JINJA_ENABLED}" ]; then
    JINJA_ENABLED="true"
fi
if [ -z "${NGL_LEVEL}" ]; then
    read -p "Enter NGL_LEVEL (number of GPU layers to offload, leave empty to skip): " NGL_LEVEL
fi
if [ -z "${HOST}" ]; then
    read -p "Enter HOST (IP to bind to, default 0.0.0.0): " HOST
    if [ -z "${HOST}" ]; then
        HOST="0.0.0.0"
    fi
fi
if [ -z "${PORT}" ]; then
    read -p "Enter PORT (port number, default 8081): " PORT
    if [ -z "${PORT}" ]; then
        PORT="8081"
    fi
fi

# Validate values are set
if [ -z "${MODEL_PATH}" ] || [ -z "${LLAMCPP_DIR}" ]; then
    echo "ERROR: MODEL_PATH and LLAMCPP_DIR are required"
    exit 1
fi

# Replace template values in environment file
sed -i "s|MODEL_PATH=.*|MODEL_PATH=${MODEL_PATH}|" "${ENV_FILE}"
sed -i "s|LLAMCPP_DIR=.*|LLAMCPP_DIR=${LLAMCPP_DIR}|" "${ENV_FILE}"
sed -i "s|HOST=.*|HOST=${HOST}|" "${ENV_FILE}"
sed -i "s|PORT=.*|PORT=${PORT}|" "${ENV_FILE}"
sed -i "s|RESTART_MODE=.*|RESTART_MODE=${RESTART_MODE}|" "${ENV_FILE}"
sed -i "s|RESTART_SECONDS=.*|RESTART_SECONDS=${RESTART_SECONDS}|" "${ENV_FILE}"
sed -i "s|JINJA_ENABLED=.*|JINJA_ENABLED=${JINJA_ENABLED}|" "${ENV_FILE}"

# Replace template values in service file
sed -i "s|RESTART_MODE=.*|Restart=always|" "${SERVICE_FILE}"
sed -i "s|RESTART_SECONDS=.*|RestartSec=5s|" "${SERVICE_FILE}"

# Check if llama.cpp directory exists
echo "Checking for llama.cpp directory..."
if [ ! -d "${LLAMCPP_DIR}" ]; then
    echo "ERROR: llama.cpp directory not found at ${LLAMCPP_DIR}"
    echo "Please download and build llama.cpp:"
    echo "  cd ${LLAMCPP_DIR}"
    echo "  git clone https://github.com/ggerganov/llama.cpp.git ."
    echo "  git pull"
    echo "  make"
    exit 1
fi

# Check if model file exists or is a Hugging Face model
echo "Checking for model..."
if [[ "${MODEL_PATH}" == *"/"* && ! -f "${MODEL_PATH}" ]]; then
    echo "✓ Using Hugging Face model: ${MODEL_PATH}"
elif [ -f "${MODEL_PATH}" ]; then
    echo "✓ Found local model file: ${MODEL_PATH}"
else
    echo "ERROR: Model file not found at ${MODEL_PATH} and it doesn't appear to be a Hugging Face model"
    echo "Please specify either:"
    echo "  - Full path to a .gguf file, or"
    echo "  - Hugging Face model identifier (e.g., Qwen/Qwen2.5-1.5B-Instruct)"
    exit 1
fi

# Check if llama-server binary exists
echo "Checking for llama-server binary..."
LLAMA_SERVER_PATH=""
if [ -f "${LLAMCPP_DIR}/build/bin/llama-server" ]; then
    LLAMA_SERVER_PATH="${LLAMCPP_DIR}/build/bin/llama-server"
elif [ -f "${LLAMCPP_DIR}/llama-server" ]; then
    LLAMA_SERVER_PATH="${LLAMCPP_DIR}/llama-server"
else
    echo "ERROR: llama-server binary not found at either:"
    echo "  ${LLAMCPP_DIR}/build/bin/llama-server"
    echo "  ${LLAMCPP_DIR}/llama-server"
    echo "Please build llama.cpp first or ensure the binary is in one of these locations"
    exit 1
fi
echo "Found llama-server at: ${LLAMA_SERVER_PATH}"

# Store the binary path in the environment file
sed -i "s|LLAMCPP_DIR=.*|LLAMCPP_DIR=${LLAMCPP_DIR}|" "${ENV_FILE}"
echo "LLAMA_SERVER_BIN=${LLAMA_SERVER_PATH}" >> "${ENV_FILE}"

# Determine and store MODEL_ARG
if [ -f "${MODEL_PATH}" ]; then
    echo "MODEL_ARG=-m" >> "${ENV_FILE}"
else
    echo "MODEL_ARG=-hf" >> "${ENV_FILE}"
fi

# Reload systemd (user-level)
echo "Reloading systemd daemon configuration..."
systemctl --user daemon-reload

# Enable and start the service
echo "Enabling and starting the service..."
systemctl --user enable "${SERVICE_NAME}"
systemctl --user start "${SERVICE_NAME}"

# Check service status
echo "Checking service status..."
systemctl --user status "${SERVICE_NAME}" --no-pager

echo "Installation complete!"
echo "Use './status.sh' to check service status"
echo "Use './logs.sh' to monitor logs"
echo "Use 'systemctl --user status llama-server' to check service status"
echo "Use 'journalctl --user-unit llama-server -f' to view logs"