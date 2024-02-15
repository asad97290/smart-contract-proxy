// SPDX-License-Identifier: MIT
// https://eips.ethereum.org/EIPS/eip-1967
pragma solidity ^0.8.20;

library StorageSlot {
    struct AddressSlot {
        address value;
    }

    function getStorageSlot(
        bytes32 _slot
    ) external pure returns (AddressSlot storage r) {
        assembly {
            r.slot := _slot
        }
    }
}

contract Proxy {
    event Upgraded(address indexed implementation);

    function changeImplementation(address _add) external {
        StorageSlot.getStorageSlot(keccak256("impl")).value = _add;
        emit Upgraded(_add);
    }

    function getImplementation() external view returns (address) {
        return StorageSlot.getStorageSlot(keccak256("impl")).value;
    }

    fallback() external {
        (bool s, ) = StorageSlot
            .getStorageSlot(keccak256("impl"))
            .value
            .delegatecall(msg.data);
        require(s);
    }
}

contract Logic1 {
    uint x;

    function changeX(uint _x) external {
        x = _x;
    }
}

contract Logic2 {
    uint x;

    function changeX(uint _x) external {
        x += 2 * _x;
    }
     function triple(uint _x) external {
        x += 3 * _x;
    }
}
