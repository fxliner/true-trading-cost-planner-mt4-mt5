# Manual validation checklist — v1.20

This is a **test plan**, not a certification that all devices and brokers passed.

- [ ] Load MT4 EX4 in MT4 and MT5 EX5 in MT5; verify expected indicator dashboard and journal.
- [ ] Confirm it never places an order.
- [ ] Drag entry/stop/target; verify BUY and SELL direction validation.
- [ ] Compare equity-risk and fixed-lot sizing using known broker minimum, maximum and step volume.
- [ ] Verify commission, extra fees and round-turn slippage are counted once.
- [ ] Verify Bid/Ask spread is not charged a second time.
- [ ] Verify the two broker profit/loss tick values and contract specs are interpreted correctly.
- [ ] Check gross vs net R:R, fee thresholds and approximate break-even.
- [ ] Attach during a closed market: quote should not be misrepresented as live.
- [ ] Enable/disable manual and automatic swaps with 0-day and multi-day horizons.
- [ ] Confirm unverified swap is excluded from net R:R.
- [ ] Confirm spread sample bins do not imply historical backfill.
- [ ] Compare MT4/MT5 results on the same broker/symbol with equivalent assumptions.

Report exact indicator version, terminal build, account *currency* (not number), symbol, settings and anonymized screenshot through [Issues](https://github.com/fxliner/true-trading-cost-planner-mt4-mt5/issues/new/choose).
