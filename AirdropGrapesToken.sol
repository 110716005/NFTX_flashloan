// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract AirdropGrapesToken is Ownable, Pausable {

    using SafeERC20 for IERC20;
    IERC20 public immutable grapesToken;

    ERC721Enumerable public immutable alpha;

    uint256 public immutable ALPHA_DISTRIBUTION_AMOUNT;

    uint256 public totalClaimed;

    uint256 public claimDuration;
    uint256 public claimStartTime;

    mapping (uint256 => bool) public alphaClaimed;

    event ClaimStart(
        uint256 _claimDuration,
        uint256 _claimStartTime
    );

    event AlphaClaimed(
        uint256 indexed tokenId,
        address indexed account,
        uint256 timestamp
    );

    event AirDrop(
        address indexed account,
        uint256 indexed amount,
        uint256 timestamp
    );


    constructor(
        address _grapesTokenAddress,
        address _alphaContractAddress,
        uint256 _ALPHA_DISTRIBUTION_AMOUNT
    ) {
        require(_grapesTokenAddress != address(0), "The Grapes token address can't be 0");
        require(_alphaContractAddress != address(0), "The Alpha contract address can't be 0");

        grapesToken = IERC20(_grapesTokenAddress);
        alpha = ERC721Enumerable(_alphaContractAddress);
        ALPHA_DISTRIBUTION_AMOUNT = _ALPHA_DISTRIBUTION_AMOUNT;

        _pause();
    }

    function startClaimablePeriod(uint256 _claimDuration) external onlyOwner whenPaused {
        require(_claimDuration > 0, "Claim duration should be greater than 0");

        claimDuration = _claimDuration;
        claimStartTime = block.timestamp;

        _unpause();

        emit ClaimStart(_claimDuration, claimStartTime);
    }

    function pauseClaimablePeriod() external onlyOwner {
        _pause();
    }

    function claimTokens() external whenNotPaused {
        require(block.timestamp >= claimStartTime && block.timestamp < claimStartTime + claimDuration, "Claimable period is finished");
        require((alpha.balanceOf(msg.sender) > 0), "Nothing to claim");

        uint256 tokensToClaim;
        uint256 gammaToBeClaim;

        (tokensToClaim, gammaToBeClaim) = getClaimableTokenAmountAndGammaToClaim(msg.sender);

        for(uint256 i; i < alpha.balanceOf(msg.sender); ++i) {
            uint256 tokenId = alpha.tokenOfOwnerByIndex(msg.sender, i);
            if(!alphaClaimed[tokenId]) {
                alphaClaimed[tokenId] = true;
                emit AlphaClaimed(tokenId, msg.sender, block.timestamp);
            }
        }

        uint256 currentGammaClaimed;

        grapesToken.safeTransfer(msg.sender, tokensToClaim);

        totalClaimed += tokensToClaim;
        emit AirDrop(msg.sender, tokensToClaim, block.timestamp);
    }

    function getClaimableTokenAmount(address _account) public view returns (uint256) {
        uint256 tokensAmount;
        (tokensAmount,) = getClaimableTokenAmountAndGammaToClaim(_account);
        return tokensAmount;
    }

    function getClaimableTokenAmountAndGammaToClaim(address _account) private view returns (uint256, uint256)
    {
        uint256 unclaimedAlphaBalance;
        for(uint256 i; i < alpha.balanceOf(_account); ++i) {
            uint256 tokenId = alpha.tokenOfOwnerByIndex(_account, i);
            if(!alphaClaimed[tokenId]) {
                ++unclaimedAlphaBalance;
            }
        }
        uint256 unclaimedBetaBalance;

        uint256 tokensAmount = (unclaimedAlphaBalance * ALPHA_DISTRIBUTION_AMOUNT) * (10 ** 18);

        return (tokensAmount, 0);
    }

    function min(uint256 a, uint256 b) private pure returns(uint256) {
        if (a <= b) {
            return a;
        } else {
            return b;
        }
    }

    function claimUnclaimedTokens() external onlyOwner {
        require(block.timestamp > claimStartTime + claimDuration, "Claimable period is not finished yet");
        grapesToken.safeTransfer(owner(), grapesToken.balanceOf(address(this)));

        uint256 balance = address(this).balance;
        if (balance > 0) {
            Address.sendValue(payable(owner()), balance);
        }
    }
}