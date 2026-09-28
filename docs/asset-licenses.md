# Asset and audio provenance

All game-specific illustrations, vector symbols, scenery, UI, character effects,
and audio in this repository are original and covered by the repository's MIT
license. No casino artwork, music recordings, brands or external asset packs
are used.

`tools/generate_assets.py` creates the SVG illustrations and deterministic PCM
WAV audio. Run it with Python 3 to regenerate the checked-in assets. Audio uses
mathematically generated sine-wave melodies and effects. The bark and howl are
stylized synthesizer sounds, not animal recordings. Meadow and snow have separate
calm loops; free spins use a faster melody. Buttons, reels, wins, bonuses and
jackpots have separate short cues. Music starts only after player interaction.

Godot 4.7.2 is MIT licensed: https://godotengine.org/license/
Its bundled fallback font and export runtime retain their upstream licensing;
see https://github.com/godotengine/godot/blob/4.7.2-stable/COPYRIGHT.txt .
No additional font files or font licenses are introduced by this project.

The repository license permits reuse; the distributed game itself contains no
monetization, tracking, advertisements, purchases, accounts or payment code.
GitHub serves the static files under its normal hosting policies. The game sends
no gameplay telemetry and uses no game server.
