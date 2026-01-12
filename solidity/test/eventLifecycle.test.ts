import { expect } from "chai";
import { network } from "hardhat";
import { Contract, Signer } from "ethers";

const { ethers } = await network.connect();

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

        const DiamondCutFacetFactory = await ethers.getContractFactory("DiamondCutFacet");
        const diamondCutFacet = await DiamondCutFacetFactory.deploy();
        await diamondCutFacet.waitForDeployment();

        const DiamondFactory = await ethers.getContractFactory("SynapseDiamond");
        diamond = await DiamondFactory.deploy(await diamondCutFacet.getAddress());
        await diamond.waitForDeployment();

        const EventFacetFactory = await ethers.getContractFactory("EventLifecycleFacet");
        const eventFacetImpl = await EventFacetFactory.deploy();
        await eventFacetImpl.waitForDeployment();

        const facetAddress = await eventFacetImpl.getAddress();
        const selectors = [
            eventFacetImpl.interface.getFunction("createEvent")!.selector,
            eventFacetImpl.interface.getFunction("fundEvent")!.selector,
            eventFacetImpl.interface.getFunction("activateEvent")!.selector,
            eventFacetImpl.interface.getFunction("beginSettlement")!.selector,
            eventFacetImpl.interface.getFunction("finalizeEvent")!.selector,
            eventFacetImpl.interface.getFunction("getEvent")!.selector,
        ];

        const diamondCutFacet = await ethers.getContractAt("SynapseDiamond", await diamond.getAddress());

        eventFacet = await ethers.getContractAt("EventLifecycleFacet", await diamond.getAddress());
    });
});
