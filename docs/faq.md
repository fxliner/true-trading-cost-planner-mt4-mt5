# FAQ

**Does True Trading Cost Planner execute trades?**  
No. It is an indicator for planning. BUY and SELL change the modeled direction, not the position on a trading account.

**Why is net R:R lower than gross R:R?**  
Modeled round-turn commissions, extra fees and slippage lower net reward and increase net risk; optional verified swap can also affect the result.

**Is spread counted twice?**  
No. The model starts from executable Bid/Ask assumptions. The spread-equivalent panel is informational, not an additional fee in the core net calculation.

**How are lots determined?**  
In percentage-risk mode, estimated risk per lot including costs divides the equity-risk budget, then volume is normalized down to allowed broker increments. Fixed lot mode uses the normalized input volume.

**Why is my lot size zero?**  
The risk budget may be below the broker's minimum lot risk, equity may be unavailable, or symbol tick values/price levels may be invalid.

**Does a zero commission input mean my broker offers free trading?**  
No. It is the unverified default. InpCommissionVerified starts false.

**When is swap included?**  
Swap is excluded from net by default; a usable source, positive horizon, verified calendar and explicit inclusion are required.

**Why does it say quotes are cached?**  
It waits to observe a new tick after attachment. Closed markets and disconnected terminals can display stale information.

**Can I use the manual-spec mode as a live signal?**  
No. It is a what-if simulation and not verified market data.

**Where are technical details?**  
See [model](cost-model.md), [parameter reference](parameters.md) and the [complete FOREXREVIEW.TOP tutorial](https://forexreview.top/2026/11/15/true-trading-cost-net-risk-reward-mt4-mt5/).
