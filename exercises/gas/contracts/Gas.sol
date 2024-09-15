// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract GasContract {

    uint8 private constant BASIC_PAYMENT = 1; 
    uint256 private immutable totalSupply; // cannot be updated
    address private immutable contractOwner;
    
    bool private wasLastOdd;
    uint256 private paymentCounter;
    address[5] public administrators;
    mapping(address => uint256) public balances;
    mapping(address => uint256) public whitelist;
    mapping(address => Payment[]) private payments;
    mapping(address => bool) private isOddWhitelistUser;
    mapping(address => ImportantStruct) private whiteListStruct;

    struct Payment {
        uint8 paymentType;
        uint256 paymentID;
        string recipientName; // max 8 characters
        address recipient;
        uint256 amount;
    }
    
    struct ImportantStruct {
        uint256 amount;
        bool paymentStatus;
        address sender;
    }

    modifier onlyAdminOrOwner() {
        if (!((msg.sender == contractOwner) || (checkForAdmin(msg.sender)))) {
            revert NotAdminOrOwner();
        }
        _;
    }

    modifier checkIfWhiteListed(address sender) {
        if (msg.sender != sender) {
            revert OriginatorNotSender();
        }
        if (whitelist[msg.sender] == 0) {
            revert NotWhitelisted();
        }
        if (whitelist[msg.sender] > 3) {
            revert IncorrectTier();
        }
        _;
    }

    event AddedToWhitelist(address userAddress, uint256 tier);
    event WhiteListTransfer(address indexed);

    error InsufficientBalance();
    error NameTooLong();
    error NotAdminOrOwner();
    error OriginatorNotSender();
    error NotWhitelisted();
    error IncorrectTier();
    error Help();
    error LowAmount();

    constructor(address[] memory _admins, uint256 _totalSupply) {
        contractOwner = msg.sender;

        //for (uint256 ii = 0; ii < administrators.length; ii++) {
        //    if (_admins[ii] != address(0)) {
        //        administrators[ii] = _admins[ii];
        //        if (_admins[ii] == msg.sender) {
        //            balances[msg.sender] = _totalSupply;
        //        }
        //    }
        //}
        totalSupply = _totalSupply;
        assembly {
            let t_totalSupply := _totalSupply
            let len := mload(_admins)           
            for {let i := 0} lt(i, len) {i := add(i, 1) } {
                let val := mload(add(_admins, mul(add(i, 1), 0x20)))
                sstore(add(administrators.slot, i), val)
                if eq(val, caller()) {
                  mstore(0x00, caller())
                  mstore(0x20, 0x07)
                  sstore(keccak256(0x00, 0x40), t_totalSupply)
                }
            }
        }
    }

    function checkForAdmin(address _user) public view returns (bool) {
        //for (uint256 ii = 0; ii < administrators.length; ii++) {
        //    if (administrators[ii] == _user) {
        //        admin_ = true;
        //        return admin_;
        //    }
        //}
        
        uint256 len = administrators.length;
        assembly {
        // Keep temporary variable so it can be incremented in place.
        //
        // NOTE: incrementing data would result in an unusable
        //       data variable after this assembly block
        let dataElementLocation := administrators.slot
        // Iterate until the bound is not met.
        for
            { let end := add(dataElementLocation, mul(len, 1)) }
            lt(dataElementLocation, end)
            { dataElementLocation := add(dataElementLocation, 1) }
            {
                let admin_ := eq(_user, sload(dataElementLocation))
                if gt(admin_, 0) {
                        mstore(0, admin_)
                        return(0, 0x20)
                }
            }
        }
    }

    function balanceOf(address _user) public view returns (uint256 amount_) {
        assembly {
            mstore(0x00, _user)
            mstore(0x20, 0x07)
            amount_ := sload(keccak256(0x00, 0x40))
        }
        //return balances[_user];
    }

    function transfer(
        address _recipient,
        uint256 _amount,
        string calldata _name
    ) public returns (bool) {
        if (balances[msg.sender] < _amount) {
            revert InsufficientBalance();
        }
        if (bytes(_name).length > 8) {
            revert NameTooLong();
        }
        unchecked {
            balances[msg.sender] -= _amount;    
        }
        balances[_recipient] += _amount;
        
        Payment memory payment;
        payment.paymentType = BASIC_PAYMENT;
        payment.recipient = _recipient;
        payment.amount = _amount;
        payment.recipientName = _name;
        unchecked {
            payment.paymentID = ++paymentCounter;    
        }
        payments[msg.sender].push(payment);
        return true;
    }

    function addToWhitelist(address _userAddrs, uint256 _tier)
        public
        onlyAdminOrOwner
    {
        if (_tier > 254) {
            revert IncorrectTier();
        }
        assembly {
            switch _tier
            case 1 {
                mstore(0x00, _userAddrs)
                mstore(0x20, 0x08)
                sstore(keccak256(0x00, 0x40), _tier)
            }
            case 2 {
                mstore(0x00, _userAddrs)
                mstore(0x20, 0x08)
                sstore(keccak256(0x00, 0x40), _tier)
            }   
            default {
                mstore(0x00, _userAddrs)
                mstore(0x20, 0x08)
                sstore(keccak256(0x00, 0x40), 3)                
            }   
        }
        emit AddedToWhitelist(_userAddrs, _tier);
    }

    function whiteTransfer(
        address _recipient,
        uint256 _amount
    ) public checkIfWhiteListed(msg.sender) {
        whiteListStruct[msg.sender] = ImportantStruct(_amount, true, msg.sender);
        if (balances[msg.sender] < _amount) {
            revert InsufficientBalance();
        }
        if (_amount < 3) {
            revert LowAmount();
        }
        balances[_recipient] += _amount;
        unchecked {
            balances[msg.sender] -= _amount;
            balances[msg.sender] += whitelist[msg.sender];  
            balances[_recipient] -= whitelist[msg.sender];  
        }
        
        emit WhiteListTransfer(_recipient);
    }

    function getPaymentStatus(address sender) public view returns (bool val1, uint256 val2) {
        assembly {
            mstore(0x00, sender)
            mstore(0x20, 0x0b)
            let structSlot := keccak256(0x00, 0x40)
            val2 := sload(structSlot)
            val1 := sload(add(structSlot, 1))
        }
        //return (whiteListStruct[sender].paymentStatus, whiteListStruct[sender].amount);
    }

}