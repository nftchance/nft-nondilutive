// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

interface INonDilutive { 
    struct Generation {
        bool loaded;
        bool enabled;
        bool locked;
        bool sticky;
        uint256 cost;
        uint256 evolutionClosure;
        string baseURI;
    }

    event GenerationChange(uint256 _layerId, uint256 _tokenId);

    function loadGeneration(
         uint256 _layerId
        ,bool _enabled
        ,bool _locked
        ,bool _sticky
        ,uint256 cost
        ,uint256 _evolutionClosure
        ,string memory _baseURI
    ) external;

    function toggleGeneration(
        uint256 _layerId
    ) external;

    function getTokenGeneration(
        uint256 _tokenId
    ) external returns (
        uint256
    );

    function focusGeneration(
         uint256 _layerId
        ,uint256 _tokenId
    ) external payable;
}