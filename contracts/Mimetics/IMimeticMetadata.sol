// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

interface IMimeticMetadata { 
    struct Generation {
        bool loaded;
        bool enabled;
        bool locked;
        bool sticky;
        uint256 cost;
        uint256 evolutionClosure;
        string baseURI;
        uint256 offset;
        uint256 top;
    }

    event GenerationChange(
         uint256 _layerId
        ,uint256 _tokenId
    );

    function setRevealed(
         uint256 _layerId
        ,uint256 _tokenId
    ) 
        external;

    function getGenerationToken(
         uint256 _offset
        ,uint256 _tokenId
    ) 
        external 
        view 
        returns (
            uint256 generationTokenId
        );

    function loadGeneration(
         uint256 _layerId
        ,bool _enabled
        ,bool _locked
        ,bool _sticky
        ,uint256 _cost
        ,uint256 _evolutionClosure
        ,string memory _baseURI
    ) 
        external;

    function toggleGeneration(
        uint256 _layerId
    ) 
        external;
}