// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.19;

import "lib/solmate/src/auth/Owned.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "./EIFFRenderer.sol";

contract EIFFReader is ERC721Enumerable, Owned(msg.sender) {

    struct READER_SETTING {
        uint64 expiration;
        address authorizedContract;
    }

    mapping(uint256 => READER_SETTING) public readerSettings;
    uint64 public creditLength = 30 days;

    constructor() ERC721("EIFFReader", unicode"📖") {}

    modifier onlyWhileAuthorized(uint256 tokenId) {
        require(msg.sender == readerSettings[tokenId].authorizedContract, "EIFFReader: caller is not authorized contract");
        require(block.timestamp <= readerSettings[tokenId].expiration, "EIFFReader: credit expired");
        _;
    }


    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        EIFFRenderer.NFT_INFO memory nftInfo = EIFFRenderer.NFT_INFO({
            tokenId: tokenId,
            owner: ownerOf(tokenId),
            authorizedContract: readerSettings[tokenId].authorizedContract,
            expiration: readerSettings[tokenId].expiration
        });
        
        return EIFFRenderer.renderEncoded(nftInfo);
    }

    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    //*                                                             Owner Functions                                                     *//
    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    function setAuthorizedContract(uint256 tokenId, address newAuthorizedContract) public {
        require(msg.sender == ownerOf(tokenId), "EIFFReader: caller is not the owner or holder");
        readerSettings[tokenId].authorizedContract = newAuthorizedContract;
    }

    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    //*                                                        Contract Owner Functions                                                 *//
    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    function changeCreditLength(uint64 newCreditLength) public onlyOwner {
        creditLength = newCreditLength;
    }

    function setExpiration(uint256 tokenId, uint64 newExpiration) public onlyOwner {
        readerSettings[tokenId].expiration = newExpiration;
    }
}