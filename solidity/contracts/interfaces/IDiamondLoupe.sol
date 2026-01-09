// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

interface IDiamondLoupe{

    struct Facet{
        address facetAddress;
        bytes4[] functionSelectors;
    }

    function getFacets() external view returns (Facet[] memory facets_);
    function getFacetFunctionSelectors(address _facet) external view returns (bytes4[] memory facetFunctionSelectors);
    function getFacetAddresses() external view returns (address[] memory facetAddresses);
    function getFacetAddress(bytes4 _functionSelector) external view returns (address facetAddress);
    function supportsInterface(bytes4 _interfaceId) external view returns (bool isSupported);

}