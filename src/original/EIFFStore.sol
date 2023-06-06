// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import {SSTORE2} from "lib/solady/src/utils/SSTORE2.sol";
import {IEIFFStore} from "./IEIFFStore.sol";
import {EIFF, Chunk} from "./EIFF.sol";
import {IChunkStore} from "./IChunkStore.sol";

contract EIFFStore is IEIFFStore {
    IChunkStore public immutable chunkStore;

    // filename => File checksum
    mapping(string => bytes32) public files;

    constructor(IChunkStore _chunkStore) {
        chunkStore = _chunkStore;
    }

    function fileExists(string memory filename) public view returns (bool) {
        return files[filename] != bytes32(0);
    }

    function getChecksum(string memory filename)
        public
        view
        returns (bytes32 checksum)
    {
        checksum = files[filename];
        if (checksum == bytes32(0)) {
            revert FileNotFound(filename);
        }
        return checksum;
    }

    function getFile(string memory filename)
        public
        view
        returns (EIFF memory file)
    {
        bytes32 checksum = files[filename];
        if (checksum == bytes32(0)) {
            revert FileNotFound(filename);
        }
        address pointer = chunkStore.pointers(checksum);
        if (pointer == address(0)) {
            revert FileNotFound(filename);
        }
        return abi.decode(SSTORE2.read(pointer), (EIFF));
    }

    function createFile(string memory filename, bytes32[] memory checksums)
        public
        returns (EIFF memory file)
    {
        return createFile(filename, checksums, new bytes(0));
    }

    function createFile(
        string memory filename,
        bytes32[] memory checksums,
        bytes memory extraData
    ) public returns (EIFF memory file) {
        if (files[filename] != bytes32(0)) {
            revert FilenameExists(filename);
        }
        return _createFile(filename, checksums, extraData);
    }

    // creating a file allows the user to define the checksums of the expected chunks
    function _createFile(
        string memory filename,
        bytes32[] memory checksums,
        bytes memory extraData
    ) private returns (EIFF memory file) {
        //create blank chunks array in storage
        Chunk[] memory chunks = new Chunk[](checksums.length);
        // bound by the max size of chunk
        unchecked {
            for (uint256 i = 0; i < checksums.length; ++i) {
                // initialize the chunk with the information about the pointer's checksum
                chunks[i] = Chunk({
                    checksum: checksums[i],
                    pointer: address(0)
                });
            }
        }
        file = EIFF({size: 0, isSetComplete: false, chunks: chunks});
        bytes32 checksum = keccak256(abi.encode(chunks)); // a file can be identified by the hash of the concatenation of its chunks checksums
        files[filename] = checksum;
        emit EIFFCreated(filename, checksum, filename, extraData);
    }

    /*function deleteFile(string memory filename) public onlyOwner {
        bytes32 checksum = files[filename];
        if (checksum == bytes32(0)) {
            revert FileNotFound(filename);
        }
        delete files[filename];
        emit EIFFDeleted(filename, checksum, filename);
    }
    */
}
