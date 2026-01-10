// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {SynapseUtils} from "./libs/SynapseUtils.sol";
import {IDiamond} from "./interfaces/IDiamond.sol";
import {IDiamondLoupe} from "./interfaces/IDiamondLoupe.sol";

contract SynapseDiamond  is IDiamondCut, IDiamondLoupe{
    using SynapseUtils for SynapseUtils.DiamondStorage;

    constructor(address diamondCut){

    }

    receive() external payable {}

    fallback() external payable {
        address facet = SynapseUtils.DiamondStorage._facet(msg.sig);
        require(facet != address(0), "Function not found");
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), facet, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }
}

