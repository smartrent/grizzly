# Zwrap task parity — cross-repository implementation plan

## Scope, baselines and worktrees

Implement the task contracts in `docs/zwrap-feature-parity.md` and its summary.
This is the executable implementation plan, written before code changes in
these worktrees. Keep source-checkout/prototype worktrees untouched.

- Core: `../zipato-zwave-core-parity`, branch `feature/task-parity`, base
  `c84b752`.
- Wrapper: `../zipato-zwrap-parity`, branch `feature/task-parity`, base
  `3bcc559`.
- Grizzly: `../grizzly-parity`, branch `feature/task-parity`, base `2b25e33`
  plus a copy of the uncommitted `grizzly-zwrap` prototype/docs.
- Native builds use `ZWAVE_CORE_ROOT=../zipato-zwave-core-parity` and Grizzly's
  Zwrap profile uses `GRIZZLY_ZWRAP_PATH=../zipato-zwrap-parity`.

Copies of this plan live at the root of all three implementation worktrees.
Grizzly's copy is canonical. Record outcomes and remaining gates in
`PARITY_IMPLEMENTATION_REPORT.md`; do not label unverified behavior complete.

## Non-negotiable architecture

1. Select exactly one backend at compile time. No deployed backend switch,
   runtime override, cross-backend fallback or bidirectional store conversion.
2. Keep ZIPGateway temporarily; remove it only after Zwrap acceptance and the
   legacy support policy allow retirement. Do not delete the working fallback
   build while implementing parity.
3. Elixir owns mailbox queues, wake-up/keep-awake policy, request deadlines,
   application retries, statistics aggregation and application workflows.
4. Elixir reads/edits native SQLite directly, under explicit quiescence and
   memory synchronization. No native per-table/per-field CRUD API.
5. The native stack stays in its isolated Rust executable. The owner thread
   alone calls C; callbacks copy bounded data before C returns.
6. Add native operations only for actual radio actions, missing observations,
   initialization settings or coordination primitives.
7. Unsupported hardware/role operations must fail specifically. Never replace
   an unimplemented task with fabricated success or silently change a target.

## Work packages and dependency order

### WP01 — Compile-time builds and test separation

Dependencies: none. Owner: Grizzly.

- Read one validated early build selector (`GRIZZLY_BACKEND`) in the Mix project
  and derive the application's compile-time setting from the same input.
- Compile dispatch/supervision against that setting, not `Options.backend`.
- Reject startup/runtime selector mismatches and record the compiled backend.
- Keep unrelated serial/storage/device options runtime-configurable.
- Make wrapper dependency opt-in for Zwrap builds; keep native tooling out of
  ZIPGateway-only dependency graphs. Audit gateway-only dependencies before
  excluding them from native production artifacts.
- Isolate build outputs by backend and run test suites in separate BEAMs.
- Preserve legacy regression tests in the ZIPGateway profile. Native profile
  uses the fake API or actual fake NCP, never starts a ZIP listener for tests.
- Change prototype tests that restart the global runtime with another backend.

Acceptance:

- Two separate clean builds report their expected backend.
- Invalid build selector fails; runtime/startup attempts cannot switch it.
- ZIPGateway build/test does not compile the wrapper or invoke Cargo.
- Native profile starts no gateway/DTLS/TUN/readiness-poller process.

### WP02 — Core safety, ABI/capabilities and initialization

Dependencies: none; needed before larger payloads. Owner: core + wrapper.

- Replace the unsafe 64-byte unsolicited copy with a validated, callback-scoped
  pointer/length or sufficient bounded storage. Reject malformed sizes before
  copying; preserve full-width lengths/endpoints/node IDs.
- Validate one-byte NOP explicitly and all TX/RX/serial/provision lengths.
- Audit the native frame-buffer and request BYTE-length boundaries. Advertise
  a safe negotiated maximum; never raise a wrapper limit beyond native support.
- Add a compact capabilities/version handshake (protocol/core ABI, max payload,
  controller ID, supported radio operations) so incompatible builds fail early.
- Expose initialization RF region, power/calibration and controller identity
  settings; validate/apply before ordinary radio work and verify readback.
