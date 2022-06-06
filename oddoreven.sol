pragma solidity >=0.7.0 <0.9.0;


// 1ether = 1000000000000000000
contract oddoreven {
    address payable _owner;	// 컨트렉트 주인
    // event randomNumber(uint random);	// 랜덤 숫자가 생성 되면 이벤트 발생
    event result(bool result, uint amount);
    mapping(uint => Bet) public Records;
    uint recordCounts;
    uint completed;

    constructor() public payable {
        _owner = payable(msg.sender);
        recordCounts = 0;
        completed = 0;
    }

    receive() external payable {}
    fallback() external payable {}


    struct Bet {
        address payable player;
        string randstr;
        uint amount;
        uint guess;
        bool done;
        bool winorlose;
    }

    Bet public betinfo;

    function getOwner() public view returns (address) {
        return _owner;
    }

    function Betmoney(uint guess, string memory randStr) public payable {
        require (guess == 1 || guess == 2, "Only write 1 (even) or 2 (odds) for guess");
        require (msg.value > 0, "Amount of money should be more than 0");
        require(msg.value < 10 ether, "Maximum amount is 10 ether");
        Bet memory bet;
        bet.player = payable(msg.sender);
        bet.amount = msg.value;
        bet.guess = guess;
        bet.randstr = randStr;
        bet.done = false;
        //betinfo = bet;
        bool sent = (_owner).send(msg.value);
        require(sent, "Failed to send Ether to owner");
        Records[recordCounts] = bet; 
        recordCounts++;
    }

    function Checkanswer(string memory _random, Bet memory betinfo) internal pure returns (bool) {
        uint random = uint(keccak256(abi.encodePacked(_random)));
        if (betinfo.guess == 1) {
            if (random % 2 == 0) {
                return true;
            }
            else {
                return false;
            }
        }
        else {
            if (random % 2 == 0) {
                return false;
            }
            else {
                return true;
            }
        }
    }

    function Result() public onlyOwner payable {
        uint i;
        for (i = completed; i < recordCounts; i++) {
            Bet memory betinfo = Records[i];
            string memory random = betinfo.randstr;
            address payable to = betinfo.player;
            uint amount = betinfo.amount;
            if (Checkanswer(random, betinfo)) {
                to.transfer(amount);
                //(bool sent, bytes memory data) = to.call{value: amount}("");
                //require(sent, "Failed to send Ether to player");
                Records[i].done = true;
                Records[i].winorlose = true;
                emit result(true, betinfo.amount * 2);
            }
            else {
                Records[i].done = true;
                Records[i].winorlose = false;
                emit result(false, 0);
            }
        }
        completed = i;
    }

    modifier onlyOwner() {
        // 주인만 함수를 사용할 수 있도록 하기
        require(msg.sender == _owner, "only owner can use");
        _;
    }
}
