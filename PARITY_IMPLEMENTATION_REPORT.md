# Cross-repository parity implementation report

## Status

This is a **partial implementation**, not completion of the entire plan.
The worktrees are suitable for continued development, not production rollout.
Unfinished software is listed below; it is not merely waiting for hardware.
ZIPGateway retirement has not been authorized or performed.

Plan: `PARITY_IMPLEMENTATION_PLAN.md`. The same plan and this report are copied
into all three worktrees. The Grizzly copies are canonical.

## Worktrees and preservation

Implementation is checkpointed as reviewable commits on `feature/task-parity`.
The worktrees retain these original baselines:

- `../zipato-zwave-core-parity`, based on `c84b752`.
- `../zipato-zwrap-parity`, based on `3bcc559`.
- `../grizzly-parity`, based on `2b25e33`, plus the previous prototype.

The original core, wrapper and Grizzly checkouts were not edited. The existing
`grizzly-zwrap` prototype was copied, not moved or modified by this execution.
No runtime fallback, deployed backend conversion or native mailbox was added.

## Implemented foundations

### Build contract — WP01 host acceptance complete

- `GRIZZLY_BACKEND=zipgateway|zwrap` selects source files and dependencies
  before
  compilation. Invalid selectors and conflicting application configuration fail.
- Shared sync/async calling facades select one process implementation. Backend
  supervision and inspection no longer reference inactive backend modules.
- Native builds exclude gateway/controller/socket processes, MuonTrap,
  ThousandIsland, BEAMNotify, ctr_drbg and legacy certificates/scripts. Legacy
  builds exclude Zwrap and its native process modules/toolchain.
- Shared Z-Wave command codecs remain intentionally available in both profiles;
  keeping a codec is not starting or packaging the other controller stack.
- The compiler prunes stale inactive BEAMs and application inventories, without
  deleting private files through source symlinks. The helper executable and its
  SHA-256/target/environment manifest belong to the dependency application
  build,
  not a shared source `priv` directory. Cargo caches are scoped by Mix
  target/env.
- Both production applications and actual host OTP releases were assembled and
  checked. Tests inject stale modules/assets before rebuilding. Changing the
  selector environment when running either release does not switch its backend.
- Native tests live under `test_native`; the legacy suite no longer compiles or
  skips native-only tests. All existing legacy test files are preserved.
- `scripts/check_backend_builds.sh` reproduces artifact/release checks. Missing
  `CARGO_BUILD_TARGET` for non-host Mix targets fails rather than shipping a
  host
  helper. Actual ARM/Nerves deployment remains unverified.

### Native safety, ABI and verified initialization

- Bounded unsolicited callback storage replaces the unsafe 64-byte copy.
  Lengths are 16-bit and checked in C and Rust before copying.
- Classic/LR NOP decoding accepts a one-byte frame only for NOP. Request lengths
  are widened at the internal BYTE boundary; application TX remains bounded at
  160 bytes. Transport reassembly/frame buffers were not blindly increased.
- ABI 2 exposes controller ID, Home ID, TX bound and implemented-operation mask.
  Grizzly rejects incompatible helpers. Public coverage is now 34 core functions
  and 21 callback variants, not a promise of complete task parity.
- Default native traffic/debug/key dumps are disabled. Optional port logs use
  mode 0600 and are not forwarded into normal BEAM logging by default.
- Typed pre-init settings cover RF region, signed TX/calibration values and host
  manufacturer/product/hardware identity. Unknown fields, invalid bounds and
  conflicting top-level/nested settings fail; explicit zero is preserved.
- Settings are copied before C startup and sealed afterwards. Every requested
  radio capability is preflighted before any radio setter. Unsupported
  500-series
  settings and missing LR support are rejected, not silently substituted.
- Radio settings use native initialization and readback before ordinary stack
  work. Power changes are reset even if RF-region commands are unavailable.
  Failed setters/readback stop startup. Unspecified RF region retains the module
  setting rather than forcing US.
- `Zwrap.initialization_settings/1` returns only requested, verified settings.
  Product values describe native host configuration, not the NCP factory
  identity
  or completion of local on-air application/NIF ownership.
- A failed initialization freezes native polling/actions and prohibits another
  C initialization in that helper; owned configuration lifetimes remain valid.
- Fake-controller tests cover supported settings, unsupported capabilities,
  mismatched readback, signed values and power that takes effect only on reset.
  A real helper/fake NCP also delivers a 100-byte application RX frame intact.