- Make production verbose/secret logging disabled by default; retain explicit
  diagnostic opt-in with warnings and protected logs.
- Honor cross-target CC/sysroot/Cargo settings; keep target artifacts separate.

Acceptance:

- Boundary/malformed request tests and Rust unit tests.
- Native fake-controller TX/RX including >64-byte incoming frames.
- Sanitizer coverage where toolchain/fixtures permit; document hardware gaps.
- Default builds do not emit private/network keys through normal logs.

### WP03 — SQLite maintenance ownership and repository

Dependencies: WP02 protocol extensions. Owner: coordination C/W, repository G.

- Add a bounded maintenance acquisition that succeeds only when relevant native
  NM/TX/probe work is quiescent. Return busy rather than racing active work.
- Preserve the prior probe-block state. While maintenance is held, prevent new
  native work/DB writers and reject conflicting host commands.
- Return an explicit token/generation. Resume must validate ownership and
  synchronize/reload affected native state before re-enabling work.
- If general reload cannot be proven safe, use a controlled native restart with
  startup probing blocked as an explicit conservative synchronization path.
- Serialize callers in an Elixir coordinator; monitor owner death. Before SQL
  commit rollback/release safely; after commit, failure must remain fail-closed
  until reload/restart completes. Never unconditionally unblock stale state.
- Extract SQL schema/flag/endpoint decoding from the gateway query module.
- Implement direct node/endpoint/listening/identity/health queries, including
  incomplete records. Use prepared statements, schema/network checks and bounded
  transactions. Coordinate snapshots where native multi-statement writes would
  otherwise expose intermediate state.
- Implement validated multi-row edits, cache invalidation and metadata repair.
  SQL cache removal must not be represented as RF exclusion.
- Add same-backend schema/version/backup/recovery helpers; no backend converter.

Acceptance:

- SQL tests against temporary real SQLite stores.
- Acquire during active native work returns busy; no writer proceeds in a held
  window. Invalid/stale token cannot resume another owner's operation.
- Commit then reload preserves edits; failures/owner death cannot overwrite them
  with stale native memory or permanently wedge the runtime without reporting.
- Actual ID, LR IDs, deleted/failed/probing states and endpoint aggregates
  decode.

### WP04 — Elixir request engine, mailbox and raw frame access

Dependencies: WP01/WP02/WP03 directory queries. Owner: Grizzly.

- Separate the raw device transport from controller tasks/local application
  handling; stop blanket routing management classes to node 1.
- Add raw CC send/subscription with endpoint/security metadata and cancellation.
- Match responses once using handler matchers, node/endpoint and protocol IDs.
  Serialize ambiguous requests; do not pretend Z-Wave has a ZIP request ID.
- Forward device-initiated/unmatched session frames to their owning OTA/async
  session as well as intended public subscriptions, without duplicate handling.
- Add supervised per-node sleeping queues: bounded admission, fairness,
  deadlines, cancellation, progress and optional durable logical work.
- Drain on wake-up; track Elixir awake leases. `more_info` becomes lease policy.
- Send Wake Up No More Information only after host and relevant native work
  drain; do not add native mailbox queues or policy timers.
- Preserve completion/report semantics, native death and timeout cleanup.
- Map native transmit reports into normalized diagnostics and aggregate
  counters in Elixir; obtain native-originated TX observations where missing.

Acceptance:

- Deterministic tests for sleeping/awake queues, expiry, saturation,
  cancellation,
  lease cleanup, concurrency, multipart replies and callback ordering.
- Classic/LR NOP tests; unknown raw frame tests; endpoint reply round-trips.
- Session receives unsolicited firmware requests and native failures.

### Continuation slice — native TX observations and queue ownership

Implement this slice before claiming broader statistics or cancellation parity:

- Observe accepted `ZW_SendDataAppl` work from both host calls and native
  interview/application work. Emit bounded queue/start/terminal facts with
  helper-scoped IDs, full node IDs, endpoints and requested security scheme.
- Copy optional native TX reports before returning from the callback; never
  export payloads, opaque C pointers, keys or synthetic RF/IMA measurements.
- Repair session/frame ownership on queued abort, discard and completion.
  Save callback data before freeing reusable pool slots; stop discard timers.
