# vmenu_cocaine

ESX-compatible cocaine gameplay loop for FiveM:

- Cocaine plants spawn in a configurable field (max 15 by default).
- Players pick plants with `E`, play a gardener animation, and receive random `coke_leaf`.
- Players process `coke_leaf` at a configurable location into random `coke` (1 leaf per action).
- Using `coke` gives armor, speed boost, and a visual effect.

## Installation

1. Put this resource in your `resources` folder.
2. Add `ensure vmenu_cocaine` to your `server.cfg`.
3. Add required items to your ESX items definition:

```lua
['coke_leaf'] = { label = 'Cocaine Leaf', weight = 1 },
['coke'] = { label = 'Cocaine', weight = 1 },
```

## Notes

- Interaction prompt uses native GTA help UI (top-left `Press E`).
- Progress uses `exports['esx_progressbar']:Progressbar(...)` when available.
- If `esx_progressbar` is not installed or fails, it falls back to a simple `Wait()`-based timer.
- Plant rewards and processing output are fully server-side randomized.
