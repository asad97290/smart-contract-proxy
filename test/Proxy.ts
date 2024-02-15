import {
  loadFixture,
} from "@nomicfoundation/hardhat-toolbox/network-helpers";
import { expect } from "chai";
import { ethers } from "hardhat";
import { Proxy,Logic1,Logic2 } from "../typechain-types";
import { Addressable } from "ethers";
describe("Proxy", function () {
  const ZERO_ADDRESS = "0x0000000000000000000000000000000000000000"
  
  async function deployProxyFixture() {
     const [owner, otherAccount] = await ethers.getSigners();
    const StorageSlot = await ethers.getContractFactory("StorageSlot");
    const storageSlot = await StorageSlot.deploy() 
    const Proxy = await ethers.getContractFactory("Proxy",{
      libraries: {
        "StorageSlot":storageSlot.target
      },
    });
    const proxy = await Proxy.deploy();
    const Logic1 = await ethers.getContractFactory("Logic1");
    const logic1 = await Logic1.deploy();
    const Logic2 = await ethers.getContractFactory("Logic2");
    const logic2 = await Logic2.deploy();
    const proxyAsLogic1 = await ethers.getContractAt("Logic1",proxy.target) 
    const proxyAsLogic2 = await ethers.getContractAt("Logic2",proxy.target) 
    return { proxy,logic1,proxyAsLogic1,proxyAsLogic2,logic2, owner, otherAccount };
  }

  async function lookupSlot(contractAddress: Addressable | string, slot: string) : Promise<number>{
    return parseInt(await ethers.provider.getStorage(contractAddress,slot))
  }

  describe("Deployment", function () {
   let proxy: Proxy
   let proxyAsLogic1: Logic1
   let proxyAsLogic2: Logic2
   let logic1: Logic1
   let logic2: Logic2
    before(async()=>{
      let fixture = await loadFixture(deployProxyFixture);
      proxy = fixture?.proxy
      proxyAsLogic1 = fixture?.proxyAsLogic1
      proxyAsLogic2 = fixture?.proxyAsLogic2
      logic1 = fixture?.logic1
      logic2 = fixture?.logic2
    })
    it("Should get zero address", async function () {

      expect(await proxy.getImplementation()).to.equal(ZERO_ADDRESS);
    });
    it("Should set new implementation address", async function () {
      
      await proxy.changeImplementation(logic1.target)
    });
    it("Should get new implementation address", async function () {
      
      expect(await proxy.getImplementation()).to.equal(logic1.target);
    });
    it("Should change x", async function () {
      expect(await lookupSlot(proxy.target,"0x0")).to.equal(0)
      await proxyAsLogic1.changeX(1)
      expect(await lookupSlot(proxy.target,"0x0")).to.equal(1)
    });


    it("Should change implementation", async function () {
      await proxy.changeImplementation(logic2.target)
    });
    it("Should get new implementation address", async function () {
      
      expect(await proxy.getImplementation()).to.equal(logic2.target);
    });

    it("Should change x and triple", async function () {

      await proxyAsLogic2.changeX(2)
      expect(await lookupSlot(proxy.target,"0x0")).to.equal(5)
      await proxyAsLogic2.triple(2)
      expect(await lookupSlot(proxy.target,"0x0")).to.equal(11)

      console.log(ethers.parseEther("1"))
    });
  });
});
