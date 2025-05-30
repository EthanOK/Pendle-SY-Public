// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../../SYBaseUpg.sol";
import "../../../../interfaces/Reservoir/IReservoirCreditEnforcer.sol";
import "../../../../interfaces/Reservoir/IReservoirPSM.sol";

contract PendleReservoirUSDSY is SYBaseUpg {
    address public constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address public constant RUSD = 0x09D4214C03D01F49544C0448DBE3A27f768F2b34;

    address public constant PSM = 0x4809010926aec940b550D34a46A52739f996D75D;
    address public constant CREDIT_ENFORSER = 0x04716DB62C085D9e08050fcF6F7D775A03d07720;

    uint256 public constant DECIMAL_FACTOR = 10 ** 12;

    constructor() SYBaseUpg(RUSD) {}

    function initialize() external initializer {
        __SYBaseUpg_init("SY Reservoir Protocol RUSD", "SY-RUSD");

        _safeApproveInf(RUSD, PSM);
        _safeApproveInf(USDC, PSM);
    }

    /*///////////////////////////////////////////////////////////////
                    DEPOSIT/REDEEM USING BASE TOKENS
    //////////////////////////////////////////////////////////////*/

    function _deposit(
        address tokenIn,
        uint256 amountDeposited
    ) internal virtual override returns (uint256 /*amountSharesOut*/) {
        if (tokenIn == USDC) {
            return IReservoirCreditEnforcer(CREDIT_ENFORSER).mintStablecoin(amountDeposited) * DECIMAL_FACTOR;
        }
        return amountDeposited;
    }

    function _redeem(
        address receiver,
        address tokenOut,
        uint256 amountSharesToRedeem
    ) internal override returns (uint256) {
        if (tokenOut == USDC) {
            uint256 amtOut = amountSharesToRedeem / DECIMAL_FACTOR;
            IReservoirPSM(PSM).redeem(receiver, amtOut);
            return amtOut;
        } else {
            _transferOut(tokenOut, receiver, amountSharesToRedeem);
            return amountSharesToRedeem;
        }
    }

    /*///////////////////////////////////////////////////////////////
                               EXCHANGE-RATE
    //////////////////////////////////////////////////////////////*/

    function exchangeRate() public view virtual override returns (uint256) {
        return PMath.ONE;
    }

    /*///////////////////////////////////////////////////////////////
                MISC FUNCTIONS FOR METADATA
    //////////////////////////////////////////////////////////////*/

    function _previewDeposit(
        address tokenIn,
        uint256 amountTokenToDeposit
    ) internal pure override returns (uint256 /*amountSharesOut*/) {
        return amountTokenToDeposit * (tokenIn == USDC ? DECIMAL_FACTOR : 1);
    }

    function _previewRedeem(
        address tokenOut,
        uint256 amountSharesToRedeem
    ) internal pure override returns (uint256 /*amountTokenOut*/) {
        return amountSharesToRedeem / (tokenOut == USDC ? DECIMAL_FACTOR : 1);
    }

    function getTokensIn() public pure override returns (address[] memory res) {
        return ArrayLib.create(USDC, RUSD);
    }

    function getTokensOut() public pure override returns (address[] memory res) {
        return ArrayLib.create(USDC, RUSD);
    }

    function isValidTokenIn(address token) public pure override returns (bool) {
        return token == USDC || token == RUSD;
    }

    function isValidTokenOut(address token) public pure override returns (bool) {
        return token == USDC || token == RUSD;
    }

    function assetInfo() external view returns (AssetType assetType, address assetAddress, uint8 assetDecimals) {
        return (AssetType.TOKEN, RUSD, IERC20Metadata(RUSD).decimals());
    }
}
