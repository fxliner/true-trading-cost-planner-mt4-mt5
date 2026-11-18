# Hypothetical calculation examples

**These examples are not live quotes, trade records or backtest performance.**

Assume equity $10,000, 1% budget ($100), gross per-lot stop risk $120, per-lot gross reward $240, and round-turn costs (commission + extra fees + assumed slippage) $10 per lot. No swap is included.

Risk-based raw lots = 100 / (120 + 10) = 0.76923. At 0.01 lot steps, size floors to **0.76 lots**.

| Output | Amount |
| --- | ---: |
| Gross risk | $91.20 |
| Gross reward | $182.40 |
| Modeled round-trip costs | $7.60 |
| Net risk | $98.80 |
| Net reward | $174.80 |
| Gross R:R | 1:2.00 |
| Net R:R | ~1:1.77 |

Fixed-lot example: on $5,000 equity with 1% budget ($50), a requested size predicting $90 net stop risk exceeds the budget. The indicator **warns** but does not place or resize actual trades.

Optional overnight swap example: −$4 per lot at 0.50 lots is −$2 for the chosen horizon; it is included in net results only when both verified and enabled, and the swap mode/horizon are usable.

For practical installation and current broker cost considerations, see [FOREXREVIEW.TOP](https://forexreview.top/2026/11/15/true-trading-cost-net-risk-reward-mt4-mt5/).
