# Architecture and state flow

Godot 4.7.2, GDScript, Compatibility renderer; no plugins or backend.

- `scenes/Main.tscn`: entry point. Screens are constructed as real Godot Controls
  in `game_controller.gd`, keeping one scene and reusable modal builders rather
  than empty placeholder scene files.
- `slot_machine.gd`: weighted independent cell generation with Godot's
  RandomNumberGenerator; active lines; highest-paying wild substitution; free
  generation queue; complete transactional credit, jackpot and statistic update.
- `data/probability.json`: authoritative probabilities, line paths, payout scale,
  payouts, contribution, generation limit, target and analytically verified RTP.
- `reel_board.gd`: visual-only reel motion, deterministic decorative cycling,
  sequential stops, numbered active paths and animated winning-symbol outlines.
  It cannot modify or reroll outcomes and does not consume the engine RNG.
- `game_controller.gd`: input, Auto Spin, session stats, settings, menus and
  presentation timing. Calls the engine once before animation. It saves the entire
  result immediately, then counts up the displayed balance. Closing mid-spin does
  not refund a wager, replay a jackpot or discard an earned free-spin queue.
- `save_manager.gd`: versioned JSON under `user://`, schema/range validation,
  temporary-file replacement; a corrupt file produces defaults instead of a crash.
- `progression.gd`: deterministic, strictly cosmetic milestone unlocks.
- `audio_manager.gd`: separate music/effects volume, mute, reduced sounds and
  interaction-gated audio. Six short-effect voices, looping background melody.
- `celebration.gd`: short optional dog-running and snow/sparkle win effects.
- `debug_controller.gd`: canned grids, exposed only when both `OS.is_debug_build()`
  and the `--developer` user argument are true. Development uses a separate save.
- `simulate_slots.gd`: invokes the same `spin()` method as the UI, including all
  free spins, jackpot contributions and awards. No replacement probability model.
- `verify_math.gd`: enumerates all 11^5 possible lines using the same evaluator;
  recomputes and checks every configured theoretical RTP.

The engine resolves the bonus reward before animation and credits it atomically.
The three bonus houses reveal this pre-drawn prize; the UI explicitly says there
is no wrong choice. This avoids losing pending rewards when the browser closes.

Queue tickets carry both wager and generation. Settings cannot alter the wager
of an earned free spin. Six retrigger generations form a finite tree; the expected
number of children is far below one. Stop cancels future scheduled spins using
an epoch token, while the already-drawn current result finishes. Modal screens
pause autoplay. Free spins can be resumed with the Spin button at any time.

Exports use embedded desktop PCKs and single-threaded WebAssembly. Web paths are
relative and require no COOP/COEP headers, root-domain paths or service worker.
Godot's browser `user://` persistence uses IndexedDB. Browser private mode,
storage clearing, or a different browser/profile can remove/separate local saves.
The UI uses a 1280×800 design canvas with aspect-preserving scaling and letterboxing.
Landscape is recommended; portrait is not optimized.
