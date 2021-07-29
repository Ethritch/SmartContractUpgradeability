pragma solidity >= 0.5.0;

import "./TransferContract.sol";

contract Upgrade is Transfers, Proxiable, MyFinalContract {
    
    function transferToOwner(address _to) external payable returns(bool) {
        require(_to == owner());
        (bool success, bytes memory transactionBytes) = _to.call{value:msg.value}('');
        
        require(success, "Transfer failed.");
        
        return(true);
    }
    
}