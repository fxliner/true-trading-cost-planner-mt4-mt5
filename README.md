# True Trading Cost Planner - MT4 and MT5

Free open-source MetaTrader 4 / MetaTrader 5 trade-planning indicator, version 1.20.

Plan a hypothetical BUY or SELL with interactive entry, stop-loss and take-profit levels. Estimate position size using an equity risk percentage or fixed lots, then review gross and net risk/reward, break-even price and modeled trading costs.

## Main features

- Drag entry, stop and target lines directly on the chart, with BUY / SELL / RESET controls.
- Model round-turn commission, additional fees and assumed slippage.
- Compare gross versus net potential risk and reward and estimated net R:R.
- Use broker symbol tick specifications where available, monitor current spread and optionally project swaps.
- See calculation warnings for stale quotes, unverified fee assumptions and invalid price levels.

**Important:** Results are estimates and depend on broker contract terms, account currency, actual execution and user inputs. The tool does not trade automatically or predict market direction.

## Latest download

Download the complete MT4/MT5 package from [GitHub Releases](https://github.com/fxliner/true-trading-cost-planner-mt4-mt5/releases/latest). The package includes source code, precompiled indicators, screenshots and the MIT license.

## Installation

1. Download the latest ZIP from Releases or SourceForge Files.
2. In MetaTrader use File > Open Data Folder.
3. For MT4, copy the EX4 from bin/MT4 into MQL4/Indicators. For MT5, copy the EX5 from bin/MT5 into MQL5/Indicators.
4. Restart or refresh Navigator > Indicators.
5. Attach to a chart, set commissions and fees according to your broker, then select BUY or SELL and drag the levels.

MQL4 and MQL5 source code are provided in the respective platform folders. See LICENSE for MIT terms.

## Screenshot

![Trade planning and cost calculations in MT5](Screenshot_MT5_TradingCost.png)

## Documentation and official downloads
- Developer hub: https://forexreview.top/
- Detailed installation and calculation guide: https://forexreview.top/2026/11/15/true-trading-cost-net-risk-reward-mt4-mt5/
- Official MT5 Market download: https://www.mql5.com/en/market/product/209567
- MQL5 Code Base: https://www.mql5.com/en/code/79598 and https://www.mql5.com/en/code/79600
- Developer profile: https://www.mql5.com/en/users/fxliner

For support, open a GitHub Issue or comment on the MQL5 product. Share symbol, account currency, input settings and an anonymized screenshot.

**Risk notice:** No guarantee of profitability. This indicator is for planning and education, not automated order placement.
