# Transparent probability model

There is one configuration: `data/probability.json`. Both the game and the
Monte Carlo script instantiate `scripts/slot_machine.gd` and call its `spin()`.
The engine uses Godot's RandomNumberGenerator. Animation never draws from that
RNG or changes a result. Themes, cosmetics, achievements, speed, elapsed time,
credit balance and previous results have no effect on odds.

## Cell sampling and paylines

Each of the 15 cells is sampled independently with these weights, totaling 100:

| Bone | Ball | Paw | Bowl | Dachshund | Husky | Golden biscuit | Doghouse | Wild | Collar | Bonus bone |
|---|---|---|---|---|---|---|---|---|---|---|
|30|19|14|10|8|6|4|3|3|1|2|

Reels are independent weighted draws, not simulated physical reel strips.
An active line needs 3, 4 or 5 matches from the leftmost column. Wild substitutes
for IDs 0–8 only. All candidate symbols are considered and only the highest
award pays on each line. Multiple lines can pay on the same spin. A collar is a
decorative non-paying symbol; the progressive is an independent event, not a
five-collar combination. Bonus bones are scatters, not line-paying symbols.

Using row 0 = top, 1 = middle, 2 = bottom:

1. `[1,1,1,1,1]`
2. `[0,0,0,0,0]`
3. `[2,2,2,2,2]`
4. `[0,0,1,2,2]`
5. `[2,2,1,0,0]`

Bets 1, 2, 3 activate the first 1, 2, 3 lines. Bet 4 activates all five.

## Resolving the five-lines-for-four RTP constraint

Five *full one-credit* paylines for four credits would give a 25% increase in
line RTP. It cannot coexist with the same near-103% overall return at every
wager when line wins supply most of the return.

This implementation splits the total wager equally across active lines. The
line stake is 1 at Bets 1–3 and 0.8 at Bet 4. Bet 4 also multiplies line awards
by 1.015, an explicit 1.5% Max Bet Bonus. The bonus is public in the UI. Symbol,
bonus and jackpot probabilities do not change. This is an intentional adjustment
to the full-price interpretation of the suggested max-bet rule.

## Paytable and exact expectation

`payouts[symbol][matches-3] × line_scale × line_stake` is the payout, with the
extra multiplier at Bet 4. `line_scale = 4.321746009844741`. The UI shows the
resulting multipliers, not the unscaled intermediate table. Values are
fractional; credits are double-precision internally and displayed to two decimals.

| Symbol | 3 matches | 4 matches | 5 matches |
|---|---:|---:|---:|
|Bone|8.643492×|21.608730×|51.860952×|
|Ball|10.804365×|25.930476×|64.826190×|
|Paw|12.965238×|30.252222×|77.791428×|
|Bowl|17.286984×|43.217460×|108.043650×|
|Dachshund|21.608730×|51.860952×|151.261110×|
|Husky|25.930476×|64.826190×|172.869840×|
|Golden biscuit|30.252222×|77.791428×|259.304761×|
|Doghouse|34.573968×|86.434920×|345.739681×|
|Wild puppy|34.573968×|86.434920×|345.739681×|

Payouts are larger than the illustrative request because independent multi-symbol
reels have a modest hit rate. They were calibrated by exact expectation and
validated by simulation, rather than adopting the example paytable unchanged.

`verify_math.gd` enumerates all 11^5 possible lines using the production evaluator.
It obtains per-credit line expectation **L = 0.959001426067116** and single-line
hit probability **5.6125%**. It fails the build if derived RTP disagrees with the
configuration or falls outside 102–104%.

## Free spins

For K ~ Binomial(15, 0.02), K=3 awards 5 spins, K=4 awards 8, K>=5 awards 10.
The probability of a trigger on an eligible spin is **0.3039374563%**, about
1 in 329.01. Expected child spins per eligible spin:

`m = Σ(k=3..15) P(K=k) × reward(k) = 0.0157621418060304`.

Paid spins have generation 0; their children have generation 1. Generation 6
spins still pay normally, can win jackpots and bonuses, but cannot retrigger.
This guarantees a finite retrigger tree without relying on an arbitrary runtime
loop limit. The exact expected number of total spins from a paid spin is:

