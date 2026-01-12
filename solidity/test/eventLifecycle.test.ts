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

        const diamondCutFacetInstance = await ethers.getContractAt("IDiamondCut", await diamond.getAddress());

        const cut = [{
            facetAddress: facetAddress,
            action: 0, // Add
            functionSelectors: selectors
        }];

        await diamondCutFacetInstance.facetCut(cut, ethers.ZeroAddress, "0x");

        eventFacet = await ethers.getContractAt("EventLifecycleFacet", await diamond.getAddress());

        // Remove trailing characters to fix formatting error
    });

    describe("createEvent", function () {
        it("should create event successfully", async function () {
            const now = Math.floor(Date.now() / 1000);
            const startTime = now + 3600;
            const endTime = startTime + 7200;

            const tx = await eventFacet.connect(organizer).createEvent(startTime, endTime);
            const receipt = await tx.wait();

            // Check for EventCreated event
            const event = receipt.logs.find((log: any) => {
                try {
                    return eventFacet.interface.parseLog(log)?.name === "EventCreated";
                } catch (e) {
                    return false;
                }
            });
            expect(event).to.not.be.undefined;

            const parsedLog = eventFacet.interface.parseLog(event!);
            expect(parsedLog!.args.organizer).to.equal(organizerAddr);
            expect(parsedLog!.args.startTime).to.equal(startTime);
            expect(parsedLog!.args.endTime).to.equal(endTime);

            // Verify state
            const eventId = parsedLog!.args.eventId;
            const eventState = await eventFacet.getEvent(eventId);
            expect(eventState.organizer).to.equal(organizerAddr);
            expect(eventState.startTime).to.equal(startTime);
            expect(eventState.endTime).to.equal(endTime);
            expect(eventState.state).to.equal(0); // Created
            expect(eventState.escrowBalance).to.equal(0);
        });

        it("should revert if startTime >= endTime", async function () {
            const now = Math.floor(Date.now() / 1000);
            const startTime = now + 3600;
            const endTime = startTime; // Invalid

            await expect(eventFacet.connect(organizer).createEvent(startTime, endTime))
                .to.be.revertedWithCustomError(eventFacet, "InvalidTimeRange");
        });
    });
});