- Distinguish confirmed removal from the unsent queue from an active abort
  request. Active abort is not confirmed radio cancellation or rollback.
- Retire a low-level failed attempt instead of keeping a dangling parent and
  replaying it. Remove hidden C serial-resubmission/soft-reset policy. A missing
  generation-less serial callback must fail the isolated helper, not advance
  into work that could receive the stale result.
- Keep Elixir counters for this overlapping native application-pipeline view
  separate from existing host application counters. Do not add them together.
- Exercise real C queues under sanitizers, callback reentrancy/slot reuse,
  real helper/fake-NCP delivery, Rust callback copying and Elixir aggregation.

Non-goals: secure learn/reset restoration, whole-stack cancellation, raw serial
or NIF frame accounting, physical RF statistics, complete serial-health/recovery
policy and physical/target acceptance. Remaining low-level retry and callback
correlation audits must stay visible rather than be hidden by these counters.

### Continuation slice — protocol and timer maintenance guards

- Reject maintenance while native requests await reports or run completion
  callbacks, even after the application TX queues have drained.
- Add owner-thread idle predicates for S0 transport/inclusion, S2 and Transport
  Service, checking both state and registered timers. Expired-but-undelivered
  callback timers still count as pending work; passive caches are not activity.
- Audit RD pointer-bearing timers and SUC callbacks before cache invalidation.
  Do not discard live work merely to manufacture an idle window.
- Fix request completion ownership/list iteration and preserve full-width IDs
  in the existing node-abort helper. Stop old request timers on initialization
  without reusing slots beneath callbacks. Reset discard is not task completion
  or active radio cancellation.
- Cancel completed NM operation timers so they cannot affect a later task.
- Fix concrete bounded-input violations encountered in the touched S2 paths.
- Add sanitizer tests of actual native state/timers, including pending expired
  callbacks, multipart/reentrant requests, LR abort and cache-reference timers.
  Add real-helper tests proving maintenance is busy until report timeout.

This closes a defined set of quiet-window holes, not the whole writer audit.
Serial callbacks/FD lifecycle, remaining native writers, recovery/backups and
arbitrary security/provisioning SQL synchronization remain separate open work.

### Continuation slice — tracked serial TX callback ownership

- Track accepted SendData, bridge/Transport Service and NIF work below the
  application queues, including sends whose caller requests no callback.
  Refuse same-command overlap before overwriting its callback or TX buffer.
- Match command and nonzero wire callback ID, retire before callback reentry,
  and ignore mismatched/duplicate completions. The SDK echoes only eight bits:
  do not claim unlimited provenance after ID wrap or for arbitrary NCP faults.
- Keep unresolved submissions owned until genuine completion. Ambiguous
  admission replies, malformed matching callbacks or a missing-callback safety
  deadline fail the isolated helper, not a newer task. Do not silently reset
  the radio, release ownership on abort intent or add application retries.
- Include tracked serial work, dispatch and queued/partial serial RX in quiet
  checks. Reject raw SAPI attempts to bypass the tracked send commands.
- Fix NIF acceptance reporting and concrete TS busy-spin/optional-report
  dereferences exposed by this path. Separate datagram retirement from wire
  ownership; suppress retired callbacks and guard synchronous parent retirement.
  Full TS FSM/cancellation audit stays open.
- Test real production callback dispatch under sanitizers and exercise delayed,
  duplicate, mismatched and missing callbacks through the helper/fake NCP.

Host outcome: implemented with sanitizer and real-helper/fake-NCP regressions.
This bounded continuation does not complete WP05 or the full maintenance audit.

This is not an audit of every Serial API callback family. Route/neighbor/SUC,
learn/inclusion, reset/FD replacement and higher security/fragment callback
lifetimes still require their own state/ownership contracts and acceptance.

### WP05 — Native controller/radio task surface

Dependencies: WP02 ownership/ABI; Elixir dispatch from WP04.

- Add typed owner-thread initiation for learn start/stop, network update,
  NIF send, failed replacement start/stop and neighbor discovery.
- Restore disabled learn-mode FSM path only with its security/role/reset
  transitions intact; do not send raw learn commands around the FSM.
