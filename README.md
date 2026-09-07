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
| Main menu | Title, **PLAY**, **SOUND** (on/off), **QUIT**, and your best score |
| In game | Score and best score top left, pause button top right |
| Pause | Score and best score, **RESUME**, **RESTART**, **MAIN MENU**, **SOUND** |
| Game over | Why you lost, your score, your best, and **NEW BEST!** if you beat it |

All interface text is in English. *Kedai Runtuh* stays as the game's name.

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

### Swapping in a bought UI art pack

Every button and panel is currently **drawn by Godot** — rounded boxes, no image
files. To use artwork instead (the [Cozy UI Pack](https://dobo-ui.itch.io/cozy-ui),
for example):

1. Buy and download the pack, and unzip the PNGs into `assets/ui/`.
2. Open `scripts/ui_theme.gd` and fill in the paths in the `SPRITES` block near
   the top — one for the ordinary button, one for its pressed state, one for the
   primary button, one for the panel.
3. Set each `margin` to the 9-slice border of that PNG: how many pixels at each
   edge are frame that must not stretch. For 64px pieces this is usually 16–20.

Anything left as `""` keeps the drawn version, so the game always runs and you can
swap one piece at a time. Padding is carried over from the drawn style being
replaced, so the layout does not shift when the art goes in.

## The two ways to lose

| Screen says | What happened |
|---|---|
| **TOPPLED!** | A piece fell off the table — the tower went over |
| **MISSED!** | A piece came to rest too far below the top — you missed the tower |

Land close to the centre of the piece below and you get a **PERFECT** — a chime, a
flash, and two points instead of one. When the tower starts leaning badly it
creaks and the camera trembles, so a collapse is something you can hear coming.

When you do lose, time drops to about a third, the camera shakes, the dishes go
over in waves, and it holds on the wreckage for a beat before the score appears.
That moment is the one people record, so it is deliberately the loudest thing in
the game.

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
{"name": "Doughnut", "shape": "cylinder", "width": 0.85, "height": 0.35, "color": Color("c98b4b"), "model": CAFE, "node": "Donut_brown_Food_0"},
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
| `PERFECT_WINDOW` | How close to the centre below counts as a perfect landing | Raise it if PERFECT never happens, lower it if it always does |
| `WOBBLE_LEAN` | How far the tower must lean before it starts creaking | Lower it for more tension, raise it for fewer false alarms |
| `SLOWMO_SCALE` | How far time slows during the collapse | Lower for more drama, 1.0 for none |
| `GAME_OVER_DELAY` | Real seconds spent watching the collapse before the panel | Raise it for better video clips, lower for faster retries |
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

## Putting it on an Android phone

```bash
./build-android.sh      # makes build/kedai-runtuh.apk
./install-android.sh    # makes it and pushes it to a plugged-in phone
```

The simplest way to test, needing nothing on the phone: run `./build-android.sh`,
then copy `build/kedai-runtuh.apk` onto the phone however you like and tap it.
Android will ask permission to install from an unknown source once.

To install over a cable instead, the phone needs developer mode:

1. **Settings → About phone**, tap **Build number** seven times
2. **Settings → Developer options → USB debugging**, turn it on
3. Plug it in with a cable that carries **data**, not just power
4. Accept the *Allow USB debugging?* prompt on the phone

Then `./install-android.sh`. To watch for errors while you play:

```bash
/opt/homebrew/share/android-commandlinetools/platform-tools/adb logcat -s godot
```

### What was installed to make this work

| Thing | Where | Why |
|---|---|---|
| OpenJDK 17 | `/opt/homebrew/opt/openjdk@17` | Android tools are Java |
| Android command-line tools | `/opt/homebrew/share/android-commandlinetools` | `adb`, `apksigner`, `zipalign` |
| Godot export templates 4.7.2 | `~/Library/Application Support/Godot/export_templates/` | the prebuilt Android engine |
| Debug keystore | `~/.android/debug.keystore` | Android refuses to install an unsigned app |

Godot's paths to these live in its **editor settings**, not in this repo, so a
different machine needs them set again (Editor → Editor Settings → Export →
Android). `export_presets.cfg` *is* committed, and holds no secrets.

> The keystore here is a **debug** key. It is fine for testing on your own phone
> and cannot be used to publish to the Play Store — that needs a release key you
> generate yourself and never commit or lose.

### Testing on the Mac with the emulator

```bash
./run-emulator.sh     # boots the virtual phone and installs the game
```

**It only works with the GL Compatibility renderer**, which is why that is now the
Android default. The emulator initialises Vulkan happily — it even reports the real
Apple M2 GPU — but it cannot present a single frame, so the game starts, sits at
0% CPU and shows black forever. GL Compatibility renders fine.

Two things worth knowing when a build looks dead:

- **`adb exec-out screencap` returns solid black for GPU surfaces even when the app
  is drawing.** A black screenshot on its own proves nothing.
- **CPU load is the reliable test.** `adb shell top -n 1 | grep kedairuntuh` — a
  game rendering at 60fps is busy. Stuck at 0.0% means it is not drawing.

The emulator is good for checking that it launches, that the layout fits a real
phone shape, and that touch works. It says nothing useful about frame rate.

### A trap in project.godot

`project.godot` is a Godot config file and takes `;` for comments, **not `#`**. A
`#` comment silently swallows the setting on the line after it. Adding a `#`
comment above `textures/vram_compression/import_etc2_astc=true` removed that
setting, and since the Vulkan mobile renderer requires it, the Android export
started failing with only "configuration errors" and no explanation. If an export
suddenly breaks, look for comments in `project.godot` first.

### Keeping the download small

The APK started at **84 MB**, of which **44 MB was the table's textures** — a
4096px normal map and a 4096px roughness map for a wooden slab you see edge-on.
Godot can shrink textures at import without touching the original files: the
`process/size_limit` line in each `.import` file next to the texture. Setting the
table's to 256 and the food's to 1024 took the APK to **36 MB** with no visible
difference. Worth checking whenever a downloaded model goes in.

## Assets

The food models are from Sketchfab under CC-BY-4.0 — commercial use is allowed but
the author must be credited. See [CREDITS.md](CREDITS.md); that credit has to
appear on any store or itch.io page too.
