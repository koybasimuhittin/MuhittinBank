// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract  MuhittinBank{

    mapping(address => uint) ETHbalances;
    mapping(address => mapping(address => uint)) ERC20Balances;
    mapping(address => uint) public TotalXBalance;

    event ETHDeposit(address indexed sender, uint amount);
    event ETHWithdraw(address indexed reciever, uint amount);
    event ERC20Deposit(address indexed contractAddress, address indexed sender, uint amount);
    event ERC20Withdraw(address indexed contractAddress, address indexed reciever, uint amount);

    receive() external payable {
        ETHbalances[msg.sender] += msg.value;
        emit ETHDeposit(msg.sender, msg.value);
    }


    function withdrawETH(uint _amount) public {
        require(ETHbalances[msg.sender] >= _amount, "Your balance is not enough");
        ETHbalances[msg.sender] -= _amount;
        (bool success,) = payable(msg.sender).call{value: _amount}("");
        require(success);
        emit ETHWithdraw(msg.sender, _amount);
    }


    function totalETHBalance() private view returns(uint){
        return address(this).balance;
    }


    function approve(address _contractAddress, uint _amount) external {
        IERC20(_contractAddress).approve(address(this), _amount);
    }


    function depositERC20(address _contractAddress, uint _amount) external {
        uint _allowance = IERC20(_contractAddress).allowance(msg.sender, address(this));
        require(_allowance >= _amount, "Allowance is not enough for this contract");
        IERC20(_contractAddress).transferFrom(msg.sender, address(this), _amount);
        ERC20Balances[_contractAddress][msg.sender] += _amount;
        TotalXBalance[_contractAddress] += _amount;
        emit ERC20Deposit(_contractAddress, msg.sender, _amount);
    }


    function withdrawERC20(address _contractAddress, uint _amount) external {
        require(ERC20Balances[_contractAddress][msg.sender] <= _amount);
        IERC20(_contractAddress).transfer(msg.sender, _amount);
        ERC20Balances[_contractAddress][msg.sender] -= _amount;
        TotalXBalance[_contractAddress] -= _amount;
        emit ERC20Withdraw(_contractAddress, msg.sender, _amount);
    }


    function getERC20Balances(address _contractAddress) public view returns(uint) {
        return ERC20Balances[_contractAddress][msg.sender];
    }
}