- Reuse native priority-route, background-RSSI and LR channel primitives with
  capability/region/ID validation and explicit outcomes.
- Add public-only add/learn DSK getter; do not export a private key for display.
- Generalize inclusion options/DSK challenge responses, including LR key names.
- Carry operation identity and detailed native statuses through the port where
  native callbacks have enough information; retain safe serialization otherwise.
- Add explicit terminal cancellation/state observation; no node-0 fake success.
- Preserve actual controller identity, full-width node IDs, target and source
  endpoints. Remote host administration is not the same as RF NM commands.
- Restore/test actual supported inclusion-controller/SUC handover paths where
  required, and reject unavailable remote roles rather than act locally.

Acceptance:

- Unit/port protocol coverage for every new function/event.
- Fake-NCP support for deterministic radio query/maintenance cases.
- Physical secure learn/replacement/secondary/handover validation is a required
  recorded gate; fake results alone cannot prove interoperability.

### WP06 — Provisioning, metadata, local application tasks and events

Dependencies: WP03/WP04/WP05.

- Expose complete provisioning records/TLVs through a safe bounded native store
  interface; eliminate the fixed 64-byte builder overflow risk. Preserve unknown
  metadata and define iteration behavior under changes.
- Consume durable inclusion metadata from SQLite; expose missing transient
  grants/KEX/progress/origin facts from native events.
- Adopt autonomous classic/LR SmartStart workflows without requiring a pending
  explicit add request; update Grizzly storage and inclusion consumers.
- Route supported local controller/application commands to the correct owner.
  Advertised NIF/Version/identity must match actual handlers/capabilities.
- Replace `forward_to_controller` with local task dispatch; keep RF management
  authorization restrictions. Handle Multi Command/Supervision results
  correctly.
- Route probe, busy, S2 resynchronization, serial-health, SAPI and native fault
  observations to typed Grizzly consumers. Secrets remain caller-only.

Acceptance:

- TLV set/read/iterate/delete/restart tests.
- Autonomous inclusion, metadata, event routing and local application tests.
- No outbound RPC or fake packet is required just to emit a semantic report.

### WP07 — OTA, controller maintenance and readiness

Dependencies: WP02/WP04/WP05.

- Negotiate device firmware fragment size from native and device capabilities,
  including encapsulation/CRC overhead; never use 1,024 bytes blindly.
- Reuse OTA workflow with raw session delivery, awake leases and complete
  cleanup.
- Add lifecycle/readiness operations for the one compiled backend; planned stop
  must remain stopped and restart must acquire exactly one serial owner.
- Refactor OTW runner to acquire maintenance, drain, stop the native helper,
  await FD/process exit, program/recover, restart and validate identity/state.
- Bound health checks and distinguish serial degraded, stopped, upgrading and
  initialized/probing states. Never start the other backend on failure.

Acceptance:

- OTA request/fragment/retry/status/activation workflow tests.
- Lifecycle/lease and programmer failure tests.
- Actual physical OTA/OTW and interrupted bootloader recovery remain hardware
  gates; do not claim them passed without performing them.

### WP08 — Deployment, docs, CI and eventual retirement

Dependencies: all applicable packages.

- Add reproducible build/test scripts for the three adjacent worktrees and both
  compile-time Grizzly profiles. Pin source revisions/artifact manifests.
- Run real helper/fake-NCP tests, full legacy regressions, native profile tests,
  Rust tests/Clippy, formatting and native sanitizer checks where available.
- Validate Nerves/ARM release on the actual supported target when available.
- Update README/API docs, status inventory and final implementation report.
- Track uncompleted software and hardware gates explicitly by task ID.
- ZIPGateway retirement is deliberately gated: first achieve/verify parity,
  then deprecate, establish legacy support policy and remove the legacy backend
  and exclusive dependencies. No deployment conversion machinery is required.

## Detailed proposal coverage checklist

Use these IDs from the detailed plan when reporting completion. A grouped
package is not complete just because one happy-path test passes.

- C01 learn; C02 network update; C03 NIF send; C04 DSK; C05 replacement;
  C06 neighbors: WP05.
