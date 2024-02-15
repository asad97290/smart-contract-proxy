// SPDX-License-Identifier: MIT
// https://eips.ethereum.org/EIPS/eip-1967
pragma solidity ^0.8.20;

library StorageSlot {
    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     * obtained as bytes32(uint256(keccak256('eip1967.proxy.admin')) - 1)
     */
    bytes32 public constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

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
        StorageSlot.getStorageSlot(StorageSlot._IMPLEMENTATION_SLOT).value = _add;
        emit Upgraded(_add);
    }

    function getImplementation() external view returns (address) {
        return StorageSlot.getStorageSlot(StorageSlot._IMPLEMENTATION_SLOT).value;
    }

    fallback() external {
        // forward all calls to implementation
      
        // (bool s, ) = StorageSlot
        //     .getStorageSlot(StorageSlot._IMPLEMENTATION_SLOT)
        //     .value
        //     .delegatecall(msg.data);
        // require(s);
        address implementation = StorageSlot
            .getStorageSlot(StorageSlot._IMPLEMENTATION_SLOT)
            .value;
            assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }
}

contract Logic1 {
    uint public x;

    function changeX(uint _x) external {
        x = _x;
    }
}

contract Logic2 {
    uint public x;

    function changeX(uint _x) external {
        x += 2 * _x;
    }
     function triple(uint _x) external {
        x += 3 * _x;
    }
}
