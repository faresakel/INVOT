pragma solidity ^0.4.18;
/**
* INVOT Pre-ICO Contract
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


    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

/**
* @title Token interface definition
*/
contract ERC20Token {

    function balanceOf(address _owner) public constant returns (uint256 balance); //Function to check an address balance
    function transfer(address _to, uint256 _value) public returns (bool success); //transfer function to let the contract move own tokens
    
                }

/**
* @title INVOTPREICO
* @dev PreICO contract definition
*/
contract INVOTPREICO {
    using SafeMath for uint256;

    /**
    * This PREICO have 2 states 0:Ongoing 1:Successful
    */
    enum State {
        Ongoing,
        Successful
    }

    /**
    * For the preico there is a list of prices that include bonuses
    * Since both, token and eth, have 18 decimals this is a multiplying factor
    * Thats means ETH * Price = VOT
    */
    uint256[4] public prices=[
    3600,   //+80%
    3400,   //+70%
    3300,   //+65%
    3200    //+60%
    ];

    /**
    * Variables definition - Public
    */
    State public state = State.Ongoing; //Set initial stage
    uint256 public startTime = now; //block-time when it was deployed
    uint256 public totalRaised;
    uint256 public preICODeadLine;
    uint256 public completedAt;
    uint256 public tokensDistributed;
    uint256 public hardCap = 2500 ether; //this preico have a hardCap
    ERC20Token public tokenReward;
    address public creator;
    string public campaignUrl;
    string public version = '1';

    /**
    * Log Events
    */
    event LogFundingReceived(address _addr, uint _amount, uint _currentTotal);
    event LogBeneficiaryPaid(address _beneficiaryAddress);
    event LogFundingSuccessful(uint _totalRaised);
    event LogPreICOInitialized(
        address _creator,
        string _url,
        uint256 _preICODeadLine);
    event LogContributorsPayout(address _addr, uint _amount);

    /**
    * @dev Modifier to require the preico is on going
    */
    modifier notFinished() {
        require(state != State.Successful);
        _;
    }

    /**
    * @dev Constructor
    * @param _campaignUrl the address of the campaign Web
    * @param _addressOfTokenUsedAsReward token contract address
    * @param _preICODuration time the ico last in days
    */
    function INVOTPREICO (
        string _campaignUrl,
        ERC20Token _addressOfTokenUsedAsReward,
        uint256 _preICODuration )
        public
    {
        creator = msg.sender;
        campaignUrl = _campaignUrl;
        preICODeadLine = startTime.add(_preICODuration * 1 days);
        tokenReward = _addressOfTokenUsedAsReward;
        LogPreICOInitialized(
            creator,
            campaignUrl,
            preICODeadLine);
    }

    /**
    * @dev Function to contribute to the ICO
    * Its check first if ICO is ongoin
    * so no one can transfer to it after finished
    */
    function contribute() public notFinished payable {

        uint256 tokenBought;
        totalRaised = totalRaised.add(msg.value);

        if (totalRaised < 650 ether){
            tokenBought = uint256(msg.value).mul(prices[0]);
        }
        else if(totalRaised < 1250 ether){
            tokenBought = uint256(msg.value).mul(prices[1]);
        }
        else if(totalRaised < 1875 ether){
            tokenBought = uint256(msg.value).mul(prices[2]);
        }
        else{
            tokenBought = uint256(msg.value).mul(prices[3]);   
        }

        tokensDistributed = tokensDistributed.add(tokenBought);
        tokenReward.transfer(msg.sender, tokenBought);
        
        LogFundingReceived(msg.sender, msg.value, totalRaised);
        LogContributorsPayout(msg.sender, tokenBought);
        
        checkIfFundingCompleteOrExpired();
    }

    /**
    *@dev Function to check if PreICO if finished
    */
    function checkIfFundingCompleteOrExpired() public {
        
        if( (now > preICODeadLine || totalRaised >= hardCap) && state!=State.Successful ) {
            state = State.Successful;
            completedAt = now;

            LogFundingSuccessful(totalRaised);
            finished();  
        }
    }

    /**
    * @dev Function to do final transactions
    * When finished eth and remaining tokens are transfered to creator
    */
    function finished() public {
        require(state == State.Successful); 
        uint256 remanent = tokenReward.balanceOf(this);

        tokenReward.transfer(creator,remanent); //All remanent tokens goes to creator wallet
        require(creator.send(this.balance)); //All ether goes to creator wallet

        LogBeneficiaryPaid(creator);
        LogContributorsPayout(creator, remanent);
    }

    /**
    * @dev Function to handle eth transfers
    * BEWARE: if a call to this functions doesnt have
    * enought gas, transaction will fail
    */
    function () public payable {
        contribute();
    }
}