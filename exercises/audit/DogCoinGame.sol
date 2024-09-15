// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
//@audit Fix the version
//import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract DogCoinGame is ERC20 {
    uint256 public currentPrize;
    uint256 public numberPlayers;
    //@audit players need not be payable
    address payable[] public players;
    address payable[] public winners;

    event startPayout();

    constructor() ERC20("DogCoin", "DOG") {}

    //@audit Anybody can call this
    //@audit Input argument need not be payable
    function addPlayer(address payable _player) public payable {
        //@audit msg.value should be 1e18 wei
        if (msg.value == 1) {
            players.push(_player);
        }
        numberPlayers++;
        if (numberPlayers > 200) {
            emit startPayout();
        }
    }

    //@audit Anybody can call this
    function addWinner(address payable _winner) public {
        winners.push(_winner);
    }

    //@audit Anybody can call this
    function payout() public {
        //@audit Balance may not be exactly 100
        //@audit Balance is in wei
        if (address(this).balance == 100) {
            uint256 amountToPay = winners.length / 100;
            payWinners(amountToPay);
        }
    }

    //@audit Anyone can call this
    function payWinners(uint256 _amount) public {
        //@audit condition should be i < winners.length 
        for (uint256 i = 0; i <= winners.length; i++) {
            //@audit _amount is in Wei
            //@audit return value not being checked
            //@audit No flag being set
            //@audit No reentrancy check. Attacker can delegate call in his fallback.
            winners[i].send(_amount);
        }
    }
}