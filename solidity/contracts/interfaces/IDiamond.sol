// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

interface IDiamond {

    enum FacetCutAction{
        ADD, REPLACE,REMOVE
    }

    struct FacetCut{
        address facetAddress;
        FacetCutAction action;
        bytes4[] functionSelectors;
    }

    event DiamondCut(FacetCut[] _diamondCut, address _initializer, bytes callData);
    
}