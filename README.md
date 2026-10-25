# Super Commander — source (AGPL-3.0)

Super Commander is a Roblox game. It is a modified version of [OpenFront](https://github.com/openfrontio/OpenFrontIO) (upstream commit `e02eeba66b4801ebae0b686e1b0e4bc03fbf3654`, plus selected later upstream changes), ported to Roblox/Luau and changed by Berkshire Byteaway. It is **not** an official OpenFront product and is not endorsed by OpenFront.

- Version: `roblox-v40` (internal commit `bdff62af9b34`, 2026-10-25). This is the Corresponding Source of the game version published on Roblox under this name (branch `release/roblox-v40`).
- Modified: yes. The whole codebase was translated from TypeScript to Luau and extended (lobby, matchmaking, UI, progression, Roblox services). See git history of this repository for per-release changes.
- © OpenFront and Contributors. Code: GNU AGPL v3 with the additional terms in `LICENSE` (section 7). Map data in `src/maps` derives from OpenFront `/resources` under CC BY-SA 4.0 (`LICENSE-MAPS`). Flag icons: `assets/flags/LICENSE-flag-icons.txt`.
- Art, models, sounds, logos and the "Super Commander" name are not part of this source and are All Rights Reserved. The game references them by Roblox asset ID only.
- Development-only tools (test fixtures, Studio automation, cheat panels) are not part of the published game and are not included. Internal development notes are removed from comments; copyright and license notices are kept.

## Build

Requires Node.js 18+ and Roblox Studio.

```
node tools/build-localization.mjs
node tools/build-native.mjs --lite
```

Open the generated `dist/FrontierNativeSettlement.rbxlx` in Roblox Studio and press Play.
