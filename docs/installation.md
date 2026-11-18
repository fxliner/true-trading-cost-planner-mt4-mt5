# Installation

1. Download the [v1.20 release ZIP](https://github.com/fxliner/true-trading-cost-planner-mt4-mt5/releases/tag/v1.20).
2. In MetaTrader, select **File > Open Data Folder**.
3. On MT4, copy bin/MT4/TrueTradingCostNetRR_MT4_CodeBase.ex4 to MQL4/Indicators; on MT5 copy bin/MT5/TrueTradingCostNetRR_MT5.ex5 to MQL5/Indicators.
4. Restart or refresh **Navigator > Indicators**, then attach the indicator to a chart.
5. Verify the broker's commission per round trip and other fees, choose sizing, and inspect net R:R.

Do not mix EX4 and EX5 binaries between platforms. Source code is in MQL4/Indicators and MQL5/Indicators inside the ZIP.

## Troubleshooting

- Missing from Navigator: inspect the actual Data Folder, extension and terminal build.
- Stale quote warning: the tool waits for a new tick after attachment; a cached quote is not a live quote.
- No position: risk budget may be below the broker minimum lot or symbol tick value may be unavailable.
- Invalid entry/stop/target: BUY requires stop < entry < target; SELL requires target < entry < stop.
- Net R:R differs: confirm broker tick value, account currency, round-turn fees, slippage *in points* and swap inclusion.
- MT4 includes an MT4-only tick-size-unit option.

[Full FOREXREVIEW.TOP guide](https://forexreview.top/2026/11/15/true-trading-cost-net-risk-reward-mt4-mt5/).
