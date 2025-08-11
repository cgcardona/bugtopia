require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config();

module.exports = {
  solidity: {
    version: "0.8.19",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200
      }
    }
  },
  networks: {
    // Local Bugtopia L1 (via Avalanche-CLI)
    bugtopia_local: {
      url: "http://127.0.0.1:9650/ext/bc/bugtopia-l1/rpc",
      chainId: 68420,
      accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : [],
      gas: 8000000,
      gasPrice: 25000000000, // 25 gwei in BUG
      timeout: 60000
    },
    
    // Fuji Testnet Bugtopia L1
    bugtopia_fuji: {
      url: "https://api.avax-test.network/ext/bc/bugtopia-l1/rpc",
      chainId: 68420,
      accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : [],
      gas: 8000000,
      gasPrice: 25000000000,
      timeout: 60000
    },
    
    // Mainnet Bugtopia L1 
    bugtopia_mainnet: {
      url: "https://api.avax.network/ext/bc/bugtopia-l1/rpc",
      chainId: 68420,
      accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : [],
      gas: 8000000,
      gasPrice: 25000000000,
      timeout: 60000
    },
    
    // Standard Avalanche networks for testing
    avalanche_local: {
      url: "http://127.0.0.1:9650/ext/bc/C/rpc",
      chainId: 43112,
      accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : []
    },
    
    fuji: {
      url: "https://api.avax-test.network/ext/bc/C/rpc",
      chainId: 43113,
      accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : []
    },
    
    avalanche_mainnet: {
      url: "https://api.avax.network/ext/bc/C/rpc",
      chainId: 43114,
      accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : []
    }
  },
  
  namedAccounts: {
    deployer: {
      default: 0, // First account
    },
    treasury: {
      default: 1, // Second account for treasury
    },
    validator: {
      default: 2, // Third account for validator testing
    }
  },
  
  gasReporter: {
    enabled: true,
    currency: "USD",
    gasPrice: 25, // 25 gwei equivalent in BUG
    token: "BUG",
    coinmarketcap: process.env.COINMARKETCAP_API_KEY
  },
  
  etherscan: {
    // For Avalanche networks
    apiKey: {
      avalanche: process.env.SNOWTRACE_API_KEY,
      avalancheFujiTestnet: process.env.SNOWTRACE_API_KEY,
      // Custom L1 will need block explorer setup
    },
    customChains: [
      {
        network: "bugtopia_local",
        chainId: 68420,
        urls: {
          apiURL: "http://127.0.0.1:9650/ext/bc/bugtopia-l1/api",
          browserURL: "http://127.0.0.1:9650/ext/bc/bugtopia-l1"
        }
      }
    ]
  },
  
  mocha: {
    timeout: 120000 // 2 minutes for L1 operations
  },
  
  paths: {
    sources: "./contracts",
    tests: "./test",
    cache: "./cache",
    artifacts: "./artifacts"
  }
};