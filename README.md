# Kedai Runtuh

Stack the mamak order as high as you can before it collapses.

Food hangs from a hook swinging above the table. **One tap drops it.** Land it on
top and the tower grows, the camera rises, and the hook swings faster. Miss, or
knock the whole thing over, and the run is over.

Built with **Godot 4.7**, portrait, for Android.

---

## Running it

Open the folder in Godot 4.7 and press **Play** (F5). It starts on the main menu.

On desktop, tap = left mouse click, or press **Space**. **Escape** pauses
(on Android, so does the back button).

## Screens

| Screen | What is on it |
|---|---|
| Main menu | Title, **MAIN**, **BUNYI** (sound on/off), **KELUAR**, and your best score |
| In game | Score and best score top left, pause button top right |
| Pause | Score and best score, **SAMBUNG**, **MULA SEMULA**, **MENU UTAMA**, **BUNYI** |
| Game over | Why you lost, your score, your best, and **REKOD BARU!** if you beat it |

### The high score

It lives in `scripts/save_data.gd`, which is an **autoload** — a single object that
exists outside every scene and stays alive when scenes change. That is what makes
it safe: starting a new game builds a completely fresh game scene with a score of
zero, and the high score is not part of that scene, so nothing can reset it. It is
written to disk (`user://kedai_runtuh.cfg`) the moment it changes.

The sound setting is stored the same way.

> **Note on sound:** the BUNYI button really does mute the game's master audio
> bus, and remembers the setting between sessions. There is no audio in the game
> yet, so today there is nothing to hear — the switch is wired to the real thing
> and will work the moment the first sound is added.

### Changing how the UI looks

Everything — button colours, corner radius, font sizes, panel style — is in
`scripts/ui_theme.gd`. No scene sets its own colours. The palette is at the top of
that file.

Buttons pick a look with `theme_type_variation` on the node:
`PrimaryButton` for the big red one, `IconButton` for the small round one, and
nothing at all for the ordinary cream one.

## The two ways to lose

| Screen says | What happened |
|---|---|
| **RUNTUH!** | A piece fell off the table — the tower collapsed |
| **TERSASAR!** | A piece came to rest too far below the top — you missed the tower |

---

## Where everything is

```
project.godot         engine settings — portrait size, gravity, autoload
scenes/main_menu.tscn the title screen
scenes/main.tscn      the game: camera, light, kitchen, table, hook, UI
scripts/game.gd       the whole game, and the list of food
scripts/hook.gd       the pendulum the food hangs from
scripts/rope.gd       the rope: simulated, decoration only
scripts/fit_model.gd  scales a decorative model to line up with the game
scripts/save_data.gd  autoload: high score and sound, kept between sessions
scripts/ui_theme.gd   every colour and size in the UI, in one place
scripts/main_menu.gd  the title screen
assets/models/        Sketchfab models
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
| `DROP_HEIGHT` | How far above the tower the hook hangs at the bottom of its swing | Lower it if pieces smash the tower apart on landing |
| `ANCHOR_HEIGHT` | How high above the tower the rope is pinned. The gap between this and `DROP_HEIGHT` is the pendulum's length | Raise it for a longer, lazier swing |
| `DROP_TILT` | How much of the rope's lean a piece keeps once released. `1.0` = what you see hanging is what you drop; `0.0` = always released upright | Lower it if tilted drops feel unfair |
| `LIVE_PIECES` | How many pieces at the top stay physically live | Raise it for bigger, messier collapses; lower it for a steadier tower |
| `LANDING_TOLERANCE` | How far below the top still counts as landed | Raise it if fair-looking drops are being called a miss |
| `SETTLE_SPEED` | How slow a piece must be moving to count as stopped | **Raise it if the game pauses after each drop.** Too low and every drop waits out `MAX_DROP_TIME` |
| `SETTLE_TIME` | How long a piece must sit still before it scores | Lower it if scoring feels sluggish |
| `MAX_DROP_TIME` | Give up waiting and judge the piece anyway | This is a safety net. If it fires often, `SETTLE_SPEED` is too low |

The swing itself lives in `scripts/hook.gd`: `swing_degrees` is how far it swings
either side of straight down, `base_speed` how fast it starts.

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

Other development scenes, all run the same way:

| Scene | What it does |
|---|---|
| `_test.tscn` | Plays the game automatically and prints the score |
| `_inspect.tscn` | Lists every food item's box against what its model fits to |
| `_shot.tscn` | Builds a tower and saves screenshots |
| `_uishot.tscn` | Saves a screenshot of the menu, HUD, pause menu and game over |
| `_menushot.tscn` | Just the main menu, for iterating on it quickly |
| `_persist.tscn` | Checks the high score survives a restart and a worse run |

(Everything starting with `_` is a development tool, not part of the game.)

## Assets

The food models are from Sketchfab under CC-BY-4.0 — commercial use is allowed but
the author must be credited. See [CREDITS.md](CREDITS.md); that credit has to
appear on any store or itch.io page too.
