const { ethers } = require("hardhat");

async function main() {
  console.log("🚀 Deploying Bugtopia L1 Contracts...");
  
  // Get signers
  const [deployer, treasury] = await ethers.getSigners();
  
  console.log("Deploying with account:", deployer.address);
  console.log("Treasury account:", treasury.address);
  
  // Check deployer balance (should be in native BUG tokens)
  const balance = await ethers.provider.getBalance(deployer.address);
  console.log("Deployer balance:", ethers.formatEther(balance), "BUG");
  
  if (balance < ethers.parseEther("10")) {
    console.warn("⚠️  Low BUG balance. You may need more tokens for deployment.");
  }
  
  // 1. Deploy BugtopiaL1 contract (native token economics)
  console.log("\n📋 Deploying BugtopiaL1 contract...");
  
  const BugtopiaL1 = await ethers.getContractFactory("BugtopiaL1");
  const bugtopiaL1 = await BugtopiaL1.deploy(treasury.address);
  await bugtopiaL1.waitForDeployment();
  
  const bugtopiaL1Address = await bugtopiaL1.getAddress();
  console.log("✅ BugtopiaL1 deployed to:", bugtopiaL1Address);
  
  // 2. Deploy BugtopiaCollectibles contract (ERC-1155)
  console.log("\n🎨 Deploying BugtopiaCollectibles contract...");
  
  const BugtopiaCollectibles = await ethers.getContractFactory("BugtopiaCollectibles");
  const collectibles = await BugtopiaCollectibles.deploy(
    bugtopiaL1Address,
    "https://api.bugtopia.io/metadata/{id}.json" // Metadata URI template
  );
  await collectibles.waitForDeployment();
  
  const collectiblesAddress = await collectibles.getAddress();
  console.log("✅ BugtopiaCollectibles deployed to:", collectiblesAddress);
  
  // 3. Configure permissions
  console.log("\n🔑 Setting up permissions...");
  
  // Add collectibles contract as authorized minter
  const authTx = await collectibles.addAuthorizedMinter(deployer.address);
  await authTx.wait();
  console.log("✅ Deployer added as authorized minter");
  
  // 4. Test basic functionality
  console.log("\n🧪 Testing basic functionality...");
  
  // Test utility fee payment
  const utilityFee = await bugtopiaL1.getUtilityFee("breeding");
  console.log("Breeding fee:", ethers.formatEther(utilityFee), "BUG");
  
  // Test fee payment (using small amount)
  const payFeeTx = await bugtopiaL1.payUtilityFee("breeding", { 
    value: utilityFee 
  });
  await payFeeTx.wait();
  console.log("✅ Test utility fee payment successful");
  
  // Check economic state
  const [totalBurned, rewardsPool, treasuryAddr] = await bugtopiaL1.getEconomicState();
  console.log("Economic state:");
  console.log("  Total burned:", ethers.formatEther(totalBurned), "BUG");
  console.log("  Rewards pool:", ethers.formatEther(rewardsPool), "BUG");
  console.log("  Treasury:", treasuryAddr);
  
  // 5. Generate deployment summary
  console.log("\n📊 Deployment Summary");
  console.log("====================");
  console.log("Network:", (await ethers.provider.getNetwork()).name);
  console.log("Chain ID:", (await ethers.provider.getNetwork()).chainId);
  console.log("Deployer:", deployer.address);
  console.log("Treasury:", treasury.address);
  console.log();
  console.log("Contract Addresses:");
  console.log("  BugtopiaL1:", bugtopiaL1Address);
  console.log("  BugtopiaCollectibles:", collectiblesAddress);
  console.log();
  console.log("Gas Used:");
  console.log("  BugtopiaL1:", (await bugtopiaL1.deploymentTransaction()?.wait())?.gasUsed.toString());
  console.log("  BugtopiaCollectibles:", (await collectibles.deploymentTransaction()?.wait())?.gasUsed.toString());
  
  // 6. Save deployment info
  const deploymentInfo = {
    network: (await ethers.provider.getNetwork()).name,
    chainId: Number((await ethers.provider.getNetwork()).chainId),
    timestamp: new Date().toISOString(),
    deployer: deployer.address,
    treasury: treasury.address,
    contracts: {
      bugtopiaL1: bugtopiaL1Address,
      collectibles: collectiblesAddress
    },
    nativeToken: "BUG",
    verified: false
  };
  
  const fs = require("fs");
  const path = require("path");
  
  const deploymentsDir = path.join(__dirname, "..", "deployments");
  if (!fs.existsSync(deploymentsDir)) {
    fs.mkdirSync(deploymentsDir);
  }
  
  const networkName = (await ethers.provider.getNetwork()).name || "unknown";
  const deploymentFile = path.join(deploymentsDir, `${networkName}-${Date.now()}.json`);
  
  fs.writeFileSync(deploymentFile, JSON.stringify(deploymentInfo, null, 2));
  console.log("\n💾 Deployment info saved to:", deploymentFile);
  
  // 7. Next steps
  console.log("\n🎯 Next Steps:");
  console.log("1. Update Swift app with contract addresses:");
  console.log(`   BugtopiaL1: "${bugtopiaL1Address}"`);
  console.log(`   Collectibles: "${collectiblesAddress}"`);
  console.log("2. Set up metadata server at: https://api.bugtopia.io/metadata/");
  console.log("3. Add more authorized minters as needed");
  console.log("4. Configure governance parameters");
  console.log("5. Test NFT minting from simulation");
  
  return {
    bugtopiaL1: bugtopiaL1Address,
    collectibles: collectiblesAddress
  };
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then((addresses) => {
    console.log("\n🎉 Deployment completed successfully!");
    process.exit(0);
  })
  .catch((error) => {
    console.error("\n❌ Deployment failed:");
    console.error(error);
    process.exit(1);
  });
