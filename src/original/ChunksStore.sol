// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import {SSTORE2} from "solady/utils/SSTORE2.sol";
import {IChunkStore} from "./IChunkStore.sol";

contract ChunkStore is IChunkStore {
    // chunk checksum => sstore2 pointer
    mapping(bytes32 => address) public pointers;

    function chunkExists(bytes32 checksum) public view returns (bool) {
        return pointers[checksum] != address(0);
    }

    function chunkLength(bytes32 checksum)
        public
        view
        returns (uint256 size)
    {
        if (!chunkExists(checksum)) {
            revert ChunkNotFound(checksum);
        }
        return SSTORE2.read(pointers[checksum]).length;
    }

    function addPointer(address pointer) public returns (bytes32 checksum) {
        bytes memory chunk = SSTORE2.read(pointer);
        checksum = keccak256(chunk);
        if (pointers[checksum] != address(0)) {
            return checksum;
        }
        pointers[checksum] = pointer;
        emit NewChunk(checksum, chunk.length);
        return checksum;
    }

    function uploadChunk(bytes memory chunk)
        public
        returns (bytes32 checksum, address pointer)
    {
        checksum = keccak256(chunk);
        if (pointers[checksum] != address(0)) {
            return (checksum, pointers[checksum]);
        }
        pointer = SSTORE2.write(chunk);
        pointers[checksum] = pointer;
        emit NewChunk(checksum, chunk.length);
        return (checksum, pointer);
    }

    function getPointer(bytes32 checksum)
        public
        view
        returns (address pointer)
    {
        if (!chunkExists(checksum)) {
            revert ChunkNotFound(checksum);
        }
        return pointers[checksum];
    }
}
