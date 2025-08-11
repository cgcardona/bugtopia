# How to Run Local Bugtopia L1

This guide covers setting up and running the Bugtopia Avalanche L1 locally for development.

## Prerequisites

### Install Avalanche-CLI
```bash
# Install Avalanche-CLI
curl -sSfL https://raw.githubusercontent.com/ava-labs/avalanche-cli/main/scripts/install.sh | sh -s
export PATH=$PATH:$HOME/.avalanche-cli/bin

# Verify installation
avalanche --version
```

### Install Dependencies
```bash
# Node.js for smart contract development
brew install node
npm install -g yarn

# Go (required for Avalanche-CLI)
brew install go

# Docker (for local network)
brew install docker
```

## L1 Configuration

### 1. Quick Setup (Automated)
```bash
cd blockchain

# Run the automated setup script
npm run setup:l1

# This will:
# - Install Avalanche-CLI if needed
# - Create and deploy Bugtopia L1 locally
# - Generate .env file with configuration
# - Test the connection
```

### 2. Manual Setup
```bash
cd /path/to/Bugtopia

# Create L1 configuration
avalanche l1 create bugtopia-l1

# Configuration options:
# - Chain ID: 68420 (custom for Bugtopia)
# - Native Token: BUG
# - Token Symbol: BUG
# - Initial Supply: 3,000,000,000 BUG
# - VM: C-Chain (EVM compatible)
```

### 2. L1 Genesis Configuration
```json
{
  "config": {
    "chainId": 68420,
    "homesteadBlock": 0,
    "eip150Block": 0,
    "eip155Block": 0,
    "eip158Block": 0,
    "byzantiumBlock": 0,
    "constantinopleBlock": 0,
    "petersburgBlock": 0,
    "istanbulBlock": 0,
    "muirGlacierBlock": 0,
    "berlinBlock": 0,
    "londonBlock": 0
  },
  "nonce": "0x0",
  "timestamp": "0x0",
  "extraData": "0x",
  "gasLimit": "0x7A1200",
  "difficulty": "0x0",
  "mixHash": "0x0000000000000000000000000000000000000000000000000000000000000000",
  "coinbase": "0x0000000000000000000000000000000000000000",
  "alloc": {
    "0x8db97C7cEcE249c2b98bDC0226Cc4C2A57BF52FC": {
      "balance": "1000000000000000000000000000"
    }
  }
}
```

## Local Development

### 1. Start Local L1
```bash
# Deploy L1 locally
avalanche l1 deploy bugtopia-l1 --local

# This will:
# - Start local Avalanche network
# - Deploy Bugtopia L1
# - Provide RPC endpoints
# - Fund pre-configured accounts with BUG tokens
```

### 2. Network Details
After deployment, you'll get:
```
RPC URL: http://127.0.0.1:9650/ext/bc/bugtopia-l1/rpc
Chain ID: 68420
Native Token: BUG
Block Explorer: http://127.0.0.1:9650/ext/bc/bugtopia-l1

Pre-funded Accounts:
- 0x8db97C7cEcE249c2b98bDC0226Cc4C2A57BF52FC (1B BUG)
- ... (additional accounts as configured)
```

### 3. Connect MetaMask
```json
{
  "Network Name": "Bugtopia L1 Local",
  "RPC URL": "http://127.0.0.1:9650/ext/bc/bugtopia-l1/rpc",
  "Chain ID": 68420,
  "Symbol": "BUG",
  "Block Explorer": "http://127.0.0.1:9650/ext/bc/bugtopia-l1"
}
```

## Smart Contract Development

### 1. Architecture Overview
Bugtopia L1 uses a simplified architecture:
- **BugtopiaL1.sol**: Native BUG token economics (fees, burning, staking rewards)
- **BugtopiaCollectibles.sol**: ERC-1155 for all NFTs (Bug DNA, Territories, Artifacts)
- **No separate ERC-20**: BUG is the native gas token

### 2. Deploy Contracts
```bash
cd blockchain

# Install dependencies
npm install

# Deploy to local L1
npm run deploy:local

# Or deploy to specific networks
npm run deploy:fuji      # Fuji testnet
npm run deploy:mainnet   # Avalanche mainnet
```

### 3. Available Commands
```bash
# L1 Management
npm run l1:start         # Start local L1
npm run l1:stop          # Stop local L1  
npm run l1:status        # Check L1 status
npm run l1:logs          # View L1 logs
npm run l1:describe      # Show L1 details

# Contract Operations
npm run compile          # Compile contracts
npm run test            # Run tests
npm run verify:l1       # Verify contracts on L1
```

## Swift Integration

### 1. Use New L1 Manager
The project now includes `BlockchainManagerL1.swift` specifically designed for Avalanche L1:
```swift
// Initialize L1 manager
let blockchainManager = BlockchainManagerL1()

// It automatically connects to local L1:
// - RPC: http://127.0.0.1:9650/ext/bc/bugtopia-l1/rpc
// - Chain ID: 68420
// - Native Token: BUG
```

### 2. Key Differences from ERC-20
```swift
// Native token operations (no contract calls needed)
blockchainManager.transferBug(to: recipient, amount: 1.0)
blockchainManager.payUtilityFee(type: "breeding", amount: 0.001)
blockchainManager.burnBug(amount: 0.5, reason: "deflation")

// ERC-1155 NFT operations (single contract for all NFTs)
blockchainManager.mintBugDNA(for: bug, to: recipient)
blockchainManager.mintTerritory(for: population, to: recipient)
blockchainManager.batchMintNFTs(operations: operations)
```

## Monitoring & Debugging

### 1. Check L1 Status
```bash
# View running L1s
avalanche l1 list

# Get L1 details
avalanche l1 describe bugtopia-l1

# Check logs
avalanche l1 logs bugtopia-l1
```

### 2. Stop/Restart L1
```bash
# Stop L1
avalanche l1 stop bugtopia-l1

# Restart L1
avalanche l1 start bugtopia-l1
```

## Production Deployment

### 1. Fuji Testnet
```bash
# Deploy to Fuji testnet
avalanche l1 deploy bugtopia-l1 --fuji

# Will require AVAX for deployment costs
```

### 2. Mainnet
```bash
# Deploy to mainnet (requires validator setup)
avalanche l1 deploy bugtopia-l1 --mainnet
```

## Gas Economics

Since BUG is the native token:
- **All transaction fees paid in BUG**
- **Validator rewards paid in BUG**
- **No need for ETH/AVAX for gas**
- **True circular token economy**

## Development Workflow

1. Start local L1: `avalanche l1 deploy bugtopia-l1 --local`
2. Deploy contracts: `npx hardhat run scripts/deploy.js --network bugtopia_local`
3. Run Bugtopia app with blockchain integration
4. Test evolutionary events triggering NFT mints
5. Monitor gas usage and optimize
6. Iterate on tokenomics parameters

## Troubleshooting

### Common Issues
1. **Port conflicts**: Ensure ports 9650, 9651 are available
2. **Docker issues**: Restart Docker daemon
3. **Gas estimation**: Use higher gas limits for complex operations
4. **Account funding**: Ensure accounts have sufficient BUG for gas

### Logs Location
- L1 logs: `~/.avalanche-cli/logs/`
- Network data: `~/.avalanche-cli/l1s/bugtopia-l1/`
