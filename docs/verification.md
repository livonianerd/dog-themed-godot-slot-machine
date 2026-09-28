# Verification record

## Local checks

- Godot 4.7.2 imported and parsed the project.
- Engine suite: 128 checks passed, including all wager mappings, both diagonals,
  wild exclusions, multiple wins, deductions/awards, queued wager retention,
  free costs/retriggers/generation cap, bonus award, jackpot growth/reset,
  achievements/cosmetics, versioned save/load, corrupt save recovery, refills,
  insufficient funds and reproducible seeds.
- UI integration suite passed: spin locking and completion, visible simultaneous
  wins, bonus modal, jackpot/bonus Auto Spin stops, refill buttons, settings,
  odds, statistics, collection and interaction-gated audio state.
- Exact probability enumeration agreed with configured theoretical RTP for every
  wager. The committed million-paid-spins-per-wager simulation was actually run;
  its JSON is the original measured report, not example output.
- Web, Windows x86_64 and Linux x86_64 release exports succeeded with matching
  4.7.2 templates. Linux executable launched headlessly without runtime errors.
- Chromium loaded the release under `/build/web/`, exercised spin, settings,
  odds, theme change, resizing and a landscape mobile touch spin. No script,
  failed-asset or browser console errors were reported. Screenshots were examined.
- Desktop 1280×800, resized 960×600 and landscape touch 844×390 were checked.
  Layout is letterboxed. Portrait and every physical mobile GPU are not covered.
- Browser audio is gated by interaction in the implementation and tested via
  integration assertions. Actual speaker quality is not an automated assertion.
- Release uses `OS.is_debug_build()` AND `--developer`; the ordinary release
  screen has no developer button. Engine test fixtures can still exercise debug
  outcomes headlessly, without shipping an accessible release debug menu.

## GitHub and live deployment

- [Workflow 36368929987](https://github.com/livonianerd/dog-themed-godot-slot-machine/actions/runs/36368929987)
  successfully built all three platforms, uploaded both desktop ZIPs/checksums,
  launched the Linux release, launched the Windows release on `windows-latest`,
  and deployed Pages.
- The live site at https://livonianerd.github.io/dog-themed-godot-slot-machine/
  passed Chromium assertions for Bet 4/wager deduction, spin completion, theme
  persistence across reload, jackpot persistence, resizing, landscape touch spins
  and refilling. There were no browser script or asset-loading errors.
- An initial live theme test needed a longer wait between modal interactions;
  the test now waits for layout to settle and verifies persisted state. This was
  a test timing fix, not a probability or gameplay change.
- Playwright is installed separately under `/tmp/dog-browser`; no other project
  is needed or modified by the repository or verification scripts.

## Reproduce

`bash tools/build.sh` runs exact math, unit checks and integration checks before
all exports. `tools/browser-check.cjs` exercises an HTTP-hosted Web export using
Playwright Chromium. `scripts/simulate_slots.gd` runs the actual game engine.
The simulation isn't repeated on every push; exact mathematical validation is.

## Deliberate scope and limitations

- Windows and Linux releases both passed native headless launch tests. A full
  interactive desktop GUI session on Windows has not been manually tested.
  Desktop binaries are unsigned.
- Palette variants represent the six additional breeds. The Dachshund and Husky
  have distinct original silhouettes; accessory selections are actual overlays.
- Barks/howls and music are synthesized, not studio recordings. No recorded audio
  or third-party illustration assets were introduced.
- A bonus house reveals a pre-generated award, explicitly disclosed in the game.
  It does not influence the prize; this permits atomic persistence before animation.
- Five full-credit lines for a four-credit wager would violate the near-103%
  constraint. The disclosed 0.8-credit line stake and 1.5% bonus resolve that
  conflict. See probability documentation.
- The progressive event is rare (1 in 40,000), not guaranteed in a casual session.
  Higher theoretical RTP does not imply a high per-spin hit rate.
- Completed session lengths in the simulation are strongly censored, not a promise
  of how long 100 credits lasts. The raw report includes the censored tail.
- Browser storage can be cleared externally and private browsing may not persist.
  There is no cloud save or recovery service by design.
- Portrait layout and screen-reader narration of the graphical reel canvas are
  not implemented. Keyboard, touch, contrast, numbered lines and motion/audio
  options are available.
