// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "BankContract.sol";

contract BankFactory is Ownable {
    mapping (address => Bank) private listBankEntities; // bank contract addr to Bank entity
    mapping (address => address) private listBankAddress; // bank wallet addr to bank contract addr
    mapping (string => address) private listBank; // bankID to bankID wallet

    constructor() {
        transferOwnership(msg.sender);
    }

    event NewBank(
        address indexed _bankOwner,
        address indexed _bankContractI,
        string indexed _bankIDI,
        string _bankName,
        string _bankID,
        address _bankContract,
        uint time
    );

    function registerNewBank (
        string memory _bankName,
        address _bankOwner,
        string memory _bankID
    ) external onlyOwner returns (address) {
        require(listBank[_bankID] == address(0x0), "Error: there exists a bank with this bankID");
        Bank newBank = new Bank(
            _bankOwner,
            _bankName,
            _bankID
        );
        listBankAddress[_bankOwner] = address(newBank);
        listBank[_bankID] = _bankOwner;
        listBankEntities[address(newBank)] = newBank;
        emit NewBank(_bankOwner, listBankAddress[_bankOwner], _bankID, _bankName, _bankID, listBankAddress[_bankOwner], block.timestamp);
        return listBankAddress[_bankOwner];
    }

    function getBankContractByID(
        string memory _bankID
    ) external view returns (address) {
        return listBankAddress[listBank[_bankID]];
    }

    event DeactivateBank(
        address indexed _bankContractAddressI,
        address _bankContractAddress,
        uint time
    );

    event ActivateBank(
        address indexed _bankContractAddressI,
        address _bankContractAddress,
        uint time
    );

    function deactivateBankContract(
        string memory _bankID
    ) public onlyOwner {
        address bankContractAddress = listBank[_bankID];
        require(bankContractAddress != address(0x0), "Error: bank does not exist");
        Bank bankEntity = listBankEntities[bankContractAddress];
        bankEntity.deactivateBank();
        emit DeactivateBank(
            bankContractAddress,
            bankContractAddress,
            block.timestamp
        );
    }

    function activateBankContract(
        string memory _bankID
    ) public onlyOwner {
        address bankContractAddress = listBank[_bankID];
        require(bankContractAddress != address(0x0), "Error: bank does not exist");
        Bank bankEntity = listBankEntities[bankContractAddress];
        bankEntity.activateBank();
        emit ActivateBank(
            bankContractAddress,
            bankContractAddress,
            block.timestamp
        );
    }
}