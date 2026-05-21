#!/bin/bash
# Setup SSH keys for the infrastructure

# Create SSH keys directory
mkdir -p ssh-keys

# Generate SSH key pair if it doesn't exist
if [ ! -f ssh-keys/id_rsa ]; then
    ssh-keygen -t rsa -b 4096 -f ssh-keys/id_rsa -N "" -C "redis-tool"
fi

# Copy public key to authorized_keys
cp ssh-keys/id_rsa.pub ssh-keys/authorized_keys

# Set proper permissions
chmod 600 ssh-keys/id_rsa
chmod 644 ssh-keys/id_rsa.pub
chmod 644 ssh-keys/authorized_keys

echo "SSH keys generated successfully"

