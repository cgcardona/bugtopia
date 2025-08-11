#!/bin/bash

# Setup Bugtopia L1 using Avalanche-CLI
# This script creates and deploys the Bugtopia L1 locally

set -e

echo "🏗️  Setting up Bugtopia L1..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if avalanche-cli is installed
if ! command -v avalanche &> /dev/null; then
    echo -e "${RED}❌ Avalanche-CLI not found. Installing...${NC}"
    curl -sSfL https://raw.githubusercontent.com/ava-labs/avalanche-cli/main/scripts/install.sh | sh -s
    export PATH=$PATH:$HOME/.avalanche-cli/bin
    echo -e "${GREEN}✅ Avalanche-CLI installed${NC}"
fi

echo -e "${BLUE}📊 Avalanche-CLI version:${NC}"
avalanche --version

# Check if Bugtopia L1 already exists
if avalanche l1 list | grep -q "bugtopia-l1"; then
    echo -e "${YELLOW}⚠️  Bugtopia L1 already exists. Checking status...${NC}"
    avalanche l1 describe bugtopia-l1
    
    read -p "Do you want to recreate the L1? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}🗑️  Stopping and removing existing L1...${NC}"
        avalanche l1 stop bugtopia-l1 || true
        # Note: There's no direct delete command, but we can create with different name
        L1_NAME="bugtopia-l1-$(date +%s)"
    else
        echo -e "${GREEN}✅ Using existing L1${NC}"
        exit 0
    fi
else
    L1_NAME="bugtopia-l1"
fi

echo -e "${BLUE}🔧 Creating Bugtopia L1 configuration...${NC}"

# Create L1 configuration
# Using non-interactive mode by providing a genesis file
cat > /tmp/bugtopia-genesis.json << EOF
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
    },
    "0x9632110A6c019e81e4f2Cac7E8c69E9a1c8F3e8C": {
      "balance": "1000000000000000000000000000"
    },
    "0x742d35Cc6634C0532925a3b8D17d9e5b8A8e1E6F": {
      "balance": "1000000000000000000000000000"
    }
  }
}
EOF

# Create L1 with custom configuration
echo -e "${BLUE}⚙️  Creating L1 with the following configuration:${NC}"
echo "   Chain ID: 68420"
echo "   Native Token: BUG"
echo "   Initial Supply: 3B BUG (distributed to 3 accounts)"
echo "   VM: C-Chain (EVM compatible)"

# Create the L1 (this will prompt for configuration)
avalanche l1 create $L1_NAME \
  --evm \
  --genesis /tmp/bugtopia-genesis.json \
  --token-name "Bugtopia" \
  --token-symbol "BUG" \
  --chain-id 68420

echo -e "${GREEN}✅ L1 configuration created${NC}"

# Deploy locally
echo -e "${BLUE}🚀 Deploying Bugtopia L1 locally...${NC}"
avalanche l1 deploy $L1_NAME --local

echo -e "${GREEN}✅ Bugtopia L1 deployed locally!${NC}"

# Get network details
echo -e "${BLUE}📋 Network Details:${NC}"
avalanche l1 describe $L1_NAME

# Extract RPC URL and other details
RPC_URL="http://127.0.0.1:9650/ext/bc/$L1_NAME/rpc"
CHAIN_ID=68420
EXPLORER_URL="http://127.0.0.1:9650/ext/bc/$L1_NAME"

echo -e "${BLUE}🔗 Connection Details:${NC}"
echo "   RPC URL: $RPC_URL"
echo "   Chain ID: $CHAIN_ID"
echo "   Native Token: BUG"
echo "   Block Explorer: $EXPLORER_URL"

# Create .env file for hardhat
echo -e "${BLUE}📝 Creating .env file for smart contract deployment...${NC}"
cat > .env << EOF
# Bugtopia L1 Configuration
BUGTOPIA_L1_RPC_URL=$RPC_URL
BUGTOPIA_L1_CHAIN_ID=$CHAIN_ID
BUGTOPIA_L1_EXPLORER_URL=$EXPLORER_URL

# Private keys for funded accounts (DO NOT USE IN PRODUCTION)
PRIVATE_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
TREASURY_PRIVATE_KEY=0x59c6995e998f97a5a0044966f0945389dc9e86dae88c6a8412f4f5c5a4f3e2e3
VALIDATOR_PRIVATE_KEY=0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a

# API Keys (set these if you have them)
SNOWTRACE_API_KEY=your_snowtrace_api_key_here
COINMARKETCAP_API_KEY=your_coinmarketcap_api_key_here
EOF

echo -e "${GREEN}✅ .env file created${NC}"

# Test connection
echo -e "${BLUE}🧪 Testing L1 connection...${NC}"
if curl -s -X POST \
  -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"eth_chainId","params":[],"id":1}' \
  $RPC_URL | grep -q "68420"; then
    echo -e "${GREEN}✅ L1 is responding correctly${NC}"
else
    echo -e "${RED}❌ L1 connection test failed${NC}"
    exit 1
fi

# Create MetaMask configuration
echo -e "${BLUE}🦊 MetaMask Configuration:${NC}"
echo "   Network Name: Bugtopia L1 Local"
echo "   RPC URL: $RPC_URL"
echo "   Chain ID: $CHAIN_ID"
echo "   Symbol: BUG"
echo "   Block Explorer: $EXPLORER_URL"

# Save configuration
mkdir -p deployments
cat > deployments/l1-config.json << EOF
{
  "l1Name": "$L1_NAME",
  "chainId": $CHAIN_ID,
  "rpcUrl": "$RPC_URL",
  "explorerUrl": "$EXPLORER_URL",
  "nativeToken": "BUG",
  "deployedAt": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "accounts": [
    {
      "address": "0x8db97C7cEcE249c2b98bDC0226Cc4C2A57BF52FC",
      "balance": "1000000000 BUG",
      "privateKey": "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80",
      "role": "deployer"
    },
    {
      "address": "0x9632110A6c019e81e4f2Cac7E8c69E9a1c8F3e8C", 
      "balance": "1000000000 BUG",
      "privateKey": "0x59c6995e998f97a5a0044966f0945389dc9e86dae88c6a8412f4f5c5a4f3e2e3",
      "role": "treasury"
    },
    {
      "address": "0x742d35Cc6634C0532925a3b8D17d9e5b8A8e1E6F",
      "balance": "1000000000 BUG", 
      "privateKey": "0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a",
      "role": "validator"
    }
  ]
}
EOF

echo -e "${GREEN}✅ L1 configuration saved to deployments/l1-config.json${NC}"

# Cleanup
rm -f /tmp/bugtopia-genesis.json

echo -e "${GREEN}🎉 Bugtopia L1 setup complete!${NC}"
echo
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Deploy smart contracts: npm run deploy:local"
echo "2. Add network to MetaMask using the details above"
echo "3. Import accounts using the private keys (FOR DEVELOPMENT ONLY)"
echo "4. Start developing with native BUG tokens!"
echo
echo -e "${BLUE}Useful commands:${NC}"
echo "   Check L1 status: avalanche l1 list"
echo "   View L1 logs: avalanche l1 logs $L1_NAME"
echo "   Stop L1: avalanche l1 stop $L1_NAME"
echo "   Start L1: avalanche l1 start $L1_NAME"
