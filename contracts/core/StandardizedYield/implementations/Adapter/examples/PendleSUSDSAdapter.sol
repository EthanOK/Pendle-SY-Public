// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

import "../../../../../interfaces/Sky/ISkyConverter.sol";
import "../../../../../interfaces/IStandardizedYieldAdapter.sol";
import "../../../../../interfaces/IERC4626.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract PendleSUSDSAdapter is IStandardizedYieldAdapter {
    using SafeERC20 for IERC20;

    address public constant SUSDS = 0xa3931d71877C0E7a3148CB7Eb4463524FEc27fbD;
    address public constant CONVERTER = 0x3225737a9Bbb6473CB4a45b7244ACa2BeFdB276A;
    address public constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address public constant USDS = 0xdC035D45d973E3EC169d2276DDab16f1e407384F;
    address public constant PIVOT_TOKEN = USDS;

    constructor() {
        IERC20(DAI).forceApprove(CONVERTER, type(uint256).max);
        IERC20(USDS).forceApprove(CONVERTER, type(uint256).max);
    }

    function convertToDeposit(
        address /*tokenIn*/,
        uint256 amountTokenIn
    ) external override returns (uint256 amountOut) {
        // assert(tokenIn == DAI);
        ISkyConverter(CONVERTER).daiToUsds(msg.sender, amountTokenIn);
        amountOut = amountTokenIn;
    }

    function convertToRedeem(
        address /*tokenOut*/,
        uint256 amountPivotToken
    ) external override returns (uint256 amountOut) {
        // assert(tokenOut == DAI);
        ISkyConverter(CONVERTER).usdsToDai(msg.sender, amountPivotToken);
        return amountPivotToken;
    }

    function previewConvertToDeposit(
        address /*tokenIn*/,
        uint256 amountTokenIn
    ) external pure override returns (uint256 amountOut) {
        // assert(tokenIn == DAI);
        return amountTokenIn;
    }

    function previewConvertToRedeem(
        address /*tokenOut*/,
        uint256 amountPivotToken
    ) external view override returns (uint256 amountOut) {
        // assert(tokenOut == DAI);
        return amountPivotToken;
    }

    function getAdapterTokensDeposit() external pure override returns (address[] memory tokens) {
        tokens = new address[](1);
        tokens[0] = DAI;
    }

    function getAdapterTokensRedeem() external pure override returns (address[] memory tokens) {
        tokens = new address[](1);
        tokens[0] = DAI;
    }
}
