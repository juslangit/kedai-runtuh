# Kedai Runtuh

Stack the mamak order as high as you can before it collapses.

Food hangs from a hook swinging above the table. **One tap drops it.** Land it on
top and the tower grows, the camera rises, and the hook swings faster. Miss, or
knock the whole thing over, and the run is over.

Built with **Godot 4.7**, portrait, for Android.

---

## Running it

Open the folder in Godot 4.7 and press **Play** (F5).

On desktop, tap = left mouse click, or press **Space**.

## The two ways to lose

| Screen says | What happened |
|---|---|
| **RUNTUH!** | A piece fell off the table — the tower collapsed |
| **TERSASAR!** | A piece came to rest too far below the top — you missed the tower |

---

## Where everything is

```
project.godot        engine settings — portrait size, gravity
scenes/main.tscn     the only scene: camera, light, table, hook, UI
scripts/game.gd      the whole game, and the list of food
scripts/hook.gd      the swinging hook (about 15 lines)
assets/models/       Sketchfab .glb files go here
```

## Adding a new piece of food

Open `scripts/game.gd`. At the top there is a list called `ITEMS`. Add a line:

```gdscript
{"name": "Kuih keria", "shape": "cylinder", "width": 0.85, "height": 0.35, "color": Color("c98b4b"), "model": CAFE, "node": "Donut_brown_Food_0"},
```

- `shape` — the **collision** shape: `"cylinder"` for round, `"box"` for square
- `width` — footprint in metres. **Keep every item between 0.80 and 1.05.** An item
  much narrower than the rest becomes an impossible base and ends the run whenever
  it appears
- `height` — how tall the piece is in metres
- `model` — the imported file the mesh comes from
- `node` — the name of the object inside that file
- `color` — only used if there is no model

**`width` and `height` are the real physics box. The model is scaled to fit them,
not the other way round** — so swapping a model never changes how the game plays.
Leave `model` as `""` and you get a plain coloured shape instead.

Nothing else needs changing. That is the only place food is defined.

### Finding the object name inside a model file

A Sketchfab pack is one file containing dozens of objects. To list them:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . res://_inspect.tscn
```

That prints every item's target size next to what the model actually fits to, so
you can see immediately if a model is missing or badly proportioned.

## Changing how it feels

All the tuning numbers are constants at the top of `scripts/game.gd`, with a
comment on each one:

| Constant | What it does | Try this if... |
|---|---|---|
| `DROP_HEIGHT` | How far above the tower the hook hangs | Lower it if pieces smash the tower apart on landing |
| `LIVE_PIECES` | How many pieces at the top stay physically live | Raise it for bigger, messier collapses; lower it for a steadier tower |
| `LANDING_TOLERANCE` | How far below the top still counts as landed | Raise it if fair-looking drops are being called a miss |
| `SETTLE_TIME` | How long a piece must sit still before it scores | Lower it if scoring feels sluggish |

Gravity lives in `project.godot` under `[physics]` — lower gravity means a slower,
gentler fall.

## Testing without playing

Godot can run the game with no window, so a script can play it automatically and
print the score. Useful for checking a tuning change across several runs quickly:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . res://_test.tscn
```

It plays about six runs a minute and prints the score for each, which is how the
tuning above was arrived at. To check how it *looks* rather than how it plays,
`res://_shot.tscn` builds a tower and saves screenshots.

(The `_test*`, `_inspect*` and `_shot*` files are development tools, not part of
the game.)

## Assets

The food models are from Sketchfab under CC-BY-4.0 — commercial use is allowed but
the author must be credited. See [CREDITS.md](CREDITS.md); that credit has to
appear on any store or itch.io page too.
