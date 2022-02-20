// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

interface INonDilutiveGeneration { 
    struct Generation {
        bool enabled;
        bool locked;
        bool sticky;
        string baseURI;
        string name;
    }

    event GenerationChange(uint256 _layerId, uint256 _tokenId);

    function loadGeneration(
         uint256 _layerId
        ,bool _locked
        ,bool _sticky
        ,string memory _baseURI
    ) external;

    function toggleGeneration(
        uint256 _layerId
    ) external;

    function focusGeneration(
         uint256 _layerId
        ,uint256 _tokenId
    ) external;

    function fetchGeneration(
        uint256 _tokenId
    ) external returns (
        uint256
    );
}