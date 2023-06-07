// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.19;

import {Base64, LibString, DateTimeLib} from "lib/solady/src/Milady.sol";

library EIFFRenderer {

    string constant HEADER = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style>.title{fill:#ece6ff;font-family:monospace;font-size:16px;font-weight:600}.data{fill:#ece6ff;font-family:monospace;font-size:12px}</style><rect width="100%" height="100%" fill="#9999ff" rx="20" stroke="#000066" stroke-width="1"/><rect x="5%" y="5%" width="90%" height="90%" fill="#000066" rx="20"/>';

    struct NFT_INFO {
        uint256 tokenId;
        address owner;
        address authorizedContract;
        uint64 expiration;
    }

    function renderRaw(NFT_INFO memory info) internal pure returns (string memory) {
        
        (uint256 year, uint256 month, uint256 day) = DateTimeLib.timestampToDate(info.expiration);
        
        return string.concat(
            HEADER,
            '<text x="30" y="50" class="title">EIFF READER: ', LibString.toString(info.tokenId), '</text>',
            '<text x="30" y="95" class="title">Authorized Contract: </text>',
            '<text x="30" y="110" class="data">', LibString.toHexStringChecksumed(info.authorizedContract), '</text>',
            '<text x="30" y="135" class="title">Owner: </text>',
            '<text x="30" y="150" class="data">', LibString.toHexStringChecksumed(info.owner), '</text>',
            '<text x="30" y="175" class="title">Expiration: </text>',
            '<text x="30" y="190" class="data">', LibString.toString(year), month < 10 ? '-0' : '-', LibString.toString(month), day < 10 ? '-0' : '-', LibString.toString(day), '</text>',
            '</svg>'
        );
    }

    function renderEncoded(NFT_INFO memory info) internal pure returns (string memory) {

        string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "READER #', LibString.toString(info.tokenId), '", "description": "EIFF Reader allows the holder to set a (contract) address which can read from the EIFF library, the expiration can be extended by contributing to EIFF", "image": "data:image/svg+xml;base64,', Base64.encode(bytes(renderRaw(info))), '"}'))));
        
        return string(abi.encodePacked('data:application/json;base64,', json));
    }




}