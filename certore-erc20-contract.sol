pragma solidity ^0.4.18;

//--------------------------------------------------------------------------------------------------
//      SafeMath
//--------------------------------------------------------------------------------------------------

library SafeMath
{   
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        require(a == 0 || c / a == b);
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // require(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        return a - b;
    }
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }
}

//--------------------------------------------------------------------------------------------------
//        Ownable
//--------------------------------------------------------------------------------------------------

contract Ownable
{
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function Ownable() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

//--------------------------------------------------------------------------------------------------
//        TokenERC20
//--------------------------------------------------------------------------------------------------

interface tokenRecipient
{
    function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external;
}

contract TokenERC20 is Ownable
{
    using SafeMath for uint;

    string public name;
    string public symbol;
    uint256 public decimals = 18;
    uint256 DEC = 10 ** uint256(decimals);
    address public owner;

    // 18 decimals is the strongly suggested default, avoid changing it
    uint256 public totalSupply;
    uint256 public avaliableSupply;
    // token buy price - 1/822 ether
    uint256 public buyPrice = 1216545012165500 wei;
 
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Burn(address indexed from, uint256 value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    function TokenERC20(uint256 initialSupply, string tokenName, string tokenSymbol) public {        
        totalSupply = initialSupply * DEC;            // Update total supply with the decimal amount        
        balanceOf[this] = totalSupply;                // Give the creator all initial tokens
        avaliableSupply = balanceOf[this];            // Show how much tokens on contract
        name = tokenName;                             // Set the name for display purposes
        symbol = tokenSymbol;                         // Set the symbol for display purposes
    }

    function _transfer(address _from, address _to, uint256 _value) internal {
        require(_to != 0x0);
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to] + _value > balanceOf[_to]);
        uint previousBalances = balanceOf[_from] + balanceOf[_to];        
        balanceOf[_from] = balanceOf[_from].sub(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);        
        emit Transfer(_from, _to, _value);
        require(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

    function transfer(address _to, uint256 _value) public {
        _transfer(msg.sender, _to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);
        allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);  
        _transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }

    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public onlyOwner returns (bool success) {        
        tokenRecipient spender = tokenRecipient(_spender);        
        approve(_spender, _value);            
        spender.receiveApproval(msg.sender, _value, this, _extraData);
        return true;
    }

    function increaseApproval (address _spender, uint _addedValue) public returns (bool success) {
        allowance[msg.sender][_spender] = allowance[msg.sender][_spender].add(_addedValue);
        emit Approval(msg.sender, _spender, allowance[msg.sender][_spender]);
        return true;
    }

    function decreaseApproval (address _spender, uint _subtractedValue) public returns (bool success) {        
        uint oldValue = allowance[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowance[msg.sender][_spender] = 0;
        } else {
            allowance[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowance[msg.sender][_spender]);
        return true;
    }

    function burn(uint256 _value) public onlyOwner returns (bool success) {        
        require(balanceOf[msg.sender] >= _value);   // Check if the sender has enough        
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);            // Subtract from the sender
        totalSupply = totalSupply.sub(_value);                                // Updates totalSupply
        avaliableSupply = avaliableSupply.sub(_value);        
        emit Burn(msg.sender, _value);
        return true;
    }

    function burnDec(uint256 _value) public onlyOwner returns (bool success) {        
        _value = _value.mul(DEC);
        require(balanceOf[msg.sender] >= _value);   // Check if the sender has enough        
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);            // Subtract from the sender
        totalSupply = totalSupply.sub(_value);                                // Updates totalSupply
        avaliableSupply = avaliableSupply.sub(_value);        
        emit Burn(msg.sender, _value);
        return true;
    }

    function burnFrom(address _from, uint256 _value) public onlyOwner returns (bool success) {
        require(balanceOf[_from] >= _value);                                        // Check if the targeted balance is enough
        require(_value <= allowance[_from][msg.sender]);                            // Check allowance
        balanceOf[_from] = balanceOf[_from].sub(_value);                            // Subtract from the targeted balance        
        allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);    // Subtract from the sender's allowance
        totalSupply = totalSupply.sub(_value);                                      // Update totalSupply
        avaliableSupply = avaliableSupply.sub(_value);
        emit Burn(_from, _value);
        return true;
    }
}

//--------------------------------------------------------------------------------------------------
//        ERC20Extending
//--------------------------------------------------------------------------------------------------

contract ERC20Extending is TokenERC20
{
    function transferEthFromContract(address _to, uint amount) public onlyOwner {    
        _to.transfer(amount);
    }
}

//--------------------------------------------------------------------------------------------------
//        Pauseble
//--------------------------------------------------------------------------------------------------

contract Pauseble is TokenERC20
{
    event EPause();
    event EUnpause();

    bool public paused = true;

    uint public startIcoDate = 0;

    modifier whenNotPaused() {
      require(!paused);
      _;
    }

    modifier whenPaused() {   
       require(paused);
        _;
    }

    function pause() public onlyOwner {
        paused = true;
        emit EPause();
    }

    function pauseInternal() internal {
        paused = true;
        emit EPause();
    }

    function unpause() public onlyOwner {
        paused = false;
        emit EUnpause();
    }
}

//--------------------------------------------------------------------------------------------------
//        CertoreCrowdsale
//--------------------------------------------------------------------------------------------------

