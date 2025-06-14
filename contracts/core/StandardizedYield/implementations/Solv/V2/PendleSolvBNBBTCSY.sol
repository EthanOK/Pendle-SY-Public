// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./PendleSolvSYBaseV2.sol";

contract PendleSolvBNBBTCSY is PendleSolvSYBaseV2 {
    address public constant SOLV_BNB_ROUTER_V2 = 0x67035877F5c12202c387d1698274C2aBF28F3678;

    address public constant BTC = 0x7130d2A12B9BCbFAe4f2634d864A1Ee1Ce3Ead9c;
    address public constant SOLV_BTC = 0x4aae823a6a0b376De6A78e74eCC5b079d38cBCf7;
    address public constant SOLV_BTC_BNB = 0x6c948A4C31D013515d871930Fe3807276102F25d;

    address public constant NAV_ORACLE = 0x9C491539AeC346AAFeb0bee9a1e9D9c02AB50889;
    bytes32 public constant MAIN_POOL_ID = 0x02228958e4f53e94e09cc0afd49939bf93af0b991889fa5fe761672c0e9c3021;

    address[] internal FULL_PATH;

    constructor() PendleSolvSYBaseV2(SOLV_BNB_ROUTER_V2, SOLV_BTC_BNB) {}

    function initialize() external initializer {
        __SYBaseUpg_init("SY SolvBTC.BNB", "SY-SolvBTC.BNB");
        _safeApproveInf(BTC, SOLV_BNB_ROUTER_V2);
        _safeApproveInf(SOLV_BTC, SOLV_BNB_ROUTER_V2);
        _safeApproveInf(SOLV_BTC_BNB, SOLV_BNB_ROUTER_V2);
        FULL_PATH = ArrayLib.create(BTC, SOLV_BTC, SOLV_BTC_BNB);
    }

    function _previewDeposit(
        address tokenIn,
        uint256 amountTokenToDeposit
    ) internal view virtual override returns (uint256 /*amountSharesOut*/) {
        for (uint256 i = 0; i + 1 < FULL_PATH.length; ++i) {
            if (tokenIn == FULL_PATH[i]) {
                address nxtToken = FULL_PATH[i + 1];
                bytes32 poolId = ISolvRouterV2(solvRouterV2).poolIds(nxtToken, tokenIn);
                (tokenIn, amountTokenToDeposit) = (nxtToken, _previewSolvConvert(poolId, amountTokenToDeposit));
            }
        }
        assert(tokenIn == SOLV_BTC_BNB);
        return amountTokenToDeposit;
    }

    function exchangeRate() public view virtual override returns (uint256) {
        (uint256 rate, ) = ISolvOracle(NAV_ORACLE).getSubscribeNav(MAIN_POOL_ID, block.timestamp);
        return rate;
    }

    function getTokensIn() public view virtual override returns (address[] memory) {
        return FULL_PATH;
    }

    function isValidTokenIn(address token) public view virtual override returns (bool) {
        return token == BTC || token == SOLV_BTC_BNB || token == SOLV_BTC;
    }

    function assetInfo()
        external
        view
        override
        returns (AssetType assetType, address assetAddress, uint8 assetDecimals)
    {
        return (AssetType.TOKEN, BTC, IERC20Metadata(BTC).decimals());
    }
}
