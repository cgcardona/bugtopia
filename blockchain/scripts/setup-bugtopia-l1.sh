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

# Check for Node.js (works with both nvm and brew installations)
if ! command -v node &> /dev/null; then
    echo -e "${RED}❌ Node.js not found. Please install Node.js:${NC}"
    echo -e "${YELLOW}   Using nvm (recommended): nvm install --lts && nvm use --lts${NC}"
    echo -e "${YELLOW}   Using brew: brew install node${NC}"
    exit 1
else
    echo -e "${GREEN}✅ Node.js found: $(node --version)${NC}"
fi

# Check for npm
if ! command -v npm &> /dev/null; then
    echo -e "${RED}❌ npm not found. Please ensure Node.js is properly installed.${NC}"
    exit 1
else
    echo -e "${GREEN}✅ npm found: $(npm --version)${NC}"
fi

# Check if Bugtopia blockchain already exists
if avalanche blockchain list | grep -q "bugtopial1"; then
    echo -e "${YELLOW}⚠️  Bugtopia blockchain already exists. Checking status...${NC}"
    avalanche blockchain describe bugtopial1
    
    read -p "Do you want to recreate the blockchain? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}🗑️  Stopping and removing existing blockchain...${NC}"
        avalanche network stop || true
        # Note: There's no direct delete command, but we can create with different name
        BLOCKCHAIN_NAME="bugtopial1$(date +%s)"
    else
        echo -e "${GREEN}✅ Using existing blockchain${NC}"
        exit 0
    fi
else
    BLOCKCHAIN_NAME="bugtopial1"
fi

echo -e "${BLUE}🔧 Creating Bugtopia blockchain configuration...${NC}"

# Create blockchain with custom configuration
echo -e "${BLUE}⚙️  Creating blockchain with the following configuration:${NC}"
echo "   Chain ID: 68420"
echo "   Native Token: BUG"
echo "   VM: Subnet-EVM (EVM compatible)"

# Create the blockchain using non-interactive flags
echo -e "${BLUE}📝 Creating blockchain with pre-configured settings...${NC}"
echo "   Chain ID: 68420"
echo "   Token Symbol: BUG"
echo "   VM: Subnet-EVM"
echo "   Validation: Proof of Authority"

avalanche blockchain create $BLOCKCHAIN_NAME \
  --evm \
  --evm-chain-id 68420 \
  --evm-token BUG \
  --proof-of-authority \
  --production-defaults

echo -e "${GREEN}✅ Blockchain configuration created${NC}"

# Deploy locally
echo -e "${BLUE}🚀 Deploying Bugtopia blockchain locally...${NC}"
avalanche blockchain deploy $BLOCKCHAIN_NAME --local

echo -e "${GREEN}✅ Bugtopia L1 deployed locally!${NC}"

# Get network details
echo -e "${BLUE}📋 Network Details:${NC}"
avalanche blockchain describe $BLOCKCHAIN_NAME

# Extract RPC URL and other details from actual blockchain
echo -e "${BLUE}🔍 Getting actual blockchain details...${NC}"
BLOCKCHAIN_INFO=$(avalanche blockchain describe $BLOCKCHAIN_NAME)

# Extract RPC URL from the blockchain info (handle multi-line output)
RPC_URL=$(echo "$BLOCKCHAIN_INFO" | grep -A 2 "RPC Endpoint" | grep "http" | sed 's/.*http/http/' | sed 's/[[:space:]]*|.*$//' | tr -d ' ')
CHAIN_ID=68420
EXPLORER_URL=$(echo "$RPC_URL" | sed 's|/rpc||')

echo -e "${BLUE}📋 Extracted details:${NC}"
echo "   RPC URL: $RPC_URL"
echo "   Chain ID: $CHAIN_ID"

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
RESPONSE=$(curl -s -X POST \
  -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"eth_chainId","params":[],"id":1}' \
  $RPC_URL)

echo -e "${BLUE}📡 RPC Response: $RESPONSE${NC}"

if echo "$RESPONSE" | grep -q "0x10b44"; then
    echo -e "${GREEN}✅ L1 is responding correctly (Chain ID: 68420)${NC}"
elif echo "$RESPONSE" | grep -q "error"; then
    echo -e "${RED}❌ L1 connection test failed - RPC error${NC}"
    echo "$RESPONSE"
    exit 1
else
    echo -e "${RED}❌ L1 connection test failed - Unexpected response${NC}"
    echo "$RESPONSE"
    exit 1
fi

# Create Core Wallet configuration
echo -e "${BLUE}🔵 Core Wallet Configuration:${NC}"
echo "   Network Name: Bugtopia L1 Local"
echo "   RPC URL: $RPC_URL"
echo "   Chain ID: $CHAIN_ID"
echo "   Symbol: BUG"
echo "   Block Explorer: $EXPLORER_URL"

# Save configuration
mkdir -p deployments
cat > deployments/blockchain-config.json << EOF
{
  "blockchainName": "$BLOCKCHAIN_NAME",
  "chainId": $CHAIN_ID,
  "rpcUrl": "$RPC_URL",
  "explorerUrl": "$EXPLORER_URL",
  "nativeToken": "BUG",
  "deployedAt": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "vm": "Subnet-EVM",
  "accounts": [
    {
      "address": "0x8db97C7cEcE249c2b98bDC0226Cc4C2A57BF52FC",
      "privateKey": "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80",
      "role": "deployer"
    },
    {
      "address": "0x9632110A6c019e81e4f2Cac7E8c69E9a1c8F3e8C", 
      "privateKey": "0x59c6995e998f97a5a0044966f0945389dc9e86dae88c6a8412f4f5c5a4f3e2e3",
      "role": "treasury"
    },
    {
      "address": "0x742d35Cc6634C0532925a3b8D17d9e5b8A8e1E6F",
      "privateKey": "0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a",
      "role": "validator"
    }
  ]
}
EOF

echo -e "${GREEN}✅ Blockchain configuration saved to deployments/blockchain-config.json${NC}"

echo -e "${GREEN}🎉 Bugtopia L1 setup complete!${NC}"
echo
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Deploy smart contracts: npm run deploy:local"
echo "2. Add network to Core Wallet using the details above"
echo "3. Import accounts using the private keys (FOR DEVELOPMENT ONLY)"
echo "4. Start developing with native BUG tokens!"
echo
echo -e "${BLUE}Useful commands:${NC}"
echo "   Check blockchain status: avalanche blockchain list"
echo "   View network status: avalanche network status"
echo "   Stop network: avalanche network stop"
echo "   Start network: avalanche network start"