`F = Σ(g=0..6) m^g = 1.0160145656606945`.

Each free-spin ticket retains the triggering wager. All 15 cells are freshly
sampled. Free spins deduct zero credits. Stop/pause does not discard the queue.

## Bonus and progressive

Every paid or free spin independently triggers Dog Park with probability **1%**.
The equally likely prizes are 2, 3, 4 or 7 times total wager, giving mean 4×.
The cosmetic house choice reveals the pre-drawn prize, with no wrong choice and
no purchases. A bonus does not add extra free spins or alter the symbol grid.
Every third bonus helps unlock a cosmetic.

Every paid or free spin independently hits the jackpot with probability
**1/40,000 = 0.0025%**. Expected waiting time is 40,000 total spins; probability
of at least one hit after n spins is `1 - (1 - 1/40000)^n` (about 63.2% at
40,000 spins). This is rare, not a promise to hit during a short session.

The pot starts at **500** and each paid wager contributes **0.005 × bet**, without
an additional player charge. All contributions are awarded at a jackpot, then
the pot resets to 500. The saved pot and queued free spins survive reloads.
Refilling credits does not reset the pot. New Game intentionally resets it.

The long-run contribution return is 0.5% of paid wagers. Jackpot base return per
paid wager is `F × jackpot_probability × 500 / bet`. Thus theoretical RTP is:

`F × (L × max_bet_factor + 0.01 × 4 + (1/40000) × 500 / bet) + 0.005`.

This includes the progressive award, the base pot and all free descendants. It
assumes eventual payout of contributions; finite runs leave a residual pot. A
finite-run contribution accounting identity is `contributions awarded + remaining
pot growth = total paid contributions`. Refills do not count as wins or wagers.

## Measured results

Godot 4.7.2; seed 20260927 plus wager; **1,000,000 paid spins per wager**, all
free descendants completed. Four million paid spins total. Raw results, exact
combination counts, deviations, median wins and session observations are in
[simulation-results.json](simulation-results.json).

|Bet|Theoretical RTP|Measured RTP|Payout hit rate|No payout|Free trigger|Bonus|Jackpot count|
|---|---:|---:|---:|---:|---:|---:|---:|
|1|103.270%|102.939%|6.544%|93.456%|0.3034%|0.9953%|19|
|2|102.635%|102.502%|11.828%|88.172%|0.3042%|1.0079%|25|
|3|102.423%|102.045%|16.741%|83.259%|0.3084%|1.0051%|21|
|4|103.779%|103.596%|23.246%|76.754%|0.3076%|0.9956%|27|

Event/hit rates use all spins, not just paid spins. A hit means a positive credit
award; a free-spin-only trigger without immediate credits is not a payout hit.
Combination counts classify each winning line by its highest-paying symbol and
length. They do not enumerate all 11^15 possible entire-screen combinations.

The simulator also reports completed intervals before a refill and the final
right-censored interval. These are **not an unbiased estimate of average time to
ruin**: positive-drift play can continue indefinitely and a few early jackpots
can dominate a very long run. The observed completed-session means (739, 754,
3911 and 77 spins) have only 1, 16, 7 and 3 completed samples respectively and
must not be presented as typical playtime. The final uncompleted sessions are
reported separately. There is no finite guaranteed session length at RTP>100%.

Rare jackpots make finite-run RTP noisy. Do not tune constants to a lucky seed
or require every Monte Carlo run to fall inside a narrow band. The exact RTP
check is deterministic. The reported seed happened to produce all four measured
returns in the requested range; longer and differently seeded runs are supported.

## Reproduce

```sh
godot --headless --path . --script scripts/verify_math.gd
godot --headless --path . --script scripts/simulate_slots.gd -- 1000000 20260927
# Optional count, seed, output path:
godot --headless --path . --script scripts/simulate_slots.gd -- 10000000 42 /tmp/results.json
```

Each count is **paid spins per wager**, so one million means four million paid
spins plus free spins. Defaults are one million and seed 20260927. Set 10,000
or 100,000 for faster exploratory runs. The first two CLI arguments are integers.
