# Public release validation

Run `./tools/test.sh` for 11 suites covering models, UI, Remastered form,
history simulation, graphics selection, save/continue, auto betting,
multi-horse tickets, game-over handling and the bazooka feature.

The new roster preserves stable IDs and roster size. Seeded Original fixtures
keep their established movement, finish order, payouts and RNG state; only
horse names change. Graphics tests exercise restored Classic and new
Illustrated assets, switching during a race, preference persistence and the
code-drawn animation mode.

The release workflow also checks public source exclusions, exported artwork,
pack paths and a bounded smoke launch of the Linux release runtime. Browser
startup, betting, race progression and save/reload/continue are manually
smoke-tested. Native Windows/macOS runtime behavior remains untested.

The tracked screenshots show the current credited graphics and new roster.
Historical/private screenshots and decompiled evidence are not distributed.
