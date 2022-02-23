// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

interface INonDilutive {
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