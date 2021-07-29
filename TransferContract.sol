//SPDX-License-Identifier: UNLICENSED

pragma solidity >= 0.5.0;


contract Transfers  {
    
    
    // Private state variable and set the owner
    address private admin;
    
    modifier onlyOwner() {
        require(admin == payable(msg.sender), "Ownable: caller is not the owner");
        _;
    }
    function owner() public view returns(address) {
        return admin;
    }
  
     // Defining a constructor which sets owner
     constructor() public{   
        admin = payable(msg.sender);
    }
    
    //different global varibles 
    event Received(address, uint);
    
    struct Addresses {
        uint id;
        address person;
    } 
    
    
    uint nextId = 1;
    Addresses[] addressBook;
    
    //fallback and receive functions so the contract can receive ether 
    fallback() external payable {
        require(msg.data.length == 0);
        
    }
    
    receive() external payable {
        emit Received(msg.sender, msg.value);
    }
  
    
    //function to change ownership 
    function changeOwner(address _newOwner) onlyOwner() external {
        admin = _newOwner; 
    }
  
    //functions that allow user to create an address book for transactions
    function setAddress(address _person)  onlyOwner() public {
        addressBook.push(Addresses(nextId, _person));
        nextId++; 
    }
    
    function read(uint _id) public view returns(uint, address)  {
        for(uint i = 0; i < addressBook.length; i++) {
            if(addressBook[i].id == _id) {
                return(addressBook[i].id, addressBook[i].person);   
            }
        }
        
    }
    
    //functions to send ether and return balances of owner and other contracts
    function sendEther(address payable _to) external payable returns(bool) {
        require(admin.balance >= 1 ether);
        if(admin.balance <= 1 ether) {
            revert("Not enough Ether");
        }
        (bool success, bytes memory transactionBytes) = _to.call{value:msg.value}('');
        
        require(success, "Transfer failed.");
        
        return(true);
    }
    
    function getBalance() public view returns(uint){
        return admin.balance;
    }
    
    function balanceContracts(address _other) public view returns(uint) {
        return _other.balance;
    }
    
    function kill() public onlyOwner {
    selfdestruct(payable(admin));
    }
    
    
    function constructor1() public {
        require(admin == address(0), "Already initalized");
        admin = msg.sender;
    }
    
}


contract Proxy {
    // Code position in storage is keccak256("PROXIABLE") = "0xc5f16f0fcc639fa48a6947836d9850f504798523bf8c9a3a87d5876cf622bcf7"
    constructor(bytes memory constructData, address contractLogic) {
        // save the code address
        assembly { // solium-disable-line
            sstore(0xc5f16f0fcc639fa48a6947836d9850f504798523bf8c9a3a87d5876cf622bcf7, contractLogic)
        }
        (bool success, bytes memory result ) = contractLogic.delegatecall(constructData); // solium-disable-line
        require(success, "Construction failed");
    }

    fallback() external payable {
        assembly { // solium-disable-line
            let contractLogic := sload(0xc5f16f0fcc639fa48a6947836d9850f504798523bf8c9a3a87d5876cf622bcf7)
            calldatacopy(0x0, 0x0, calldatasize())
            let success := delegatecall(sub(gas(), 10000), contractLogic, 0x0, calldatasize(), 0, 0)
            let retSz := returndatasize()
            returndatacopy(0, 0, retSz)
            switch success
            case 0 {
                revert(0, retSz)
            }
            default {
                return(0, retSz)
            }
        }
    }
}

contract Proxiable {
    // Code position in storage is keccak256("PROXIABLE") = "0xc5f16f0fcc639fa48a6947836d9850f504798523bf8c9a3a87d5876cf622bcf7"

    function updateCodeAddress(address newAddress) internal {
        require(
            bytes32(0xc5f16f0fcc639fa48a6947836d9850f504798523bf8c9a3a87d5876cf622bcf7) == Proxiable(newAddress).proxiableUUID(),
            "Not compatible"
        );
        assembly { // solium-disable-line
            sstore(0xc5f16f0fcc639fa48a6947836d9850f504798523bf8c9a3a87d5876cf622bcf7, newAddress)
        }
    }

    function proxiableUUID() public pure returns (bytes32) {
        return 0xc5f16f0fcc639fa48a6947836d9850f504798523bf8c9a3a87d5876cf622bcf7;
    }
} 



contract MyFinalContract is Transfers, Proxiable {

    function updateCode(address newCode) onlyOwner public {
        updateCodeAddress(newCode);
    }

    
}