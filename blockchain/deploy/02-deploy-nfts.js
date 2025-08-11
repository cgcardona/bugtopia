const { network } = require("hardhat");
const { developmentChains } = require("../helper-hardhat-config");
const { verify } = require("../utils/verify");

module.exports = async ({ getNamedAccounts, deployments }) => {
    const { deploy, log, get } = deployments;
    const { deployer } = await getNamedAccounts();

    // Get previously deployed BugToken
    const bugToken = await get("BugToken");

    log("----------------------------------------------------");
    log("Deploying Bug DNA NFT...");

    const bugDNAArgs = [
        bugToken.address, // $BUG token address
        deployer, // initial owner
        "https://api.bugtopia.io/metadata/bug/" // base URI
    ];

    const bugDNANFT = await deploy("BugDNANFT", {
        from: deployer,
        args: bugDNAArgs,
        log: true,
        waitConfirmations: network.config.blockConfirmations || 1,
    });

    log(`BugDNANFT deployed at ${bugDNANFT.address}`);

    log("----------------------------------------------------");
    log("Deploying Territory NFT...");

    const territoryArgs = [
        bugToken.address, // $BUG token address
        deployer, // initial owner
        "https://api.bugtopia.io/metadata/territory/" // base URI
    ];

    const territoryNFT = await deploy("TerritoryNFT", {
        from: deployer,
        args: territoryArgs,
        log: true,
        waitConfirmations: network.config.blockConfirmations || 1,
    });

    log(`TerritoryNFT deployed at ${territoryNFT.address}`);

    // Set up initial permissions
    log("----------------------------------------------------");
    log("Setting up permissions...");

    const bugTokenContract = await ethers.getContractAt("BugToken", bugToken.address);
    
    // Authorize NFT contracts to burn tokens for utility functions
    await bugTokenContract.setAuthorizedBurner(bugDNANFT.address, true);
    await bugTokenContract.setAuthorizedBurner(territoryNFT.address, true);
    
    log("Permissions configured successfully");

    // Verify contracts on non-development chains
    if (!developmentChains.includes(network.name) && process.env.ETHERSCAN_API_KEY) {
        log("Verifying Bug DNA NFT...");
        await verify(bugDNANFT.address, bugDNAArgs);
        
        log("Verifying Territory NFT...");
        await verify(territoryNFT.address, territoryArgs);
    }

    log("----------------------------------------------------");
};

module.exports.tags = ["all", "nft", "main"];
module.exports.dependencies = ["token"];