Readback does not prove regulatory compliance or physical antenna calibration.
A failed multi-setting update can leave earlier NCP writes persisted; automatic
radio-setting rollback is not promised. Physical hardware acceptance and the
remaining native input/writer audits are still outstanding.

### SQLite maintenance and direct repository

- Native acquisition checks NM, TX, report waits, S0/S2/fragment activity,
  registered protocol/RD timers, active probes, cached references and pending
  events. It drains a bounded number of pending polls first.
- A generation token pauses core polling/actions and closes the native SQLite
  connection. Untracked statements prevent declaring a successful quiet window.
- Release validates the token, reopens without startup's destructive mismatch
  clearing, checks network/schema identity and reloads directory records when
  requested. The previous probe-lock state is preserved.
- Wrapper leases are owner-monitored. Owner death does not automatically resume
  native work. Release from another owner or with another token is rejected.
- Elixir serializes transactions, validates schema 1.0, uses prepared
  statements,
  rolls back failures, and provides coherent snapshots and bounded node edits.
- Cached-node removal protects the actual controller ID and explicitly does not
  mean RF exclusion. SQL decoding is extracted into
  `Grizzly.Directory.Database`;
  the old module delegates for compatibility.
- A durable `.host-maintenance` journal survives interruption/reload failure.
  Native startup refuses a leftover journal; recovery is manual, not automatic.
- The real helper/fake NCP test commits a wake-up interval edit and verifies it
  through native interview export after cache reload.

This reload covers resource-directory records, **not arbitrary native state**.
Do not infer that SQL edits to S2 SPAN, keys, provisioning or other stores are
synchronized by it. Generic transaction callbacks are trusted internal code,
not a safe interface for untrusted SQL. Full writer/cache/timer audit, recovery
workflow, endpoint edits, backups and metadata repair remain unfinished.

### Protocol/timer maintenance audit and request ownership

- Empty TX queues no longer permit maintenance while native requests wait for
  reports, continue multipart delivery or execute callbacks. Report callback
  slots stay reserved until their multipart return value is known; terminal
  callbacks can safely reuse a freed slot while callback depth blocks reload.
- Request TX contexts use helper-local generations, not recycled pool pointers.
  Retired/duplicate callbacks cannot finish a new request in the same slot.
  The existing report-wait abort helper handles LR IDs and snapshots generations
  safely across callback-driven list mutation, without aborting fresh work.
- Request initialization stops old timers and retains generation continuity.
  Resetting underneath a callback fails closed. Other reset discard behavior
  remains legacy behavior, not a completed task cancellation/restart workflow.
- Callback timer readiness includes expired-but-undelivered and currently
  dispatching callbacks. A stopped/rearmed timer rejects an older queued expiry
  instead of firing the new callback early.
- S0 transport/inclusion, S2 and Transport Service now expose narrow internal
  idle predicates. Live S0 nonces block maintenance rather than having their
  tick-aged lifetime extended across a paused stack. Passive caches and empty
  nonce housekeeping are not counted as active protocol work.
- RD checks pointer-bearing retry/NIF/find timers, retained NIF endpoints and
  SUC callback waits, in addition to probe state/reference counts. Reload
  rechecks readiness before freeing records. The dead-node worker retains a
  numeric node ID and looks up the current cache after resume, not an old
  pointer.
- NM's ResetState path stops operation/cancellation timers. The public idle
  observation uses the stronger protocol/directory predicates.
- S2 wrapper bounds now protect short ordinary/Multi Channel commands, bounded
  Multi Command inspection and the separate 50-byte nonce-report buffer.
  Transport Service uses actual full-width identity/bridge declarations.
- A third C sanitizer harness exercises actual request, S0/S2 and fragmentation
  state, timer reuse, multipart/reentrant callbacks, LR abort and S2 bounds.
  Real-helper tests prove maintenance stays busy through a report wait and can
  succeed after the timeout or inclusion abort retires its operation timer.

Scope and exclusions: `docs/zwrap-maintenance-audit.md` in the Grizzly worktree.
This is not a completed whole-stack writer/serial callback audit. It adds no
native CRUD, automatic journal recovery or arbitrary security-store reload.

### Tracked serial sends and Transport Service continuation

- SendData (0x13), bridge/TS (0xA9) and NIF (0x12) retain one wire owner
  per command, including sends with no caller callback. Same-command overlap
  rejects before overwriting the shared callback or command buffer.
- Completion matches command and nonzero SDK callback ID; ownership retires
  before callback reentry, while dispatch depth still prevents maintenance.
  Queued RX, partial frames and pending serial ACK state also prevent quiet.
