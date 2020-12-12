pragma solidity ^0.5.0;

contract Vault {
    address public farmer;
    address public contracter;

    //Will be settling the dispute
    address public administrator;

    //to lock the funds so that no one can withdraw the funds
    bool public lock;

    mapping(address => uint256) public depositedAmount;
    mapping(address => uint256) public amountToClaim;

    //Should be confirmed by all to settle
    mapping(address => bool) public claimConfirmation;

    /**
     * @dev Funds deposited.
     */
    event Deposit(address from, uint256 value);

    /**
     * @dev Funds withdrawn.
     */
    event Withdraw(address to, uint256 value);

    modifier onlyOwners() {
        require(
            msg.sender == farmer || msg.sender == contracter,
            "Invalid Owner"
        );
        _;
    }

    modifier onlyAdministrator() {
        require(msg.sender == administrator, "Invalid Administrator");
        _;
    }

    modifier onlyConfirmed() {
        require(
            claimConfirmation[administrator] &&
                claimConfirmation[farmer] &&
                claimConfirmation[contracter],
            "Could not claim"
        );
        _;
    }

    /**
     * @dev Constructor.
     */
    constructor(
        address _farmer,
        address _contracter,
        address _administrator
    ) public {
        farmer = _farmer;
        contracter = _contracter;
        administrator = _administrator;
    }

    /**
     * @dev Deposit funds. Fallback function which receive ethers and emits the event
     */
    function() external payable onlyOwners {
        require(!lock, "Vault is locked");
        emit Deposit(msg.sender, msg.value);
        depositedAmount[msg.sender] += msg.value;
    }

    /**
     * @dev Withdraw funds. To withdraw the claimed amount set by administrator
     * which is approved by both parties
     */
    function withdraw() external onlyOwners onlyConfirmed {
        require(!lock, "Vault is locked");

        uint256 amount = amountToClaim[msg.sender];
        //reset deposits after claim
        depositedAmount[msg.sender] = 0;

        emit Withdraw(msg.sender, amount);

        require(msg.sender.send(amount));
    }

    /**
     * @dev Use to settle the trade by updating the amount to be claimed by each party
     * @param target The target address to set the claim amount.
     * @param amount The amount to be claimed by target
     */
    function settle(address target, uint256 amount) external onlyAdministrator {
        require(
            target == farmer || target == contracter,
            "Invalid target address"
        );
        amountToClaim[target] = amount;
        claimConfirmation[administrator] = true;
    }

    /**
     * @dev Use to confirm the amount to be claimed by each party
     */
    function confirmClaimAmount() external onlyOwners {
        claimConfirmation[msg.sender] = true;
    }

    /**
     * @dev Used for locking funds
     */
    function lockVault(bool _lock) external onlyAdministrator {
        lock = _lock;
    }
}
