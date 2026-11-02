# Industrial Frontier (Roblox)

An independent Roblox prototype scaffold for a multiplayer industrial economy. The existing `IceeDy/industrial_frontier` project remains a read-only design reference; this repository is a fresh Roblox implementation.

## Prototype decisions

- Multiplayer from the first build, with server-authoritative state.
- Hybrid art direction: realistic industrial environments and stylized characters.
- Third-person camera.
- Shared, world-level economy and company inventory.
- Server-owned services apply production and transactions.

## Requirements

- Roblox Studio
- [Rokit](https://github.com/rojo-rbx/rokit) toolchain manager
- [Rojo](https://rojo.space/) 7.x
- [Lune](https://lune-org.github.io/) for the standalone domain tests

## Local workflow

1. Clone this repository and switch to `initial-scaffold` if your clone did not check it out automatically.
2. Install Rokit using its official setup instructions, then run `rokit install` in the project folder to install the pinned Rojo and Lune versions from `rokit.toml`.
3. Run `lune run tests/run.luau` for domain tests.
4. Run `rojo plugin install` once to install the Studio plugin, then run `rojo serve` from the project folder.
5. In Studio, create or open a new place, open the Rojo plugin, connect it to the running server, and sync the project.
6. Enable **Studio Access to API Services** only in a separate test experience when validating DataStore integration. Never test persistence against production keys.
7. Publish the place from Studio and configure experience access, collaborators, and private server settings there.

The scaffold deliberately contains no place file or Roblox credentials. Roblox Studio execution, publishing, DataStore access, and live multiplayer behavior have not been validated here.

## Layout

- `src/shared`: typed domain rules and definitions shared by server and client.
- `src/server`: server-owned transaction, production, remote, and persistence adapters.
- `src/client`: client presentation and third-person camera setup.
- `tests`: deterministic Lune tests for inventory, production, and transaction idempotency.

## Security and authority

Clients send intent only. Server handlers validate payload types, bounds, rate limits, and available funds/resources before changing state. Unsupported action types are ignored. Shared modules contain deterministic rules; clients never compute authoritative balances or production results. Remote instances are server-created with explicit names. Any future marketplace, trade, or ownership transfer must be implemented as an atomic server transaction with an idempotency key.

## Persistence notes

`DataStoreAdapter` is an interface boundary with `UpdateAsync`, bounded retries, and safe failure behavior. Roblox DataStore calls only run on the server. Keep payloads versioned and small, handle throttling and outages, and do not acknowledge a durable transaction until its state is saved. A shared economy spanning multiple servers needs a durable ledger/outbox design and reconciliation; a single DataStore key is not a cross-key transaction. This scaffold provides idempotency foundations, not a production-grade distributed economy.

## GitHub setup

This scaffold is published on the `initial-scaffold` branch. Do not push it to `IceeDy/industrial_frontier`.

Suggested initial commands:

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

