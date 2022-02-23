// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import { IMimeticMetadata } from "./IMimeticMetadata.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

error MintExceedsMaxSupply();
error MintCostMismatch();
error MintNotEnabled();

error GenerationAlreadyLoaded();
error GenerationNotDifferent();
error GenerationNotEnabled();
error GenerationNotDowngradable();
error GenerationNotToggleable();
error GenerationCostMismatch();

error TokenNonExistent();
error TokenNotRevealed();
error TokenRevealed();
error TokenOwnerMismatch();

error WithdrawFailed();

/**
 * @title  Non-Dilutive 721
 * @author nftchance
 * @notice This token was created to serve as a proof for a conversational point. Non-dilutive 721 
 *         tokens can exist. Teams can easily build around this concept. Teams can additionally  
 *         still monetize the going ons and hard work of their team. However, that does not need to 
 *         come at the cost of their holders. As it stands every token drop following the 
 *         initial is a holder mining experience in which every single holders is impacted by the 
 *         lower market concentration of liquidty and attention.
 * @notice If you plan on yoinking this code. Please message me. Curiosity breeds progress. I am 
 *         here to help if you need or want it. I do not want a cut; I do not want paid. I want a 
 *         market of * honest and holder thoughtful devs. This is a very very weird 721 
 *         implementation and comes with many nuances. I'd love to discuss.
 * @notice Doodles drop of the Spaceships by wrapping into a new token is 100% dilutive.
 * @dev The extendable 'Generations' wrap the token metadata within the content to remove the need 
 *         of dropping another token into the collection. By doing this, that does not inherently
 *         mean the metadata is mutable beyond the extent that the token holder can change the
 *         active metadata. The underlying generations still much exist and can be configured in a 
 *         way that allows accessing them again if desired. However, there does also exist the 
 *         ability to have truly immutable layers that cannot be removed. (If following this
 *         implementation it is vitally noted that object permanence must be achieved from day one.
 *         A project CANNOT implement this on a mutable URL that is massive holder-trust betrayal.)
 */
