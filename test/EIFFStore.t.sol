// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "src/EIFFStore.sol";

contract EIFFStoreTest is Test {
    EIFFStore public store;

    address admin = address(0xad1);
    address alice = address(0xa1ce);

    function setUp() public {
        vm.warp(1686132000);
        vm.prank(admin);
        store = new EIFFStore();
    }

    function testMintNFT() public {

        vm.startPrank(alice);

        bytes[] memory dummyData = new bytes[](2);

        dummyData[0] = new bytes(24_000);
        dummyData[0][69] = 0x01;

        dummyData[1] = new bytes(24_000);
        dummyData[1][420] = 0x42;

        bytes32[] memory dummyChecksum = new bytes32[](2);
        dummyChecksum[0] = keccak256(dummyData[0]);
        dummyChecksum[1] = keccak256(dummyData[1]);

        string memory filename = "dummy";

        store.createFile(filename, dummyChecksum);

        store.uploadChunk(filename, 0, dummyData[0]);
        store.uploadChunk(filename, 1, dummyData[1]);

        emit log_string(store.tokenURI(0));

        vm.stopPrank();
    }

}
