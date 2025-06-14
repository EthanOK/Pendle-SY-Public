// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

import "../../SYBaseWithRewardsUpg.sol";
import "../../../../interfaces/AaveV3/IAaveStkGHO.sol";
import "../../../../interfaces/Angle/IAngleDistributor.sol";
import "./PendleAaveMerit.sol";

contract PendleSGHOSY is SYBaseWithRewardsUpg, PendleAaveMerit {
    using PMath for uint256;

    event ClaimedOffchainGHO(uint256 amountClaimed);

    address public constant STKGHO = 0x1a88Df1cFe15Af22B3c4c783D4e6F7F9e0C1885d;
    address public constant GHO = 0x40D16FC0246aD3160Ccc09B8D0D3A2cD28aE6C2f;
    address public constant AAVE = 0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9;
    bytes32 public constant ZERO_REWARD_ERROR = 0x33d2eb294587ef7b32eb48e48695ebfec45a9c8922ec7d1c444cfad1fb208e8d;

    constructor(address _offchainReceiver) SYBaseUpg(STKGHO) PendleAaveMerit(_offchainReceiver) {}

    function initialize() external initializer {
        __SYBaseUpg_init("SY staked GHO", "SY-sGHO");
        _safeApproveInf(GHO, STKGHO);
    }

    function _deposit(address tokenIn, uint256 amountDeposited) internal virtual override returns (uint256) {
        if (tokenIn == STKGHO) {
            return amountDeposited;
        }

        uint256 preBalance = _selfBalance(STKGHO);
        IAaveStkGHO(STKGHO).stake(address(this), amountDeposited);
        return _selfBalance(STKGHO) - preBalance;
    }

    function _redeem(
        address receiver,
        address /*tokenOut*/,
        uint256 amountSharesToRedeem
    ) internal virtual override returns (uint256) {
        _transferOut(STKGHO, receiver, amountSharesToRedeem);
        return amountSharesToRedeem;
    }

    /*///////////////////////////////////////////////////////////////
                               EXCHANGE-RATE
    //////////////////////////////////////////////////////////////*/

    function exchangeRate() public view virtual override returns (uint256) {
        return PMath.ONE.divDown(IAaveStkGHO(STKGHO).getExchangeRate());
    }

    /*///////////////////////////////////////////////////////////////
                               REWARDS-RELATED
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev See {IStandardizedYield-getRewardTokens}
     */
    function _getRewardTokens() internal pure override returns (address[] memory) {
        return ArrayLib.create(AAVE);
    }

    function _redeemExternalReward() internal override {
        try IAaveStkGHO(STKGHO).claimRewards(address(this), type(uint256).max) {} catch Error(
            string memory errorString
        ) {
            // StkGHO claim reverts when claimable amount = 0, meaning two sy transfers in diff block/same timestamp would revert.
            // This is expected to not happen at all on ETH mainnet but just to be sure.
            if (keccak256(abi.encodePacked(errorString)) != ZERO_REWARD_ERROR) {
                revert(errorString);
            }
        }
    }

    /*///////////////////////////////////////////////////////////////
                MISC FUNCTIONS FOR METADATA
    //////////////////////////////////////////////////////////////*/

    function _previewDeposit(
        address tokenIn,
        uint256 amountTokenToDeposit
    ) internal view override returns (uint256 amountSharesOut) {
        if (tokenIn == STKGHO) return amountTokenToDeposit;
        return IAaveStkGHO(STKGHO).previewStake(amountTokenToDeposit);
    }

    function _previewRedeem(
        address /*tokenOut*/,
        uint256 amountSharesToRedeem
    ) internal view override returns (uint256 amountTokenOut) {
        return amountSharesToRedeem;
    }

    function getTokensIn() public view virtual override returns (address[] memory) {
        return ArrayLib.create(GHO, STKGHO);
    }

    function getTokensOut() public view virtual override returns (address[] memory) {
        return ArrayLib.create(STKGHO);
    }

    function isValidTokenIn(address token) public view virtual override returns (bool) {
        return token == GHO || token == STKGHO;
    }

    function isValidTokenOut(address token) public view virtual override returns (bool) {
        return token == STKGHO;
    }

    function assetInfo() external view returns (AssetType assetType, address assetAddress, uint8 assetDecimals) {
        return (AssetType.TOKEN, GHO, IERC20Metadata(GHO).decimals());
    }
}