contract MimeticMetadata is 
     IMimeticMetadata
    ,Ownable
{
    using Strings for uint256;

    uint256 public MAX_SUPPLY;

    string public baseUnrevealedURI;

    mapping(uint256 => Generation) public generations;

    mapping(uint256 => uint256) tokenToGeneration;
    mapping(bytes32 => uint256) tokenGenerationToFunded;

    /**
     * @notice Generates a psuedo-random number that is to be used for the 
     *         metadata offset. In production, this realistically should be an
     *         implementation with VRF (Chainlink). It is incredibly easy to setup
     *         and use, additionally with this structure there is no reason it needs 
     *         to be expensive.
     * @dev A focus of psuedo-random number quality has not been a focus. In order for
     *         for the modulus to even return a fair chance for all #s it must be a 
     *         power of 2.
     * @param _layerId the generation the offset is used for.
     */
    function _getOffset(
        uint256 _layerId
    ) 
        internal 
        view 
        returns (
            uint256
        ) 
    {
        return uint256(
            keccak256(
                abi.encodePacked(
                     msg.sender
                    ,_layerId
                    ,block.number
                    ,block.difficulty
                )
            )
        ) % MAX_SUPPLY + 1;
    }

    /**
     * @notice Allows for generation-level reveal. That means that just because the assets
     *         in Generation Zero have been revealed, Generation One is not revealed. The
     *         reveal mechanisms of them are entirely separate. Precisely like a normal
     *         ERC721 token.
     * @notice Cannot be reverted once a token has been revealed. No mutable metadata!
     * @dev With this implementation it is vital that you implement and utilize an offset.
     *         This is not something that you can skip because you don't want to work
     *         with Chainlink or another VRF method. Even if not VRF, you must implement
     *         at least a generally fair offset mechanism. Holders for the most part
     *         do not know how Solidity works. That does not mean you take advantage of that.
     * @param _layerId the generation that is being revealed
     * @param _topTokenId the highest token id to be revealed
     */
    function setRevealed(
         uint256 _layerId
        ,uint256 _topTokenId
    )
        override
        public
        virtual
        onlyOwner
    {
        Generation storage generation = generations[_layerId];

        // Make sure the generation has been loaded and enabled
        if(!generation.loaded || !generation.enabled) revert GenerationNotEnabled();

        // Make sure that the amount of tokens revealed is not being lowered
        if(_topTokenId < generation.top) revert TokenRevealed();

        // Make sure that we create the offset the first time a generation is revealed
        if(generation.offset == 0) {
            generation.offset = _getOffset(_layerId);
        } 

        // Finally set the top token of the generation
        generation.top = _topTokenId;
    }

    /**
     * @notice Allows users to calculate the metadata id that is associated with this token
     *         at all times on any of the layers. This is not code that validates the input
     *         as it operates like an internal function but has been exposed to holders
     *         for UX purposes.
     * @param _offset how far the ids have been shifted
     * @param _tokenId the token we are getting the generational data for
     */
    function getGenerationToken(
         uint256 _offset
        ,uint256 _tokenId
    ) 
        override
        public
        virtual
        view
        returns (
            uint256 generationTokenId
        )
    { 
        generationTokenId = _tokenId + _offset - 1;
        if (generationTokenId > MAX_SUPPLY) generationTokenId - MAX_SUPPLY - 1;
    }

    /**
     * @notice Function that controls which metadata the token is currently utilizing.
     *         By default every token is using layer zero which is loaded during the time
     *         of contract deployment. Cannot be removed, is immutable, holders can always
     *         revert back. However, if at any time they choose to "wrap" their token then
     *         it is automatically reflected here.
     * @notice Errors out if the token has not yet been revealed within this collection.
     * @param _tokenId the token we are getting the URI for
     * @return _tokenURI The internet accessible URI of the token 
     */
    function _tokenURI(
        uint256 _tokenId
    ) 
        internal
        virtual
        view 
        returns (
            string memory
        ) 
    {
        // Make sure that the token has been minted
        uint256 activeGenerationLayer = tokenToGeneration[_tokenId];

        // Make sure that the token has been revealed
        Generation memory activeGeneration = generations[activeGenerationLayer];

        /**
         * @dev Returns a non-token specific URI that is to be used for unrevealed tokens. This is
         *      not a case where every generation has it's own unrevealed URI. All generations 
         *      utilize the same one so that "evolution in progress" is consistent across the collection.
         */
        if(_tokenId > activeGeneration.top) return baseUnrevealedURI;

        // Make sure the baseTokenId is within the bounds of MAX_SUPPLY and fix if not
        // Apply the generational offset to the tokens metadata
        uint256 generationTokenId = getGenerationToken(
             activeGeneration.offset
            ,_tokenId
        );
        
        return string(
            abi.encodePacked(
                 activeGeneration.baseURI
                ,generationTokenId.toString()
            )
        );
    }

    /**
     * @notice Allows the project owner to establish a new generation. Generations are enabled by 
     *      default. With this we initialize the generation to be loaded.
     * @dev _name is passed as a param, if this is not needed; remove it. Don't be superfluous.
     * @dev only accessed by owner of contract
     * @param _layerId the z-depth of the metadata being loaded
     * @param _enabled a generation can be connected before a token can utilize it
     * @param _locked can this layer be disabled by the project owner
     * @param _sticky can this layer be removed by the holder
     * @param _cost the focus cost
     * @param _evolutionClosure if set to zero, disabled. If not set to zero is the last timestamp
     *                          at which someone can focus this generation.
     * @param _baseURI the internet URI the metadata is stored on
     */
    function loadGeneration(
         uint256 _layerId
        ,bool _enabled
        ,bool _locked
        ,bool _sticky
        ,uint256 _cost
        ,uint256 _evolutionClosure
        ,string memory _baseURI
    )
        override 
        public 
        virtual 
        onlyOwner 
    {
        Generation storage generation = generations[_layerId];

        // Make sure that we are not overwriting an existing layer.
        if(generation.loaded) revert GenerationAlreadyLoaded();

        generations[_layerId] = Generation({
             loaded: true
            ,enabled: _enabled
            ,locked: _locked
            ,sticky: _sticky
            ,cost: _cost
            ,evolutionClosure: _evolutionClosure
            ,baseURI: _baseURI
            ,offset: 0
            ,top: 0
        });
    }

    /**
     * @notice Used to toggle the state of a generation. Disable generations cannot be focused by 
     *         token holders.
     */
    function toggleGeneration(
        uint256 _layerId
    )
        override 
        public
        virtual
        onlyOwner 
    {
        Generation memory generation = generations[_layerId];

        // Make sure that the token isn't locked (immutable but overlapping keywords is spicy)
        if(generation.enabled && generation.locked) revert GenerationNotToggleable();

        generations[_layerId].enabled = !generation.enabled;
    }

    /**
     * @notice Allows any user to see the layer that a token currently has enabled.
     */
    function _getTokenGeneration(
        uint256 _tokenId
    )
        internal
        virtual
        view
        returns(
            uint256
        )
    {
        return tokenToGeneration[_tokenId];       
    }

    /**
     *  @notice Internal view function to clean up focusGeneration(). Pretty useless but the
     *          function was getting out of control.
     */
    function _generationEnabled(Generation memory generation) 
        internal 
        view 
        returns (
            bool
        ) 
    {
        if(!generation.enabled) return false;
        if(generation.evolutionClosure != 0) return block.timestamp < generation.evolutionClosure;
        return true;
    }

    /**
     * @notice Function that allows token holders to focus a generation and wear their skin.
     *         This is not in control of the project maintainers once the layer has been 
     *         initialized.
     * @dev This function is utilized when building supporting functions around the concept of 
     *         extendable metadata. For example, if Doodles were to drop their spaceships, it would 
     *         be loaded and then enabled by the holder through this function on a front-end.
     * @param _layerId the layer that this generation belongs on. The bottom is zero.
     * @param _tokenId the token that we are updating the metadata for
     */
    function _focusGeneration(
         uint256 _layerId
        ,uint256 _tokenId
    )
        internal
        virtual
    {
        uint256 activeGenerationLayer = tokenToGeneration[_tokenId]; 
        if(activeGenerationLayer == _layerId) revert GenerationNotDifferent();
        
        // Make sure that the generation has been enabled
        Generation memory generation = generations[_layerId];
        if(!_generationEnabled(generation)) revert GenerationNotEnabled();

        // Make sure a user can't take off a sticky generation
        Generation memory activeGeneration = generations[activeGenerationLayer];
        if(activeGeneration.sticky && _layerId < activeGenerationLayer) revert GenerationNotDowngradable(); 

        // Make sure they've supplied the right amount of money to unlock access
        bytes32 tokenIdGeneration = keccak256(abi.encodePacked(_tokenId, _layerId));
        if(msg.value + tokenGenerationToFunded[tokenIdGeneration] != generation.cost) revert GenerationCostMismatch();
        tokenGenerationToFunded[tokenIdGeneration] = msg.value;

        // Finally evolve to the generation
        tokenToGeneration[_tokenId] = _layerId;

        emit GenerationChange(
             _layerId
            ,_tokenId
        );
    }
}