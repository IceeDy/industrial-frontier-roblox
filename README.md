# Industrial Frontier (Roblox)

An independent Roblox prototype scaffold for a multiplayer industrial economy. The existing `IceeDy/industrial_frontier` project remains a read-only design reference; this repository is a fresh Roblox implementation.

## Prototype decisions

- Multiplayer from the first build, with server-authoritative state.
- Hybrid art direction: realistic industrial environments and stylized characters.
- Third-person camera.
- Shared, world-level economy and company inventory.
- Server-owned services apply production and transactions.

## Requirements

- Roblox Studio for visual iteration and publishing (not needed for local domain tests)
- [Rokit](https://github.com/rojo-rbx/rokit) toolchain manager
- [Rojo](https://rojo.space/) 7.x
- [Lune](https://lune-org.github.io/) for standalone domain tests

## Local workflow

1. Clone this repository and switch to `initial-scaffold` if your clone did not check it out automatically.
2. Install Rokit using its official setup instructions, then run `rokit install` in the project folder to install the pinned Rojo and Lune versions from `rokit.toml`.
3. Run `lune run tests/run.luau` for domain tests. This works without Roblox Studio.
4. Run `rojo build default.project.json -o outputs/IndustrialFrontier.rbxlx` to create a place model for later Studio use.
5. When a graphics-capable machine is available, install the Rojo Studio plugin and connect it to `rojo serve`.
6. Enable **Studio Access to API Services** only in a separate test experience when validating DataStore integration. Never test persistence against production keys.

The scaffold deliberately contains no Roblox credentials. Roblox Studio execution, publishing, DataStore access, and live multiplayer behavior have not been validated here.

## Layout

- `src/shared`: deterministic domain rules and definitions shared by server and client.
- `src/server`: server-owned transaction, production, building, logistics, remote, and persistence adapters.
- `src/client`: client presentation and third-person camera setup.
- `tests`: deterministic Lune tests for inventory, production, transaction idempotency, placement, logistics, and export rules.

## Current systems foundation

The server accepts planetary building, production, logistics, and export actions through `SubmitAction`. Buildings have planet IDs and local inventories. Production runs only at a compatible building. Same-planet logistics routes connect facilities with the shared company inventory; route and receiving storage capacities are enforced. Exporting from shared inventory adds credits and increases market supply. The snapshot includes planet definitions, buildings, facility inventories, and routes.

`Planets.lua` starts with three editable prototype destinations: Nova Terra, Ferrum, and Pelagia. Names and resource distributions are placeholders. The systems currently run in memory. Route transfers are player-triggered; automatic schedules, persistent saves, export contracts, and the planet-navigation UI remain follow-up work. The placement model stores grid coordinates; rendering, plot ownership, and terrain checks also need a later Studio pass.

Run `lune run tests/run.luau` after changing pure domain rules. It does not require Roblox Studio or a graphics-capable machine. Use `rojo build default.project.json -o outputs/IndustrialFrontier.rbxlx` to regenerate a place model for later Studio use.

## Security and authority

Clients send intent only. Server handlers validate payload types, bounds, rate limits, and available funds/resources before changing state. Unsupported action types are ignored. Shared modules contain deterministic rules; clients never compute authoritative balances or production results. Remote instances are server-created with explicit names. Any future marketplace, trade, or ownership transfer must be implemented as an atomic server transaction with an idempotency key.

## Persistence notes

`DataStoreAdapter` is an interface boundary with `UpdateAsync`, bounded retries, and safe failure behavior. Roblox DataStore calls only run on the server. Keep payloads versioned and small, handle throttling and outages, and do not acknowledge a durable transaction until its state is saved. A shared economy spanning multiple servers needs a durable ledger/outbox design and reconciliation; a single DataStore key is not a cross-key transaction. This scaffold provides idempotency foundations, not a production-grade distributed economy.

## GitHub setup

This scaffold is published on the `initial-scaffold` branch. Do not push it to `IceeDy/industrial_frontier`.

```sh
git clone https://github.com/IceeDy/industrial-frontier-roblox.git
git switch initial-scaffold
```

## Manual Studio follow-up

- Create a new Roblox experience and connect it through Rojo.
- Review the default spawn and camera feel on keyboard, touch, and controller.
- Create and inspect the RemoteEvent/RemoteFunction instances after sync.
- Add map geometry, lighting, industrial environment assets, and stylized character assets.
- Configure a test universe and enable API Services only for that test universe.
- Verify two-player flows, server shutdown/rejoin behavior, and DataStore failure handling in Studio.
