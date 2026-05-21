#!/bin/bash
# Setup script for Redis Cluster Lifecycle Tool on Linux/macOS

echo "Checking prerequisites..."

# Check Python
if ! command -v python3 &> /dev/null; then
    echo "ERROR: Python 3 is not installed"
    echo "Please install Python 3 using your package manager"
    echo "  Ubuntu/Debian: sudo apt-get install python3"
    echo "  macOS: brew install python3"
    exit 1
fi

# Check Docker or Podman
if ! command -v docker &> /dev/null && ! command -v podman &> /dev/null; then
    echo "ERROR: Neither Docker nor Podman is installed"
    echo "Please install Docker or Podman:"
    echo "  Docker: https://docs.docker.com/engine/install/"
    echo "  Podman: https://podman.io/docs/installation"
    exit 1
fi

# Check Ansible
if ! command -v ansible-playbook &> /dev/null; then
    echo "ERROR: Ansible is not installed"
    echo "Please install Ansible: pip install ansible"
    exit 1
fi

echo "All prerequisites found!"
echo ""

# Create output directory
mkdir -p output

# Create SSH keys directory
mkdir -p infra/ssh-keys

# Generate SSH keys if they don't exist
if [ ! -f infra/ssh-keys/id_rsa ]; then
    echo "Generating SSH keys..."
    ssh-keygen -t rsa -b 4096 -f infra/ssh-keys/id_rsa -N "" -C "redis-tool"
    cp infra/ssh-keys/id_rsa.pub infra/ssh-keys/authorized_keys
    chmod 600 infra/ssh-keys/id_rsa
    chmod 644 infra/ssh-keys/id_rsa.pub
    chmod 644 infra/ssh-keys/authorized_keys
    echo "SSH keys generated successfully"
fi

# Make redis-tool executable
chmod +x redis-tool

echo ""
echo "Setup complete!"
echo ""
echo "To run the tool, use: ./redis-tool [command]"
echo "For help: ./redis-tool --help"
