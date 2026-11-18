# Source parameters — v1.20

These names and initial values were checked in the released MT4 and MT5 source. Defaults are **not broker-verified**.

| Input | Default | Purpose |
| --- | --- | --- |
| InpSizing | TTC_RISK_PERCENT | Equity-risk % or fixed lots |
| InpRiskPercent | 1.00 | Budget as % of equity |
| InpFixedLots | 0.10 | Fixed trade volume, lots |
| InpCommissionRoundTurnPerLot | 0.00 | Commission to open and close 1 lot, deposit currency |
| InpCommissionVerified | false | Confirm fee amount, even when zero |
| InpExtraFeesRoundTurnPerLot | 0.00 | Additional round-turn fees per lot |
| InpSlippageRoundTurnPoints | 0.00 | Assumed round-trip slippage in symbol points |
| InpInitialStopATRMultiplier | 1.20 | ATR(14) initial-stop distance |
| InpInitialTargetRR | 2.00 | Initial target/stop ratio |
| InpFallbackStopPoints | 200 | Stop distance when ATR unavailable |
| InpPanelX / InpPanelY | 16 / 26 | Dashboard position in pixels |
| InpShowBreakEvenLine | true | Show projected break-even line |
| InpWarnCostTargetPercent | 15.0 | Warn if costs exceed % of target (0=off) |
| InpUpdateSeconds | 3 | Refresh seconds, supported 1–60 |
| InpSwapSource | TTC_SWAP_AUTO | Off / automatic broker estimate / manual |
| InpRolloverDays | 3 | Broker-calendar days ahead, allowed 0–30 |
| InpManualSwapPerLotNight | −5.0 | Manual nightly swap per lot, deposit currency |
| InpTripleSwapWeekday | 3 | Manual triple-day default, Wednesday |
| InpSwapStartWeekdayOverride | −1 | Automatic weekday unless overridden |
| InpSwapCalendarVerified | false | Verify broker rollover and triple-day calendar |
| InpIncludeSwapInNetRR | false | Include eligible swap explicitly |
| InpUseManualSymbolSpecs | false | Manual/offline contract specification simulation |
| InpManualTickSizePrice | 0.00001 | Manual price increment |
| InpManualTickValueProfit | 1.0 | Manual profit tick value |
| InpManualTickValueLoss | 1.0 | Manual loss tick value |
| InpManualMinLot / MaxLot / LotStep | 0.01 / 100 / 0.01 | Manual volume limits |
| InpManualAccountCurrency | USD | Fallback display currency |
| InpCollectSpreadStats | true | Gather fresh spread samples by server time |
| InpShowInsightsPanel | true | Show overnight/spread sidebar |

**MT4-specific:** InpMT4TickSizeUnit = TTC_TICK_AUTO helps interpret different MT4 tick-size unit conventions. This input does not exist in the MT5 source.

Commission and swap defaults must be verified with the broker. See [cost model](cost-model.md) and [FOREXREVIEW.TOP guide](https://forexreview.top/2026/11/15/true-trading-cost-net-risk-reward-mt4-mt5/).
