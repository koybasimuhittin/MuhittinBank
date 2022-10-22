// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.16;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Muhittin20 is ERC20 {

    mapping(address => bool) mintedBefore;
    mapping(address => uint) remainderMintables;

    uint _maxMintAllowance = 10**6;
    address _owner;

    constructor(string memory _name, string memory _symbol) ERC20(_name, _symbol){
        _owner = msg.sender;
    }



    function mint(uint _amount) external {
        if(msg.sender == _owner){
            _mint(msg.sender, _amount);
        }
        else if(!mintedBefore[msg.sender]){
            require(_amount <= _maxMintAllowance, "You are not able to mint this amount");
            _mint(msg.sender, _amount);
            remainderMintables[msg.sender] = _maxMintAllowance - _amount;
            mintedBefore[msg.sender] = true;
        }
        else{
            require(_amount <= remainderMintables[msg.sender], "You are not able to mint this amount");
            _mint(msg.sender, _amount);
            remainderMintables[msg.sender] = _maxMintAllowance - _amount;
        }
    }

    function getRemainMintRight() view public returns(uint) {
        if(!mintedBefore[msg.sender]) return _maxMintAllowance;
        return remainderMintables[msg.sender];
    }
}
