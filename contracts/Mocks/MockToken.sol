// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract MockToken is ERC721 {
    uint256 internal supply;

    constructor(
          string memory _name
        , string memory _symbol
    ) ERC721(_name, _symbol) {

    }

    function tokenURI(uint256 _tokenId) 
        override 
        public 
        view 
        returns (
            string memory
        )
    {
        return "";
    }

    function mint(uint256 _quantity)
        public
        virtual
    {
        for(
            uint256 i;
            i < _quantity;
            i++
        ) {
            _mint(msg.sender, supply + i);
            supply++;
        }
    }
}