// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;
import {IDiamond} from "../interfaces/IDiamond.sol";

library SynapseUtils{

    bytes32 constant SYNAPSE_DIAMOND_STORAGE = keccak256("Synapse.diamond.storage");
    
    struct DiamondStorage {
        address _owner;
        mapping (bytes4 => address) _facets;
        mapping (address => bytes4[]) _facetFunctionSelectors;
        bytes4[] _selectors;
    }

     function getDiamondStorage() internal pure returns (DiamondStorage storage ds) {
        bytes32 position = SYNAPSE_DIAMOND_STORAGE;
        assembly {
            ds.slot := position
        }
    }
    
    function diamondCut(IDiamond.FacetCut[] memory _diamondCut,address _init,bytes memory _calldata) internal {
        DiamondStorage storage ds = getDiamondStorage();
        for (uint256 i = 0; i < _diamondCut.length; i++) {
            IDiamond.FacetCut memory facetCut = _diamondCut[i];
            address facet_address = facetCut.facetAddress;
            IDiamond.FacetCutAction action = facetCut.action;
            if (action == IDiamond.FacetCutAction.Add) {
                addFacet(ds, facet_address, facetCut.functionSelectors);
            } else if (action == IDiamond.FacetCutAction.Replace) {
                replaceFacet(ds, facet_address, facetCut.functionSelectors);
            } else if (action == IDiamond.FacetCutAction.Remove) {
                removeFacet(ds, facet_address, facetCut.functionSelectors);
            }
        }
        if (_init != address(0)) {
            (bool success,) = _init.delegatecall(_calldata);
            require(success, "Diamodcut Initialization failed");
        }
    }

}