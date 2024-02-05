import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";

const deployMultiSigContract: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployer } = await hre.getNamedAccounts();
  const { deploy } = hre.deployments;

  const myToken = await deploy("MyToken", {
    from: deployer,

    args: [deployer],
    log: true,
    autoMine: true,
  });
  await deploy("MultiSig", {
    from: deployer,
    // Contract constructor arguments
    args: [
      ["0x8626f6940E2eb28930eFb4CeF49B2d1F2C9C1199", "0xdD2FD4581271e230360230F9337D5c0430Bf44C0"],
      2,
      myToken.address,
    ],
    log: true,
    // autoMine: can be passed to the deploy function to make the deployment process faster on local networks by
    // automatically mining the contract deployment transaction. There is no effect on live networks.
    autoMine: true,
  });
};

export default deployMultiSigContract;

deployMultiSigContract.tags = ["MultiSig"];
