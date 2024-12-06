// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract DOUBLOON is ERC20, ERC20Burnable, Ownable, ReentrancyGuard {
    uint256 public constant MAX_SUPPLY = 1e9 * (10 ** 18);

    // Allocation breakdown constants
    uint256 public constant LIQUIDITY_ALLOCATION = (MAX_SUPPLY * 50) / 100; // 50% of total supply
    uint256 public constant COMMUNITY_REWARDS_ALLOCATION = (MAX_SUPPLY * 15) / 100; // 15% of total supply
    uint256 public constant CHARITY_ALLOCATION = (MAX_SUPPLY * 15) / 100; // 15% of total supply
    uint256 public constant FOUNDERS_ALLOCATION = (MAX_SUPPLY * 9) / 100; // 9% of total supply
    uint256 public constant DEVELOPMENT_ALLOCATION = (MAX_SUPPLY * 11) / 100; // 11% of total supply
    uint256 public constant INITIAL_UNLOCK_FOUNDERS_ALLOCATION = (FOUNDERS_ALLOCATION * 10) / 100; // Initial unlock of 10% for founders
    uint256 public constant MONTHLY_VESTING_AMOUNT = (FOUNDERS_ALLOCATION * 10) / 100; // Monthly vesting of 10% per founder over 9 months

    // Founders addresses
    address public constant NAS = 0x4620Ac1cB2340AbDE6ceAAED9669d1abF577C9E6;
    address public constant ANT = 0xC22E5e94e8D9fC2068cF17E23c1BEba062cD7824;
    address public constant JAY = 0x53fFc861a2a3013B7bEcb4306048171598fcC637;

    // Wallet addresses
    address public constant OWNER_WALLET = 0x9e0723C3bEeA8A0E24778adbd8Fd9c6A8DC19Caa;
    address public constant LIQUIDITY_WALLET = 0x5FddA9D1Fb8CdAd39c7Ed80f8A5AFFfF11b32df0;
    address public constant DEVELOPMENT_WALLET = 0xDEc862dD2684EdeBf0b70f90Ac628390e691E31e;
    address public constant CHARITY_WALLET = 0xd54B048Eb1e4b030964A064F4933c9920F0717A0;
    address public constant COMMUNITY_REWARDS_WALLET = 0x5B8aD5a11b230f6D8CeB62f3E7c0eb9d8a3cc1b3;

    uint256 public startVestingTime;
    mapping(address => uint256) public vestedTokensClaimed;

    constructor() ERC20("DOUBLOON", "DBLN") Ownable(msg.sender) {
        _mint(address(this), MAX_SUPPLY);
        startVestingTime = block.timestamp;

        // Initial allocations
        _transfer(address(this), CHARITY_WALLET, CHARITY_ALLOCATION);
        _transfer(address(this), LIQUIDITY_WALLET, LIQUIDITY_ALLOCATION);
        _transfer(address(this), DEVELOPMENT_WALLET, DEVELOPMENT_ALLOCATION);

        // Immediate initial unlock for founders
        uint256 perFounderInitialAllocation = INITIAL_UNLOCK_FOUNDERS_ALLOCATION / 3;
        _transfer(address(this), NAS, perFounderInitialAllocation);
        _transfer(address(this), ANT, perFounderInitialAllocation);
        _transfer(address(this), JAY, perFounderInitialAllocation);
    }

    function transferWithTax(address recipient, uint256 amount) public {
        address sender = _msgSender();
        require(balanceOf(sender) >= amount, "Insufficient balance");

        // Calculate 4% total tax
        uint256 totalTax = (amount * 4) / 100;

        // Split the tax: 1% burn, 1% to charity, 1% to liquidity, 1% to development
        uint256 burnAmount = totalTax / 4; // 1% of the amount
        uint256 charityFee = totalTax / 4; // 1% of the amount
        uint256 liquidityFee = totalTax / 4; // 1% of the amount
        uint256 developmentFee = totalTax - burnAmount - charityFee - liquidityFee; // Remaining 1% to development
        uint256 amountAfterTax = amount - totalTax;

        // Burn 1% of the amount
        _burn(sender, burnAmount);

        // Transfer fees to respective wallets
        super._transfer(sender, CHARITY_WALLET, charityFee);
        super._transfer(sender, LIQUIDITY_WALLET, liquidityFee);
        super._transfer(sender, DEVELOPMENT_WALLET, developmentFee);

        // Transfer remaining amount to recipient
        super._transfer(sender, recipient, amountAfterTax);
    }

    function claimVestedTokens() public nonReentrant {
        require(msg.sender == NAS || msg.sender == ANT || msg.sender == JAY, "Caller is not a founder");
        require(block.timestamp >= startVestingTime, "Vesting period has not started yet");

        uint256 monthsElapsed = (block.timestamp - startVestingTime) / 30 days;
        require(monthsElapsed > 0, "No tokens available for release yet");
        require(monthsElapsed <= 9, "Vesting period is over");

        uint256 totalClaimable = monthsElapsed * MONTHLY_VESTING_AMOUNT;
        uint256 amountToClaim = totalClaimable - vestedTokensClaimed[msg.sender];
        require(amountToClaim > 0, "No tokens available to claim");

        vestedTokensClaimed[msg.sender] += amountToClaim;
        _transfer(address(this), msg.sender, amountToClaim);
    }

    function allocatePublicTokens(address to, uint256 amount) public onlyOwner {
        require(amount <= COMMUNITY_REWARDS_ALLOCATION, "Amount exceeds community rewards allocation");
        _transfer(address(this), to, amount);
    }

    function allocateCharityTokens(address to, uint256 amount) public onlyOwner {
        require(amount <= CHARITY_ALLOCATION, "Amount exceeds charity allocation");
        _transfer(CHARITY_WALLET, to, amount);
    }

    function allocateCommunityRewards(address to, uint256 amount) public onlyOwner {
        require(amount <= COMMUNITY_REWARDS_ALLOCATION, "Amount exceeds community rewards allocation");
        _transfer(COMMUNITY_REWARDS_WALLET, to, amount);
    }
}