- Explicit FALSE admission releases an unaccepted send. Missing/malformed
  admission, truncated matching status, reset under tracked work or an
  unresolved 65-second safety deadline abort the isolated helper. Blocking
  SDK calls can delay deadline checks. No radio rollback, reset or application
  retry is inferred; UART framing retries remain unchanged.
- Raw SAPI cannot bypass these three tracked send commands. Partial/older TX
  extensions retain genuine status but omit unavailable metrics. Serial frame
  bounds reserve space for the length byte and outgoing framing overhead.
- NIF serial ACK now means accepted submission, not immediate failure or radio
  success. Its eventual completion preserves actual target/native status.
  Real-helper Grizzly tests exercise this path with controller IDs 1 and 7.
- TS wire ownership survives protocol reset/terminal completion. Datagram epochs
  suppress callbacks from retired datagrams; one parent completion clears
  ownership/timers before callback reentry. Rejected admission cannot busy-spin
  or inspect a synchronously retired low-level session. Optional reports remain
  optional rather than becoming fabricated zero measurements.
- A fourth C sanitizer harness tests actual serial send/dispatch, reentry,
  callback-free sends, explicit rejection, queued early callbacks, duplicates,
  wrong IDs/commands, ID wrap, malformed/missing replies and fail-closed reset.
  Existing harnesses add TS retirement, late callbacks and synchronous failure.
  Fake NCP tests add delayed/duplicate/mismatched/missing callback cases.
- Both new regression boundaries were checked against core `9ccabe2`: an old
  or mismatched callback prematurely completed newer work, and synchronous TS
  completion caused an ASan/UBSan null-session fault. Both pass after the fix.

This remains a bounded audit. Eight-bit SDK IDs wrap: arbitrary ancient
callbacks after ID reuse cannot be distinguished from new completions. There
is no lifetime-255 cap, but qualified NCP callback lifetime/reuse behavior is
still a production gate, not established by these tests. Route/neighbor/SUC,
learn/inclusion and higher security/fragment/reset/FD lifetimes remain open.
No public operation/cancellation identity or complete writer audit is claimed.

### Elixir transport policy

- Bounded, volatile sleeping-node queues; deadlines, cancellation, owner
  cleanup,
  wake-up drain and serialization of same-node/same-class requests.
- `more_info` is an Elixir grace lease, not a native mailbox setting. Async
  application sessions can hold longer, bounded leases.
- No More Information waits for host queues/leases and a native idle
  observation.
- Classification uses the direct directory. Unknown/unavailable classifications
  still attempt transmission; this is not a complete sleeping-device policy.
- Opted-in async sessions receive unmatched firmware requests. Incoming raw
  frames and typed native events have subscriptions.
- Application TX/RX statistics are aggregated in Elixir with explicitly limited
  coverage. Known route speeds are normalized without fabricating IMA values.
- OTA uses a conservative fragment cap of 128 bytes and session delivery. This
  is not proof of a complete OTA workflow or physical firmware transfer.

### Native TX observations and queue ownership

- Core emits queued, started, completed, unsent-queue cancellation and active
  abort-request facts for `ZW_SendDataAppl`, including autonomous interview and
  reply traffic. IDs are helper-scoped u32 values, wrap after UINT32_MAX, and
  are observations rather than protocol IDs or cancellation handles.
- Facts preserve full node IDs, endpoints, original requested security scheme,
  unencapsulated frame length and genuine completion status/report when present.
  Requested AUTO is not relabeled as verified on-air security. No payload,
  pointer, opaque caller context or key is exposed by this event.
- Rust copies callback data before returning to C. Grizzly forwards the event
  and aggregates `native_tx` in Elixir, separately from host application counts.
  These views overlap; they must never be summed. Neither counts every RF
  frame, raw SAPI command, NIF, security exchange or transport fragment.
- Queued abort/discard now free their frames; completion/abort/discard preserve
  callbacks before freeing reusable slots and stop discard timers. Immediate
  process-event queue rejection releases ownership instead of accepting work.
- Low-level TX failure now retires the frame before completing its parent.
  The old failure path retained the frame and could call a retired parent or
  replay a finished request. Hidden native serial-resubmission and soft-reset
  timers were removed; host retries/recovery remain Elixir policy. NCP routing
  retries requested through transmit options are unchanged.
- A missing serial callback cannot safely be correlated to later work, so its
  existing watchdog now aborts the isolated helper rather than fabricating a
  failed completion and advancing the queue. Grizzly sees helper failure, not
  RF rollback or successful cancellation. Planned restart/recovery remains
  unfinished.
