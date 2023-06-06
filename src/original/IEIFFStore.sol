// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import {EIFF} from "./EIFF.sol";
import {IChunkStore} from "./IChunkStore.sol";

interface IEIFFStore {
    event EIFFCreated(
        string indexed indexedFilename,
        bytes32 indexed checksum,
        string filename,
        bytes metadata
    );
    event EIFFFinalized(
        string indexed indexedFilename,
        bytes32 indexed checksum,
        string filename,
        uint256 size,
        bytes metadata
    );
    event EIFFDeleted(
        string indexed indexedFilename,
        bytes32 indexed checksum,
        string filename
    );

    error FileNotFound(string filename);
    error FilenameExists(string filename);
    error EmptyFile();

    function chunkStore() external view returns (IChunkStore);

    function files(string memory filename)
        external
        view
        returns (bytes32 checksum);

    function fileExists(string memory filename) external view returns (bool);

    function getChecksum(string memory filename)
        external
        view
        returns (bytes32 checksum);

    function getFile(string memory filename)
        external
        view
        returns (EIFF memory file);

    function createFile(string memory filename, bytes32[] memory checksums)
        external
        returns (EIFF memory file);

    function createFile(
        string memory filename,
        bytes32[] memory checksums,
        bytes memory extraData
    ) external returns (EIFF memory file);
}
