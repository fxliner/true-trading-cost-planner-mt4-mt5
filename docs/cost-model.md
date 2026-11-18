# Cost model — v1.20

The indicator estimates hypothetical risk and reward, **not** guaranteed execution outcomes.

For an instrument with price tick size T, loss tick value Vloss and profit tick value Vprofit:

- Gross loss per lot = |entry − stop| / T × Vloss.
- Gross reward per lot = |target − entry| / T × Vprofit.
- Slippage per lot = round-trip slippage points × symbol point size / T × Vloss.
- Total modeled cost per lot = round-trip commission + extra round-trip fees + modeled slippage (nonnegative values).

The **spread is already in executable Bid/Ask assumptions** and is displayed separately; it is not added again as an additional charge.

## Sizing and net totals

Risk budget = equity × risk percentage / 100.

Risk-based lots = risk budget / (gross loss per lot + costs per lot + any eligible negative swap per lot), rounded down to a permitted broker lot step. A budget below minimum lot risk can produce zero lots.

- Gross risk = gross loss per lot × lots.
- Gross reward = gross reward per lot × lots.
- Net risk = gross risk + costs + any eligible negative swap.
- Net reward = gross reward − costs + any eligible swap (positive or negative).
- Net R:R = net reward / net risk, when net risk > 0.

Positive swap **does not reduce stop-risk budget**. Swap is excluded by default; it is included only when the source and horizon are usable and both calendar-verification and inclusion inputs are explicitly enabled.

Break-even is an approximate entry adjustment for modeled costs and eligible swap; it is not a guaranteed executable price.

## Quote and spread caution

Quotes are initially treated as cached until an actual new tick is observed. Disconnection or an observed tick older than approximately 5 minutes triggers a stale warning. Spread-observation panels show samples accumulated since attachment, not a backfilled broker spread database.

[Further education and broker cost comparisons](https://forexreview.top/).
