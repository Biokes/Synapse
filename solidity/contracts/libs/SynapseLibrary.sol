// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;
import {IDiamond} from "../interfaces/IDiamond.sol";
import {IDiamondLoupe} from "../interfaces/IDiamondLoupe.sol";

library SynapseLibrary{

    bytes32 constant SYNAPSE_DIAMOND_STORAGE = keccak256("Synapse.diamond.storage");
    bytes32 constant APP_STORAGE_POSITION = keccak256("Synapse.app.storage");
    
    struct Event {
        address organizer;
        uint64 startTime;
        uint64 endTime;
        uint8 state;
        uint256 escrowBalance;
    }
    
    uint8 constant STATE_CREATED = 0;
    uint8 constant STATE_FUNDED = 1;
    uint8 constant STATE_ACTIVE = 2;
    uint8 constant STATE_SETTLING = 3;
    uint8 constant STATE_FINALIZED = 4;
    
    struct DiamondStorage {
        address _owner;
        mapping (bytes4 => address) _facets;
        mapping (address => bytes4[]) _facetFunctionSelectors;
        bytes4[] _selectors;
    }

    struct AppStorage {
        uint256 nextEventId;
        mapping(uint256 => Event) events;
        uint256 reentrancyGuard;
    }

     function getDiamondStorage() internal pure returns (DiamondStorage storage ds) {
        bytes32 position = SYNAPSE_DIAMOND_STORAGE;
        assembly {
            ds.slot := position
        }
    }
    
    function diamondStorage() internal pure returns (AppStorage storage ds) {
        bytes32 position = APP_STORAGE_POSITION;
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
            if (action == IDiamond.FacetCutAction.ADD) {
                addFacet(ds, facet_address, facetCut.functionSelectors);
            } else if (action == IDiamond.FacetCutAction.REPLACE) {
                replaceFacet(ds, facet_address, facetCut.functionSelectors);
            } else if (action == IDiamond.FacetCutAction.REMOVE) {
                removeFacet(ds, facet_address, facetCut.functionSelectors);
            }
        }
        if (_init != address(0)) {
            (bool success,) = _init.delegatecall(_calldata);
            require(success, "Diamodcut Initialization failed");
        }
    }

    function supportsInterface(bytes4 _interfaceId) internal view returns (bool) {
        DiamondStorage storage ds = getDiamondStorage();
        return ds._facets[_interfaceId] != address(0);
    }

    function getFacetAddress(bytes4 _functionSelector) internal view returns (address) {
        DiamondStorage storage ds = getDiamondStorage();
        return ds._facets[_functionSelector];
    }

    function getFacetsAddresses() internal view returns (address[] memory) {
        DiamondStorage storage ds = getDiamondStorage();
        address[] memory temp = new address[](ds._selectors.length);
        uint256 uniqueCount = 0;
        for (uint256 i = 0; i < ds._selectors.length; i++) {
            address facetAddr = ds._facets[ds._selectors[i]];
            bool alreadyAdded = false;
            for (uint256 j = 0; j < uniqueCount; j++) {
                if (temp[j] == facetAddr) {
                    alreadyAdded = true;
                    break;
                }
            }
            if (!alreadyAdded) {
                temp[uniqueCount] = facetAddr;
                uniqueCount++;
            }
        }

        address[] memory unique = new address[](uniqueCount);
        for (uint256 i = 0; i < uniqueCount; i++) {
            unique[i] = temp[i];
        }

        return unique;
    }

    function getFacetFunctionSelectors(address _facet) internal view returns (bytes4[] memory) {
        DiamondStorage storage ds = getDiamondStorage();
        return ds._facetFunctionSelectors[_facet];
    }

    function getFacets() internal view returns (IDiamondLoupe.Facet[] memory facets_) {
        facets_ = new IDiamondLoupe.Facet[](getFacetsAddresses().length);
        for (uint256 i = 0; i < facets_.length; i++) {
            address facetAddress_ = getFacetsAddresses()[i];
            facets_[i] = IDiamondLoupe.Facet({
                facetAddress: facetAddress_,
                functionSelectors: getFacetFunctionSelectors(facetAddress_)
            });
        }
    }
    function addFacet(DiamondStorage storage ds,address _facetAddress,bytes4[] memory _functionSelectors) internal {
        require(_facetAddress != address(0), "Facet address cannot be zero");
        for (uint256 i = 0; i < _functionSelectors.length; i++) {
            bytes4 selector = _functionSelectors[i];
            require(ds._facets[selector] == address(0), "Function already exists");
            ds._facets[selector] = _facetAddress;
            ds._selectors.push(selector);
        }
        ds._facetFunctionSelectors[_facetAddress] = _functionSelectors;
    }
    
    function removeFacet(DiamondStorage storage ds,address _facetAddress,bytes4[] memory _functionSelectors) internal {
        require(_facetAddress == address(0), "Remove facet address must be zero");
        for (uint256 i = 0; i < _functionSelectors.length; i++) {
            bytes4 selector = _functionSelectors[i];
            require(ds._facets[selector] != address(0), "Function does not exist");
            delete ds._facets[selector];
            for (uint256 j = 0; j < ds._selectors.length; j++) {
                if (ds._selectors[j] == selector) {
                    ds._selectors[j] = ds._selectors[ds._selectors.length - 1];
                    ds._selectors.pop();
                    break;
                }
            }
        }
        delete ds._facetFunctionSelectors[_facetAddress];
    }
    function replaceFacet(DiamondStorage storage ds,address _facetAddress,bytes4[] memory _functionSelectors) internal {
        require(_facetAddress != address(0), "Facet address cannot be zero");
        for (uint256 i = 0; i < _functionSelectors.length; i++) {
            bytes4 selector = _functionSelectors[i];
            require(ds._facets[selector] != address(0), "Function does not exist");
            ds._facets[selector] = _facetAddress;
        }
        ds._facetFunctionSelectors[_facetAddress] = _functionSelectors;
    }
}