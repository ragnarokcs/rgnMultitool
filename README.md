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
- Velocity display and configurable jump trail.
- Prediction edge-bug helper with hold/toggle activation.
- W/A/S/D null-bind resolver.
- Movement features are opt-in and disabled by default.

### Identity and Killsay

- Custom player name and clan prefix controls, independently enabled and saved.
- Killsay with multilingual message packs, random/sequential order, custom templates and optional victim names.
- Identity and Killsay features are opt-in and disabled by default.

### Vote information

- Built-in vote start, choice and result information in a local-only HUD chat feed.
- Voter overlay with F1/F2 choices.
- Terrorist `(T)` labels in red and Counter-Terrorist `(CT)` labels in blue.
- Correct controller/team resolution and surrender reconstruction after a teammate disconnects.

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
