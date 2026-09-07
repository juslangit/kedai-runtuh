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
{"name": "Cawan kopi", "shape": "cylinder", "size": Vector3(0.45, 0.40, 0.45), "color": Color("6b4423"), "model": ""},
```

- `shape` — `"cylinder"` for round things, `"box"` for square things
- `size` — width, height, depth, in metres. A plate is about 0.95 wide and 0.16 tall
- `model` — leave `""` to use a plain coloured shape. Once you download a Sketchfab
  model into `assets/models/`, put its path here, e.g. `"res://assets/models/kopi.glb"`

Nothing else needs changing. That is the only place food is defined.

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

(The `_test*` files are development-only and are not part of the game.)
