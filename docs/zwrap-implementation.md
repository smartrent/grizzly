# Zwrap backend implementation report

> Historical prototype baseline/proposal. This worktree now has a partial
> implementation beyond that baseline. Use the current progress report for
> implemented behavior, validation and all remaining task IDs.
>
> [Current progress][parity-progress] · [Execution plan][parity-execution]


**Historical prototype report:** this records the initial startup-selectable
adapter, not completion of the subsequently clarified deployment contract.
The required selector is **compile time**, one backend per firmware/release
build, with temporary coexistence followed by ZIPGateway deprecation/removal.
The current startup option still needs refactoring. Backend switching on deployed
systems and bidirectional store conversion are not requirements. See the
[current summary](zwrap-feature-parity-summary.md) and
[build/retirement plan](zwrap-feature-parity.md#24-compile-time-selection-and-zipgateway-retirement).

## Worktree

- Worktree: `../grizzly-zwrap`
- Branch: `feature/zwrap-backend`
- Base: Grizzly `2b25e33`
- Original Grizzly checkout and the wrapper/core sources were not modified.
- Changes are left uncommitted in the new worktree.

## Plan followed

The plan was recorded before implementation: locate the pre-Z/IP boundary,
create an isolated worktree, add a startup-selectable backend, retain request
semantics, translate controller operations/events, separate supervision, then
validate and document capabilities. Subsequent scope clarification allowed
bypassing the existing connection implementation rather than forcing a direct
API into its network transport abstraction.

## What changed

### Selection and dependencies

`Grizzly.Options` and `Grizzly.Supervisor` accept `backend: :zipgateway | :zwrap`
and `zwrap_options: [...]`. ZIPGateway remains the default. Selection is at
startup, not a hot switch. Invalid backend selections fail early.

A consuming application supplies the Zwrap dependency. For local development,
`GRIZZLY_ZWRAP_PATH` adds an optional path dependency without editing the project.
ZIPGateway-only builds do not acquire a Rust/core dependency.

### Correct integration boundary

`Grizzly.Connections.Supervisor` selects the direct request engine in Zwrap
mode. Its logical request processes maintain compatibility with existing
sync/async connection calls, inclusion ownership and cancellation, but use no
network transport, keep-alive or Z/IP packet logic.

`Grizzly.Requests.Request` now exposes shared, transport-neutral command, ACK
and failure handling. The original ZIPGateway path still encodes requests with
`Request.to_binary/1`; the direct path sends only `request.source` as raw
command-class bytes using `Zwrap.send_data_appl/4`.

### Native ownership and reports

`Grizzly.Backends.Zwrap` owns/subscribes to a linked Zwrap controller. Zwrap's
existing Rust **port process** remains the native isolation boundary; no NIF or
native code was added to Grizzly.

TX callbacks carry request/attempt references. Successful sends become ACK
reports, failed sends use existing retries/NACKs, and GET/Supervision/aggregate
handlers wait for application reports. Timeout and cancellation clean up timers
and registrations. A native/backend failure releases waiters, resets active
inclusion state and is recovered by OTP without replaying commands.

Incoming CC frames are decoded, matched once against pending requests for the
node/endpoint, or passed to the existing unsolicited application handler.
Multi Command processing, Supervision replies, subscriptions and storage
updates are reused. Nonzero destination endpoints use Multi Channel rather
than Z/IP encapsulation, including replies to unsolicited endpoint commands.
Trace records raw CC bytes.

### Controller operations

`Grizzly.Backends.Zwrap.Management` maps:

- secure/unsecure inclusion, abort, key grants and DSK responses;
- exclusion/abort, failed-node removal and controller reset;
- provisioning set/delete/delete-all/get/iteration.

Native intermediate/final callbacks are converted to Grizzly command reports,
so the existing inclusion server and public Network helpers continue to work
for these operations. Context-free management callbacks are serialized by
operation kind; timed-out requests retain their native reservation until the
actual callback arrives, avoiding accidental completion of a newer request.

### Startup and compatibility fixes

Zwrap mode does not start ZIPGateway's supervisor, DTLS unsolicited listener or
readiness checker. It adds `Grizzly.ready?/0` while retaining explicit
ZIPGateway-only helpers. Automatic controller firmware programming is rejected
in Zwrap mode to prevent concurrent serial ownership.

Async submission errors now propagate instead of causing pattern-match crashes.
Inclusion abort also works after keys/DSK submission, and native failure returns
inclusion to idle. Controller reset tolerates disabled association-file storage.
Existing ZIPGateway behavior remains covered by the full regression suite.

## Unsupported operations

This is **not full ZIPGateway parity**. Every rejected local command is named
in [zwrap-unsupported.md](zwrap-unsupported.md), alongside affected public APIs,
unsupported options/configuration, partial metadata/queue/statistics behavior,
native-only events, payload limits and deployment limitations.

In particular, node-list/failed-list services, ZIPGateway cached node-info
queries, learn-mode initiation, route/statistics/RSSI management, controller OTW
programming, and the Z/IP binary API are not emulated. They fail explicitly;
there is no hidden ZIPGateway fallback. Core-only operations remain available
through the owned controller PID and the full Zwrap API.

A test checks the documented inventory against all rejected built-in local
controller commands, preventing new silent documentation gaps.

## Validation

Final validation in the worktree:

| Check | Result |
|---|---|
| `mix test` without opting into Zwrap | 53 doctests, 1,206 tests, **0 failures**; 7 excluded (existing hardware tests and opt-in native integration) |
| Real Rust helper + upstream Python fake NCP integration | **1 test, 0 failures** |
| `mix credo --strict` | No issues |
| `mix format --check-formatted` | Passed |
| `git diff --check` | Passed |

The new ordinary backend tests cover backend selection, raw sends, completion
mapping, GET matching, retries/stale callbacks, concurrent sync/async requests,
Supervision, endpoints, unsolicited processing, inclusion/keys/DSK/abort,
provisioning, reset/removal, timeout reservations, unsupported operations,
malformed incoming frames, session closure and native failure recovery.

The native integration runs the actual wrapper executable and core against a
fake serial controller, restores an interview, sends Manufacturer Specific and
Version GETs, checks TX completion for a Switch Binary SET, and resets the
controller with native persistence. It does not use the mock wrapper API.

No physical-radio, secure-device, sleeping-node, OTA firmware or Nerves
cross-build validation was performed. Those are not implied by passing the
fake-controller tests.

## Usage

See [backends.md](backends.md) for dependency/build requirements and examples.
The minimal selection is:

```elixir
{Grizzly.Supervisor,
 backend: :zwrap,
 serial_port: "/dev/ttyACM0",
 zwrap_options: [data_dir: "/data/zwrap"]}
```

These are development-prototype options. The target release interface fixes the
backend at compile time; it does not switch a deployed installation. Keep native
persistence scoped to the selected build and review the unsupported-operation
inventory before claiming production task parity.

[parity-progress]: ../PARITY_IMPLEMENTATION_REPORT.md
[parity-execution]: ../PARITY_IMPLEMENTATION_PLAN.md
