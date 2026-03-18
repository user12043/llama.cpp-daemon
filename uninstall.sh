#!/bin/bash

SERVICE_NAME="llama-server.service"
USERCONFIG_DIR="${HOME}/.config/systemd/user"
SERVICE_FILE="${USERCONFIG_DIR}/${SERVICE_NAME}"
ENV_FILE="${USERCONFIG_DIR}/llama-server.env"

echo "Uninstalling llama.cpp server daemon..."

# Stop the service if running
echo "Stopping the service..."
systemctl --user stop "${SERVICE_NAME}" 2>/dev/null || true

# Disable the service
echo "Disabling the service..."
systemctl --user disable "${SERVICE_NAME}" 2>/dev/null || true

# Remove the service file
echo "Removing service file..."
rm -f "${SERVICE_FILE}"

# Remove the environment file
echo "Removing environment file..."
rm -f "${ENV_FILE}"

# Reload systemd (user-level)
echo "Reloading systemd daemon configuration..."
systemctl --user daemon-reload

echo "Uninstallation complete!"