- Targeted C sanitizers exercise pool saturation, 800 queued aborts, reentrant
  callback slot reuse, low-level discard/failure, one-byte NOP, event-queue
  rejection and watchdog process isolation. Fake NCP tests observe autonomous
  interview traffic and a failed attempt followed by successful fresh work.

This does not complete task cancellation: active abort is only intent, queued
removal is the narrow confirmed outcome, and the full Grizzly cancellation API,
security/transport timer audit, serial correlation and reset lifecycle remain
open. Statistics describe events actually observed across subscription/reset
boundaries; they do not infer in-flight counts or certify physical radio work.

### Native inspection facades

- Native `Grizzly.home_id/0` returns current uppercase hexadecimal identity, not
  a value scraped from gateway logs. Listening mode uses a coordinated directory
  read and handles virtual nodes without querying the physical directory.
- Assigned-key/Zniffer exports are caller-only. The wrapper captures keys and
  Home ID in one owner-thread turn without polling C between reads, preventing
  a reset from pairing one network's keys with another network's Home ID.
- Real helper tests exercise controller IDs 1 and 7, protected cache removal,
  local identity, FLIRS listening mode and explicit rejection of remote node-1
  administration when the controller is 7.
- Add/learn public DSK getters now have end-to-end Grizzly report-handler tests.
  No private ECDH key is exported merely to display a DSK.

### Radio operations and provisioning

- Owner-thread bounded operations for network update, NIF, failed replacement,
  neighbor update, priority routes, RSSI, LR channel and public-only DSK.
- NIF completion has an explicit callback; immediate failure is not accepted as
  a successful send. Some operations are wrapper-only, not Grizzly facades.
- Learn start/stop explicitly return unsupported. The disabled secure/reset FSM
  has not been bypassed with raw serial commands.
- General callbacks preserve native status; NIF adds operation identity.
- Local controller routing and inclusion/lifeline defaults use the actual ID,
  not a silently substituted node 1. Remote administration is still unsupported.
- Provisioning set input is bounded at 1,024 TLV bytes. Builders, callback
  copies,
  report buffers and short headers are checked, including the separate 512-byte
  SmartStart report buffer. Unknown non-critical TLVs are retained.
- Provisioning get/iteration carry full TLVs and handle empty DSKs correctly.
  A fake-NCP test round-trips an unknown TLV larger than the old 44-byte limit.

## Validation performed

Host results for these worktrees:

- ZIPGateway profile: 53 doctests, 1,184 tests, zero failures (six excluded).
  The earlier count included native-only tests, now in a separate test tree.
- Zwrap profile, including actual Rust helper/fake NCP: 42 tests, zero failures.
  This is not a substitute for the separately executed legacy suite.
- Wrapper including native/fake-NCP integration: 54 tests, zero failures.
- Rust: 32 unit tests passed; strict Clippy passed.
- Strict Grizzly Credo covers source, both test trees and build support.
  Elixir/Rust formatting and whitespace checks passed.
- Four C host bounds, TX ownership, maintenance and serial harnesses passed
  ASan, UBSan and leak detection: RX/TX bounds, provisioning, initialization,
  transport queues, request generations, security/fragment state, timer reuse,
  reentrant callbacks, LR report-wait abort, TS retirement, SDK callback IDs,
  missing/malformed replies and fail-closed watchdog behavior.
- Both production profiles compile with warnings-as-errors. Actual host OTP
  releases pass dependency/artifact checks and retain their compiled backend
  despite the opposite runtime selector environment. Stale-artifact repair and
  rejection of unspecified cross-target builds are tested.

Reproduce with `scripts/validate_parity.sh` in the Grizzly worktree. Logs and a
source manifest are written to `/tmp/zwrap-parity-validation` by default.
The C harness is targeted coverage, not sanitizer certification of the entire
native stack. Existing C warnings remain. No physical radio or ARM/Nerves
release validation was performed.

## Task-ID accounting

"Partial" means code exists but some contract, facade or acceptance evidence
is missing. No package or group is complete merely because a unit test passed.

### Controller tasks

- C01 open: secure learn FSM/security/reset integration.
- C02 partial: native update and Grizzly mapping; end-to-end task acceptance.
- C03 partial: actual-helper NIF acceptance/completion through Grizzly for IDs
  1/7; full radio/role coverage remains open.
