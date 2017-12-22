pragma solidity ^0.4.18;
/**
* INVOT ICO Contract
* VOT is an ERC-20 Token Standar Compliant
* @author Fares A. Akel C. f.antonio.akel@gmail.com
*/

/**
 * @title SafeMath by OpenZeppelin
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a / b;
        return c;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

/**
* Token interface definition
*/
contract ERC20Token {

    function balanceOf(address _owner) public constant returns (uint256 balance); //Function to check an address balance
    function transfer(address _to, uint256 _value) public returns (bool success); //transfer function to let the contract move own tokens
    
                }

/**
* @title INVOTICO
* @dev ICO contract definition
*/
contract INVOTICO {
    using SafeMath for uint256;

    /**
    * This ICO have 2 states 0:Ongoing 1:Successful
    */
    enum State {
        Ongoing,
        Successful
    }

    /**
    * For the ico there is a list of base prices that include level bonuses
    * Since both, token and eth, have 18 decimals this is a multiplying factor
    * Thats means ETH * Price = VOT
    */
    uint256[6] public prices=[
    7200,   //+20%
    6900,   //+15%
    6600,   //+10%
    6300,   //+5%
    6150,    //+2.5%
    6000
    ];

    /**
    * Variables definition - Public
    */
    State public state = State.Ongoing; //Set initial stage
    uint256 public startTime = now; //block-time when it was deployed
    uint256 public totalRaised;
    uint256 public ICODeadLine;
    uint256 public completedAt;
    uint256 public tokensToDistribute = 10500000; //only a public reference number
    uint256 public tokensDistributed;
    ERC20Token public tokenReward;
    address public creator;
    string public campaignUrl;
    uint256 public constant version = 1;

    /**
    *Log Events
    */
    event LogFundingReceived(address _addr, uint _amount, uint _currentTotal);
    event LogBeneficiaryPaid(address _beneficiaryAddress);
    event LogFundingSuccessful(uint _totalRaised);
    event LogPreICOInitialized(
        address _creator,
        string _url,
        uint256 _ICODeadLine);
    event LogContributorsPayout(address _addr, uint _amount);
    
    /**
    * @dev Modifier to require the ICO is on going
    */
    modifier notFinished() {
        require(state != State.Successful);
        _;
    }

    /**
    * @dev Constructor
    * @param _campaignUrl the address of the campaign Web
    * @param _addressOfTokenUsedAsReward token contract address
    * @param _ICODuration time the ico last in days
    */
    function INVOTICO (
        string _campaignUrl,
        ERC20Token _addressOfTokenUsedAsReward,
        uint256 _ICODuration )
        public
    {
        creator = msg.sender;
        campaignUrl = _campaignUrl;
        ICODeadLine = startTime.add(_ICODuration * 1 days);
        tokenReward = _addressOfTokenUsedAsReward;
        LogPreICOInitialized(
            creator,
            campaignUrl,
            ICODeadLine);
    }
    /**
    *@dev Function to contribute to the ICO
    *Its check first if ICO is ongoin
    *so no one can transfer to it after finished
    */
    function contribute() public notFinished payable {

        uint256 tokenBought;
        totalRaised = totalRaised.add(msg.value);

        //base price calc
        if (totalRaised < 300 ether){
            tokenBought = uint256(msg.value).mul(prices[0]);
        }
        else if(totalRaised < 600 ether){
            tokenBought = uint256(msg.value).mul(prices[1]);
        }
        else if(totalRaised < 900 ether){
            tokenBought = uint256(msg.value).mul(prices[2]);
        }
        else if(totalRaised < 1200 ether){
            tokenBought = uint256(msg.value).mul(prices[3]);
        }
        else if(totalRaised < 1500 ether){
            tokenBought = uint256(msg.value).mul(prices[4]);
        }
        else{
            tokenBought = uint256(msg.value).mul(prices[5]);   
        }

        //bonus amount-based calc
        if (msg.value >= 1 ether){
            tokenBought = tokenBought.mul(101); // 101/100 = 1.01 > +1%
            tokenBought = tokenBought.div(100);
        }
        else if(msg.value >= 2 ether){
            tokenBought = tokenBought.mul(1015); // 1015/1000 = 1.015 > +1.5%
            tokenBought = tokenBought.div(1000);
        }
        else if(msg.value >= 3 ether){
            tokenBought = tokenBought.mul(102); // 102/100 = 1.02 > +2%
            tokenBought = tokenBought.div(100);
        }
        else if(msg.value >= 5 ether){
            tokenBought = tokenBought.mul(103); // 103/100 = 1.03 > +3%
            tokenBought = tokenBought.div(100);
        }
        else if(msg.value >= 7 ether){
            tokenBought = tokenBought.mul(104); // 104/100 = 1.04 > +4%
            tokenBought = tokenBought.div(100);
        }
        else if(msg.value >= 10 ether){
            tokenBought = tokenBought.mul(105); // 105/100 = 1.05 > +5%
            tokenBought = tokenBought.div(100);
        }
        else if(msg.value >= 13 ether){
            tokenBought = tokenBought.mul(106); // 106/100 = 1.06 > +6%
            tokenBought = tokenBought.div(100);
        }
        else if(msg.value >= 16 ether){
            tokenBought = tokenBought.mul(107); // 107/100 = 1.07 > +7%
            tokenBought = tokenBought.div(100);
        }
        else if(msg.value >= 20 ether){
            tokenBought = tokenBought.mul(1085); // 1085/1000 = 1.085 > +8.5%
            tokenBought = tokenBought.div(1000);
        }

        tokensDistributed = tokensDistributed.add(tokenBought);
        tokenReward.transfer(msg.sender, tokenBought);
        
        LogFundingReceived(msg.sender, msg.value, totalRaised);
        LogContributorsPayout(msg.sender, tokenBought);
        
        checkIfFundingCompleteOrExpired();
    }

    /**
    *@dev Function to check if ICO finished
    */
    function checkIfFundingCompleteOrExpired() public {
        
        if( now > ICODeadLine && state!=State.Successful ) {
            state = State.Successful;
            completedAt = now;

            LogFundingSuccessful(totalRaised);
            finished();  
        }
    }

    /**
    *@dev Function to do final transactions
    *When finished eth and remaining tokens are transfered to creator
    */
    function finished() public {
        require(state == State.Successful); 
        uint256 remanent = tokenReward.balanceOf(this);

        tokenReward.transfer(creator,remanent); //remanent tokens to creator wallet
        require(creator.send(this.balance)); //All ether to creator wallet

        LogBeneficiaryPaid(creator);
        LogContributorsPayout(creator, remanent);
    }

    /**
    *@dev Function to handle eth transfers
    *BEWARE: if a call to this functions doesnt have
    *enought gas transaction could not be finished
    */
    function () public payable {
        contribute();
    }
}
