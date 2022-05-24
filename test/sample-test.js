const { expect } = require("chai");
const { ethers } = require("hardhat");

describe ("Vesting Contract", function () {
  let Vesting, vesting, QuanToken, quanToken, owner, addr1, addr2, addr3;
  const _DEFAULT_ISSUE_TOKEN = 1000000000000000000000;
  const decimals = ethers.BigNumber.from(10).pow(18);
  beforeEach(async function(){
      [owner, addr1, addr2, addr3, ...addr4] = await ethers.getSigners();
      let utcTimestamp = new Date().getTime();
      utcTimestamp = 1653367140;

      QuanToken = await ethers.getContractFactory("QuanToken");
      quanToken = await QuanToken.deploy();

      Vesting = await ethers.getContractFactory("Vesting");
      vesting = await Vesting.deploy();
  });
  
  it("Check Claim Function", async function(){
      //Whitelist
      await vesting.addWhiteList(addr1.address, 1000);
      await vesting.addWhiteList(addr2.address, 3500);
      await vesting.addWhiteList(addr3.address, 2300);

      //Issuing Token for Owner
      await quanToken.issueToken();
      
      //Approve for vesting to using owner's token
      const totalTokens = await vesting.getTotalTokens();
      await quanToken.approve(vesting.address, totalTokens);
      await vesting.fundVesting(totalTokens);

      //Claim
  });
});
