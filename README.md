# Redis Cluster Lifecycle Tool

A CLI tool that wraps Ansible to provision, operate, and perform rolling upgrades of a Redis Cluster with zero downtime and verified data integrity.

## Project Overview

This tool manages a 6-node Redis Cluster (3 masters + 3 replicas) running inside containers (Docker or Podman) that simulate real servers with SSH access. Everything is driven through the CLI — no manual SSH, no manual redis-cli commands during operations.

## Prerequisites

- **Container Runtime**: Docker Engine or Podman (Podman is preferred as it's fully open source)
- **Ansible**: Version 2.14 or higher
- **Python**: 3.x (for the CLI tool)
- **SSH**: For container communication

### Installing Prerequisites

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
pip install PyPDF2  # For PDF reading if needed
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
pip install PyPDF2  # For PDF reading if needed
```

## Project Structure

```
DevOps_support_project/
├── redis-tool                    # CLI entrypoint (Python script)
├── ansible/
│   ├── ansible.cfg              # Ansible configuration
│   ├── inventory/
│   │   └── hosts.ini            # Ansible inventory file
│   ├── playbooks/
│   │   ├── provision.yml        # Provision Redis cluster
│   │   ├── upgrade.yml          # Rolling upgrade
│   │   ├── status.yml           # Cluster status
│   │   └── verify.yml           # Cluster verification
│   ├── scripts/
│   │   ├── seed_data.sh         # Seed test data
│   │   └── verify_data.sh       # Verify data integrity
│   └── roles/
│       └── redis/
│           ├── tasks/
│           │   └── main.yml     # Redis installation tasks
│           ├── handlers/
│           │   └── main.yml     # Service handlers
│           ├── templates/
│           │   ├── redis.conf.j2    # Redis configuration template
│           │   └── redis.service.j2 # Systemd service template
│           └── defaults/
│               └── main.yml     # Default variables
├── infra/
│   ├── compose.yml              # Docker/Podman compose file
│   └── setup-ssh.sh             # SSH key setup script
├── output/                      # Command output logs
│   ├── provision_output.txt
│   ├── status_output.txt
│   ├── upgrade_output.txt
│   └── verify_output.txt
└── README.md                    # This file
```

## How to Use

### 1. Run the Setup Script

```bash
chmod +x setup.sh
./setup.sh
```

This will:
- Check prerequisites (Python, Docker/Podman, Ansible)
- Generate SSH keys
- Create necessary directories
- Make redis-tool executable

### 2. Check Prerequisites

The tool automatically checks for required dependencies before any operation:

```bash
./redis-tool status
```

If dependencies are missing, the tool will print installation instructions.

### 3. Provision Redis Cluster

Provision a 6-node Redis cluster with 3 masters and 1 replica per master:

```bash
./redis-tool provision --version 7.0.15 --masters 3 --replicas-per-master 1
```

This command:
- Sets up 6 containers with SSH access (Ubuntu 22.04)
- Installs Redis 7.0.15 on all nodes
- Configures Redis for cluster mode
- Initializes the Redis cluster
- Seeds 1000 test keys for data verification

**What happens behind the scenes:**
1. Generates SSH keys for container communication
2. Starts 6 containers using Docker/Podman compose
3. Runs Ansible playbooks to install and configure Redis
4. Initializes the Redis cluster with 3 masters and 3 replicas
5. Seeds test data for verification

### 4. Check Cluster Status

View the current cluster status:

```bash
./redis-tool status
```

Output includes:
- Each node's IP, port, role (master/replica), and Redis version
- For masters: hash slot range and number of keys
- For replicas: which master they're replicating
- Cluster state (ok/fail)
- Memory usage per node

### 5. Perform Rolling Upgrade

Upgrade the cluster to a new Redis version with zero downtime:

```bash
./redis-tool upgrade --target-version 7.2.6 --strategy rolling
```

**Rolling Upgrade Strategy:**
1. **Pre-flight checks**
   - Verify cluster is healthy (cluster_state: ok)
   - Verify all nodes are reachable
   - Verify current version differs from target version
   - Run data verify to establish pre-upgrade integrity baseline

2. **Upgrade replicas first (one at a time)**
   - Stop Redis on the replica node
   - Install new Redis version
   - Start Redis with same configuration
   - Wait for replica to rejoin and complete sync
   - Verify cluster state is ok before moving to next node

3. **Upgrade masters (one at a time, with failover)**
   - Trigger CLUSTER FAILOVER on its replica
   - Wait for failover to complete
   - Stop Redis on the old master (now a replica)
   - Install new Redis version
   - Start Redis, wait for it to rejoin as replica
   - Verify cluster state is ok before moving to next master

4. **Post-upgrade verification**
   - Run data verify - all 1000 keys must be present and correct
   - Run status - all nodes must show new version
   - Print upgrade completion message

### 6. Verify Cluster Integrity

Run comprehensive cluster verification:

```bash
./redis-tool verify --full
```

Verification includes:
- Data integrity (all 1000 keys present and correct)
- Version consistency (all nodes report same Redis version)
- Topology health (all hash slots covered, every master has at least one replica)
- Cluster state (cluster_state: ok)
- Replication lag (all replicas have master_link_status: up)

## Workflow Summary

### Complete Workflow Example

```bash
# 1. Check prerequisites
./redis-tool status

# 2. Provision the cluster
./redis-tool provision --version 7.0.15 --masters 3 --replicas-per-master 1

# 3. Check cluster status
./redis-tool status

# 4. Perform rolling upgrade
./redis-tool upgrade --target-version 7.2.6 --strategy rolling

# 5. Verify the upgrade
./redis-tool verify --full

# 6. Check final status
./redis-tool status
```

## Container Infrastructure

The tool uses Docker/Podman to create 6 containers simulating real servers:

- **redis-node-1**: 10.10.0.11 (Master)
- **redis-node-2**: 10.10.0.12 (Master)
- **redis-node-3**: 10.10.0.13 (Master)
- **redis-node-4**: 10.10.0.14 (Replica)
- **redis-node-5**: 10.10.0.15 (Replica)
- **redis-node-6**: 10.10.0.16 (Replica)

All containers run Ubuntu 22.04 with SSH server enabled. Your host machine acts as the Ansible control node.

## Troubleshooting

### Container Runtime Issues

If containers fail to start:
```bash
# Check container status
docker ps -a
# or
podman ps -a

# View container logs
docker logs redis-node-1
# or
podman logs redis-node-1
```

### SSH Connection Issues

If Ansible can't connect to containers:
```bash
# Test SSH connection manually
ssh -o StrictHostKeyChecking=no root@10.10.0.11
# Password: password

# Check SSH keys
ls -la infra/ssh-keys/

# Verify SSH key permissions
ls -l infra/ssh-keys/id_rsa  # Should be 600
ls -l infra/ssh-keys/id_rsa.pub  # Should be 644
```

### Redis Cluster Issues

If cluster initialization fails:
```bash
# Check Redis logs on a node
docker exec redis-node-1 cat /var/log/redis/redis.log

# Check cluster status manually
docker exec redis-node-1 redis-cli CLUSTER INFO
docker exec redis-node-1 redis-cli CLUSTER NODES
```

### Ansible Playbook Issues

If Ansible playbooks fail:
```bash
# Run with verbose output
ansible-playbook -vvv ansible/playbooks/provision.yml

# Check Ansible configuration
cat ansible/ansible.cfg
```

## Architecture Decisions

### Why Ansible?
- Declarative configuration management
- Idempotent operations (safe to run multiple times)
- Excellent for multi-node orchestration
- Built-in modules for common tasks

### Why Docker/Podman?
- Lightweight containerization
- Easy to simulate multi-node environment locally
- Supports both Docker and Podman for flexibility
- Rootless operation with Podman (more secure)

### Why Python CLI?
- Cross-platform compatibility
- Easy to read and maintain
- Good library support for subprocess management
- Simple argument parsing

## Known Limitations

1. **Network Configuration**: Static IP addresses are used; may conflict with existing networks
2. **Resource Requirements**: Running 6 containers requires sufficient system resources
3. **Rollback**: Automatic rollback is not implemented (stretch goal)
4. **Scale Operations**: Scale out/in operations are not implemented (stretch goals)

## Stretch Goals (Not Implemented)

These features are noted in the requirements but not implemented in this version:

- **S1 - Scale Out**: Add new master + replica pairs to the cluster
- **S2 - Scale In**: Remove nodes from the cluster
- **S3 - Rollback**: Automatic rollback on upgrade failure
- **S4 - Idempotency**: Enhanced idempotency for all operations
- **S5 - Structured Logging**: Detailed JSON logging to logs/ directory

## Output Files

All command outputs are saved to the `output/` directory:

- `provision_output.txt`: Provision command output
- `status_output.txt`: Cluster status information
- `upgrade_output.txt`: Rolling upgrade progress and results
- `verify_output.txt`: Verification results

## Security Notes

- SSH keys are generated locally and not shared
- Containers use simple password authentication (for development only)
- Redis is configured without password (for development only)
- In production, use proper authentication and encryption

## License

This project is created for educational purposes to demonstrate DevOps automation skills.

## Support

For issues or questions:
1. Check the troubleshooting section above
2. Review the output files in the `output/` directory
3. Examine Ansible playbook logs with `-vvv` flag
4. Check container logs for runtime issues
