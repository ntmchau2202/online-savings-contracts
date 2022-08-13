// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "Ownable.sol";

contract Bank is Ownable {
    struct User {
        address userAddress;
        string userID;
        bool activate;
    }

    mapping (address => User) private listUser;
    User[] users;
    string private bankName;
    string private bankID;
    address private factory;
    bool private activate;

    constructor(
        address _bankOwner,
        string memory _bankName,
        string memory _bankID
    ) {
        transferOwnership(_bankOwner);
        bankName = _bankName;
        bankID = _bankID;
        activate = true;
        factory = msg.sender;
    }

    function activateBank() external {
        require(msg.sender == factory, "Error: function must be called by factory");
        activate = false;
    }

    function deactivateBank() external {
        require(msg.sender == factory, "Error: function must be called by factory");
        activate = true;
    }

    function isActivated() public view returns (bool) {
        return activate;
    }

    function getBankName() external view returns (string memory) {
        return bankName;
    }

    function getBankID() external view returns (string memory) {
        return bankID;
    }

    event NewUser(
        address _userAddress,
        uint time
    );

    function getFactory() external view returns (address) {
        return factory;
    }

    function addUser (
        address _userAddress,
        string memory _userID
    ) external onlyOwner {
        User memory newUser = User(_userAddress, _userID, true);
        users.push(newUser);
        listUser[_userAddress] = newUser;
        emit NewUser(_userAddress, block.timestamp);
    }

    function findUser(
        string memory userID 
    ) public view returns (address) {
        for(uint256 i = 0; i < users.length; i++) {
            if (keccak256(bytes(users[i].userID)) == keccak256(bytes(userID))) {
                return users[i].userAddress;
            }
        }
        return address(0x0);
    }

    function isMember(
        address _userAddress
    ) public view returns (bool) {
        User memory usr = listUser[_userAddress];
        if (usr.userAddress == address(0)) {
            return false;
        } else {
            return true;
        }
    }

    function isCustomerActive(
        string memory userID
    ) public view returns (bool) {
        address customerAddress = findUser(userID);
        require(customerAddress != address(0x0), "Customer have not enrolled in the contract");
        return listUser[customerAddress].activate;
    }

    function verifyUser(
        bytes32 hash, 
        bytes[2] memory signature
    ) public view returns (bool, address) {
        bytes32 r;
        bytes32 s;
        uint8 v;
        address customerAddress = address(0x0);
        address bankAddress = address(0x0);
        for (uint256 i = 0; i < signature.length; i++) {
            bytes memory currentSignature = signature[i];
            assembly {
                r := mload(add(currentSignature, 0x20))
                s := mload(add(currentSignature, 0x40))
                v := byte(0, mload(add(currentSignature, 0x60)))
            }

            // Version of signature should be 27 or 28, but 0 and 1 are also possible versions
            if (v < 27) {
                v += 27;
            }

            // If the version is correct return the signer address
            if (v != 27 && v != 28) {
                return (false, customerAddress);
            } else {
                address recovered = ecrecover(hash, v, r, s);
                User memory usr = listUser[recovered];
                if (!isMember(usr.userAddress) && recovered != this.owner()) {
                    return (false, customerAddress);
                }

                if (isMember(usr.userAddress)) {
                    customerAddress = usr.userAddress;
                } else {
                    bankAddress = recovered;
                }
            }
        }
        require(customerAddress != bankAddress && customerAddress != address(0x0) && bankAddress != address(0x0),
                "Error: missing signature");
        return (true, customerAddress);
    }

    event OpenSavingsAccountTransaction(
        address indexed _customerAddressI,
        address _customerAddress,
        bytes _firstSignature,
        bytes _secondSignature,
        string _receiptHashBank,
        string _receiptHashCustomer
    );

    event SettleSavingsAccountTransaction(
        address indexed _customerAddressI,
        address _customerAddress,
        bytes _firstSignature,
        bytes _secondSignature,
        string _receiptHashBank,
        string _receiptHashCustomer
    );
    
    event DeactivateCustomer(
        address indexed _customerAddressI,
        address _customerAddress,
        uint time
    );

    event ActivateCustomer(
        address indexed _customerAddressI,
        address _customerAddress,
        uint time
    );

    function activateCustomer(
        string memory _customerID
    ) public onlyOwner {
        address customerAddress = findUser(_customerID);
        require(customerAddress != address(0x0), "Error: customer does not enrolled in the contract");
        listUser[customerAddress].activate = true;
        emit ActivateCustomer(
            customerAddress,
            customerAddress,
            block.timestamp
        );
    }

    function deactivateCustomer(
        string memory _customerID
    ) public onlyOwner {
        address customerAddress = findUser(_customerID);
        require(customerAddress != address(0x0), "Error: customer does not enrolled in the contract");
        listUser[customerAddress].activate = false;
        emit DeactivateCustomer(
            customerAddress,
            customerAddress,
            block.timestamp
        );
    }

    function BroadcastOpenAccountTransaction(
        // address _customerAddress,
        bytes32 _hash,
        bytes[2] memory _signatures,
        string memory _receiptHashBank,
        string memory _receiptHashCustomer
    ) public {
        require(this.isActivated(), "Error: contract has been deactivated");
        bool valid = false;
        address customerAddress = address(0x0);
        (valid, customerAddress) = verifyUser(_hash, _signatures);
        require(customerAddress != address(0x0), "Error: customer does not enrolled in the contract");
        require(listUser[customerAddress].activate, "Error: customer is deactivated");
        require(msg.sender == customerAddress, "Error: requester and savings account owner mismatch");
        require(valid, "Error: invalid signatures");
        emit OpenSavingsAccountTransaction(
            customerAddress,
            customerAddress,
            _signatures[0],
            _signatures[1],
            _receiptHashBank,
            _receiptHashCustomer
        );
    }

    function BroadcastSettleAccountTransaction(
        // address _customerAddress,
        bytes32 _hash,
        bytes[2] memory _signatures,
        string memory _receiptHashBank,
        string memory _receiptHashCustomer
    ) public {
        require(this.isActivated(), "Error: contract has been deactivated");
        bool valid = false;
        address customerAddress = address(0x0);
        (valid, customerAddress) = verifyUser(_hash, _signatures);
        require(customerAddress != address(0x0), "Error: customer does not enrolled in the contract");
        require(listUser[customerAddress].activate, "Error: customer is deactivated");
        require(msg.sender == customerAddress, "Error: requester and savings account owner mismatch");
        require(valid, "Error: invalid signatures");
        emit SettleSavingsAccountTransaction(
            customerAddress,
            customerAddress,
            _signatures[0],
            _signatures[1],
            _receiptHashBank,
            _receiptHashCustomer
        );
    }
}