contract CertoreCrowdsale is Pauseble
{
    using SafeMath for uint;

    event CrowdSaleFinished(string info);

    struct Ico {
        uint256 initialTokens; // Tokens in crowdsale
        uint256 tokens; // Tokens in crowdsale
        uint256 preIcoTokens; // Pre ICO tokens in crowdsale
        uint256 devTokens; // Dev tokens
        uint256 bountyTokens; // Bounty tokens
        uint startDate; // Date when crowsale will be starting, after its starting that property will be the 0
        uint endPreIcoDate; // Date when ICO without bonus start
        uint endDate;   // Date when crowdsale will be stop        
        uint unlockDevTokensDate; // Date when allow dev to transfer tokens
        uint8 discountPresaleICO; // Discount. Pre-sale
        uint8 discountFirstDayICO; // Discount. Only for first day ico
    }

    Ico public ICO;


    function crowdSaleStatus() internal constant returns (string) {        
        if (now >= ICO.startDate && now <= ICO.endPreIcoDate) {            
            return "Pre-sale ICO";        
        } else if(now > ICO.endPreIcoDate && now <= ICO.endPreIcoDate + 1 days) {            
            return "ICO first day";
        } else if (now > (ICO.endPreIcoDate + 1 days) && now <= ICO.endDate) {
            return "ICO";
        }
        return "ICO end";
    }


    function sell(address _investor, uint256 amount) internal
    {
        uint256 _amount = amount.mul(DEC).div(buyPrice);

        if (now >= ICO.startDate && now <= ICO.endPreIcoDate) 
        {      
            if(ICO.preIcoTokens > 0){
                uint256 _bonusValue = withDiscount(_amount, ICO.discountPresaleICO);
                if(_bonusValue >= ICO.preIcoTokens){
                    _bonusValue = ICO.preIcoTokens;
                    _amount = _amount.add(_bonusValue);
                    ICO.preIcoTokens = ICO.preIcoTokens.sub(_bonusValue);
                }else{
                    _amount = _amount.add(_bonusValue);
                    ICO.preIcoTokens = ICO.preIcoTokens.sub(_bonusValue);
                }
                
            }
        }
        else if(now > ICO.endPreIcoDate && now <= ICO.endPreIcoDate + 1 days)        
        {   
            _amount = _amount.add(withDiscount(_amount, ICO.discountFirstDayICO));
        }
        
        require(_amount <= ICO.tokens);
        
        ICO.tokens = ICO.tokens.sub(_amount);
        avaliableSupply = avaliableSupply.sub(_amount);
        _transfer(this, _investor, _amount);
    }
    
    function transferBounty(address _to, uint256 _value) public onlyOwner {
        uint256 _amount = _value.mul(DEC); 
        require(ICO.bountyTokens >= _amount);
        ICO.bountyTokens = ICO.bountyTokens.sub(_amount);
        avaliableSupply = avaliableSupply.sub(_amount);
        _transfer(this, _to, _amount);
    }    
    
    function transferDevTokens(address _to, uint256 _value) public onlyOwner {
        uint256 _amount = _value.mul(DEC); 
        require(ICO.devTokens >= _amount);
        require(now >= ICO.unlockDevTokensDate);
        ICO.devTokens = ICO.devTokens.sub(_amount);
        avaliableSupply = avaliableSupply.sub(_amount);
        _transfer(this, _to, _amount);
    }

    function startCrowd() public onlyOwner {
        uint8 _discountPresaleICO = 20;
        uint8 _discountFirstDayICO = 5;
        uint _startDate = 1522540800; // 2018-04-01 00:00:00
        uint _endPreIcoDate = 1525132799; //  2018-04-30 23:59:59
        uint _endDate = 1530403199; // 2018-06-30 23:59:59
        uint _unlockDevTokensDate = 1546300799; // 2018-12-31 23:59:59
        uint256 _devTokens = 15000000;
        uint256 _bountyTokens = 7500000;
        uint256 _initialTokens = 52500000;
        uint256 _tokens = _initialTokens;
        uint256 _preIcoTokens = 1500000;

        startIcoDate = _startDate;    

        ICO = Ico (
            _initialTokens.mul(DEC),
            _tokens.mul(DEC),
            _preIcoTokens.mul(DEC),
            _devTokens.mul(DEC),
            _bountyTokens.mul(DEC),
            _startDate,
            _endPreIcoDate,
            _endDate,
            _unlockDevTokensDate,
            _discountPresaleICO,
            _discountFirstDayICO
        );
        unpause();
    }

    function transferWeb3js(address _investor, uint256 _amount) external onlyOwner
    {
        sell(_investor, _amount);
    }    
    
    function emitCrowdSaleFinished() public onlyOwner
    {
        emit CrowdSaleFinished(crowdSaleStatus());
        pauseInternal();
    }

    function withDiscount(uint256 _amount, uint _percent) internal pure returns (uint256) {        
        return _amount.mul(_percent).div(100);
    }
}

//--------------------------------------------------------------------------------------------------
//        CertoreContract
//--------------------------------------------------------------------------------------------------

contract CertoreContract is ERC20Extending,  CertoreCrowdsale
{
    uint public weisRaised;                                                          // how many weis was raised on crowdsale

    function CertoreContract() public TokenERC20(75000000, "Certore", "CERT") {}      

    function () public payable
    {
        require(msg.value >= 1 ether / 100);
        require(now >= ICO.startDate); 
        if (now > ICO.endDate) {          
          emit CrowdSaleFinished(crowdSaleStatus());
          pauseInternal();
          revert();
        }else{
            if (0 != startIcoDate){
                if (now < startIcoDate) {
                    revert();
                } else {
                    startIcoDate = 0;
                }
            }
            sell(msg.sender, msg.value);
            weisRaised = weisRaised.add(msg.value);
        }

    }
}