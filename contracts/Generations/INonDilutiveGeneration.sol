// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

interface INonDilutiveGeneration { 
    struct Generation {
        bool loaded;
        bool enabled;
        bool locked;
        bool sticky;
        string baseURI;
        uint256 cost;
        uint256 evolutionClosure;
    }

    event GenerationChange(uint256 _layerId, uint256 _tokenId);

    function loadGeneration(
         uint256 _layerId
        ,bool _enabled
        ,bool _locked
        ,bool _sticky
        ,string memory _baseURI
        ,uint256 cost
        ,uint256 _evolutionClosure
    ) external;

    function toggleGeneration(
        uint256 _layerId
    ) external;

    function focusGeneration(
         uint256 _layerId
        ,uint256 _tokenId
    ) external payable;

    function getTokenGeneration(
        uint256 _tokenId
    ) external returns (
        uint256
    );
}