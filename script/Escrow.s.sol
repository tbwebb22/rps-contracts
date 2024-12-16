// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {Escrow} from "../src/Escrow.sol";

contract EscrowScript is Script {
    Escrow public escrow;

    address public owner = vm.envAddress("OWNER_ADDRESS");
    address public moxie = vm.envAddress("MOXIE_ADDRESS");

    function setUp() public {}

    function run() public {
        vm.startBroadcast(vm.envUint("DEPLOYER_PRIVATE_KEY"));

        escrow = new Escrow(owner, moxie);

        vm.stopBroadcast();
    }
}
