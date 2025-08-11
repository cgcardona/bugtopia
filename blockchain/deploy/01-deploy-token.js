const { network } = require("hardhat");
const { developmentChains } = require("../helper-hardhat-config");
const { verify } = require("../utils/verify");

module.exports = async ({ getNamedAccounts, deployments }) => {
    const { deploy, log } = deployments;
    const { deployer } = await getNamedAccounts();

    log("----------------------------------------------------");
    log("Deploying BugToken...");

    // Calculate initial supply (30% of max supply for initial distribution)
    const maxSupply = ethers.utils.parseEther("1000000000"); // 1 billion tokens
    const initialSupply = maxSupply.mul(30).div(100); // 300 million tokens

    const args = [
        deployer, // initial owner
        initialSupply // initial supply
    ];

    const bugToken = await deploy("BugToken", {
        from: deployer,
        args: args,
        log: true,
        waitConfirmations: network.config.blockConfirmations || 1,
    });

    log(`BugToken deployed at ${bugToken.address}`);

    // Verify contract on non-development chains
    if (!developmentChains.includes(network.name) && process.env.ETHERSCAN_API_KEY) {
        log("Verifying...");
        await verify(bugToken.address, args);
    }

    log("----------------------------------------------------");
};

module.exports.tags = ["all", "token", "main"];
