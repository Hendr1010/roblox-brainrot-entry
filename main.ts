// Brainrot Base Rush — make.fun roblox-brainrot-01 entry handoff.
//
// This program hands the game in. The game itself is the Rojo project in
// this directory: `rojo build default.project.json --output game.rbxl`
// turns src/ + default.project.json into the place file, and this script
// copies game.rbxl, src/, screenshots/ and PLAY.json into the output
// directory and writes dossier.json there with the vendored make.fun
// library (vendor/makefun-roblox.ts, kit code, used unchanged).
//
// Run it the way the grader does, with MAKEFUN_OUTPUT_DIR standing in
// for /output outside the grader's container:
//
//   mkdir -p out && MAKEFUN_OUTPUT_DIR=out node main.ts
//
// Output names must start with a letter, a digit or _ and hold only
// letters, digits, . _ and -; the grader fails an entry that carries any
// other name, so dotfiles (.gitkeep, .DS_Store, .git) are filtered out of
// every copied tree, at any depth.

import { copyFileSync, cpSync, existsSync, mkdirSync, writeFileSync } from 'node:fs';
import { basename, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { buildDossier } from './vendor/makefun-roblox.ts';

const here = fileURLToPath(new URL('.', import.meta.url));
const out = process.env.MAKEFUN_OUTPUT_DIR ?? '/output';

/** cpSync filter: skip every file and directory whose name starts with a dot. */
const notDotted = (path: string): boolean => !basename(path).startsWith('.');

mkdirSync(out, { recursive: true });
copyFileSync(join(here, 'game.rbxl'), join(out, 'game.rbxl'));
copyFileSync(join(here, 'PLAY.json'), join(out, 'PLAY.json'));
cpSync(join(here, 'src'), join(out, 'src'), { recursive: true, filter: notDotted });
mkdirSync(join(out, 'screenshots'), { recursive: true });
if (existsSync(join(here, 'screenshots'))) {
  cpSync(join(here, 'screenshots'), join(out, 'screenshots'), { recursive: true, filter: notDotted });
}

// The scorer's own caps (reference/gate.json): only text_max_bytes shapes
// the bytes; the others refuse an entry the scorer would refuse (more than
// 4 screenshots or one over 256 KiB; a place of more than 500000
// instances, whose scripts' sources come to over 8 MiB or whose scripts'
// paths come to over 1048576 characters, in all).
writeFileSync(
  join(out, 'dossier.json'),
  buildDossier(out, {
    text_max_bytes: 65536,
    screenshots: { max: 4, max_bytes: 262144 },
    max_instances: 500000,
    scripts_max_source_bytes: 8388608,
    scripts_max_path_chars: 1048576,
  }),
);
