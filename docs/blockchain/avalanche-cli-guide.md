# 🏔️ Avalanche CLI Complete Guide

A comprehensive guide to using Avalanche CLI for network and blockchain management in the Bugtopia project.

## 📋 Table of Contents

- [Installation](#installation)
- [Network Management](#network-management)
- [Blockchain Management](#blockchain-management)
- [L1/Subnet Management](#l1subnet-management)
- [Development Workflow](#development-workflow)
- [Troubleshooting](#troubleshooting)
- [Advanced Usage](#advanced-usage)

## 🚀 Installation

### Install Avalanche CLI
```bash
# Install via official script
curl -sSfL https://raw.githubusercontent.com/ava-labs/avalanche-cli/main/scripts/install.sh | sh -s

# Add to PATH (add to your .zshrc or .bashrc)
export PATH=$PATH:$HOME/bin

# Verify installation
avalanche --version
```

### Alternative Installation Methods
```bash
# Using Go (if you have Go installed)
go install github.com/ava-labs/avalanche-cli/cmd/avalanche@latest

# Using Homebrew (macOS)
brew install ava-labs/tap/avalanche-cli

# Manual download from GitHub releases
# https://github.com/ava-labs/avalanche-cli/releases
```

## 🌐 Network Management

### Start Local Network
```bash
# Start a local Avalanche network
avalanche network start

# Start with specific version (use stable versions)
avalanche network start --avalanchego-version v1.13.4

# Start with custom number of nodes (requires clean network)
avalanche network clean  # Required for --num-nodes to take effect
avalanche network start --num-nodes 3
```

### Check Network Status
```bash
# Check if network is running
avalanche network status

# Example output (3-node network):
# Network is Up:
#   Number of Nodes: 3
#   Number of Blockchains: 0
#   Network Healthy: true
#   Blockchains Healthy: true
#
# +------------------------------------------------------------------+
# |                           PRIMARY NODES                          |
# +------------------------------------------+-----------------------+
# | NODE ID                                  | LOCALHOST ENDPOINT    |
# +------------------------------------------+-----------------------+
# | NodeID-7Xhw2mDxuDS44j42TCB6U5579esbSt3Lg | http://127.0.0.1:9650 |
# +------------------------------------------+-----------------------+
# | NodeID-MFrZFVCXPv5iCn6M9K6XduxGTYp891xXZ | http://127.0.0.1:9652 |
# +------------------------------------------+-----------------------+
# | NodeID-NFBbbJ4qCmNaCzeW7sxErhvWqvEQMnYcN | http://127.0.0.1:9654 |
# +------------------------------------------+-----------------------+
```

### Stop Network
```bash
# Stop the local network (saves snapshot by default)
avalanche network stop

# Stop without saving snapshot
avalanche network stop --dont-save

# Stop and save to custom snapshot name
avalanche network stop --snapshot-name "my-custom-snapshot"
```

### Clean/Reset Network
```bash
# Clean network data (removes all blockchain data)
avalanche network clean

# Clean and restart
avalanche network clean && avalanche network start
```

### Delete Network
```bash
# Note: There is no 'avalanche network delete' command
# To remove network data, use:
avalanche network clean

# This stops the network and deletes all state
```

## ⛓️ Blockchain Management

### List Blockchains
```bash
# List all available blockchains/L1s
avalanche blockchain list

# List with detailed information
avalanche blockchain list --deployed

# Example output:
# +------------------+--------+----------+---------+
# | BLOCKCHAIN       | VM     | VM ID    | NETWORK |
# +------------------+--------+----------+---------+
# | bugtopial1       | Subnet | subnet   | Local   |
# +------------------+--------+----------+---------+
```

### Describe Blockchain
```bash
# Get detailed information about a blockchain
avalanche blockchain describe <blockchain-name>

# Example: Describe Bugtopia L1
avalanche blockchain describe bugtopial11754956150

# Get configuration details
avalanche blockchain describe bugtopial11754956150 --config

# Example output:
# Blockchain: bugtopial11754956150
# VM: SubnetEVM
# Chain ID: 68420
# RPC URL: http://127.0.0.1:9650/ext/bc/2ZEUiUD3bYhrqsXCVvRdHNfAdegYuUVy3Vn9BYhQkhZ3uKzXeA/rpc
# Token Symbol: BUG
# Network: Local
```

### Create New Blockchain
```bash
# Create a new blockchain/L1
avalanche blockchain create <blockchain-name>

# Example: Create Bugtopia L1
avalanche blockchain create bugtopia-l1

# Interactive prompts will ask for:
# - VM type (SubnetEVM for EVM compatibility)
# - Chain ID (68420 for Bugtopia)
# - Token symbol (BUG)
# - Initial token allocation
```

### Deploy Blockchain
```bash
# Deploy to local network
avalanche blockchain deploy <blockchain-name> --local

# Deploy to Fuji testnet
avalanche blockchain deploy <blockchain-name> --fuji

# Deploy to mainnet
avalanche blockchain deploy <blockchain-name> --mainnet

# Example: Deploy Bugtopia L1 locally
avalanche blockchain deploy bugtopia-l1 --local
```

### Delete Blockchain Configuration
```bash
# Delete a blockchain configuration (not deployment)
avalanche blockchain delete <blockchain-name>

# Example: Delete Bugtopia L1 configuration
avalanche blockchain delete bugtopia-l1

# Note: This only deletes the configuration, not active deployments
# To stop deployments, use: avalanche network stop
```

## 🏗️ L1/Subnet Management

**Note**: L1s (Layer 1 blockchains) are managed through the `blockchain` command, not a separate `l1` command.

### Create L1/Subnet
```bash
# Create a new blockchain (L1/Subnet)
avalanche blockchain create <blockchain-name>

# Example: Create Bugtopia L1
avalanche blockchain create bugtopia-l1

# Interactive wizard will ask for:
# - VM type (SubnetEVM for EVM compatibility)
# - Chain ID, token symbol, etc.
```

### Deploy L1
```bash
# Deploy blockchain locally
avalanche blockchain deploy <blockchain-name> --local

# Deploy to testnet
avalanche blockchain deploy <blockchain-name> --fuji

# Deploy to mainnet
avalanche blockchain deploy <blockchain-name> --mainnet

# Example: Deploy Bugtopia L1
avalanche blockchain deploy bugtopia-l1 --local
```

### L1 Status and Information
```bash
# List all blockchains
avalanche blockchain list

# Describe specific blockchain
avalanche blockchain describe <blockchain-name>

# Example: Get Bugtopia L1 info
avalanche blockchain describe bugtopia-l1
```

### Start/Stop L1
```bash
# L1s are started/stopped with the network
avalanche network start   # Starts all deployed blockchains
avalanche network stop    # Stops all blockchains
avalanche network status  # Shows status of all blockchains
```

### Delete L1
```bash
# Delete blockchain configuration
avalanche blockchain delete <blockchain-name>

# Example: Delete Bugtopia L1 configuration
avalanche blockchain delete bugtopia-l1

# Note: This only removes the configuration, not active deployments
```

## 🔧 Development Workflow

### 1. Initial Setup
```bash
# Start local network
avalanche network start

# Create Bugtopia L1
avalanche blockchain create bugtopia-l1
# Choose: SubnetEVM
# Chain ID: 68420
# Token Symbol: BUG
# Initial Allocation: 1000000000 (1B BUG)

# Deploy locally
avalanche blockchain deploy bugtopia-l1 --local
```

### 2. Development Cycle
```bash
# Check network status
avalanche network status

# Check blockchain status
avalanche blockchain describe bugtopia-l1

# If issues occur, restart network
avalanche network stop
avalanche network start
```

### 3. Testing and Iteration
```bash
# List all blockchains
avalanche blockchain list

# Get detailed blockchain info
avalanche blockchain describe bugtopia-l1

# Clean restart if needed
avalanche network stop
avalanche network clean
avalanche network start
avalanche blockchain deploy bugtopia-l1 --local
```

### 4. Cleanup
```bash
# Stop everything
avalanche network stop

# Clean up (optional)
avalanche network clean
avalanche blockchain delete bugtopia-l1
```

## 🐛 Troubleshooting

### Common Issues and Solutions

#### "Address Already in Use" Error
This is the most common issue when starting Avalanche networks.

```bash
# Error you might see:
# listen tcp 127.0.0.1:9650: bind: address already in use

# Step 1: Check what's using the ports
lsof -i :9650
lsof -i :9651
lsof -i :9652

# Step 2: Kill conflicting processes
kill -9 <PID>

# Step 3: Clean any leftover network state
avalanche network stop
avalanche network clean

# Step 4: Restart fresh
avalanche network start

# Alternative: Force kill all avalanchego processes
pkill -f avalanchego
# Then clean and restart
avalanche network clean
avalanche network start
```

#### AvalancheGo Version Compatibility Issues
Some versions may have compatibility issues or bugs.

⚠️ **KNOWN ISSUE: v1.10.0 is unstable and creates stuck processes!**

```bash
# Error you might see with v1.10.0:
# context deadline exceeded
# failed to load process context
# IMPORTANT: v1.10.0 often leaves stuck processes that block ports!

# Solution 1: Use latest stable version (recommended)
avalanche network start
# This uses the latest version (currently v1.13.4)

# Solution 2: If you need a specific version, try these stable versions:
avalanche network start --avalanchego-version v1.13.4
avalanche network start --avalanchego-version v1.12.9
avalanche network start --avalanchego-version v1.11.11

# Solution 3: Check available versions
ls ~/.avalanche-cli/bin/avalanchego/

# Solution 4: Clean install if version is corrupted
rm -rf ~/.avalanche-cli/bin/avalanchego/avalanchego-v1.10.0
avalanche network start --avalanchego-version v1.13.4
```

#### "Tried v1.10.0, Now Getting Address in Use" 
This is a common sequence: v1.10.0 fails → leaves stuck process → next start fails with port conflict.

```bash
# The exact scenario you experienced:
# 1. avalanche network start --avalanchego-version v1.10.0  # FAILS
# 2. avalanche network start                                # "address already in use"

# Quick fix for this specific scenario:
pkill -f avalanchego                    # Kill stuck v1.10.0 process
avalanche network clean                 # Clean state
avalanche network start                 # Start with stable version

# Verification steps:
ps aux | grep avalanchego              # Should only show the grep command
lsof -i :9650 -i :9651 -i :9652      # Should show no output or only new processes
```

#### Network Won't Start (General)
```bash
# Full diagnostic and cleanup procedure
echo "=== Checking for running processes ==="
ps aux | grep avalanchego

echo "=== Checking port usage ==="
lsof -i :9650 -i :9651 -i :9652

echo "=== Stopping everything ==="
avalanche network stop
pkill -f avalanchego

echo "=== Cleaning state ==="
avalanche network clean

echo "=== Starting fresh ==="
avalanche network start
```

#### L1 Deployment Fails
```bash
# Check network is running
avalanche network status

# Check available resources
docker ps
docker system df

# Clean Docker if needed
docker system prune -f

# Retry deployment
avalanche l1 deploy bugtopia-l1 --local
```

#### Can't Connect to RPC
```bash
# Verify L1 is running
avalanche l1 describe bugtopia-l1

# Check RPC endpoint
curl -X POST --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' \
  -H "Content-Type: application/json" \
  http://127.0.0.1:9650/ext/bc/<blockchain-id>/rpc
```

#### Blockchain ID Changes
```bash
# Get current blockchain ID
avalanche blockchain describe bugtopia-l1

# Update your application configuration with new ID
# The blockchain ID changes each time you redeploy
```

### Debug Commands
```bash
# Verbose logging
avalanche --log-level debug network start

# Check configuration
avalanche config list

# View all network data
ls -la ~/.avalanche-cli/

# Check logs
tail -f ~/.avalanche-cli/logs/avalanchego.log
```

## 🚀 Advanced Usage

### Custom Network Configuration
```bash
# Start network with custom config
avalanche network start --config custom-network-config.json

# Example config file:
cat > custom-network-config.json << EOF
{
  "network-id": 1337,
  "staking-enabled": false,
  "log-level": "info",
  "http-port": 9650,
  "staker-port": 9651
}
EOF
```

### Multi-Node Setup
```bash
# IMPORTANT: --num-nodes only works with fresh networks, not existing snapshots

# Method 1: Clean start (recommended for changing node count)
avalanche network clean
avalanche network start --num-nodes 7

# Method 2: Use a custom snapshot name
avalanche network start --num-nodes 7 --snapshot-name "my-7-node-network"

# Verify the node count worked
avalanche network status
# Should show: "Number of Nodes: 7"
```

#### ⚠️ **Important: Snapshot Behavior**
- If you run `avalanche network start --num-nodes 5` on an existing network, it will show:
  ```
  Starting previously deployed and stopped snapshot
  ```
- This **ignores** the `--num-nodes` flag and uses the existing snapshot's configuration
- **Solution**: Always run `avalanche network clean` first, or use a new `--snapshot-name`

### Monitoring and Metrics
```bash
# Enable metrics
avalanche network start --metrics-enabled

# View metrics endpoint
curl http://127.0.0.1:9650/ext/metrics

# Health check
curl http://127.0.0.1:9650/ext/health
```

### Backup and Restore
```bash
# Backup network data
cp -r ~/.avalanche-cli/networks/local ~/backup/

# Restore network data
cp -r ~/backup/local ~/.avalanche-cli/networks/

# Export L1 configuration
avalanche l1 export bugtopia-l1 --output bugtopia-l1-config.json

# Import L1 configuration
avalanche l1 import --config bugtopia-l1-config.json
```

## 📚 Useful Commands Reference

### Quick Commands
```bash
# Status check
avalanche network status && avalanche l1 list

# Full restart
avalanche network stop && avalanche network start

# Deploy fresh L1
avalanche l1 deploy bugtopia-l1 --local

# Get RPC endpoint
avalanche l1 describe bugtopia-l1 | grep "RPC URL"

# Clean everything
avalanche network stop && avalanche network clean
```

### Environment Variables
```bash
# Set custom Avalanche CLI home
export AVALANCHE_CLI_HOME=~/.avalanche-cli

# Set log level
export AVALANCHE_CLI_LOG_LEVEL=debug

# Set network timeout
export AVALANCHE_CLI_NETWORK_TIMEOUT=30s
```

### Configuration Files
```bash
# Global config location
~/.avalanche-cli/config.json

# Network configurations
~/.avalanche-cli/networks/

# L1 configurations
~/.avalanche-cli/l1s/

# Logs
~/.avalanche-cli/logs/
```

## 🔗 Integration with Bugtopia

### Bugtopia-Specific Commands
```bash
# Start Bugtopia development environment
avalanche network start
avalanche blockchain deploy bugtopia-l1 --local

# Get Bugtopia L1 details for Swift integration
avalanche blockchain describe bugtopia-l1

# Reset Bugtopia L1 for testing
avalanche network stop
avalanche network clean
avalanche network start
avalanche blockchain deploy bugtopia-l1 --local
```

### Swift App Integration
After running the commands above, use the output to configure `BlockchainManagerL1.swift`:

```swift
// Use the RPC URL from: avalanche blockchain describe bugtopia-l1
let rpcURL = "http://127.0.0.1:9650/ext/bc/<blockchain-id>/rpc"
let chainId = 68420
let nativeToken = "BUG"
```

---

## 💡 Pro Tips

1. **Always check network status** before deploying L1s
2. **Use `--dont-save` flag carefully** - it prevents snapshot creation
3. **Keep blockchain IDs handy** - they change with each deployment
4. **Monitor logs** during development for debugging
5. **Clean network data** when switching between different configurations
6. **Backup important configurations** before major changes
7. **Use descriptive names** for L1s to avoid confusion

This guide covers the essential Avalanche CLI commands for Bugtopia development. For the latest features and commands, always refer to `avalanche --help` and the official [Avalanche CLI documentation](https://docs.avax.network/tooling/cli-guides/install-avalanche-cli).
