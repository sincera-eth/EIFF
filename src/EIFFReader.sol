// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.19;

import "lib/solmate/src/tokens/ERC721.sol";

contract EIFFReader is ERC721 {

    

    mapping(uint256 => uint64) public expirations;

    constructor() ERC721("EIFF Reader", unicode"📖") {}

    function mint(address to, uint256 tokenId) public {
        _mint(to, tokenId);
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        return "sxs";
    }
}