// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

interface IChunkStore {
    event NewChunk(bytes32 indexed checksum, uint256 contentSize);

    error ChunkExists(bytes32 checksum);
    error ChunkNotFound(bytes32 checksum);

    function pointers(bytes32 checksum)
        external
        view
        returns (address pointer);

    function chunkExists(bytes32 checksum) external view returns (bool);

    function chunkLength(bytes32 checksum)
        external
        view
        returns (uint256 size);

    function addPointer(address pointer) external returns (bytes32 checksum);

    function uploadChunk(bytes memory chunk)
        external
        returns (bytes32 checksum, address pointer);

    function getPointer(bytes32 checksum)
        external
        view
        returns (address pointer);
}
