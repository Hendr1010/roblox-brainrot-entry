# Brainrot Base Rush — roblox-brainrot-01

[![roblox-brainrot-01](https://make.fun/badge/roblox-brainrot-01.svg)](https://make.fun/bounty/roblox-brainrot-01)
[![rank](https://make.fun/badge/roblox-brainrot-01/Hendr1010/roblox-brainrot-entry/rank.svg)](https://make.fun/bounty/roblox-brainrot-01)
[![reward](https://make.fun/badge/roblox-brainrot-01/Hendr1010/roblox-brainrot-entry/reward.svg)](https://make.fun/bounty/roblox-brainrot-01)

A 3D brainrot collector in the Steal a Brainrot style, built for make.fun's
["Make the best AI Roblox brainrot game"](https://make.fun/bounty/roblox-brainrot-01)
bounty (roblox-brainrot-01).

## The game

Brainrots spawn at the central portal every ~6 seconds and walk the winding
golden path toward your base. Touch one to buy it (if you can afford it) —
it walks to a free slot on your base and starts earning $/s. Eight meme
characters across five rarities:

| Rarity | Brainrot | $/s | Cost |
| --- | --- | --- | --- |
| Common | Tung Tung Tung Sahur | $1 | $25 |
| Common | Chimpanzini Bananini | $2 | $60 |
| Rare | Tralalero Tralala | $5 | $200 |
| Rare | Ballerina Cappuccina | $8 | $350 |
| Epic | Bombardiro Crocodilo | $15 | $800 |
| Epic | Lirili Larila | $22 | $1,200 |
| Legendary | Brr Brr Patapim | $50 | $3,000 |
| Mythic | Giraffa Celeste | $150 | $10,000 |

Mutations: 5% Golden (2x rate), 1% Rainbow (5x rate).

- **Brainrot Tsunami** every ~90s: a glowing wall sweeps the arena. Get to
  the green base (the safe zone) or get knocked back and lose 10% of your
  cash. Announced 10s ahead.
- **Noob Nabber** thief every ~75s: runs to a random base slot and channels
  3s to steal a brainrot. Slap him away with the Slap tool before the
  channel finishes.
- **Rebirth** at $25,000 lifetime earned: resets money and brainrots for a
  permanent +50% earnings multiplier (stacking).

The HUD (top-right, clear of the Roblox menu buttons) shows money, $/s,
brainrot count, the next spawn preview, the wave countdown, and the Rebirth
button when it is available.

## Layout

- `default.project.json` — Rojo project; the whole 3D world lives here as
  Parts (200x200 arena, portal, winding path, base with 8 slots, towers,
  trees, fences) plus the Slap tool in StarterPack.
- `src/shared/BrainrotData.luau` — brainrot definitions, rarities, mutations.
- `src/server/init.server.luau` — spawning, economy, tsunami wave, thief, rebirth.
- `src/server/BrainrotFactory.luau` — builds brainrot and thief Models from Parts.
- `src/client/Game.client.luau` — HUD and Slap tool handling.
- `main.ts` — hands the game in: copies `game.rbxl`, `src/`,
  `screenshots/` and `PLAY.json` to `/output` and writes `dossier.json`
  with `vendor/makefun-roblox.ts` (kit code, unchanged).
- `screenshots/` — placeholder captures for now; real Roblox Studio
  captures replace them before submission.
- `PLAY.json` — still zeros until the place is published and the place /
  universe ids are filled in.

## Build and validate

```sh
~/workspace/bin/rojo build default.project.json --output game.rbxl
mkdir -p out && MAKEFUN_OUTPUT_DIR=out node main.ts
```

`main.ts` needs Node 22+ (`node --type-strip` handles the `.ts` import of
the vendored library). Rojo 7.7.1 builds the place; `game.rbxl` must be a
binary place file, not XML.
