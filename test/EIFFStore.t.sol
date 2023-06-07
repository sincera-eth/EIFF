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

        bytes memory dummyData = new bytes(24_000);
        dummyData[69] = 0x01;
        bytes32[] memory dummyChecksum = new bytes32[](1);
        dummyChecksum[0] = keccak256(dummyData);

        string memory filename = "dummy";

        store.createFile(filename, dummyChecksum);

        store.uploadChunk(filename, dummyData);

        emit log_string(store.tokenURI(0));

        vm.stopPrank();
    }

}
