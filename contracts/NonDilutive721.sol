// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import { INonDilutiveGeneration } from "./Generations/INonDilutiveGeneration.sol";
import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

error NotTheOwner();

error GenerationAlreadyLoaded();
error GenerationNotDifferent();
error GenerationNotEnabled();
error GenerationNotDowngradable();
error GenerationNotToggleable();

/**
 * @title Non-Dilutive 721
 * @author nftchance
 * @notice This token was created to serve as a proof for a conversational point. Non-dilutive 721 tokens can
 *     exist. Teams can easily build around this concept. Teams can additionally still monetize the going ons
 *     and hard work of their team. However, that does not need to come at the cost of their holders.
 *     As it stands every token drop following the initial is a holder mining experience in which every single
 *     holders is impacted by the lower market concentration of liquidty and attention.
 * @notice Doodles drop of the Spaceships by wrapping into a new token is 100% dilutive.
 * @notice If you plan on yoinking this code. Please message me. Curiosity breeds progress. I am here to help if 
 *        you need or want it. I do not want a cut; I do not want paid. I want a market of honest and 
 *        holder thoughtful devs. This is a very very weird 721 implementation and comes with many nuances. I'd
 *        love to discuss.
 * @dev The extendable 'Generations' wrap the token metadata within the content to remove the need of dropping
 *     another token into the collection. By doing this, that does not inherently mean the metadata is mutable
 *     beyond the extent that the token holder can change the active metadata. The underlying generations still
 *     much exist and can be configured in a way that allows accessing them again if desired. However, there does
 *     also exist the ability to have truly immutable layers that cannot be removed. (If following this implementation
 *     it is vitally noted that object permanence must be achieved from day one. A project CANNOT implement this on a 
 *     mutable URL that is massive holder-trust betrayal.)
 */
contract NonDilutive721 is 
     INonDilutiveGeneration 
    ,ERC721
    ,Ownable
{
    using Strings for uint256;

    uint256 public totalSupply;

    Generation[] public generations;

    mapping(uint256 => uint256) tokenIdToGeneration;

    constructor(
         string memory _name
        ,string memory _symbol
    ) ERC721(_name, _symbol) { }

    function tokenURI(
        uint256 _tokenId
    ) 
        override 
        public 
        view 
        returns (
            string memory _tokenURI
        ) 
    {
        require(_exists(_tokenId), "This token does not exist.");

        _tokenURI = string(
            abi.encodePacked(
                 tokenIdToGeneration[_tokenId]
                ,_tokenId.toString()
            )
        );
    }

    function mint() 
        public 
        virtual 
        payable 
    {
        _mint(msg.sender, totalSupply++);
    }

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

    /**
     * @notice Allows any user to see the layer that a token currently has enabled.
     */
    function fetchGeneration(
        uint256 _tokenId
    )
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
     * @notice Function that allows token holders to focus a generation and wear their skin.
     *     This is not in control of the project maintainers once the layer has been initialized.
     * @dev This function is utilized when building supporting functions around the concept of extendable
     *     metadata. For example, if Doodles were to drop their spaceships, it would be loaded and then
     *     enabled by the holder through this function on a front-end.
     * @param _layerId the layer that this generation belongs on. The bottom is zero.
     * @param _tokenId the token that we are updating the metadata for
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

        emit GenerationChange(
             _layerId
            ,_tokenId
        );
    }
}