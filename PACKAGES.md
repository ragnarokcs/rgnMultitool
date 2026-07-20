# Manual asset packages

rgnMultitool does not automatically download, extract or install game assets. The Lua only reads compatible files that the user has deliberately placed inside the CS2 `game/csgo` directory.

The optional packages are published in the [Manual Asset Packs v1.0 release](https://github.com/ragnarokcs/rgnMultitool/releases/tag/assets-v1.0). They contain static, compiled CS2 resources only—no executables, PowerShell scripts, installers or background services.

## Requirements

- Counter-Strike 2 installed through Steam.
- Aimware allowed to use game scripting and insecure FFI, as already required by the skin modules.
- Enough free disk space:
  - Sound pack: approximately 2.8 MB installed.
  - Custom character pack: approximately 5.5 GB downloaded and installed.
- WinRAR or 7-Zip for the multi-part character archive.

The standard CS2 folder is:

```text
C:\Program Files (x86)\Steam\steamapps\common\Counter-Strike Global Offensive\game\csgo
```

If Steam is installed elsewhere, open Steam, right-click Counter-Strike 2, select **Manage > Browse local files**, then open `game\csgo`.

## Sound pack

1. Download `rgnMultitool-Sounds-v1.0.zip` from the asset release.
2. Open the archive and extract its contents into CS2's `game\csgo` directory.
3. Confirm that the final files are inside `game\csgo\sounds`. Subfolders are supported:

   ```text
   game\csgo\sounds\bell.vsnd_c
   game\csgo\sounds\bonk.vsnd_c
   game\csgo\sounds\hitmarker.vsnd_c
   game\csgo\sounds\my_pack\custom_hit.vsnd_c
   ```

4. Run rgnMultitool, open **CUSTOM SOUNDS**, and press **Refresh csgo/sounds**.
5. Use the preview buttons before enabling the independent hit and kill effects.

Do not create an accidental extra `sounds\sounds` folder. The `.vsnd_c` files must remain somewhere below `game\csgo\sounds`.

## Custom character pack

The curated package is split into three RAR volumes because GitHub limits the size of each Release asset:

```text
rgnMultitool-Custom-Characters-v1.part1.rar
rgnMultitool-Custom-Characters-v1.part2.rar
rgnMultitool-Custom-Characters-v1.part3.rar
```

1. Download every file whose name begins with `rgnMultitool-Custom-Characters-v1.part`.
2. Keep all parts together in the same local folder.
3. Open only `rgnMultitool-Custom-Characters-v1.part1.rar` with WinRAR or 7-Zip.
4. Extract the archive into CS2's `game\csgo` directory.
5. Confirm the resulting structure begins with:

   ```text
   game\csgo\characters\models\...
   game\csgo\characters\materials\...
   ```

6. Restart CS2 if it was running, then run rgnMultitool and open **SKINS CUSTOM**.

Do not extract each part separately. Do not create an extra `characters\characters` folder.

The curated build contains 279 compiled character models and their associated resources. It is built from the working local `game\csgo\characters` directory rather than the larger unfiltered source archive.

The exact model and sound filenames are documented in [`CUSTOM_CHARACTER_CATALOG.txt`](packages/CUSTOM_CHARACTER_CATALOG.txt) and [`SOUND_CATALOG.txt`](packages/SOUND_CATALOG.txt).

## Integrity verification

Download `SHA256SUMS.txt` from the same Release and compare each package hash before extracting. On PowerShell, run:

```powershell
Get-FileHash -Algorithm SHA256 .\rgnMultitool-Sounds-v1.0.zip
Get-FileHash -Algorithm SHA256 .\rgnMultitool-Custom-Characters-v1.part1.rar
```

Repeat the second command for every numbered character part. A mismatched hash means the download is incomplete and must not be extracted.

## Troubleshooting

### The sound list is empty

- Verify the extension is `.vsnd_c`, not `.wav`, `.mp3` or `.vsnd`.
- Verify the files are inside `game\csgo\sounds` or one of its subfolders.
- Press **Refresh csgo/sounds** after copying the files.

### No custom characters are listed

- Verify the final path starts with `game\csgo\characters\models`.
- Restart CS2 after installing the package.
- Run the Lua only after the files have finished extracting.

### CS2 reports a missing or error material

- Stop using that model immediately.
- Verify every archive part against `SHA256SUMS.txt`.
- Extract the complete multi-part archive again; never extract only one volume.

## Removal

- Sounds: remove only the custom `.vsnd_c` files from `game\csgo\sounds`.
- Characters: remove the installed custom `game\csgo\characters` directory only if it contains no personal files you want to keep.

Back up personal assets before deleting either folder.

## Credits

- Sound collection format and original pack: `cachorropacoca/aw_cs2v6_femboytap`.
- Character source collection: LynX's Custom Models [AG2].
- Packaging, filtering and rgnMultitool integration: Ragnarokcs.
