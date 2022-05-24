pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./QuanToken.sol";

contract Vesting is Ownable{
    //using SafeMath for uint256;
    uint256 public firstRelease;
    uint256 public startTime = block.timestamp;
    uint256 public totalPeriods;
    uint256 public timePerPeriods;
    uint256 public cliff;
    uint256 public totalToken;
    QuanToken public token;

    struct BuyerInfo{
        uint256 amount;
        uint256 tokenClaimed;
    }
    mapping(address => BuyerInfo) public buyerInfo;
    constructor(
        address _token, //token dung
        uint256 _firstRelease, // block.timestamp : khởi tạo smartcontract
        uint256 _startTime,// thời gian bắt đầu trả dần
        uint256 _cliff, // khoang thoi gian token bi khoa
        uint256 _totalPeriod, //khoảng thời gian còn lại sau khi nhận 20% VD: 8 tháng
        uint256 _timePerPeriods, // khoảng thời gian giữa các lần claim còn lại VD: 1 tháng
        uint256 _totalToken
    ) {
        token = QuanToken(_token);
        firstRelease = _firstRelease;
        startTime = _startTime;
        totalPeriods = _totalPeriod;
        timePerPeriods = _timePerPeriods;
        cliff = _cliff;
        totalToken = _totalToken;
    }

    function fundVesting() public onlyOwner {
        token.transfer(address(this),totalToken);
    }

    function whilteList(address buyer, uint256 _amount) external {
        buyerInfo[buyer].amount = _amount;
        buyerInfo[buyer].tokenClaimed = 0; 
    }

    function claim() public {
        uint256 time = block.timestamp;
        uint256 tokenClaimable = 0;
        uint256 tokenClaimPerPeriod = buyerInfo[msg.sender].amount * 80 / 100 / totalPeriods;
        if(time < firstRelease + cliff){
                        tokenClaimable = buyerInfo[msg.sender].amount * 20 / 100;
            token.transfer(msg.sender,tokenClaimable);
            buyerInfo[msg.sender].tokenClaimed = tokenClaimable;
        } else {
            tokenClaimable += tokenClaimPerPeriod*((time-startTime)/timePerPeriods);
            startTime = startTime + ((time-startTime)/timePerPeriods) * timePerPeriods;
            totalPeriods = totalPeriods - ((time-startTime)/timePerPeriods);
            token.transfer(msg.sender,tokenClaimable);
            buyerInfo[msg.sender].tokenClaimed += tokenClaimable;
        }
    }
}
