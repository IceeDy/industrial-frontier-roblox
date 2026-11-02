# Industrial Frontier (Roblox)

An independent Roblox prototype scaffold for a multiplayer industrial economy. The existing `IceeDy/industrial_frontier` project remains a read-only design reference; this repository is a fresh Roblox implementation.

## Prototype decisions

- Multiplayer from the first build, with server-authoritative state.
- Hybrid art direction: realistic industrial environments and stylized characters.
- Third-person camera.
- Shared, world-level economy and company inventory.
- One authoritative simulation service owns production and transactions.

## Requirements

- Roblox Studio
- [Rojo](https://rojo.space/) 7.x
- [Lune](https://lune-org.github.io/) for standalone domain tests

## Local workflow

1. Clone this repository and install the tools above.
2. Run `lune run tests/run.luau` for domain tests.
3. Run `rojo serve` and connect Roblox Studio using the Rojo plugin.
4. In Studio, create a place, connect the Rojo server, and sync the project.
5. Enable **Studio Access to API Services** only in a separate test experience when validating DataStore integration. Never test persistence against production keys.
6. Publish the place from Studio and configure experience access, collaborators, and private server settings there.

The scaffold deliberately contains no place file or Roblox credentials. Roblox Studio execution, publishing, DataStore access, and live multiplayer behavior have not been validated here.

## Layout

- `src/shared`: typed domain rules and definitions shared by server and client.
- `src/server`: server-owned transaction, production, remote, and persistence adapters.
- `src/client`: client presentation and third-person camera setup.
- `tests`: deterministic Lune tests for inventory, production, and transaction idempotency.

## Security and authority

Clients send intent only. Server handlers validate payload types, bounds, player state, rate limits, ownership, and available funds/resources before changing state. Shared modules contain deterministic rules; clients never compute authoritative balances or production results. Remote instances are server-created with explicit names. Any future marketplace, trade, or ownership transfer must be implemented as an atomic server transaction with an idempotency key.

## Persistence notes

`DataStoreAdapter` is an interface boundary with `UpdateAsync`, bounded retries, per-key serialization, and safe failure behavior. Roblox DataStore calls only run on the server. Keep payloads versioned and small, handle throttling and outages, and do not acknowledge a durable transaction until its state is saved. A shared economy spanning multiple servers needs a durable ledger/outbox design and reconciliation; a single DataStore key is not a cross-key transaction. This scaffold provides idempotency foundations, not a production-grade distributed economy.

## GitHub setup

The scaffold is published on the `initial-scaffold` branch. Do not push it to `IceeDy/industrial_frontier`.

## Manual Studio follow-up

- Create a new Roblox experience and connect it through Rojo.
- Review the default spawn and camera feel on keyboard, touch, and controller.
- Create and inspect the RemoteEvent/RemoteFunction instances after sync.
- Add map geometry, lighting, industrial environment assets, and stylized character assets.
- Configure a test universe and enable API Services only for that test universe.
- Verify two-player flows, server shutdown/rejoin behavior, and DataStore failure handling in Studio.
