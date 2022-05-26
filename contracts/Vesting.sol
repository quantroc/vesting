// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./QuanToken.sol";

contract TokenVesting is Ownable {
    using SafeMath for uint256;
    // Info of each user
    struct UserInfo {
        uint256 amount;
        uint256 tokensClaimed;
    }

    // mapping user info by address
    mapping(address => UserInfo) public userInfo;

    QuanToken public token;
    uint256 public firstRelease;
    uint256 public startTime;
    uint256 public totalPeriods;
    uint256 public timePerPeriod;
    uint256 public cliff;
    uint256 public totalTokens;

    event TokenClaimed(address _address, uint256 tokensClaimed);
    event VestingFunded(uint256 totalTokens);
    event SetStartTime(uint256 _startTime);
    event AddWhitelistUser(address _address, uint256 _amount);
    event RemoveWhitelistUser(address _address);

    /**
     *@dev constructor
     *@param _token address of BEP20 token
     *@param _firstRelease in percent for percent of total tokens that user will receive at first claim, 100 = 1%
     *@param _startTime moment when releasing the first 20% of the tokens
     *@param _cliff delay (seconds) from _startTime after that monthly vesting starts
     *@param _totalPeriods total amount of vesting periods
     *@param _timePerPeriod time in seconds for every vesting period
     */
    constructor(
        address _token,
        uint256 _firstRelease,
        uint256 _startTime,
        uint256 _cliff,
        uint256 _totalPeriods,
        uint256 _timePerPeriod
    ) {
        require(_token != address(0), "zero address not allowed");
        require(_firstRelease <= 10000, "_firstRelease must less than 10000");
        require(_totalPeriods > 0, "_totalPeriods must greater than 0");
        require(_startTime > block.timestamp, "_startTime must greater than current time");
        require(_timePerPeriod > 0, "_timePerPeriod must greater than 0");

        token = QuanToken(_token);
        firstRelease = _firstRelease;
        startTime = _startTime;
        cliff = _cliff;
        totalPeriods = _totalPeriods;
        timePerPeriod = _timePerPeriod;
    }

    /**
     * @dev function responsible for supplying tokens that will be vested
     * @param _totalTokens amount of tokens that will be supplied to this contract
     */
    function fundVesting(uint256 _totalTokens) public onlyOwner {
        require(token.allowance(msg.sender, address(this)) == _totalTokens, "Not allow spend GRBE token");
        totalTokens = totalTokens.add(_totalTokens);
        token.transferFrom(msg.sender, address(this), _totalTokens);
        emit VestingFunded(_totalTokens);
    }

    /**
     * @dev function that allows receiver to claim tokens, can be called only by receiver
     */
    function claimTokens() public {
        require(totalTokens > 1000000, "Vesting has not been funded yet");
        address _sender = msg.sender;
        UserInfo storage user = userInfo[_sender];
        require(user.amount > user.tokensClaimed.add(1), "All tokens claimed or not whitelist");
        require(block.timestamp > startTime, "Vesting hasn't started yet");

        uint256 timePassed = block.timestamp.sub(startTime);
        uint256 firstClaim = user.amount.mul(firstRelease).div(10000);
        if (timePassed < cliff) {
            require(user.tokensClaimed == 0, "tokens claimed");
            user.tokensClaimed = user.tokensClaimed.add(firstClaim);
            totalTokens = totalTokens.sub(firstClaim);
            token.transfer(_sender, firstClaim);
            emit TokenClaimed(_sender, firstClaim);
        } else {
            timePassed = timePassed.sub(cliff);
            uint256 time = timePassed.div(timePerPeriod).add(1);
            if (time > totalPeriods) {
                time = totalPeriods;
            }

            uint256 _amount = user.amount.sub(firstClaim);
            uint256 tokensToClaim = _amount.mul(time).div(totalPeriods).add(firstClaim).sub(user.tokensClaimed);

            user.tokensClaimed = user.tokensClaimed.add(tokensToClaim);
            totalTokens = totalTokens.sub(tokensToClaim);
            token.transfer(_sender, tokensToClaim);

            emit TokenClaimed(_sender, tokensToClaim);
        }
    }

    function setStartTime(uint256 _startTime) public onlyOwner {
        startTime = _startTime;

        emit SetStartTime(_startTime);
    }

    function addWhitelistUser(address _address, uint256 _amount) public onlyOwner {
        require(block.timestamp < startTime, "Vesting has started, cannot add whitelist");
        UserInfo storage user = userInfo[_address];
        user.amount = _amount;
        user.tokensClaimed = 0;

        emit AddWhitelistUser(_address, _amount);
    }

    function removeWhitelistUser(address _address) public onlyOwner {
        delete userInfo[_address];

        emit RemoveWhitelistUser(_address);
    }
}
