// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import { MimeticMetadata } from "./Mimetics/MimeticMetadata.sol";
import { INonDilutive } from "./INonDilutive.sol";

import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { ERC721Enumerable } from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
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
contract NonDilutive is 
     ERC721Enumerable
    ,MimeticMetadata
    ,INonDilutive
{
    using Strings for uint256;

    uint256 public constant COST = .02 ether;

    bool public mintOpen;

    constructor(
         string memory _name
        ,string memory _symbol
        ,string memory _baseUnrevealedURI
        ,string memory _baseURI
        ,uint256 _MAX_SUPPLY
    ) ERC721(_name, _symbol) {
        MAX_SUPPLY = _MAX_SUPPLY;

        baseUnrevealedURI = _baseUnrevealedURI;

        loadGeneration(
             0              // layer
            ,true           // enabled   (can be focused by holders)
            ,true           // locked    (cannot be removed by project owner)
            ,true           // sticky    (cannot be removed by owner)
            ,0              // cost      (does not cost to convert to or back to)
            ,0              // closure   (can be swapped to forever)
            ,_baseURI
        );

        _mint(msg.sender, 0); // Mints the creator their token. Equitable ownership.
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
    function tokenURI(
        uint256 _tokenId
    ) 
        override 
        public 
        view 
        returns (
            string memory
        ) 
    {
        // Make sure that the token has been minted
        if(!_exists(_tokenId)) revert TokenNonExistent();
        return _tokenURI(_tokenId);
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
        if(!_exists(_tokenId)) revert TokenNonExistent();
        return _getTokenGeneration(_tokenId);
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
        if(ownerOf(_tokenId) != msg.sender) revert TokenOwnerMismatch();

        _focusGeneration(_layerId, _tokenId);
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
        (bool chance, ) = payable(
            0x62180042606624f02D8A130dA8A3171e9b33894d
        ).call{
            value: address(this).balance * 5 / 100
        }("");
        if(!chance) revert WithdrawFailed();
        
        (bool owner, ) = payable(
            owner()
        ).call{
            value: address(this).balance
        }("");
        if(!owner) revert WithdrawFailed();
    }
}