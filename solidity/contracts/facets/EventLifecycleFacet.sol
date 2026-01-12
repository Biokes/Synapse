// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {SynapseLibrary} from "../libs/SynapseLibrary.sol";

error NotOrganizer();
error InvalidTimeRange();
error InvalidState();
error InvalidAmount();
error InvalidTimestamp();
error TransferFailed();
error ReentrancyGuard();

contract EventLifecycleFacet {

    event EventCreated(uint256 indexed eventId, address indexed organizer, uint64 startTime, uint64 endTime);
    event EventFunded(uint256 indexed eventId, uint256 amount);
    event EventActivated(uint256 indexed eventId);
    event EventSettling(uint256 indexed eventId);
    event EventFinalized(uint256 indexed eventId, uint256 payoutAmount);

    function createEvent(uint64 startTime, uint64 endTime) external returns (uint256 eventId) {
        if (startTime >= endTime) revert InvalidTimeRange();
        
        SynapseLibrary.AppStorage storage s = SynapseLibrary.diamondStorage();
        
        eventId = s.nextEventId++;
        
        s.events[eventId] = SynapseLibrary.Event({
            organizer: msg.sender,
            startTime: startTime,
            endTime: endTime,
            state: SynapseLibrary.STATE_CREATED,
            escrowBalance: 0
        });
        
        emit EventCreated(eventId, msg.sender, startTime, endTime);
    }

    function fundEvent(uint256 eventId) external payable {
        SynapseLibrary.AppStorage storage s = SynapseLibrary.diamondStorage();
        SynapseLibrary.Event storage evt = s.events[eventId];
        
        if (evt.organizer != msg.sender) revert NotOrganizer();
        if (evt.state != SynapseLibrary.STATE_CREATED) revert InvalidState();
        if (msg.value == 0) revert InvalidAmount();
        
        evt.escrowBalance += msg.value;
        evt.state = SynapseLibrary.STATE_FUNDED;
        
        emit EventFunded(eventId, msg.value);
    }

    function activateEvent(uint256 eventId) external {
        SynapseLibrary.AppStorage storage s = SynapseLibrary.diamondStorage();
        SynapseLibrary.Event storage evt = s.events[eventId];
        
        if (evt.organizer != msg.sender) revert NotOrganizer();
        if (evt.state != SynapseLibrary.STATE_FUNDED) revert InvalidState();
        if (block.timestamp < evt.startTime) revert InvalidTimestamp();
        
        evt.state = SynapseLibrary.STATE_ACTIVE;
        
        emit EventActivated(eventId);
    }

}
