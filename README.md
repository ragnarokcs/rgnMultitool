# rgnMultitool

Source-visible Aimware Lua toolkit for CS2 focused on cosmetics:

- weapon finishes, knives and gloves;
- official agents;
- custom character models from the local `csgo/characters` directory;
- XYZ viewmodel positioning;
- saved cosmetic profiles.

The distributed `loader.lua` checks the small `version.txt` manifest on startup. It downloads the full source only when the published version changes, validates the release signature and Lua syntax, then keeps a local offline cache. Updates are never hot-loaded while a match is running; use **CONFIGS > Check for updates**, then run the Lua again.

## Installation

1. Download `loader.lua` and place it in Aimware's Lua scripts folder.
2. In Aimware Lua permissions, allow internet connections and editing Lua files.
3. Run `loader.lua`.
4. Keep only one rgnMultitool loader/source active at a time.

The loader uses only relative filenames, so it does not contain a Windows username or a PC-specific path.

## Update safety

Before replacing its cache, the loader verifies:

- the response is large enough to be a complete release;
- the fixed `RGN_MULTITOOL_SOURCE_V1` signature is present;
- the source version matches the manifest;
- `loadstring` can compile the complete source.

If GitHub is unavailable, the last validated cache is used. The source is intentionally published in full so users can inspect it before running it.

## Credits

Built by **ragnarokcs**. The project was developed with API and implementation references from the Aimware Lua documentation, `cachorropacoca/aw_cs2v6_femboytap`, `mahanneo/SkinChanger_aw_v6`, and community research. See `NOTICE.md`.

## Disclaimer

This is an unofficial community project and is not affiliated with Valve or Aimware. Use only where permitted and at your own risk.
