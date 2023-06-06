// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

struct Chunk {
    bytes32 checksum;
    address pointer;
}

struct EIFF {
    uint248 size; // content length in bytes, max 24k
    bool isSetComplete;
    Chunk[] chunks;
}

function isComplete(EIFF memory file) view returns (bool) {
    if(file.isSetComplete) {
        return true;
    } else {
        Chunk[] memory chunks = file.chunks;

        uint256 totalSize = 0;

        assembly {
            let len := mload(chunks)
            let size
            let chunk
            let pointer

            // loop through all pointer addresses
            // - get address
            // - get data size
            // - update total size

            for { let i := 0 } lt(i, len) { i := add(i, 1) } {
                chunk := mload(add(chunks, add(0x20, mul(i, 0x20))))
                pointer := mload(add(chunk, 0x20))

                size := sub(extcodesize(pointer), 1)
                totalSize := add(totalSize, size)
            }
        }

        return (totalSize == file.size);
    }
}

function setComplete(EIFF storage file) {
    if(file.isSetComplete) {
        return;
    } else {
        file.isSetComplete = isComplete(file);
    }
}

function read(EIFF memory file) view returns (string memory contents) {
    Chunk[] memory chunks = file.chunks;

    // Adapted from https://gist.github.com/xtremetom/20411eb126aaf35f98c8a8ffa00123cd
    assembly {
        let len := mload(chunks)
        let totalSize := 0x20
        contents := mload(0x40)
        let size
        let chunk
        let pointer

        // loop through all pointer addresses
        // - get content
        // - get address
        // - get data size
        // - get code and add to contents
        // - update total size

        for { let i := 0 } lt(i, len) { i := add(i, 1) } {
            chunk := mload(add(chunks, add(0x20, mul(i, 0x20))))
            pointer := mload(add(chunk, 0x20))

            size := sub(extcodesize(pointer), 1)
            extcodecopy(pointer, add(contents, totalSize), 1, size)
            totalSize := add(totalSize, size)
        }

        // update contents size
        mstore(contents, sub(totalSize, 0x20))
        // store contents
        mstore(0x40, add(contents, and(add(totalSize, 0x1f), not(0x1f))))
    }
}

using {read} for EIFF global;
