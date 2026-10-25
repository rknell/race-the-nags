# Remastered mode

The enhanced mode is displayed as **Remastered** (formerly Form). Existing saves keep the internal `form` id for compatibility. Original remains limited to its existing Win, Place and Show bets and recovered race rules. Quinella, Exacta, Trifecta and Box trifecta are exclusive to Remastered; see [bet rules and game payout formulas](../README.md#play).

Form is an optional new game design inspired by the user's TurtleRace clone. Original mode continues to use the recovered DOS rules. Choose either on the title screen before starting a visit; Continue always uses the saved game's mode.

## What the player sees

Every one of the 217 horses has three fixed ratings from 1 to 5:

- **Speed** raises its base racing pace.
- **Stamina** helps it maintain pace late in the race.
- **Consistency** reduces the variation in its daily performance and short bursts.

The runner list shows recent finishes and a style (fast starter, strong finisher, or all-rounder). **Racing Form** opens the full card with all three ratings, lifetime starts/wins in this mode, and the last five finishes, newest first. DNF means the jockey fell. Horses without starts are honestly shown as having no results; results come from races run by the game engine, including optional background simulation.

Traits are generated deterministically from each horse's identity using a separate generator, and stored in the records file. Race outcomes do not change those traits. Finishes accumulate across races, visits, and app restarts. With a large stable, some runners naturally have few previous starts.

On the home screen, select Remastered and choose **Build recent form → Simulate races** to run 160 background meetings without animation delays. A random 80% of the stable is eligible, giving many horses several starts while leaving some newcomers. The simulation uses the full weighted movement, hidden daily form, bursts, falls and settlement rules. It adds to existing Remastered records without players, bets, bankroll changes or high scores; Original records are untouched. Voided races add no history. The action is available once per records file. Closing the progress window cancels before any changes are applied. The completed results and one-time flag persist across restarts. Continue imports this background history into saves made before generation while preserving their field, booked odds, hidden form and race RNG.

## What stays hidden

Once a field is selected, each horse receives a hidden multiplicative race-day form roll. It lasts for that race and survives save/resume. Its spread is smaller for consistent horses. The card and published odds do not expose or read that actual roll. Reading/editing a local JSON save is outside the in-game information boundary; the save is not encrypted.

## Weighted movement

Each loop awards one weighted ballot, and only its selected horse can advance 0–5 pixels. A horse's ballot weight combines:

1. Its base speed and stamina-dependent pace at its current progress.
2. Its hidden race-day form.
3. A small publicly inferable trend from its last five results.
4. A temporary burst or lull that lasts roughly 0.7–1.6 seconds.

Finished and fallen runners receive no further ballots. No winner or finishing order is selected in advance. Speed favours early running; stamina matters later; the sustained form and bursts keep the loop from simply averaging into a fixed ordering.

Form mode runs until all surviving horses finish, so fourth, fifth and sixth are real recorded places. Falls retain the existing chance and a fourth fall voids the race. Voided races refund stakes and add no statistics or recent results.

## Published odds and money

The bookmaker forecasts from **public traits and recent results**, using a separate deterministic random generator. It samples 768 plausible performances, including possible form and movement uncertainty, then rounds inverse win-frequency estimates with a nominal 10% price reduction into the existing 2:1–20:1 range. It never uses the actual race-day form roll or consumes the racing RNG.

This is an approximate bookmaker model, not a claim that a displayed price is an exact probability or a guaranteed house edge. Rounding, the price limits, falls, and differences between forecast and full race movement allow imperfect prices. The odds affect payout only in Form mode; they never directly change movement.

Both modes keep the existing Win/Place/Show rules, integer-cent accounting, $50 opening bankroll, and betting limits. Place and Show still use reduced profits. Their economics have not been independently redesigned.

## Persistence and compatibility

Game saves now use version 2, storing the mode, profiles, current hidden form, burst values/timers, RNG state, recent results, and both modes' records. Version-1 saves restore as Original. Existing statistics and untagged scores migrate to Original.

Each mode has its own statistics, lifetime race count, Hall of Fame and Millionaires Club entries. A Form visit cannot populate Original's leaderboard. Current profiles and recent results live in the existing `nags-records.json` file under Godot `user://`, while `nags-save.json` retains the current save slot. The original DOS files are untouched.

The older native build does not understand version-2 records; reopen the rebuilt executable to use this update. Saved games are historical snapshots: restoring one restores the records captured with it, with the exception that a save made before optional background generation inherits that generated history.

## Verification

The new tests check profile stability, public/private separation, proportional ballots, trait effects, odds boundaries, all six results, bounded newest-first history, DNF and void handling, separate records, restart persistence, version-1 migration, and deterministic mid-race continuation. Late-race saves specifically cover a horse that has already crossed the line.

Four Original-mode seeded fixtures were recorded before adding the new engine. Initial fields, final movements/falls, payouts, finish order, and final RNG states match those fixtures. The implementation lives in `godot/scripts/form_racing.gd`; the Original movement branch is kept separate in `race_model.gd`.