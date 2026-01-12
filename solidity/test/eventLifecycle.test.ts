import { expect } from "chai";
import { ethers } from "hardhat";
import { Contract, Signer } from "ethers";

describe("EventLifecycleFacet", function () {
    let diamond: Contract;
    let eventFacet: Contract;
    let owner: Signer;
    let organizer: Signer;
    let other: Signer;
    let ownerAddr: string;
    let organizerAddr: string;
    let otherAddr: string;

    beforeEach(async function () {
        [owner, organizer, other] = await ethers.getSigners();
        ownerAddr = await owner.getAddress();
        organizerAddr = await organizer.getAddress();
        otherAddr = await other.getAddress();
    });
});
