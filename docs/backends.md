# Controller backends

## One backend per compiled build

This worktree implements compile-time selection and isolated host release
artifacts, but not full feature parity. See the current implementation report:
`../PARITY_IMPLEMENTATION_REPORT.md`.

Set the early Mix build input before resolving dependencies:

```sh
# Legacy build: no wrapper dependency or Cargo invocation.
GRIZZLY_BACKEND=zipgateway mix deps.get
GRIZZLY_BACKEND=zipgateway mix test

# Native build, in this three-worktree development layout.
export GRIZZLY_BACKEND=zwrap
export GRIZZLY_ZWRAP_PATH=../zipato-zwrap-parity
export ZWAVE_CORE_ROOT=../zipato-zwave-core-parity
mix deps.get
mix compile
mix test --include zwrap_integration
```

The selector defaults to `zipgateway`. Invalid values fail. Application backend
configuration must match this build input. Do not set it in `runtime.exs`.
`GRIZZLY_ZWRAP_PATH` selects a dependency location, not a runtime backend.

`Grizzly.Backend.name/0` reports the compiled choice. Startup options may only
assert that same choice; they cannot change it. Runtime environment changes,
application configuration, backend failure and mutable options do not select
another stack. Build outputs use separate `_build/<backend>` directories.

Both backends remain temporarily in source. Each build excludes the inactive
controller/transport implementation and dependencies. Shared command codecs
remain. ZIPGateway will be retired only after
parity, deployment and legacy-support gates are met. No deployed backend
conversion or bidirectional database converter is required.

## Native startup

```elixir
{Grizzly.Supervisor,
 serial_port: "/dev/ttyACM0",
 associations_file: "/data/grizzly-associations.etf",
 zwrap_options: [data_dir: "/data/zwrap"]}
```

Create the associations parent directory first. Runtime serial, persistence,
logging and probe options remain configurable. Never run both native stacks on
one serial device. Native initialization requires Linux, Elixir 1.19+, Rust,
a C toolchain and libclang. ARM/Nerves deployment is not yet validated.

Native mode starts no ZIPGateway, TUN, DTLS listener or ZIP readiness poller.
`Grizzly.ready?/0` reflects initialization and maintenance fault journals, not
completion of every interview or a complete serial-health state model.

Typed RF/power/product settings are forwarded, capability-checked and verified
before startup succeeds. For example, `rf_region: :us` and
`power_level: {-5, 6}` use the SDK's signed calibration values. Product settings
configure the native host, not the NCP factory identity. Conflicting nested
settings, unsupported hardware, malformed values and failed readback fail startup.
Unspecified region retains the module setting. Physical calibration and on-air
application/NIF parity are separate gates; arbitrary legacy config text is not
accepted as native configuration.

## Commands and policy

The native path sends raw command-class frames through Zwrap, without creating
Z/IP packets. Request handlers retain ACK/report/retry/deadline semantics.
Native TX contexts distinguish attempts; frames without protocol IDs cannot
provide perfect provenance after a timeout.

Elixir owns the bounded sleeping queues, cancellation, wake-up drain, awake
leases and statistics. `more_info` requests a host grace lease. Unknown mode
classification currently attempts transmission; complete mailbox policy remains
unfinished. Statistics retain separate host-application and native application-
pipeline views, not complete RF/IMA accounting.

Opted-in async sessions receive unmatched firmware requests. OTA fragments are
capped conservatively at 128 bytes; complete OTA/OTW acceptance is outstanding.
Raw incoming frames are available through `Grizzly.Events.subscribe(:raw_frame)`;
other native observations through `:native_event`. Neither includes exported
private/network keys. Do not log secret replies from direct key-export calls.

## Native transmission facts

`Grizzly.Events.subscribe(:native_event)` includes `:tx_observation` facts from
host sends and autonomous core interviews/replies. Stages distinguish queueing,
entry into encapsulation, genuine completion, confirmed unsent-queue removal
and active abort intent. Abort intent is not successful cancellation or rollback.
IDs are helper-scoped observations, not protocol IDs or cancellation handles.

`Grizzly.Backends.Zwrap.Statistics.snapshot/0` keeps the existing host `nodes`
view and a separate `native_tx` view with `:application_pipeline` coverage.
These views overlap: never sum them. Counts describe observed events, not
inferred in-flight work, all radio frames or persistent lifetime counters.
Native transport endpoints/security requests are not decoded from opaque CC
payloads or promoted to verified on-air security.

Serial FAIL retires the native attempt without hidden replay/soft-reset timers.
A missing uncorrelated serial callback fails the isolated helper, not an
arbitrary newer request. Complete health/recovery and task cancellation remain
unfinished; helper failure must not start the other backend.

## Direct SQLite access

```elixir
alias Grizzly.Backends.Zwrap.Directory
Directory.snapshot()
Directory.get_node(2)
Grizzly.listening_mode(2)
Grizzly.home_id()
Directory.edit_node(2, %{wake_up_interval: 600})
```

The directory acquires a native quiet window, closes native SQLite access,
executes a host transaction, reloads directory cache after edits, and resumes
with the previous probe-block state. Snapshot/lease acquisition can return busy.
A cache removal is not RF exclusion.

Quiet-window guards include native report waits, security/fragment work and
registered RD/protocol timers, not merely an empty TX queue. Busy can persist
while an S0 nonce exchange or fragmentation grace timer remains live. See the
[bounded native audit](zwrap-maintenance-audit.md); the complete writer/serial
callback audit is still open.

Interruption or synchronization failure leaves a `.host-maintenance` journal.
Startup refuses that journal. Inspect and reconcile it manually; do not delete
it merely to make startup succeed. This is not an implemented automatic recovery
workflow. Directory reload is not a general reload of keys, S2 SPAN or other
native caches. Do not edit unrelated stores under that assumption.

## Direct wrapper operations

```elixir
controller = Grizzly.Backends.Zwrap.controller()
Zwrap.capabilities(controller)
Zwrap.control(controller, :public_dsk, a: 1)
```

The PID changes on restart. These are privileged application calls, not remote
RF administration. Learn explicitly remains unsupported; role/hardware-specific
operations may reject. Public API coverage is not task-level parity.

## Current status and validation

- Plan: `../PARITY_IMPLEMENTATION_PLAN.md`.
- Current progress and every task ID: `../PARITY_IMPLEMENTATION_REPORT.md`.
- Original detailed proposal: `zwrap-feature-parity.md`.
- Plain-text workstream overview: `zwrap-feature-parity-summary.md`.
- Reproduce host validation: `../scripts/validate_parity.sh`.

The earlier unsupported inventory and prototype implementation report are kept
as historical baselines; their current deltas are recorded in the new report.
No physical-radio, OTA/OTW recovery or Nerves release validation is implied by
passing host/fake-NCP tests.
