# Trackside Easter egg

After three completed player races across visits, a small unmarked crate appears in the track's lower-right corner during races. Background form simulations do not count toward discovery. Hovering explains the crate; clicking fires a bazooka. It is deliberately absent from Help and the title screen.

There is one shared shot per race, in either rules mode. Every horse still running has the same chance of being knocked out, including any backed horse and the current leader. Already finished and fallen horses are excluded. The projectile, burst, low synthesized boom and track notice identify the hit. The runner cannot finish or earn a payout; the surviving runners continue normally. Removing the leader can help a ticket, but never guarantees a win. Four eliminated runners void the race and refund stakes under the existing rules.

Discovery progress persists in records and saved games. Ammo, target, elimination and random state survive Save/Continue. A shot immediately autosaves. Paused races and other dialogs block firing; automatic play never fires by itself. The next race replenishes the shared round.

Verification: `tests/bazooka_test.gd` checks both modes, every target lane across 600 seeded races per mode, no duplicate shots, settlement/refunds, deterministic resume, ammo reset, and UI clicks including pause and autosave. `tests/capture_bazooka.gd` captures the crate and explosion for visual review.
