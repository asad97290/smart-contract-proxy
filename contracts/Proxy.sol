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

contract Proxy {
    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     * obtained as bytes32(uint256(keccak256('eip1967.proxy.admin')) - 1)
     */
    bytes32 private constant IMPLEMENTATION_SLOT =
        0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
    /**
     * @dev Storage slot with the address of the current admin.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     * obtained as bytes32(uint256(keccak256('eip1967.proxy.admin')) - 1)
     */
    bytes32 private constant ADMIN_SLOT =
        0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    constructor() {
        StorageSlot.getStorageSlot(ADMIN_SLOT).value = msg.sender;
    }

    modifier onlyAdmin() {
        require(
            StorageSlot.getStorageSlot(ADMIN_SLOT).value == msg.sender,
            "only admin"
        );
        _;
    }
    event UpgradedImplementation(address indexed add);
    event UpgradedAdmin(address indexed add);
    
    modifier ifAdmin() {
        if (msg.sender == getAdmin()) {
            _;
        } else {
            _fallback();
        }
    }
    function changeImplementation(address _add) external onlyAdmin {
        require(_add.code.length > 0, "address is not a contract address");
        StorageSlot.getStorageSlot(IMPLEMENTATION_SLOT).value = _add;
        emit UpgradedImplementation(_add);
    }

    function changeAdmin(address _add) external onlyAdmin {
        require(_add != address(0));
        StorageSlot.getStorageSlot(ADMIN_SLOT).value = _add;
        emit UpgradedAdmin(_add);
    }

    function getImplementation() external view returns (address) {
        return StorageSlot.getStorageSlot(IMPLEMENTATION_SLOT).value;
    }

    function getAdmin() public view returns (address) {
        return StorageSlot.getStorageSlot(ADMIN_SLOT).value;
    }



    function _fallback() private {
        // forward all calls to implementation
        address implementation = StorageSlot
            .getStorageSlot(IMPLEMENTATION_SLOT)
            .value;
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(
                gas(),
                implementation,
                0,
                calldatasize(),
                0,
                0
            )

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

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback() external payable virtual {
        _fallback();
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
     * is empty.
     */
    receive() external payable virtual {
        _fallback();
    }
}

contract ProxyAdmin {
    address public admin;
    address payable proxy;

    constructor(address payable _proxy) {
        proxy = _proxy;
        admin = msg.sender;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin);
        _;
    }

    function changeImplementation(address _add) external onlyAdmin {
        Proxy(proxy).changeImplementation(_add);
    }

    function changeProxyAdmin(address _admi) external onlyAdmin {
        Proxy(proxy).changeAdmin(_admi);
    }

    function getImplementation() external view returns (address) {
        (bool ok, bytes memory res) = proxy.staticcall(
            abi.encodeCall(Proxy.getImplementation, ())
        );
        require(ok, "call failed");
        return abi.decode(res, (address));
    }

    function getAdmin() external view returns (address) {
        (bool ok, bytes memory res) = proxy.staticcall(
            abi.encodeCall(Proxy.getAdmin, ())
        );
        require(ok, "call failed");
        return abi.decode(res, (address));
    }

    function changeAdmin(address _addr) external {
        admin = _addr;
    }
}
