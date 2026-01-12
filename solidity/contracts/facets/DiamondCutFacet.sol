// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {IDiamondCut} from "../interfaces/IDiamondCut.sol";
import {SynapseLibrary} from "../libs/SynapseLibrary.sol";

contract DiamondCutFacet is IDiamondCut {
    function facetCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external override {
        SynapseLibrary.diamondCut(_diamondCut, _init, _calldata);
    }
}
