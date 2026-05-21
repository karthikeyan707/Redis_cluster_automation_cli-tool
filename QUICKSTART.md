# Quick Start Guide - Redis Cluster Lifecycle Tool

## For Linux/macOS Users

### Prerequisites Installation

#### On Linux (Ubuntu/Debian):
```bash
# Install Podman (recommended)
sudo apt-get update
sudo apt-get install -y podman

# Or install Docker
# See: https://docs.docker.com/engine/install/ubuntu/

# Install Ansible
pip install ansible

# Install Python dependencies
pip install PyPDF2
```

#### On macOS:
```bash
# Install Podman (recommended)
brew install podman

# Or install Docker Desktop for Mac
# See: https://docs.docker.com/desktop/install/mac-install/

# Install Ansible
pip install ansible

# Install Python dependencies
pip install PyPDF2
```

### Project Setup

1. **Make setup script executable**
   ```bash
   chmod +x setup.sh
   ```

2. **Run the setup script**
   ```bash
   ./setup.sh
   ```

This will:
- Check prerequisites (Python, Docker/Podman, Ansible)
- Generate SSH keys with proper permissions
- Create necessary directories
- Make redis-tool executable

### Running the Tool

```bash
# Check prerequisites
./redis-tool status

# Provision the cluster
./redis-tool provision --version 7.0.15 --masters 3 --replicas-per-master 1

# Check cluster status
./redis-tool status

# Perform rolling upgrade
./redis-tool upgrade --target-version 7.2.6 --strategy rolling

# Verify cluster integrity
./redis-tool verify --full
```

## Complete Workflow

### Step 1: Initial Setup
```bash
# Run setup script
./setup.sh

# Verify prerequisites
./redis-tool status
```

### Step 2: Provision the Cluster
```bash
# This will:
# - Start 6 Docker containers with SSH
# - Install Redis 7.0.15 on all nodes
# - Configure Redis cluster mode
# - Initialize the cluster (3 masters + 3 replicas)
# - Seed 1000 test keys
./redis-tool provision --version 7.0.15 --masters 3 --replicas-per-master 1
```

**Expected Output:**
- Container infrastructure started
- Redis installed on all 6 nodes
- Cluster initialized
- Test data seeded
- Output saved to: output/provision_output.txt

### Step 3: Verify Cluster Status
```bash
./redis-tool status
```

**Expected Output:**
- Cluster state: ok
- 3 masters with hash slot ranges
- 3 replicas with their masters
- Redis version: 7.0.15 on all nodes
- Memory usage per node

### Step 4: Perform Rolling Upgrade
```bash
./redis-tool upgrade --target-version 7.2.6 --strategy rolling
```

**What Happens:**
1. Pre-flight checks (cluster health, data integrity)
2. Upgrade replicas first (one at a time)
3. Upgrade masters with failover (one at a time)
4. Post-upgrade verification
5. Progress messages for each node

**Expected Output:**
- Progress indicators: [1/6], [2/6], etc.
- Cluster remains in "ok" state throughout
- All nodes upgraded to 7.2.6
- Data integrity verified
- Output saved to: output/upgrade_output.txt

### Step 5: Final Verification
```bash
./redis-tool verify --full
```

**Expected Output:**
- Data integrity: PASS
- Version consistency: PASS
- Topology health: PASS
- Cluster state: ok
- Replication lag: 0
- Output saved to: output/verify_output.txt

## Troubleshooting

### Docker Issues
```bash
# Check Docker is running
docker ps
# or
podman ps

# If Docker is not running, start Docker service
sudo systemctl start docker
# or
sudo systemctl start podman
```

### Ansible Connection Issues
```bash
# Test SSH to containers (password: password)
ssh -o StrictHostKeyChecking=no root@10.10.0.11

# If SSH fails, check container logs
docker logs redis-node-1
# or
podman logs redis-node-1

# Check SSH key permissions
ls -l infra/ssh-keys/id_rsa  # Should be 600
```

### Permission Issues
```bash
# Make scripts executable
chmod +x setup.sh
chmod +x redis-tool
chmod +x infra/setup-ssh.sh
```

## Project Structure Overview

```
DevOps_support_project/
├── redis-tool              # Main CLI tool (Python script)
├── setup.sh               # Linux/macOS setup script
├── README.md              # Detailed documentation
├── QUICKSTART.md          # This file
├── ansible/              # Ansible playbooks and roles
│   ├── playbooks/         # provision.yml, upgrade.yml, status.yml, verify.yml
│   ├── inventory/         # hosts.ini (container IPs)
│   └── roles/redis/       # Redis installation and configuration
├── infra/                 # Container infrastructure
│   ├── compose.yml        # Docker compose file (6 containers)
│   └── setup-ssh.sh       # SSH key generation
└── output/                # Command output logs
    ├── provision_output.txt
    ├── status_output.txt
    ├── upgrade_output.txt
    └── verify_output.txt
```

## Key Concepts

### What is a Redis Cluster?
- A distributed Redis implementation with automatic sharding
- Data is split across multiple master nodes
- Each master has replicas for high availability
- Supports automatic failover

### What is Zero Downtime Upgrade?
- Upgrading nodes one at a time
- Using Redis cluster failover to promote replicas
- Cluster remains operational throughout
- No client-visible interruptions

### What is Ansible?
- Configuration management tool
- Automates software provisioning and configuration
- Uses playbooks (YAML files) to define tasks
- Runs tasks on multiple servers in parallel

### What is Docker/Podman?
- Container platform
- Packages applications with dependencies
- Simulates multiple servers on one machine
- Lightweight and fast to start/stop

## Learning Resources

As a fresher, you might want to learn more about:

1. **Redis**: https://redis.io/docs/manual/patterns/distributed-locks/
2. **Ansible**: https://docs.ansible.com/ansible/latest/getting_started/index.html
3. **Docker**: https://docs.docker.com/get-started/
4. **Python**: https://docs.python.org/3/tutorial/

## Next Steps

After successfully running the project:

1. **Examine the output files** in the `output/` directory to understand what happened
2. **Read the Ansible playbooks** in `ansible/playbooks/` to understand the automation
3. **Modify the Redis configuration** in `ansible/roles/redis/templates/redis.conf.j2`
4. **Try different Redis versions** by changing the `--version` parameter
5. **Add more test data** by modifying `ansible/scripts/seed_data.sh`

## Common Commands Reference

```bash
# View all containers
docker ps -a
# or
podman ps -a

# View container logs
docker logs redis-node-1
# or
podman logs redis-node-1

# Stop all containers
docker-compose -f infra/compose.yml down
# or
podman-compose -f infra/compose.yml down

# Start all containers
docker-compose -f infra/compose.yml up -d
# or
podman-compose -f infra/compose.yml up -d

# Connect to a container
docker exec -it redis-node-1 bash
# or
podman exec -it redis-node-1 bash

# Check Redis cluster info inside container
docker exec redis-node-1 redis-cli CLUSTER INFO
docker exec redis-node-1 redis-cli CLUSTER NODES
# or
podman exec redis-node-1 redis-cli CLUSTER INFO
podman exec redis-node-1 redis-cli CLUSTER NODES
```

## Support

If you encounter issues:
1. Check the output files in `output/` directory
2. Review the troubleshooting section in README.md
3. Check Docker container logs
4. Verify all prerequisites are installed correctly
