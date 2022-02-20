// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import { INonDillutiveGeneration } from "./INonDillutiveGeneration.sol";

import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

error NotTheOwner();

error GenerationAlreadyLoaded();
error GenerationNotDifferent();
error GenerationNotEnabled();
error GenerationNotDowngradable();
error GenerationNotToggleable();


contract NonDillutiveGeneration is 
     INonDillutiveGeneration 
    ,ERC721
    ,Ownable 
{
    Generation[] public generations;

    mapping(uint256 => uint256) tokenIdToGeneration;

    /**
     * @dev Allows the project owner to establish a new generation. Generations are enabled by 
     *     default. With this we initialize the generation to be loaded.
     */
    function loadGeneration(
         uint256 _layerId
        ,bool _locked
        ,bool _sticky
        ,string memory _baseURI
    ) 
        override 
        public 
        virtual 
        onlyOwner 
    {
        if(generations[_layerId].enabled) revert GenerationAlreadyLoaded();

        /**
         * @dev Generations are enabled by default to avoid handling weird edge cases where
         *     a layer was to be removed. Please reference the documentation on how to implement
         *     "removable" / situational metadata.
         */
        generations[_layerId] = Generation(
             true
            ,_locked
            ,_sticky
            ,_baseURI
            ,""
        );
    }

    function toggleGeneration(
        uint256 _layerId
    )
        override 
        public 
        virtual 
        onlyOwner 
    {
        Generation memory generation = generations[_layerId];

        // If generation is not locked

        if(generation.enabled == true && generation.locked) revert GenerationNotToggleable();

        generation.enabled == !generation.enabled;
    }

    function fetchGeneration(uint256 _tokenId)
        override
        public
        virtual
        view
        returns(
            uint256
        )
    {
        return tokenIdToGeneration[_tokenId];       
    }

    /**
     * @dev Function that allows token holders 
     */
    function focusGeneration(
         uint256 _layerId
        ,uint256 _tokenId
    )
        override
        public
        virtual
    {
        // TODO: Need to owner limit
        if(ownerOf(_tokenId) != msg.sender) revert NotTheOwner();

        uint256 activeGenerationLayer = tokenIdToGeneration[_tokenId]; 

        if(activeGenerationLayer != _layerId) revert GenerationNotDifferent();
        
        // Make sure that the generation has been enabled
        Generation memory generation = generations[_layerId];

        if(generation.enabled == false) revert GenerationNotEnabled();

        // Make sure a user can't take off a sticky generation

        Generation memory activeGeneration = generations[activeGenerationLayer];

        if(activeGeneration.sticky && _layerId < activeGenerationLayer) revert GenerationNotDowngradable(); 
        
        // Finally evolve to the next generation

        tokenIdToGeneration[_tokenId] = _layerId;
    }
}