- C07 membership; C08 failed inventory; C09 node cache/refresh; C10 endpoints:
  WP03/WP05.
- C11 routes; C12 statistics; C13 RSSI; C14 LR channel: WP04/WP05.
- C15 capabilities; C16 no ZIP transport; C17 local commands; C18 actual/remote
  controller targets: WP01/WP05/WP06.
- D01 NOP; D02 raw frames; D03 large payload/OTA; D04 endpoints; D05 unknown CC:
  WP02/WP04/WP07.
- P01 mailbox; P02 more-info/awake; P03 stats: WP04.
- P04 inclusion options; P05 DSK/LR grants; P06 metadata; P07 abort: WP05/WP06.
- P08 provisioning: WP06. P09 management context; P10 correlation: WP04/WP05.
- P11 SmartStart; P12 native events; P13 Multi Command: WP06.
- L01 lifecycle; L02 readiness: WP07. L03 listening mode; L04 Home ID: WP03.
- L05 key/Zniffer; L06 diagnostics/repair: WP03/WP06.
- L07 OTW: WP07. L08 same-backend persistence: WP03/WP08.
- L09 cross-build/deployment: WP02/WP08.
- Report-name compatibility and all configuration items: WP01/WP02/WP05/WP06.

## Execution record

- [x] Create three worktrees and copy the existing prototype without modifying
  it.
- [x] Write this implementation plan before code changes.
- [x] WP01 host implementation and validation (both production releases).
- [ ] WP02 implementation and validation.
- [ ] WP03 implementation and validation.
- [ ] WP04 implementation and validation.
- [ ] WP05 implementation and validation.
- [ ] WP06 implementation and validation.
- [ ] WP07 implementation and validation.
- [ ] WP08 software validation, final report and hardware-gate accounting.

Implementation is partial. Remaining package boxes stay unchecked until
all their software contracts and acceptance checks are satisfied. Consult
`PARITY_IMPLEMENTATION_REPORT.md` for the implemented foundations, task-by-task
remaining work and hardware gates. Reproduce host checks with
`scripts/validate_parity.sh`.

## Continuation 1 — backend isolation and inspection facades

Implement before proceeding to native initialization settings:

1. Select actual Elixir source files in the early Mix profile. Compile shared
   command codecs and compatibility facades, but never the inactive backend's
   controller/transport processes. Keep legacy process implementations intact
   behind shared sync/async calling facades.
2. Move backend-specific supervision and legacy inspection into the selected
   backend module. Remove direct ZIPGateway references from shared entry points.
3. Exclude MuonTrap, ThousandIsland, BEAMNotify and ctr_drbg from native builds;
   exclude Zwrap from legacy builds. Filter backend-specific test support too.
4. Package private assets without following source-directory symlinks. Exclude
   legacy certificates/scripts from native artifacts and install the wrapper
   executable into the selected target's application directory.
5. Add source/dependency/BEAM/private-asset assertions for both production
   builds,
   including rebuilds with stale artifacts. Preserve all legacy regressions.
6. Wire native Home ID, listening-mode and caller-only key inspection through
   the
   direct backend. Keep security-cache reset/recovery separate from RD reload.

Acceptance remains host-only until physical hardware and target releases run.

## Continuation 2 — verified native initialization settings

- Add a copied, scalar-only pre-init settings structure. Validate its presence
  mask and RF region before native startup; seal it once initialization begins.
- Preflight every requested radio setting against chip/setup capabilities before
  changing any radio setting. Check signed TX/calibration bounds at both inputs.
- Apply through the existing native serial initialization path, then verify RF
  and power readback before enabling ordinary stack work. Failed/unsupported
  settings must fail startup; no implicit region fallback or fabricated success.
- Carry optional settings through the existing port init tuple and expose only
  verified requested settings for diagnostics. Initialization failure must not
  permit a second C initialization in the same helper.
- Forward Grizzly identity/RF options without silently overriding conflicting
  nested wrapper settings. Keep product identity in native host configuration,
  not as an assertion that the NCP's own manufacturer identity was changed.
- Extend fake NCP setup support with opt-in supported/refusal/mismatch fixtures.
  Test success, unsupported capabilities, malformed inputs and failed readback.
