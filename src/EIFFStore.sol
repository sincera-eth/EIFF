// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import {SSTORE2} from "lib/solady/src/utils/SSTORE2.sol";
import {EIFFReader} from "./EIFFReader.sol";
import {EIFF, Chunk} from "./EIFF.sol";

contract EIFFStore is EIFFReader {
    // file checksums => EIFF object
    mapping(bytes32 => EIFF) private _files;

    mapping(string => bytes32) public filenames;

    event EIFFCreated(
        string indexed indexedFilename,
        bytes32 indexed checksum,
        bytes metadata
    );

    event EIFFFinalized(
        string indexed indexedFilename,
        bytes32 indexed checksum,
        uint256 size,
        bytes metadata
    );

    event ChunkUploaded(bytes32 fileId, address pointer, uint256 contentSize);

    error ChunkExists(bytes32 checksum);
    error ChunkNotInEIFF(bytes32 checksum);

    error FileNotFound(string filename);
    error FileIdNotFound(bytes32 fileId);
    error FilenameExists(string filename);
    error EmptyFile();
 
    constructor() {}

    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    //*                                                             File Info                                                           *//
    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    function fileExists(string memory filename) public view returns (bool) {
        return filenames[filename] != bytes32(0);
    }

    function fileExists(bytes32 fileId) public view returns (bool) {
        return _files[fileId].chunks.length != 0;
    }

    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    //*                                                             Create File                                                         *//
    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    function createFile(string memory filename, bytes32[] memory checksums)
        public
        returns (bytes32 checksum)
    {
        return createFile(filename, checksums, new bytes(0));
    }

    function createFile(
        string memory filename,
        bytes32[] memory checksums,
        bytes memory extraData
    ) public returns (bytes32 checksum) {
        if (_files[filenames[filename]].chunks.length != 0) {
            revert FilenameExists(filename);
        }
        return _createFile(filename, checksums, extraData);
    }

    // creating a file allows the user to define the checksums of the expected chunks
    function _createFile(
        string memory filename,
        bytes32[] memory checksums,
        bytes memory extraData
    ) private returns (bytes32 checksum) {
        if(checksums.length == 0) {
            revert EmptyFile();
        }

        checksum = keccak256(abi.encode(checksums)); // a file can be identified by the hash of the concatenation of its chunks checksums

        EIFF storage $file = _files[checksum];
        $file.size = 0;
        $file.isSetComplete = false;

        // bound by the max size of chunk
        unchecked {
            for (uint256 i = 0; i < checksums.length; ++i) {
                // initialize the chunk with the information about the pointer's checksum
                $file.chunks.push(Chunk({
                    checksum: checksums[i],
                    pointer: address(0)
                }));
            }
        }

        filenames[filename] = checksum;
        emit EIFFCreated(filename, checksum, extraData);
    }

    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    //*                                                             Upload chunks                                                       *//
    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    // upload a chunk of data to the chunk store
    function uploadChunk(string memory filename, bytes memory chunk)
        public
        returns (address pointer)
    {
        if (!fileExists(filename)) {
            revert FileNotFound(filename);
        }
        
        bytes32 fileId = filenames[filename];

        bytes32 checksum = keccak256(chunk);

        // check if the chunk is found in the file's expected chunks
        uint256 chunkIndex;
        bool found;
        unchecked {
            for (chunkIndex = 0; chunkIndex < _files[fileId].chunks.length; ++chunkIndex) {
                if (_files[fileId].chunks[chunkIndex].checksum == checksum) {
                    found = true;
                    break;
                }
            }

            if (!found) {
                revert ChunkNotInEIFF(checksum);
            }
        }
        
        return _uploadChunk(fileId, chunkIndex, chunk);
    }

    function uploadChunk(string memory filename, uint256 chunkIndex, bytes memory chunk)
        public
        returns (address pointer)
    {
        if (!fileExists(filename)) {
            revert FileNotFound(filename);
        }
        
        bytes32 fileId = filenames[filename];

        bytes32 checksum = keccak256(chunk);

        // check if the chunk matches the index for the file's expected chunks
        if (_files[fileId].chunks[chunkIndex].checksum != checksum) {
            revert ChunkNotInEIFF(checksum);
        }
        
        return _uploadChunk(fileId, chunkIndex, chunk);
    }

    function uploadChunk(bytes32 fileId, bytes memory chunk)
        public
        returns (address pointer)
    {
        if (!fileExists(fileId)) {
            revert FileIdNotFound(fileId);
        }

        bytes32 checksum = keccak256(chunk);

        // check if the chunk is found in the file's expected chunks
        uint256 chunkIndex;
        bool found;
        unchecked {
            for (chunkIndex = 0; chunkIndex < _files[fileId].chunks.length; ++chunkIndex) {
                if (_files[fileId].chunks[chunkIndex].checksum == checksum) {
                    found = true;
                    break;
                }
            }

            if (!found) {
                revert ChunkNotInEIFF(checksum);
            }
        }
        
        return _uploadChunk(fileId, chunkIndex, chunk);
    }

    function uploadChunk(bytes32 fileId, uint256 chunkIndex, bytes memory chunk)
        public
        returns (address pointer)
    {
        if (!fileExists(fileId)) {
            revert FileIdNotFound(fileId);
        }

        bytes32 checksum = keccak256(chunk);

        // check if the chunk matches the index for the file's expected chunks
        if (_files[fileId].chunks[chunkIndex].checksum != checksum) {
            revert ChunkNotInEIFF(checksum);
        }
        
        return _uploadChunk(fileId, chunkIndex, chunk);
    }

    // give the holder credit for the upload, mint if needed
    function _creditHolder(address holder) internal {
        if(balanceOf(holder) == 0) {
            _mint(holder, totalSupply());
        } 
        uint256 holderId = tokenOfOwnerByIndex(holder, 0);
        readerSettings[holderId].expiration = readerSettings[holderId].expiration < uint64(block.timestamp) ? uint64(block.timestamp) + creditLength : ++creditLength;
    }

    function _uploadChunk(bytes32 fileId, uint256 chunkIndex, bytes memory chunk)
        internal
        returns (address pointer)
    {
        EIFF storage file = _files[fileId];
        
        // check if the chunk is already uploaded
        if (file.chunks[chunkIndex].pointer != address(0)) {
            revert ChunkExists(keccak256(chunk));
        }

        pointer = SSTORE2.write(chunk);
        file.chunks[chunkIndex].pointer = pointer;
        file.size += uint248(chunk.length);

        // check that the chunk is at least 23kbs unless it is the last one before crediting the expiration
        if (chunk.length > 23_000 || chunkIndex == file.chunks.length - 1) {
            _creditHolder(msg.sender);
        }

        emit ChunkUploaded(fileId, pointer, chunk.length);
        return pointer;
    }

    function readFile(
        string memory filename, 
        uint256 tokenId
    ) public view onlyWhileAuthorized(tokenId) returns (string memory) {
        if (!fileExists(filename)) {
            revert FileNotFound(filename);
        }
        return _files[filenames[filename]].read();
    }



}

