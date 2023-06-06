// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import {SSTORE2} from "solady/utils/SSTORE2.sol";
import {IEIFFStore} from "./IEIFFStore.sol";
import {Ownable2Step} from "openzeppelin-contracts/contracts/access/Ownable2Step.sol";
import {EIFF, Chunk} from "./EIFF.sol";
import {IChunkStore} from "./IChunkStore.sol";

contract EIFFStore is IEIFFStore, Ownable2Step {
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
        return abi.decode(SSTORE2.read(pointer), (File));
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

    function _createFile(
        string memory filename,
        bytes32[] memory checksums,
        bytes memory extraData
    ) private returns (EIFF memory file) {
        Content[] memory contents = new Content[](checksums.length);
        uint256 size = 0;
        // TODO: optimize this
        for (uint256 i = 0; i < checksums.length; ++i) {
            size += chunkStore.contentLength(checksums[i]);
            contents[i] = Content({
                checksum: checksums[i],
                pointer: chunkStore.getPointer(checksums[i])
            });
        }
        if (size == 0) {
            revert EmptyFile();
        }
        file = File({size: size, contents: contents});
        (bytes32 checksum,) = chunkStore.addContent(abi.encode(file));
        files[filename] = checksum;
        emit FileCreated(filename, checksum, filename, file.size, extraData);
    }

    function deleteFile(string memory filename) public onlyOwner {
        bytes32 checksum = files[filename];
        if (checksum == bytes32(0)) {
            revert FileNotFound(filename);
        }
        delete files[filename];
        emit FileDeleted(filename, checksum, filename);
    }
}
