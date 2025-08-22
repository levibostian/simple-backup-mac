#!/bin/bash

# Exit on any error
set -e

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Find the plist file matching the pattern com.simplebackup*.plist
PLIST_FILE=$(find "$SCRIPT_DIR" -name "com.simplebackup*.plist" -type f | head -n 1)

if [ -z "$PLIST_FILE" ]; then
    echo "Error: No plist file matching pattern 'com.simplebackup*.plist' found in $SCRIPT_DIR"
    exit 1
fi

# Extract just the filename from the full path
PLIST_FILENAME=$(basename "$PLIST_FILE")

# Extract the service name from the filename (remove .plist extension)
SERVICE_NAME="${PLIST_FILENAME%.plist}"

echo "Found plist file: $PLIST_FILENAME"
echo "Service name: $SERVICE_NAME"

# Define the destination path
DEST_PATH="$HOME/Library/LaunchAgents/$PLIST_FILENAME"

# Check if service is currently loaded and unload it if necessary
if launchctl list | grep -q "$SERVICE_NAME"; then
    echo "Service $SERVICE_NAME is currently loaded. Unloading..."
    launchctl unload "$DEST_PATH" 2>/dev/null || true
fi

# Copy the plist file to LaunchAgents directory
echo "Copying $PLIST_FILENAME to ~/Library/LaunchAgents/"
cp "$PLIST_FILE" "$DEST_PATH"

# Load the service
echo "Loading service $SERVICE_NAME..."
launchctl load "$DEST_PATH"

# Start the service
echo "Starting service $SERVICE_NAME..."
launchctl start "$SERVICE_NAME"

echo "Successfully installed and started $SERVICE_NAME"