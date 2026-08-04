<p align="center">
  <img src="assets/rgnmultitool-banner.png" alt="rgnMULTITOOL — Aimware Lua Toolkit — Created and owned by ragnarokcs" width="100%">
</p>

<h1 align="center">rgnMultitool</h1>

<p align="center">
  <strong>Source-visible Aimware Lua toolkit for CS2.</strong><br>
  Every module lives in one compact menu and optional gameplay modules start disabled.
</p>

<p align="center">
  <img alt="Lua" src="https://img.shields.io/badge/Lua-Aimware-43A9FF?style=flat-square">
  <img alt="Platform" src="https://img.shields.io/badge/Platform-CS2-43A9FF?style=flat-square">
  <img alt="Source" src="https://img.shields.io/badge/Source-Visible-43A9FF?style=flat-square">
  <img alt="Owner" src="https://img.shields.io/badge/Owner-ragnarokcs-43A9FF?style=flat-square">
</p>

## Download

[**Download `loader.lua`**](https://raw.githubusercontent.com/ragnarokcs/rgnMultitool/main/loader.lua)

`loader.lua` is the primary and recommended entry point. It validates and runs the current public source, keeps a last-known-good offline cache and downloads the full Lua again only when `version.txt` changes. `rgnMultitool.lua` remains available for source review and development; regular users do not need to install it manually.

## Interface preview

Click any preview to open the full-size image.

<table>
  <tr>
    <td width="50%" valign="top">
      <a href="assets/previews/weapons.png"><img src="assets/previews/weapons.png" alt="Weapons module preview" width="100%"></a>
      <p><strong>Weapons</strong><br>Browse weapons, knives and gloves, select finishes, tune wear and seed, and save the setup.</p>
    </td>
    <td width="50%" valign="top">
      <a href="assets/previews/agents.png"><img src="assets/previews/agents.png" alt="Agents module preview" width="100%"></a>
      <p><strong>Agents</strong><br>Select and persist official Terrorist and Counter-Terrorist agents.</p>
    </td>
  </tr>
  <tr>
    <td width="50%" valign="top">
      <a href="assets/previews/custom-skins.png"><img src="assets/previews/custom-skins.png" alt="Custom character skins module preview" width="100%"></a>
      <p><strong>Custom Skins</strong><br>Discover compatible character models from the local <code>csgo/characters</code> directory.</p>
    </td>
    <td width="50%" valign="top">
      <a href="assets/previews/viewmodel.png"><img src="assets/previews/viewmodel.png" alt="Viewmodel module preview" width="100%"></a>
      <p><strong>Viewmodel</strong><br>Adjust X, Y and Z positioning, apply presets and optionally keep the knife in the left hand.</p>
    </td>
  </tr>
  <tr>
    <td width="50%" valign="top">
      <a href="assets/previews/scope-overlay.png"><img src="assets/previews/scope-overlay.png" alt="Scope overlay in game" width="100%"></a>
      <p><strong>Scope Overlay</strong><br>Use the lightweight luminous sniper overlay with a configurable color and separated center point.</p>
    </td>
    <td width="50%" valign="top">
      <a href="assets/previews/custom-sounds.png"><img src="assets/previews/custom-sounds.png" alt="Custom sounds module preview" width="100%"></a>
      <p><strong>Custom Sounds</strong><br>Choose local hit and kill sounds, preview them and control each volume independently.</p>
    </td>
  </tr>
  <tr>
    <td width="50%" valign="top">
      <a href="assets/previews/movement.png"><img src="assets/previews/movement.png" alt="Movement module preview" width="100%"></a>
      <p><strong>Movement</strong><br>Optional velocity display, jump trail, edge-bug helper and W/A/S/D null-bind resolver.</p>
    </td>
    <td width="50%" valign="top">
      <a href="assets/previews/identity.png"><img src="assets/previews/identity.png" alt="Identity module preview" width="100%"></a>
      <p><strong>Identity</strong><br>Configure custom player-name and clan-prefix behavior independently.</p>
    </td>
  </tr>
  <tr>
    <td width="50%" valign="top">
      <a href="assets/previews/killsay.png"><img src="assets/previews/killsay.png" alt="Killsay module preview" width="100%"></a>
      <p><strong>Killsay</strong><br>Select a language pack, message order, interval and optional victim-name template.</p>
    </td>
    <td width="50%" valign="top">
      <a href="assets/previews/configs.png"><img src="assets/previews/configs.png" alt="Configs module preview" width="100%"></a>
      <p><strong>Configs</strong><br>Reapply the automatic setup, manage named profiles and check for validated updates.</p>
    </td>
  </tr>
</table>

## Features

### Cosmetics

- Weapon finishes for the complete supported weapon catalogue, including modern and legacy paint flows.
- Knife models and finishes with automatic reapplication after spawn, death, team changes and map changes.
- Glove models and finishes with guarded refresh timing to prevent flicker and repeated writes.
- Official agents with saved selection.
- Custom character models discovered from the local `game/csgo/characters` directory, including Steam libraries whose paths contain non-English characters and sessions whose working directory was changed by Steam or another overlay.
- Automatic cosmetic persistence plus five named weapon, knife and glove profiles.

### Viewmodel and movement

- Verified X, Y and Z viewmodel positioning with presets. The documented convar path is used first; extended mode safely falls back to the native range if its validated hook is unavailable.
- Optional 60–120 View FOV override through Aimware's native setting, keeping native ESP projection synchronized and saved independently from X/Y/Z.
- Optional automatic left-hand knife, routed through the main command hook, with right-hand restoration for other weapons.
- Velocity display and configurable jump trail.
- Prediction edge-bug helper with hold/toggle activation.
- W/A/S/D null-bind resolver.
- Movement features are opt-in and disabled by default.

### Manual AA, region and whitelist

- Manual AA directions are available through Aimware's native **Ragebot > Anti-Aim** controls, with optional compact on-screen direction indicators.
- The **Region** module provides a curated list of CS2 Steam relay preferences and a maximum-matchmaking-ping control without calling game-owned native relay interfaces.
- Select one or more relays and apply the preference from the main menu. Changes requested during a live server are queued until the next safe menu state.
- The **Whitelist** module refreshes the active enemy roster on joins, spawns and team changes. Enemies begin as valid targets; selected players can be protected locally from targeting, with the target state applied immediately after every UI change.
- The optional **Kill Timer** tracks local round kills, shows a compact animated delay HUD and supports a configurable limit of up to five opponents.

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
- Unicode-aware discovery supports Steam libraries on other drives and paths containing non-English characters. An empty list reports whether insecure FFI is disabled, the folder is missing or no compiled files were found.
- Sound scanning occurs only at Lua startup or on manual refresh; both effects are disabled by default.
- The Lua never downloads or installs asset packs automatically. See [Manual asset packages](PACKAGES.md) for the optional sound and custom-character downloads.

### Vote information

- Always-on vote revealer with fully English, team-colored local chat messages and no separate HUD overlay.
- Reliable allied and enemy initiator, voter and kick-target names resolved from the exact zero-based vote slot and bidirectionally between controllers and pawns.
- Version 1.1.11 retains the one-time Killsay and vote event bridges; session transitions renew listeners and state without mutating Aimware's native callback registry.
- The release keeps the proven per-file configuration and cache layout from 1.1.0; it does not use the reverted unified-storage experiment.

### Reliability

- Native cosmetics now fail closed after a CS2 update unless both the current runtime offsets and matching client schema can be fetched and validated; stale packaged addresses are never used as an offline fallback.
- Event-driven cosmetic engine with sparse maintenance work for reduced frame-time impact.
- Disabled Killsay, Custom Sounds, Movement, Scope Overlay, left-hand knife and Identity paths now short-circuit before protected callbacks, entity work or session polling.
- Killsay no longer writes diagnostic files for unrelated server deaths; runtime files are reserved for state transitions, send failures and actionable diagnostics.
- Vote logic preserves its 20 Hz service cadence while avoiding protected-call overhead on intermediate `CreateMove` commands.
- Runtime overlay dispatch is allocated once at startup instead of creating a temporary closure every rendered frame.
- Automatic session rearming when joining another server or changing maps.
- Region forcing uses only regular CS2 console settings, never a LuaJIT call through a game-owned SteamNetworkingSockets interface, and never mutates the preference while connected to a live server.
- Local configuration files only; no user-specific Windows paths are embedded.
- Built-in update check with source-size, signature, version and Lua syntax validation.
- Menu resolution does not affect custom-asset discovery or viewmodel values; both paths are independent of screen coordinates and support 1920x1080 and other common resolutions.

The distributed `loader.lua` checks the small `version.txt` manifest on startup. It downloads the full source only when the published version changes, validates the release signature and Lua syntax, then keeps a local offline cache. Updates are never hot-loaded while a match is running; use **CONFIGS > Check for updates**, then run the Lua again.

## Installation

1. Download only [`loader.lua`](https://raw.githubusercontent.com/ragnarokcs/rgnMultitool/main/loader.lua) and place it in Aimware's Lua scripts folder.
2. In Aimware Lua permissions, allow internet connections and editing Lua files.
3. Enable **Allow game scripting** and **Allow insecure FFI** for the cosmetics, custom-character and extended-viewmodel modules.
4. Run `loader.lua`.
5. Keep only one rgnMultitool loader/source active at a time.

Keep `loader.lua` as the only rgnMultitool script configured for autorun. The loader and full source use relative data filenames and contain no Windows username or PC-specific installation path.

### Custom assets and viewmodel compatibility

- Screen resolution does not control either module; 1920x1080, other 16:9 resolutions and 4:3 layouts use the same game-relative asset paths and viewmodel values.
- Custom characters must be compiled `.vmdl_c` resources below `game/csgo/characters`, with their complete materials beside them. Use **Skins Custom > Portable status / requirements** to print the exact resolved folder and engine status.
- The regular X/Y/Z controls use Aimware's documented convar API and work without the extended hook. **Extended XYZ** is optional and automatically falls back to the native range when the current CS2 call site cannot be safely validated.
- If assets were copied while CS2 was already open, restart CS2 before running the Lua so Source 2 can mount the resources.

## Update safety

Before replacing its cache, the loader verifies:

- the response is large enough to be a complete release;
- the fixed `RGN_MULTITOOL_SOURCE_V1` signature is present;
- the source version matches the manifest;
- `loadstring` can compile the complete source.

If GitHub is unavailable, the last validated cache is used. The source is intentionally published in full so users can inspect it before running it.

## Credits

Created and owned by **ragnarokcs**. The project was developed with API and implementation references from the Aimware Lua documentation, `cachorropacoca/aw_cs2v6_femboytap`, `mahanneo/SkinChanger_aw_v6`, public Aimware Lua examples and community research. See `NOTICE.md`.

## Disclaimer

This is an unofficial community project and is not affiliated with Valve or Aimware. Use only where permitted and at your own risk.
