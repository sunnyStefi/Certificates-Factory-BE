// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {Course} from "../src/Course.sol";
import {CourseV2} from "../src/CourseV2.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";

contract Deployment is Script {
    address addressAdmin;
    uint256 privateKeyAdmin;

    function run() external returns (address) {
        if (block.chainid == 11155111) {
            addressAdmin = vm.envAddress("ADDRESS_ALICE");
            privateKeyAdmin = vm.envUint("PRIVATE_KEY_ALICE");
        }
        if (block.chainid == 31337) {
            addressAdmin = vm.envAddress("ADDRESS_ALICE_ANVIL");
            privateKeyAdmin = vm.envUint("PRIVATE_KEY_ALICE_ANVIL");
        }
        vm.startBroadcast(privateKeyAdmin);
        Course coursesFactory = new Course();
        bytes memory initializerData = abi.encodeWithSelector(Course.initialize.selector, addressAdmin, addressAdmin);
        ERC1967Proxy proxy = new ERC1967Proxy(address(coursesFactory), initializerData);
        vm.stopBroadcast();
        return (address(proxy));
    }
}

contract Upgrade is Script {
    address addressAdmin;
    uint256 privateKeyAdmin;

    /**
     * 1. Deploy CourseV2
     * 2. From Course call upgradeToAndCall (initializerV2!)
     */
    function run() external returns (address) {
        if (block.chainid == 11155111) {
            addressAdmin = vm.envAddress("ADDRESS_ALICE");
            privateKeyAdmin = vm.envUint("PRIVATE_KEY_ALICE");
        }
        if (block.chainid == 31337) {
            addressAdmin = vm.envAddress("ADDRESS_ALICE_ANVIL");
            privateKeyAdmin = vm.envUint("PRIVATE_KEY_ALICE_ANVIL");
        }
        vm.startBroadcast(privateKeyAdmin);
        address mostRecentDeployedProxy = DevOpsTools.get_most_recent_deployment("ERC1967Proxy", block.chainid);
        CourseV2 newCourse = new CourseV2();
        Course implementation1 = Course(payable(mostRecentDeployedProxy));
        bytes memory initializerDataV2 = abi.encodeWithSelector(CourseV2.initializeV2.selector, addressAdmin, addressAdmin); 
        implementation1.upgradeToAndCall(address(newCourse), initializerDataV2);

        vm.stopBroadcast();
        return mostRecentDeployedProxy;
    }
}
