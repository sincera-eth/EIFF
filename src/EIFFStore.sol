// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import {SSTORE2} from "lib/solady/src/utils/SSTORE2.sol";
import {EIFF, Chunk} from "./EIFF.sol";

contract EIFFStore {
    // file checksums => EIFF object
    mapping(bytes32 => EIFF) private files;

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
        return files[fileId].chunks.length != 0;
    }

    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    //*                                                             Create File                                                         *//
    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

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
        if (files[filenames[filename]].chunks.length != 0) {
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
        if(checksums.length == 0) {
            revert EmptyFile();
        }
        
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

        bytes32 checksum = keccak256(abi.encode(chunks)); // a file can be identified by the hash of the concatenation of its chunks checksums
        file = EIFF({size: 0, isSetComplete: false, chunks: chunks});
        files[checksum] = file;
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
            for (chunkIndex = 0; chunkIndex < files[fileId].chunks.length; ++chunkIndex) {
                if (files[fileId].chunks[chunkIndex].checksum == checksum) {
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
        if (files[fileId].chunks[chunkIndex].checksum != checksum) {
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
            for (chunkIndex = 0; chunkIndex < files[fileId].chunks.length; ++chunkIndex) {
                if (files[fileId].chunks[chunkIndex].checksum == checksum) {
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
        if (files[fileId].chunks[chunkIndex].checksum != checksum) {
            revert ChunkNotInEIFF(checksum);
        }
        
        return _uploadChunk(fileId, chunkIndex, chunk);
    }



    function _uploadChunk(bytes32 fileId, uint256 chunkIndex, bytes memory chunk)
        internal
        returns (address pointer)
    {
        EIFF storage file = files[fileId];
        
        // check if the chunk is already uploaded
        if (SSTORE2.read(file.chunks[chunkIndex].pointer).length != 0) {
            revert ChunkExists(keccak256(chunk));
        }

        pointer = SSTORE2.write(chunk);
        file.chunks[chunkIndex].pointer = pointer;
        file.size += uint248(chunk.length);
        emit ChunkUploaded(fileId, pointer, chunk.length);
        return pointer;
    }

    function readFile(string memory filename) public view returns (string memory) {
        if (!fileExists(filename)) {
            revert FileNotFound(filename);
        }
        return files[filenames[filename]].read();
    }


}

