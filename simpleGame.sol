pragma solidity >=0.7.0 <0.9.0;


// 1ether = 1000000000000000000
contract simpleGame {

    // account 별 balance
    mapping (address => uint256) private balance;

    address payable _owner;	// 컨트렉트 주인
    // event randomNumber(uint random);	// 랜덤 숫자가 생성 되면 이벤트 발생
    //결과
    event result(bool result, uint amount);
    // 게임 시도 기록
    mapping(uint => Bet) public Records;
    // 출금 요청
    mapping(uint => withdrawReq) public Requests;
    // 단어리스트
    mapping(uint => string) public usedWords;

    uint recordCounts;
    uint completed;
    uint requestCounts;
    uint requestCompleted;
    uint wordCount;
    string words;

    constructor() public payable {
        _owner = payable(msg.sender);
        recordCounts = 0;
        requestCounts = 0;
        requestCompleted = 0;
        completed = 0;
        wordCount = 0;
        // 10 이더 이상을 넣어야 함(owner)
        require(msg.value >= 10 ether, "You must insert more than 50 ether to deploy");
        bool sent = payable(address(this)).send(msg.value);
        require(sent, "Failed to send Ether to contract");
        balance[_owner] = msg.value;
    }

    modifier onlyOwner() {
        // 주인만 함수를 사용할 수 있도록 하기
        require(msg.sender == _owner, "only owner can use");
        _;
    }

    receive() external payable {}
    fallback() external payable {}

    // 베팅 관련 구조체
    struct Bet {
        address payable player;
        string randstr;
        uint amount;
        uint guess;
        bool done;
        bool winorlose;
    }
    //출금 요청 관련 구조체
    struct withdrawReq {
        address payable requester;
        uint amount;
        bool done;
    }
    // owner의 주소
    function getOwner() public view returns (address) {
        return _owner;
    }
    // owner가 입금한 돈
    function getOwnerMoney() public view returns (uint) {
        return balance[_owner];
    }
    // 주소가 갖고 있는 돈
    // function checkBalance(address _addr) public view returns (uint) {
    //     return _addr.balance;
    // }
    

    // contract에 입금
    function deposit() external payable {
        require(msg.value > 0, "Amount of money should be more than 0");
        balance[msg.sender] += msg.value;
    }
    
    // 출금 요청
    function withdrawRequest(uint amount) external payable {
        require(balance[msg.sender] >= amount, "You don't have enough money");
        require(msg.value == 0);

        withdrawReq memory req;
        req.amount = amount;
        req.requester = payable(msg.sender);
        req.done = false;
        Requests[requestCounts] = req;
        requestCounts++;
    }

    // 출금 실행
    function executeRequest() external payable onlyOwner {
        uint i;
        uint j;
        j = requestCompleted;
        for (i=j; i<requestCounts; i++) {
            withdrawReq memory req = Requests[i];
            require(Requests[i].done == false, "request already done");
            address to = req.requester;
            uint amount = req.amount;
            (bool sent, ) = to.call{value: amount}("");
            require(sent, "Failed to send Ether to player");
            balance[to] -= amount;
            Requests[i].done = true;
        }
        requestCompleted = requestCounts-1;
    }
    
    // 송금
    function transfer(address _to, uint256 _amount) external {
        require(balance[msg.sender] >= _amount, "Not enough money");
        require(balance[_to] + _amount > balance[_to]);
        
        balance[msg.sender] -= _amount;
        balance[_to] += _amount;
    }

    // 보유 money 확인 
    function getBalance(address _user) external view returns (uint256) {
        return balance[_user];
    }

    // 베팅
    function Betmoney(uint amount, uint guess, string memory randStr) public payable {
        require(msg.value == 0, "Do not deposit money from your account");
        require (guess == 1 || guess == 2, "Only write 1 (even) or 2 (odds) for guess");
        require (amount > 0, "Amount of money should be more than 0");
        require(amount < 10 ether, "Maximum amount is 10 ether");
        require(balance[_owner] > amount * 2, "Owner does not have enough money");
        for (uint i=0; i<wordCount; i++) {
            require(keccak256(abi.encodePacked((randStr))) != keccak256(abi.encodePacked((usedWords[i]))), "randStr already used");
        }
        Bet memory bet;
        bet.player = payable(msg.sender);
        bet.amount = amount;
        bet.guess = guess;
        bet.randstr = randStr;
        usedWords[wordCount] = randStr;
        wordCount++;
        bet.done = false;
        //betinfo = bet;
        // bool sent = (_owner).send(msg.value);
        // require(sent, "Failed to send Ether to owner");
        Records[recordCounts] = bet; 
        recordCounts++;
        Result();
    }

    // 정답 확인
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

    // 결과 도출
    function Result() private {
        Bet memory betinfo = Records[recordCounts-1];
        string memory random = betinfo.randstr;
     
        if (Checkanswer(random, betinfo)) {
            balance[betinfo.player] += betinfo.amount * 2;
            balance[_owner] -= betinfo.amount*2;
            Records[recordCounts-1].done = true;
            Records[recordCounts-1].winorlose = true;
            emit result(true, betinfo.amount * 2);
        }
        else {
            balance[betinfo.player] -= betinfo.amount;
            balance[_owner] += betinfo.amount;
            Records[recordCounts-1].done = true;
            Records[recordCounts-1].winorlose = false;
            emit result(false, 0);
        }
    }
}
