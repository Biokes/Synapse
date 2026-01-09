// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

library SynapseUtils{

    bytes32 constant SYNAPSE_STORAGE = keccak256("Synapse.diamond.storage");
    
    struct DiamonsStorage {
        address _owner;
        mapping (bytes4 => address) _facets;
        mapping (address => bytes4[]) _facetFunctionSelectors;
        bytes4[] _selectors;
    }

    

}