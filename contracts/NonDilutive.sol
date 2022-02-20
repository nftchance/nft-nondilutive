// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import { INonDilutive } from "./INonDilutive.sol";
import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { ERC721Enumerable } from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

import "hardhat/console.sol";

error MintExceedsMaxSupply();
error MintCostMismatch();
error MintNotEnabled();

error GenerationAlreadyLoaded();
error GenerationNotDifferent();
error GenerationNotEnabled();
error GenerationNotDowngradable();
error GenerationNotToggleable();
error GenerationCostMismatch();

error NonExistentToken();
error NotTheOwner();
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
contract NonDilutive is 
     INonDilutive
    ,ERC721Enumerable
    ,Ownable
{
    using Strings for uint256;

    uint256 public constant MAX_SUPPLY = 900;
    uint256 public constant COST = .02 ether;

    bool public mintOpen;

    mapping(uint256 => Generation) public generations;

    mapping(uint256 => uint256) tokenIdToGeneration;
    mapping(bytes32 => uint256) tokenIdGenerationToFunded;

    constructor(
         string memory _name
        ,string memory _symbol
        ,string memory _baseURI
        
    ) ERC721(_name, _symbol) { 
        loadGeneration(
             0              // layer
            ,true           // enabled   (can be focused by holders)
            ,true           // locked    (cannot be removed by project owner)
            ,true           // sticky    (cannot be removed by owner)
            ,0              // cost      (does not cost to convert to or back to)
            ,0              // closure   (can be swapped to forever)
            ,_baseURI
        );

        _mint(msg.sender, 0);
    }

    /**
     * @notice Function that controls which metadata the token is currently utilizing.
     *         By default every token is using layer zero which is loaded during the time
     *         of contract deployment. Cannot be removed, is immutable, holders can always
     *         revert back. However, if at any time they choose to "wrap" their token then
     *         it is automatically reflected here.
     * @param _tokenId the token we are getting the URI for
     * @return _tokenURI The internet accessible URI of the token 
     */
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
        if(!_exists(_tokenId)) revert NonExistentToken();

        _tokenURI = string(
            abi.encodePacked(
                 generations[tokenIdToGeneration[_tokenId]].baseURI
                ,_tokenId.toString()
            )
        );
    }

    /**
     * @dev This is the most extreme of the basic sale enables. When using this, you will
     *      start your sale through Flashbots so that bots cannot backrun you.
     */
    function toggleMint()
        public
        virtual
        onlyOwner
    { 
        mintOpen = !mintOpen;
    }

    /**
     * @notice The public minting function of this contract while making sure that
     *         supply is not exceeded and the proper $$ has been supplied.
     */
    function mint(uint256 _count) 
        public 
        virtual 
        payable 
    {
        if(!mintOpen) revert MintNotEnabled();

        uint256 totalSupply = totalSupply();

        if(totalSupply + _count >= MAX_SUPPLY) revert MintExceedsMaxSupply();
        if(msg.value != COST * _count) revert MintCostMismatch();

        unchecked {
            for(uint256 i; i < _count; i++) {
                _mint(msg.sender, totalSupply + i);
            }
        }
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
        // Make sure that we are not overwriting an existing layer.
        if(generations[_layerId].loaded) revert GenerationAlreadyLoaded();

        generations[_layerId] = Generation({
             loaded: true
            ,enabled: _enabled
            ,locked: _locked
            ,sticky: _sticky
            ,cost: _cost
            ,evolutionClosure: _evolutionClosure
            ,baseURI: _baseURI
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
    function getTokenGeneration(
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
        if(!_exists(_tokenId)) revert NonExistentToken();
        return tokenIdToGeneration[_tokenId];       
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
    function focusGeneration(
         uint256 _layerId
        ,uint256 _tokenId
    )
        override
        public
        virtual
        payable
    {
        // Make sure the owner of the token is operating
        if(ownerOf(_tokenId) != msg.sender) revert NotTheOwner();

        uint256 activeGenerationLayer = tokenIdToGeneration[_tokenId]; 
        if(activeGenerationLayer == _layerId) revert GenerationNotDifferent();
        
        // Make sure that the generation has been enabled
        Generation memory generation = generations[_layerId];
        if(!_generationEnabled(generation)) revert GenerationNotEnabled();

        // Make sure a user can't take off a sticky generation
        Generation memory activeGeneration = generations[activeGenerationLayer];
        if(activeGeneration.sticky && _layerId < activeGenerationLayer) revert GenerationNotDowngradable(); 

        // Make sure they've supplied the right amount of money to unlock access
        bytes32 tokenIdGeneration = keccak256(abi.encodePacked(_tokenId, _layerId));
        if(msg.value + tokenIdGenerationToFunded[tokenIdGeneration] != generation.cost) revert GenerationCostMismatch();
        tokenIdGenerationToFunded[tokenIdGeneration] = msg.value;

        // Finally evolve to the generation
        tokenIdToGeneration[_tokenId] = _layerId;

        emit GenerationChange(
             _layerId
            ,_tokenId
        );
    }

    /**
     * @notice Withdraws the money from this contract to Chance + the owner.
     */
    function withdraw() 
        public 
        payable 
        onlyOwner 
    {
        /**
         * @dev Pays Chance 5% -- Feel free to remove this or leave it. Up to you. You really 
         *      don't even need to credit me in your code. Realistically, you can yoink all of this 
         *      without me ever knowing or caring. That's why this is open source. But of course, 
         *      I have to keep on the lights somehow :)
         */ 
        (bool chance, ) = payable(0x62180042606624f02D8A130dA8A3171e9b33894d).call{value: address(this).balance * 5 / 100}("");
        if(!chance) revert WithdrawFailed();
        
        (bool owner, ) = payable(owner()).call{value: address(this).balance}("");
        if(!owner) revert WithdrawFailed();
    }

    /**
     * @notice on chain function to retrieve the tokens that an address owns
     * @param _owner the holder we are retrieving the tokens for
     * @return tokenIds this address currently holds
     */
    function walletOfOwner(address _owner) 
        public 
        view 
        returns (
            uint256[] memory
        ) 
    {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) return new uint256[](0);

        uint256[] memory tokenIds = new uint256[](tokenCount);
        for (uint256 i; i < tokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(
                 _owner
                ,i
            );
        }
        return tokenIds;
    }
}