const hre = require("hardhat");
const { upgrades } = require("hardhat");
const { ethers } = hre;

var deployer;
var verifyOnDeploy = true

async function main() {
    deployer = await getDeployer()

    await deployOGXT()
}

async function getDeployer() {
    const [deployer] = await ethers.getSigners()   
    console.log("Account : ", deployer.address)
    console.log("Account balance: ", (await deployer.getBalance()).toString()) 
    return deployer
}


async function deploy(factoryName, args) {
    const Factory = await ethers.getContractFactory(factoryName)
    const contract = await Factory.deploy(...args)
    await contract.deployed()
    console.log(factoryName + " address: ", contract.address)

    if (verifyOnDeploy) {
    await delay(30000)
    try {
        await hre.run("verify:verify", {
            address: contract.address,
            network: hre.network,
            constructorArguments: args
        });
    } catch (error) {
        console.error(error);
        return contract
    }
    }
    return contract
}

async function deployUpgradable(factoryName, args) {
    const Factory = await ethers.getContractFactory(factoryName)
    const proxy = await upgrades.deployProxy(Factory, args, { 
        initializer: 'initialize', 
        kind: 'uups' 
    });
    await proxy.deployed()
    console.log(factoryName + " proxy address: ", proxy.address)

    const implementationAddress = await upgrades.erc1967.getImplementationAddress(proxy.address)
    console.log(factoryName + " implementation address: ", implementationAddress)

    if (verifyOnDeploy) {
    await delay(30000)
    try {
        await hre.run("verify:verify", {
            address: implementationAddress,
            network: hre.network
        });
    } catch (error) {
        console.error(error);
        return proxy
    }
    }
    return proxy
}

async function upgradeContract(address, factoryName, args) {
    const Factory = await ethers.getContractFactory(factoryName)
    const proxy = await upgrades.upgradeProxy(address, Factory, args, { 
        initializer: 'initialize', 
        kind: 'uups' 
    });
    await proxy.deployed()
    console.log(factoryName + " proxy address: ", proxy.address)

    const implementationAddress = await upgrades.erc1967.getImplementationAddress(proxy.address)
    console.log(factoryName + " implementation address: ", implementationAddress)

    if (verifyOnDeploy) {
    await delay(30000)
    try {
        await hre.run("verify:verify", {
            address: implementationAddress,
            network: hre.network
        });
    } catch (error) {
        console.error(error);
        return proxy
    }
    }
    return proxy
}


async function deployOGXT() {
    const gcd = await deployUpgradable("OGXT", [])
}

async function upgradeOGXT() {
    const address = ""
    const upgrade = await upgradeContract(address, "OGXT", [config.vaultParams])
}

async function verify(address, args) {
    try {
        await hre.run("verify:verify", {
            address: address,
            network: hre.network,
            constructorArguments: args
        });
    } catch (error) {
        console.error(error);
        return proxy
    }
}

async function delay(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
  }

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error)
        process.exit(1)
    })
