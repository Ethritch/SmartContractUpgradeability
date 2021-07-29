pragma solidity >= 0.5.0;



//This Contract contains all the mappings for storage of any needed variable declaration 
contract EternalStorage{

    mapping(bytes32 => uint) UIntStorage;

    function getUIntValue(bytes32 record) public view returns (uint){
        return UIntStorage[record];
    }

    function setUIntValue(bytes32 record, uint value) public
    {
        UIntStorage[record] = value;
    }

    mapping(bytes32 => string) StringStorage;

    function getStringValue(bytes32 record) public view returns (string memory){
        return StringStorage[record];
    }

    function setStringValue(bytes32 record, string calldata value) public
    {
        StringStorage[record] = value;
    }

    mapping(bytes32 => address) AddressStorage;

    function getAddressValue(bytes32 record) public view returns (address){
        return AddressStorage[record];
    }

    function setAddressValue(bytes32 record, address value) public
    {
        AddressStorage[record] = value;
    }

    mapping(bytes32 => bytes) BytesStorage;

    function getBytesValue(bytes32 record) public view returns (bytes memory){
        return BytesStorage[record];
    }

    function setBytesValue(bytes32 record, bytes calldata value) public
    {
        BytesStorage[record] = value;
    }

    mapping(bytes32 => bool) BooleanStorage;

    function getBooleanValue(bytes32 record) public view returns (bool){
        return BooleanStorage[record];
    }

    function setBooleanValue(bytes32 record, bool value) public
    {
        BooleanStorage[record] = value;
    }
    
    mapping(bytes32 => int) IntStorage;

    function getIntValue(bytes32 record) public view returns (int){
        return IntStorage[record];
    }

    function setIntValue(bytes32 record, int value) public
    {
        IntStorage[record] = value;
    }
    
}


library reservationLib {
    //The first two functions are meant for the unupgraded smart contract and are hence not well put together
    
    function setDateBad(address _eternalStorage, uint _count, string memory _reservationDate) public {
        EternalStorage(_eternalStorage).setStringValue(keccak256(abi.encodePacked(_count)), _reservationDate);
    }
    
    function getDateBad(address _eternalStorage, uint _count) view public returns(string memory) {
        return EternalStorage(_eternalStorage).getStringValue(keccak256(abi.encodePacked(_count)));
    }
    
    //These functions are used/added to the library so that an upgrade can be implemented using these functions to call to the EternalStorage contract
    function getDate(address _eternalStorage, address _reserver) view public returns(string memory) {
        return EternalStorage(_eternalStorage).getStringValue(keccak256(abi.encodePacked(_reserver)));
    }
    
    function getPerson(address _eternalStorage, string memory _date) view public returns(address) {
        return EternalStorage(_eternalStorage).getAddressValue(keccak256(abi.encodePacked(_date)));
    }
    
    function setDate(address _eternalStorage, address _reserver, string memory _reservationDate) public {
        EternalStorage(_eternalStorage).setStringValue(keccak256(abi.encodePacked(_reserver)), _reservationDate);
    }
    
    function setPerson(address _eternalStorage,string memory _reservationDate, address _reserver) public {
        EternalStorage(_eternalStorage).setAddressValue(keccak256(abi.encodePacked(_reservationDate)), _reserver);
    }
    
    
     function isReserved(address _eternalStorage, string memory _reservationDate) public view returns(bool) {
        return EternalStorage(_eternalStorage).getBooleanValue(keccak256(abi.encodePacked(_reservationDate, msg.sender)));
    }

    function setDateReserved(address _eternalStorage, string memory _date) public {
        EternalStorage(_eternalStorage).setBooleanValue(keccak256(abi.encodePacked(_date, msg.sender)), true);
    }
}

//This contract is the first one that has lots of problems
contract Reservations {
    
    //note that we are using the reservationLib library and that the contract should be deployed using the EternalStorage contract address
    using reservationLib for address;
    address eternalStorage;
    

    constructor(address _eternalStorage) {
        eternalStorage = _eternalStorage;
    }
    
    //This is for a basic retrival of data that is stored using this contract. It is finite and not perfect at all
    uint count = 0;

    function reserve(string memory _reservation) public {
        eternalStorage.setDateBad(count, _reservation);
        count++;
    }
    
    function verify(uint _count) view public returns (string memory) {
        return eternalStorage.getDateBad(_count);
    }
    
    //contract kill sequence incase of upgrade 
    address payable public owner = payable(msg.sender);

    modifier onlyOwner {
    require(msg.sender == owner);
     _;
    }   

    function kill() public onlyOwner {
    selfdestruct(owner);
    }
}

//This is the upgrade contract
contract UpgradedReservation {
    
    //same specs using the EternalStorage contract address for deployment
    using reservationLib for address;
    address eternalStorage;
    

    constructor(address _eternalStorage) {
        eternalStorage = _eternalStorage;
    }
    
    //retrives data stored from past contract
    function array() public {
        for (uint count = 0; count < 10; count++) {
            dates.push(eternalStorage.getDateBad(count));
        }
    }
    
    //stores dates so that we can verify that they are reserved
    string[] dates;
    
    //functions to reserve dates and verify who reserved them and which dates are reserved by certain people
    function reserve(address _reserve, string memory _reservation) public {
        uint i;
        for ( i = 0; i < dates.length; i++) {
          if (keccak256(abi.encodePacked(dates[i])) == keccak256(abi.encodePacked(_reservation)))  {
              eternalStorage.setDateReserved(_reservation);
              revert("This date has been reserved already");
          }
        }
        require(eternalStorage.isReserved(_reservation) == false);
        eternalStorage.setDate(_reserve, _reservation);
        eternalStorage.setPerson(_reservation, _reserve);
        dates.push(_reservation);
        
    }
    
    function verifyDate(address _reserve) view public returns (string memory) {
        return eternalStorage.getDate(_reserve);
    }
    function verifyPerson(string memory _date) view public returns (address) {
        return eternalStorage.getPerson(_date);
    }
    
}