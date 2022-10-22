// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract  MuhittinBank{

    event ETHDeposit(address indexed sender, uint amount);
    event ETHWithdraw(address indexed reciever, uint amount);
    event ERC20Deposit(address indexed contractAddress, address indexed sender, uint amount);
    event ERC20Withdraw(address indexed contractAddress, address indexed reciever, uint amount);

    struct Stake{
        address tokenAddress;
        uint balance;
        uint reward;
        uint unlockDate;
    }

    mapping(address => mapping(uint => bool)) isAlreadyWithdrawed;
    mapping(address => Stake[]) addressToStakes;
    mapping(address => uint) ETHBalances;
    mapping(address => mapping(address => uint)) ERC20Balances;
    mapping(address => uint) public TotalXBalance;

    address _owner;

    uint _feeRatio = 2;
    uint _stakeRewardRatio = 1;

    constructor() {
        _owner = msg.sender;
    }

    modifier isStakeExist(uint _id){
        require(_id < addressToStakes[msg.sender].length, "Stake does not exist");
        _;
    }

    modifier isWithdrawable(uint _id, bool _accordingToTime){
        require(isAlreadyWithdrawed[msg.sender][_id] == false, "You already withdraw your stake");
        if(_accordingToTime){
            require(addressToStakes[msg.sender][_id].unlockDate <= block.timestamp, "Stake is not unlocked yet");
        }
        _;
    }

    modifier isEnoughAllowance(address _contractAddress, uint _amount){
        uint _allowance = IERC20(_contractAddress).allowance(msg.sender, address(this));
        require(_allowance >= _amount, "Allowance is not enough for this contract");
        _;
    }

    receive() external payable {
        ETHBalances[msg.sender] += msg.value;
        emit ETHDeposit(msg.sender, msg.value);
    }

    function withdrawETH(uint _amount) public {
        require(ETHBalances[msg.sender] >= _amount, "Your balance is not enough");
        ETHBalances[msg.sender] -= _amount;
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
        uint _amountWithFee = _amount + ((_amount * _feeRatio) / 10**3);
        uint _allowance = IERC20(_contractAddress).allowance(msg.sender, address(this));
        require(_allowance >= _amountWithFee, "Allowance is not enough for this contract");
        IERC20(_contractAddress).transferFrom(msg.sender, address(this), _amountWithFee);
        ERC20Balances[_contractAddress][msg.sender] += _amount;
        TotalXBalance[_contractAddress] += _amountWithFee;
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
    
    function stakeERC20(address _contractAddress, uint _amount, uint _lockTime) external isEnoughAllowance(_contractAddress, _amount){

        Stake memory _stake = Stake(_contractAddress, _amount, (_amount * _lockTime * _stakeRewardRatio) / 10**6, block.timestamp + _lockTime);
        addressToStakes[msg.sender].push(_stake);

        IERC20(_contractAddress).transferFrom(msg.sender, address(this), _amount);
        TotalXBalance[_contractAddress] += _amount;
    }

    function withdrawWithReward(uint _stakeId) external isStakeExist(_stakeId) isWithdrawable(_stakeId, true) {

        Stake memory _stake = addressToStakes[msg.sender][_stakeId];
        uint _amount = _stake.balance + _stake.reward;

        IERC20(_stake.tokenAddress).transfer(msg.sender, _amount);
        TotalXBalance[_stake.tokenAddress] -= _amount;
        isAlreadyWithdrawed[msg.sender][_stakeId] = true;
    
    }

    function withdrawWithoutReward(uint _stakeId) external isStakeExist(_stakeId) isWithdrawable(_stakeId, false) {
        
        Stake memory _stake = addressToStakes[msg.sender][_stakeId];
        uint _amount = _stake.balance;

        IERC20(_stake.tokenAddress).transfer(msg.sender, _amount);
        TotalXBalance[_stake.tokenAddress] -= _amount;
        isAlreadyWithdrawed[msg.sender][_stakeId] = true;
    }

}
