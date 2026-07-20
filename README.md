# rgnMultitool

Source-visible Aimware Lua toolkit for CS2. Every module lives in one compact menu and optional gameplay modules start disabled.

## Features

### Cosmetics

- Weapon finishes for the complete supported weapon catalogue, including modern and legacy paint flows.
- Knife models and finishes with automatic reapplication after spawn, death, team changes and map changes.
- Glove models and finishes with guarded refresh timing to prevent flicker and repeated writes.
- Official agents with saved selection.
- Custom character models discovered from the local `csgo/characters` directory.
- Automatic cosmetic persistence plus five named weapon, knife and glove profiles.

### Viewmodel and movement

- Safe extended X, Y and Z viewmodel positioning with presets.
- Optional automatic left-hand knife, routed through the main command hook, with right-hand restoration for other weapons.
- Velocity display and configurable jump trail.
- Prediction edge-bug helper with hold/toggle activation.
- W/A/S/D null-bind resolver.
- Movement features are opt-in and disabled by default.

### Scope overlay

- Optional Neverlose-inspired sniper overlay with pointed arms, a separated luminous center dot and configurable color.
- Six supersampled fog/bloom layers are cached as one texture and rendered in one operation per frame.
- Replaces Aimware's native full-screen NoScope lines while active and restores the user's original NoScope settings when disabled or unloaded.
- Scope detection is cached at 20 Hz; the module is disabled by default.

### Identity and Killsay

- Custom player name and clan prefix controls, independently enabled and saved.
- Killsay with multilingual message packs, random/sequential order, custom templates and optional victim names.
- Identity and Killsay features are opt-in and disabled by default.

### Custom sounds

- Independent custom hit and kill sounds with volume controls and preview buttons.
- Strict local-attacker resolution prevents hits and kills by teammates or opponents from playing sounds, including in Deathmatch.
- Local respawns, team changes and controlled bots are resolved through the current pawn/controller identity cache.
- Place compiled `.vsnd_c` files in `Counter-Strike Global Offensive/game/csgo/sounds` or its subfolders, then press **Refresh csgo/sounds**.
- Sound scanning occurs only at Lua startup or on manual refresh; both effects are disabled by default.
- The Lua never downloads or installs asset packs automatically. See [Manual asset packages](PACKAGES.md) for the optional sound and custom-character downloads.

### Vote information

- Always-on vote revealer with fully English, team-colored local chat messages and no separate HUD overlay.
- Reliable allied and enemy initiator, voter and kick-target names resolved from the exact zero-based vote slot and bidirectionally between controllers and pawns.
- Version 1.1.11 retains the one-time Killsay and vote event bridges; session transitions renew listeners and state without mutating Aimware's native callback registry.
- The release keeps the proven per-file configuration and cache layout from 1.1.0; it does not use the reverted unified-storage experiment.

### Reliability

- Event-driven cosmetic engine with sparse maintenance work for reduced frame-time impact.
- Automatic session rearming when joining another server or changing maps.
- Local configuration files only; no user-specific Windows paths are embedded.
- Built-in update check with source-size, signature, version and Lua syntax validation.

The distributed `loader.lua` checks the small `version.txt` manifest on startup. It downloads the full source only when the published version changes, validates the release signature and Lua syntax, then keeps a local offline cache. Updates are never hot-loaded while a match is running; use **CONFIGS > Check for updates**, then run the Lua again.

## Installation

1. Download `loader.lua` and place it in Aimware's Lua scripts folder.
2. In Aimware Lua permissions, allow internet connections and editing Lua files.
3. Run `loader.lua`.
4. Keep only one rgnMultitool loader/source active at a time.

The loader and full source use relative data filenames and contain no Windows username or PC-specific installation path.

## Update safety

Before replacing its cache, the loader verifies:

- the response is large enough to be a complete release;
- the fixed `RGN_MULTITOOL_SOURCE_V1` signature is present;
- the source version matches the manifest;
- `loadstring` can compile the complete source.

If GitHub is unavailable, the last validated cache is used. The source is intentionally published in full so users can inspect it before running it.

## Credits

Built by **ragnarokcs**. The project was developed with API and implementation references from the Aimware Lua documentation, `cachorropacoca/aw_cs2v6_femboytap`, `mahanneo/SkinChanger_aw_v6`, public Aimware Lua examples and community research. See `NOTICE.md`.

## Disclaimer

This is an unofficial community project and is not affiliated with Valve or Aimware. Use only where permitted and at your own risk.
