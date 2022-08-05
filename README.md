# Online savings smart contracts

This repository stores files to implement smart contracts used for broadcasting events of transactions on online savings accounts. 

This is a part of the _Graduation Thesis: Blockchain for verifying online savings account transactions_ of Chau, Nguyen Thi Minh, supervised by Asso. Prof. Linh, Truong Dieu of semester 2022.2 at Hanoi University of Science and Technology.

- BankFactory.sol: Used to implement the Bank Factory contract for creating other Bank Contracts. It can only be called by its owner who created this contract
- BankContract.sol: Used to implement the Bank Contracts. Bank Contract is implemented as a multisig wallet so that functions to broadcast online savings account transactions can only be executed when there are enough valid signatures. Its write functions can only be called by owners of the contract, including customers registered to the contract, the Bank Contract owner and Bank Factory contract.
- Ownable: Helper to declare additional access modifier for Bank Factory and Bank Contract
- Context: Helper to examine sender and data of the request received.

This work is under MIT license.