- C04 implemented on host: add/learn public DSK and Grizzly report contracts.
- C05 partial: native replacement initiation; stop/security/workflow parity.
- C06 partial: native neighbor operation; complete controller-task tests.
- C07 partial: cached inventory only; reconcile actual radio membership.
- C08 partial: decoded flags only; failed-inventory task surface.
- C09 partial: reads/edits/reload and protocol/timer/tracked-serial guards;
  complete writer audit, refresh/recovery and cache semantics remain open.
- C10 partial: endpoint snapshots; aggregates and validated multi-row edits.
- C11 partial: wrapper route primitives; Grizzly tasks and route validation.
- C12 partial: host and native application-pipeline observations/counters;
  complete diagnostic facade, coverage and physical acceptance remain open.
- C13 partial: RSSI wrapper operation; hardware validation/task facade.
- C14 partial: LR primitives/region checks; full eligibility and task tests.
- C15 partial: ABI/identity/bounds handshake, not complete controller
  capabilities.
- C16 implemented on host: native command path starts no ZIP/DTLS listener.
- C17 open: local controller application ownership and truthful advertised NIF.
- C18 partial: IDs 1/7 and remote-target rejection tested; remote/role/handover
  contracts and identity-change lifecycle remain outstanding.

### Device transport

- D01 partial: NOP boundaries and native path; physical classic/LR acceptance.
- D02 partial: raw receive subscription; complete Grizzly raw-send/cancel API.
- D03 partial: conservative payload/OTA limits; complete negotiated OTA
  workflow.
- D04 partial: existing endpoint path; full source/security/endpoint contracts.
- D05 partial: raw unknown RX visible; unknown-CC send/session interface.

### Policy and workflows

- P01 partial: volatile bounded queues; full sleeping-node/fairness/admission
  policy.
- P02 partial: awake leases; renewal, maximum-awake and complete policy tests.
- P03 partial: separate overlapping host/native-pipeline counters in Elixir;
  persistence, complete diagnostics and all-radio coverage remain open.
- P04 open: full inclusion options, including detailed security/role choices.
- P05 partial: baseline DSK/key interaction; all challenge sizes and LR grants.
- P06 open: complete durable/transient inclusion metadata consumption.
- P07 partial: unsent-queue removal and full-width native report-wait abort;
  active abort remains intent, not task-level cancellation. Stop paths still use
  synthetic failed status reports; exclusion stop no longer fabricates success.
- P08 partial: bounded TLV preservation; iteration mutation/restart acceptance.
- P09 partial: request generations, tracked SDK IDs and TS datagram epochs;
  complete public operation identity/cancellation remains unfinished.
- P10 partial: class serialization/session routing; protocol-ID/multipart
  coverage.
- P11 open: autonomous classic/LR SmartStart application workflows.
- P12 partial: native event subscriptions and TX statistics consumer; remaining
  typed consumers and complete health/recovery policy are unfinished.
- P13 open: complete Multi Command/Supervision outcome and authorization
  semantics.

### Lifecycle and deployment

- L01 open: planned stop/restart and maintenance ownership across helper
  replacement.
- L02 partial: initialization/readiness and journal faults; full health state
  model.
- L03 implemented on host: public direct listening-mode inspection. Full
  sleeping
  policy remains tracked under P01/P02.
- L04 implemented on host: public Home ID inspection without gateway log state.
- L05 partial: caller-only key/Zniffer inspection with coherent identity. Safe
  SPAN clearing/capture workflow is still open; RD reload is not security
  reload.
- L06 partial: direct diagnostics/limited edits; complete repair/audit
  workflows.
- L07 open: OTW drain/stop/FD release/program/recovery/restart workflow.
- L08 partial: schema checks/journals; backups and same-backend upgrade
  recovery.
- L09 partial: Cargo target artifact lookup; isolated target packaging and
  deployment.

## Next implementation order

1. Audit remaining serial callback families (route/neighbor/SUC, NM/security),
   establish NCP callback lifetime/reuse contracts, and finish writer/reference/
   timer coverage. Implement recovery, endpoint edits and directory tasks.
2. Replace synthetic cancellation with task-level cancellation and native state
   confirmation; complete correlation and raw/session APIs.
3. Implement secure learn, full inclusion/replacement options and autonomous
   SmartStart; validate roles and local application/NIF ownership.
4. Complete OTA workflow tests and OTW/lifecycle maintenance, including identity
   refresh and serial ownership across reset/restart.
5. Extend observations beyond the native application pipeline, finish health
   consumers, security-cache workflows and configuration/capability contracts.
6. Validate physical classic/LR/S2 hardware, interrupted updates and actual
   ARM/Nerves releases. Only then revisit ZIPGateway retirement gates.
