# Task-level feature parity: Grizzly on Zwrap

> Historical prototype baseline/proposal. This worktree now has a partial
> implementation beyond that baseline. Use the current progress report for
> implemented behavior, validation and all remaining task IDs.
>
> [Current progress][parity-progress] · [Execution plan][parity-execution]


Start with the [feature-parity summary](zwrap-feature-parity-summary.md) for the
ownership decisions, grouped work checklist and delivery order. This document
contains the full proposals, source findings and acceptance criteria.

## Goal and status

**Goal: Grizzly must be able to accomplish the same Z-Wave tasks with Zwrap as
with ZIPGateway. Recreating ZIPGateway's command API, Z/IP packets, sockets,
logs, or database service names is not the goal.**

**Deployment model:** select exactly one backend at compile time for each
firmware/release build. Keep both implementations temporarily for separate build
profiles; do not support changing a deployed installation from ZIPGateway to
Zwrap or back. The end state is to deprecate and completely remove ZIPGateway,
not to preserve a permanent dual-backend architecture. Post-deployment backend
switches, runtime fallback and bidirectional store migration are not parity
requirements.

The current prototype still selects its backend through supervisor startup
options. It must be refactored to meet this compile-time contract; documenting
the target does not mean that change is already implemented.

This is a proposal for `backend: :zwrap`, not a statement that parity is
implemented. It reviews every section of
[zwrap-unsupported.md](zwrap-unsupported.md), including its report
commands, partial semantics, helpers, deployment restrictions and ignored
configuration. That document remains the inventory of the current integration.
Names of new interfaces below are illustrative, not existing APIs.

The review is based on the current Grizzly worktree, wrapper sources and
`zipato-zwave-core` revision `c84b752`. Source references `[S1]`–`[S12]` are listed
at the end. Changes fall into three categories:

- **G** — Grizzly changes, using existing native capabilities/data.
- **W** — wrapper/port changes, exposing or safely carrying native functionality.
- **C** — core changes, including its public C API, active implementations and
  persistence. Every new public C operation/event also needs **W**, not a direct
  call from Elixir into an internal C symbol.

A wire command name identifies an existing use case in this review; it does not
prescribe the implementation. Existing public Grizzly results can be retained
with semantic report adapters, without constructing Z/IP packets.

### Navigation

- [Existing SQLite and active-core findings](#1-findings-that-change-the-plan)
- [Architecture and database ownership](#2-target-architecture-and-data-ownership)
- [Compile-time selection and ZIPGateway retirement](#24-compile-time-selection-and-zipgateway-retirement)
- [Controller tasks C01–C18](#3-unsupported-controller-requests-task-by-task-proposals)
- [Report and notification outcomes](#4-reportnotification-commands-preserve-outcomes-not-outbound-emulation)
- [Device I/O D01–D05](#5-device-io--payload-forms)
- [Partial-support tasks P01–P13](#6-every-partial-support-item)
- [Helpers and deployment L01–L09](#7-helpers-diagnostics-and-deployment)
- [Configuration mapping](#8-every-ignored-configuration-item)
- [Delivery phases and acceptance](#9-proposed-implementation-order-and-completion-gates)
- [Inventory and public-entrypoint crosswalk](#10-coverage-of-the-original-inventory)

## 1. Findings that change the plan

### 1.1 The core already has a real SQLite resource directory

The wrapper's `native/zwrap_port/build.rs` compiles
`pal/RD_DataStore_Sqlite.c` and bundled SQLite. It does **not** compile the
similarly named `pal/RD_DataStore_Sqlite_custom.c`, which contains stub methods.
The active database includes the following persisted data [S1], [S2]:

| Table | Useful existing data | Parity tasks it can help satisfy |
|---|---|---|
| `nodes` | `nodeid`, `mode`, `state`, `probe_flags`, `security_flags`, `properties_flags`, wake-up interval, last-awake/update times, product IDs, name, DSK, CC versions | Node inspection, listening mode, cached interviews, health state, security metadata, scheduling |
| `endpoints` | Node/endpoint IDs, `info`, `aggr`, name/location, endpoint state, icon IDs | Endpoint counts/capabilities, aggregated membership, controller application inspection |
| `network` | Home ID, local node ID, schema major/minor | Identity, network binding, migration validation |
| `s2_span` | Persisted security-session state | Quiesced diagnostics/session reset; **not** an application-facing key export API |
| `ip_association`, `virtual_nodes`, `gw`, `peer` | Legacy gateway-oriented records | Migration/diagnostics where relevant; their existence does not prove the IP features are active |

Provisioning and native configuration/key persistence also have separate files;
**not everything is in this SQLite database**. The existing public interview
export already returns node modes, endpoints and much of the metadata, but only
for completed interviews. It omits live node/probe state and can reject failing
nodes. It is not a general inventory or health-query API [S3].

Accordingly, the earlier inventory's references to a missing gateway database
must not be read as “there is no database to query.” Grizzly's existing
`ZIPGateway.Database` is primarily a file-query module, not a database daemon
that must be recreated. Its decoding and transactional edit helpers can be
extracted and reused [S4]. Missing native getters/setters for persisted RD data
are often deliberate: **Elixir is expected to read and edit SQLite directly,
coordinating with the core so the two do not collide.** That is the default
parity strategy, not a temporary workaround before adding native CRUD APIs.

### 1.2 Presence in the source tree is not proof of working functionality

The **active build** contains both deliberate architectural omissions and
functionality that still needs work [S1], [S5], [S6], [S8]. In particular,
mailbox omission is intentional, not a core defect to repair:

- Learn-mode initiation in `NM_IDLE` is inside `#if 0` in
  `pal/CC_NetworkManagement_custom.c`. Adding a public function alone will not
  make learn mode work.
- Mailbox handling is intentionally absent from the core. Sleeping-node queues,
  wake-up scheduling and application policy belong in Elixir/Grizzly, where OTP
  makes them much easier to implement and supervise. The native TX FIFO serves
  immediate radio work only; it must not grow into a sleeping-node mailbox.
- `ima_send_data_start` / `ima_send_data_done` in `pal/misc_defines.c` do not
  implement the original IMA accounting. Gather the underlying TX observations
  and calculate/store statistics in Elixir; exposing the header alone or
  restoring a native policy module is not the intended solution.
- Some inclusion-controller handover helpers are stubs. Secondary/remote
  controller parity requires implementation/testing of those paths.
- The public notification union discards information that exists earlier in the
  native pipeline. For example, provisioning TLVs and detailed management
  statuses are not recoverable in Grizzly from the current callbacks.
- Unsolicited RX currently copies into a 64-byte C buffer before the wrapper
  sees the length. This is a core memory-safety issue, not just an Elixir limit.

## 2. Target architecture and data ownership

### 2.1 Put the backend boundary at tasks, not simulated connections

Introduce backend-neutral services/behaviours for:

1. **Directory**: membership, node/endpoint snapshots, health, freshness and
   targeted re-interview.
2. **Controller**: identity/capabilities, inclusion/exclusion/learn/replacement,
   network maintenance, provisioning and radio configuration.
3. **Command I/O**: typed commands and raw CC frames, endpoints/security options,
   TX results, request matching and cancellation; Grizzly/Elixir owns mailbox
   queues and wake-up scheduling.
4. **Lifecycle/maintenance**: start/stop/readiness, exclusive serial ownership,
   OTW updates, diagnostics and backup/migration.

`Grizzly.Network`, `Node`, `Inclusions`, firmware runners and public helpers
should use these services. ZIPGateway implements them with its existing
mechanisms; Zwrap implements them with native calls and directory data. Keep
logical request/session processes where ownership/cancellation need them, but
do not make socket “connection” semantics the core abstraction.

A compatibility dispatcher may interpret an old local `send_command` request
and call a task service. It must not become another ZIPGateway command engine.
Pure application CC commands still use the same Grizzly encoders/handlers.
Administrative host operations and application commands must retain distinct
security boundaries. The active core blocks RF access to network-management
CCs; do not remove that protection just to make a local task router convenient.
Remote administrative access needs explicit authentication/authorization.

### 2.2 Direct SQLite access with coordinated ownership

**Default implementation: G reads and edits the existing SQLite database.**
Extract a backend-neutral, schema-aware repository from `ZIPGateway.Database`,
resolving the actual `core_database_path`/`data_dir` used by Zwrap. Use Exqlite,
prepared statements, transactions and validated Elixir data structures for node,
endpoint, cache and maintenance tasks. Do not introduce a C getter/setter for
each field or make a new core snapshot API a prerequisite for parity.

The core normally maintains native RD state; Elixir acquires an exclusive
maintenance window for coordinated edits. The radio/NCP remains authoritative
for actual membership, keys in use and RF operations. An SQL cache edit does
not include/exclude a device, change the radio's Home ID or rekey its network.

#### Existing coordination and what this checkout verifies

The current public interface includes `zipatoZwaveCoreBlockNodeProbe`,
`zipatoZwaveCoreUnblockNodeProbe` and startup blocking. Zwrap already exposes
`block_node_probe`, `unblock_node_probe` and `node_probe_autostart_block: true`.
Use these mechanisms as the starting point, not a fabricated missing-query API
[S2], [S3], [S5].

At revision `c84b752`, `rd_probe_lock()` sets the probe-lock flag and emits a
blocked event. This is not, by itself, proof that every database user is idle:
`current_probe_entry` may still exist, other callbacks/timers can update RD, and
`rd_get_node_dbe()` returns an in-memory `ndb[]` record rather than rereading
SQLite. Existing interview import separately checks that probing is blocked
**and** no probe is active, then updates memory and persistence [S2], [S3].

Therefore verify/document the intended pause/resume contract, including its
scope and cache synchronization. If the current controls leave a gap, add only
the missing quiescence acknowledgment or reload/invalidation primitive through
C/W. That supports direct SQL access; it is not a reason to replace it with
native CRUD APIs. Do not assume `:blocked` means a database connection has been
closed, every writer has drained, or all edited rows will automatically reload.

#### Elixir-owned coordinated access protocol

Implement a supervised database-access coordinator in Grizzly:

1. Serialize maintenance callers; preserve prior probe-block state and any
   nested ownership. Stop admitting conflicting Grizzly radio/NM/interview work.
   Request the existing native pause/block (or start with probing blocked).
2. Establish quiescence for the records being read/edited: drain active work and
   verify relevant callbacks, probe timers, health updates and other DB writers
   cannot race the window. Keep the port/core event loop running to drain work;
   simply stopping polling is not a safe pause. Use a narrow C/W coordination
   extension only if the exposed controls cannot establish this condition.
3. Check schema version, network binding and allowed changes. Open a bounded
   SQLite transaction, using write ownership such as `BEGIN IMMEDIATE` for
   edits. Update node/endpoint rows and dependent data atomically; commit or
   roll back. Use busy handling as error recovery, not as a substitute for
   ownership or native-state synchronization.
4. Synchronize/invalidate/reload affected native in-memory records **before**
   they are used again. Use an existing supported synchronization path where
   its semantics fit. Completed-interview import is available but normalizes
   states and is not a generic “reload arbitrary SQL edits” operation. If a
   narrow reload primitive is absent, a controlled native restart with startup
   probing blocked can be a conservative fallback, subject to tests of startup
   normalization. It must not accidentally factory-reset the radio or overwrite
   the edits during recovery.
5. Invalidate/update Grizzly caches and publish changes only after commit and
   native synchronization. Restore the previous admission/probe state and
   resume. On failure before commit, roll back and restore safely; after commit
   but before successful synchronization, keep affected work blocked and recover
   deliberately. Do not unconditionally unblock in an `after` clause if that
   would let stale native state overwrite the committed edits.

Monitor the maintenance owner, bound wait times and recover from owner death,
SQLite busy/I/O errors, failed synchronization and native restart. Neither a
permanent pause nor an unsafe automatic resume is acceptable.

For ordinary read-only inspection, use short read transactions when the
consistency contract permits. When a coherent multi-table snapshot is required,
use a coordinated window or a consistent backup. The current native writer
performs delete/reinsert sequences without an enclosing transaction; a reader
transaction alone can observe an intermediate autocommitted state. Atomic core
writes are useful hardening for concurrent readers, **not a mandatory redesign
before a verified pause-based SQL workflow can work** [S2].

#### Data semantics and boundaries

- Reconcile persisted membership with NCP classic/LR membership when freshness
  matters; `rd_probe_new_nodes()` already reads both masks. Do not turn stale RD
  tombstones into phantom network members.
- Decode `mode`'s low-byte value separately from flags; distinguish
  `STATUS_FAILING`, probe failure and unknown health. SQL reads can include
  incomplete/failed nodes that completed-interview export rejects.
- Validate writes against state-machine invariants and preserve related rows.
  Editing metadata, requesting a cache-state transition, and changing physical
  radio/security state are different operations.
- Version decoders for `cc_versions` and security-session blobs; native blobs
  are not portable interchange formats. Normalize Home ID byte order/signed
  SQL integers and establish timestamp clock domains before computing ages in
  Elixir.
- Network keys and provisioning also have separate persistence; do not pretend
  an RD SQL row can substitute for their real stores or live security state.

**Missing persisted-data APIs are not automatically missing core features.**
Only missing low-level coordination, radio actions or information that is not
available in the shared store should require native API additions. Optional
mailbox jobs remain separate Elixir-owned state; the core need not implement
mailbox tables or scheduling.

### 2.3 Mailbox and scheduling ownership: Elixir only

This is a design decision, not one option among equivalent implementations:

- **Grizzly/Elixir owns** per-node queues, admission limits, fairness, deadlines,
  cancellation, optional durable work, retry/backoff policy, wake-up estimates,
  missed-wake-up policy, keep-awake leases, OTA transaction scheduling and queue
  progress notifications. Use supervised OTP processes and timers.
- **Core owns** RF/security/encapsulation, immediate bounded TX execution and
  native interview execution. Resource-directory persistence is shared with
  Elixir through the coordinated SQL protocol in section 2.2. The core exposes
  frames, TX outcomes and relevant native busy/probe observations through Zwrap.
- **W/C additions only where necessary:** expose missing observations or a small
  explicit probe-control/host-managed-wake-up primitive if native work could
  otherwise conflict with Grizzly. Do not add native mailbox queues, durable
  application jobs, wake-up timers or lease-expiration policy.
- Grizzly decides when to send Wake Up No More Information, using the existing
  application-send API once its work is drained and relevant native work is
  quiescent. Keep native automatic sleep handling disabled in this mode. A new
  native awake-lease manager is not a prerequisite.

Prefer the existing notifications and send APIs first. Introduce a core change
only for a demonstrated missing low-level capability, not to move an easier
Elixir coordination problem into C.

### 2.4 Compile-time selection and ZIPGateway retirement

**G build/configuration work:** use one early build-profile input to determine
backend-specific source paths, dependencies/artifacts and compile-time
application configuration. The selected dispatcher/supervisor code can read
`Application.compile_env/3`; it must not choose a backend from supervisor
arguments, runtime configuration or a deployed process environment.

Proposed application configuration contract (not yet implemented by the
startup-selectable prototype):

```elixir
# Build-time configuration, not config/runtime.exs.
config :grizzly, :backend, :zwrap
# A separate legacy build uses :zipgateway instead.
```

Build requirements during temporary coexistence:

- Each firmware/release image is fixed to one backend. Changing the build input
  requires rebuilding the affected application/release, not restarting Grizzly
  with different options. Runtime selector attempts must be rejected rather
  than silently selecting the other implementation.
- Dependency selection happens early enough for Mix to construct the correct
  graph. Keep it consistent with the compiled backend value. A Zwrap build
  includes the wrapper/helper and core; a ZIPGateway-only build must not require
  Rust/core sources. Do not mistake `GRIZZLY_ZWRAP_PATH`, a source-location
  option, for the backend selector.
- Package only the selected backend implementation and its required artifacts;
  exclude dependencies exclusive to the other backend. Audit shared code/types
  for references to omitted backend modules. Keep shared dependencies genuinely
  needed by Elixir SQLite, radio/application logic or firmware tooling.
- Maintain separate build/cache outputs and CI jobs for the two profiles. Run
  common task contracts in each, plus backend-specific tests. Replace prototype
  tests that switch the running global supervisor between backends with
  separate-build tests; mocks can still isolate individual task components.
- Permit ordinary device/serial/persistence settings appropriate to the compiled
  backend, but not a selector hidden in runtime options. Native crash recovery,
  OTW maintenance and intentional stop/start always operate the same compiled
  backend; there is no automatic ZIPGateway/Zwrap failover.
- No deployed-system backend migration or reverse data converter is required.
  Retain ordinary backup/recovery and same-backend schema/release upgrades.
  Build/deployment metadata should identify the selected backend so artifacts
  and persistence are not accidentally mixed.

Retirement path:

1. Keep the legacy ZIPGateway build working while closing Zwrap task parity and
   proving it on required radios/devices/targets.
2. Make Zwrap the default for new builds once those acceptance gates pass;
   deprecate the ZIPGateway backend and ZIPGateway-specific public/config APIs.
3. Establish a support policy for remaining legacy deployments. Do not assume
   retirement requires or authorizes an in-place backend conversion.
4. Remove the ZIPGateway implementation, exclusive build dependencies/artifacts,
   transport/listener/process code, obsolete configuration and compatibility
   shims. Remove the selector when Zwrap is the only supported backend.

Shared task services are a way to preserve application behavior during this
transition, not an obligation to maintain two implementations forever.

## 3. Unsupported controller requests: task-by-task proposals

Each numbered item gives the replacement task, implementation and acceptance
criterion. A “capability error” below means a genuine hardware/role/protocol
restriction, not an excuse to leave a software parity gap unimplemented.

### C01 — Learn mode: `learn_mode_set`

**Task:** join/leave another controller's network, start/stop learn mode, report
security bootstrap and optionally interview completion.

**C + W + G:** restore/refactor the disabled learn start path into a typed
controller operation, using the existing NM/S2 FSM rather than issuing a raw
Serial API learn command from Elixir. Support classic/NWI/NWE modes, cancellation,
probe locks, role changes, keys and Home/local-node-ID changes. Enrich callbacks
with operation ID, raw/final status, new identity, granted keys and KEX result.
Invalidate old Grizzly directory state only after the real network transition;
connect this operation to `Grizzly.Inclusions.learn_mode/1` and stop [S5].

**Accept:** include/exclude the controller as a secondary, authenticated S2 join,
stop/timeout/failure, restart in the new network, and interview-completion events.
No stuck busy state and no success manufactured on acceptance.

### C02 — Network update: `network_update_request`

**Task:** synchronize a secondary controller with the SUC/SIS and refresh its
network view.

**C + W + G:** expose a typed network-update operation around the existing
`ZW_RequestNetWorkUpdate`/`NetworkUpdateCallback` path. Retain detailed results,
reconcile classic/LR membership and trigger RD probes as appropriate. Preserve
the primary-controller no-op semantics of
`Grizzly.Network.request_network_update/1`; do not reset the network [S5].

**Accept:** secondary gains/loses expected members after synchronization; primary
no-op, missing SUC, timeout and failure produce distinct terminal results.

### C03 — Controller NIF send: `node_information_send`

**Task:** advertise the local controller to a selected node or broadcast.

**C + W + G:** expose `send_node_information(destination, tx_options)` via the
existing NM/`ZW_SendNodeInformation` path, using the actual local node identity
and configured advertised classes. Preserve security/role-dependent NIF handling
and TX outcome; never advertise an unsupported controller service [S5], [S8].

**Accept:** target receives a valid NIF, low-power/default options work where
supported, broadcast/unicast and TX failures are reported correctly.

### C04 — Controller DSK: `dsk_get`

**Task:** display the controller DSK needed for inclusion/learn workflows.

**G + W, small C extension recommended:** add a **public-only** native DSK getter
with the add/learn selector. Existing `get_ecdh_key_pair` could serve the
currently selected key, but exports a private key unnecessarily and currently
reads selector 0. The old NM path derives the DSK using the selected add/learn
keystore; reproduce that choice, not “first 16 bytes of whichever key we have.”
Return the correct public-key prefix and format it with Grizzly's DSK type [S7].

**Accept:** displayed DSK matches the controller's challenge in both modes and
survives restart as intended; no private key is returned/logged for this task.

### C05 — Failed replacement: `failed_node_replace`

**Task:** replace a failed device while retaining its node ID and associations.

**C + W + G:** expose replacement start/stop, secure/unsecure options and detailed
NM progress/completion. Reuse existing replacement/S2 code, but audit active
handover stubs and refresh RD/SQLite only on confirmed replacement. Retain the
requested ID and distinguish “node still works,” replacement timeout, bootstrap
failure and successful replacement [S5].

**Accept:** a failed classic device is replaced under the same ID, S2 interaction
works, failure leaves the old record explainable/retryable, and unsupported LR
replacement is reported based on real controller/protocol capability rather
than truncating the ID.

### C06 — Neighbor discovery: `node_neighbor_update_request`

**Task:** ask a node to rediscover its neighbors / repair its topology.

**C + W + G:** expose the existing NM neighbor-update operation, including its
watchdog, node ID, progress and final status. Do not implement it by replacing
the SQLite node record. Use full-width IDs at the public boundary and reject
LR mesh-only operations only where the protocol truly does not apply [S5].

**Accept:** a supported node completes the update; missing callback, unreachable
node and cancellation do not leave NM busy indefinitely.

### C07 — Node inventory: `node_list_get`

**Task:** enumerate the real network plus Grizzly virtual devices.

**G using SQLite and existing radio access:** query the native directory directly
for persisted membership and node state, including incomplete interviews. Return
the actual controller ID and a clear cached/current status; exclude deleted/stale
RD tombstones and native virtual/proxy IDs as appropriate, then merge Grizzly's
application virtual devices exactly once. Coordinate consistent reads as in
section 2.2. Do not require completed-interview export or a new native node-list
API just to enumerate persisted rows.

Where current NCP membership is required, reconcile with classic/LR masks using
existing native reconciliation or safe serialized read-only Serial API access.
Add a narrow C/W radio observation only if the required live membership cannot
be obtained that way. A persisted SQL roster is not proof that an excluded node
is still allocated on the NCP [S2], [S3], [S6].

**Accept:** `get_node_ids`, `get_all_node_ids`, `all_node_ids` work after restart,
before interviews finish, after exclusion/reset, with a local ID other than 1,
and with LR/virtual nodes. Stale DB rows do not become phantom live members.

### C08 — Failed-node inventory: `failed_node_list_get`

**Task:** report nodes believed unreachable, without classifying normal sleepers
as failed.

**G using SQLite and observed traffic:** query persisted
`state`/`MODE_FLAGS_FAILED` directly through the Elixir repository; no native
failed-list getter is needed. Distinguish probe failure from operational failure.
Grizzly owns sleeping-node health policy based on wake-up interval/last-heard
state and mailbox deadlines. If health decisions are persisted back into RD,
use the coordinated SQL-edit/synchronization protocol, not concurrent writes
against stale native records. Make health provenance explicit; do not add a
second native missed-wake-up policy.

Audit native success/failure observations and existing dead-node checks; expose
only genuinely missing observations or disable conflicting automatic policy as
needed. A protocol failed-node query is a separate radio observation, not
automatically equivalent to RD health [S2].

**Accept:** a listening node becomes failing after qualifying TX failure and
recovers on traffic; an ordinary sleeping node is not marked failing after one
missed ACK; timed-out sleepers and restarted states follow a defined policy.

### C09 — Node information and refresh: `node_info_cached_get`

**Task:** retrieve node information, respect cache age, and explicitly refresh it.

**G for cached reads and cache management:** implement `Grizzly.Node.get_info`
from direct `nodes`/`endpoints` queries, including incomplete/failed/probing
records. Decode freshness and `max_age` in Elixir using the native clock contract.
Missing or incomplete information must not be confused with an absent node; a
new C directory getter is unnecessary.

For `force_update` or stale data, coordinate with the native pause/resume
mechanism. If the documented native resume behavior supports scheduling a probe
from edited persistent state, apply the complete validated node/endpoint state
transition in a SQL transaction, synchronize/reload memory, and resume. Test
that this actually starts and completes the intended probe: changing a flag in
SQLite alone is not enough when native memory remains cached. If a targeted
probe trigger or completion observation is genuinely missing, add that small
control/event through C/W, using existing RD machinery such as
`rd_register_new_node` / `rd_register_node_probe_notifier`, rather than a family
of cache CRUD APIs. Preserve DSK/security and do not re-interview the whole
network unnecessarily [S2], [S3], [S5].

**Accept:** cached reads make no unnecessary radio requests; forced/stale reads
refresh the requested node, preserve DSK/security, report partial/timeout status,
and behave sensibly for sleeping devices. Grizzly storage mirrors completed
native changes rather than becoming a second conflicting interview owner.

### C10 — Endpoint cache

Names: `network_management_multi_channel_capability_get`,
`network_management_multi_channel_end_point_get`.

**Task:** inspect discovered endpoint counts, device classes, supported/controlled
CCs and aggregated membership, even while the device sleeps.

**G through direct SQLite reads:** decode existing `endpoints.info`, `aggr` and
node/endpoint state in the shared database. Exclude root endpoint 0 from
individual-endpoint counts and account for aggregated endpoints correctly.
Use a coordinated snapshot when counts and rows must agree; no native endpoint
query API is needed. Metadata/cache repairs use coordinated SQL edits and native
synchronization. Expose freshness and offer targeted refresh as in C09. Direct
application Multi Channel queries are an explicit refresh/fallback tool, **not**
a replacement for cached inspection of a sleeping device [S2], [S3], [S5].

**Accept:** cached root/individual/aggregate capabilities match native records,
including security CC markers and LR IDs, without waking the device.

### C11 — Priority routes: `priority_route_get`, `priority_route_set`

**Task:** inspect/set/clear a controller's preferred route to a mesh node.

**C + W + G:** add typed route operations around existing
`ZW_GetPriorityRoute`/`ZW_SetPriorityRoute`, inside the core's serial owner.
Validate repeaters, speed, routing domain and route deletion/default behavior;
return applied/read-back state. A read-only `sapi_resp` prototype is possible,
but Grizzly must not contain ad hoc unchecked serial offsets or mutate routing
behind the native owner [S6].

**Accept:** route round-trip and clearing work on supported hardware, survive as
specified by controller NVM, and reject LR mesh routing where inapplicable.

### C12 — Statistics: `statistics_get`, `statistics_clear`

**Task:** inspect/reset cumulative per-node reliability, route and transmission
statistics (`Grizzly.Node.get_statistics/1`).

**G accounting/persistence; C + W only for missing observations:** calculate
per-node counters, route changes and timing aggregates in Elixir from native TX
observations. Implement statistics queries/reset in the Grizzly repository or
storage adapter, with an explicit reset/restart contract, rather than restoring
a native IMA policy module or adding native statistics CRUD APIs.

Full parity must include core-originated interview/security/maintenance traffic,
not only Grizzly-originated sends. If those observations are not already
available, expose start/completion facts at the native hooks with full-width
node IDs and documented units. Core changes stop at reporting the facts; Elixir
does the accounting. SQLite's existing node records are not themselves an IMA
statistics table, so define Grizzly-owned storage separately where required
[S6], [S8].

**Accept:** known TX success/no-ACK/route-change sequences produce defined
counters, include native-originated traffic, reset atomically and handle counter
overflow/LR addressing. Missing radio measurements are unavailable, not zero.

### C13 — Background RSSI: `rssi_get`

**Task:** observe channel noise, both on demand and through monitoring.

**C + W + G:** expose typed reads using the existing `ZW_GetBackgroundRSSI`
implementation. Normalize signed values, channel count and special sentinels;
reuse the same result for `Grizzly.background_rssi/0` and a backend-neutral
periodic monitor. Monitor scheduling belongs in Grizzly and must not monopolize
the serial loop [S6].

**Accept:** correct per-channel results on supported regions/chips, bounded
polling, no bogus dBm for unsupported/unavailable readings, clear status on
radio failure.

### C14 — LR channel: `zwave_long_range_channel_get`, `zwave_long_range_channel_set`

**Task:** inspect/change LR radio channel policy.

**C + W + G:** expose `GetLongRangeChannel`/`SetLongRangeChannel` through typed
operations and capability metadata. Validate region/chip support, retain
automatic/manual selection semantics, read back effective settings and schedule
required reinitialization safely. Keep this separate from LR node-ID support
[S6].

**Accept:** configured and effective channel agree after restart where intended;
non-LR hardware/regions return precise capability errors, not fake success.

### C15 — Application/controller capabilities: `application_node_info_get`

**Task:** inspect the actual controller/application NIF and command-class support.

**G + C + W:** provide a controller-capabilities service combining native
security/transport/management capabilities and Grizzly's application handlers.
Expose the current NIF and allowed configuration through the core; use existing
NIF construction as the source, not a hard-coded ZIPGateway compatibility list.
Ensure advertised support matches where incoming commands are actually handled
[S8]. In particular, Grizzly's local `version_command_class_get` shortcut must
reflect effective capabilities, not imply that a native management service is
available merely because Grizzly has its encoder.

**Accept:** queries and over-the-air NIFs agree with configured features and
security level; unsupported features are not advertised as implemented.

### C16 — Z/IP artifacts: `zip_packet`, `keep_alive`

**Task equivalence, G + W/C diagnostics:** do **not** implement Z/IP as part of
Zwrap. Replace envelope/ACK handling with raw CC sends, TX status, request
lifecycle and native health/heartbeat/serial responsiveness. Raw debugging is
covered in D02 and readiness in L02. Preserve traceability/cancellation and
failure detection, not keep-alive packets or TUN endpoints.

**Accept:** normal device operations, diagnostics and recovery work with no
ZIPGateway process/socket/packet. Applications with custom ZIP envelopes have an
explicit migration to raw frames/options, not silently changed byte semantics.

### C17 — Other local application commands sent to `:gateway`

**Task:** exercise a local controller/application function without knowing its
transport.

**G + C/W as needed:** replace blanket rejection at `:gateway` with a local
command/task router. Native transport/security/controller services execute in
the core; Grizzly-owned Association, Version, Manufacturer Specific, device
identity and other advertised application CCs execute in Grizzly handlers. Audit
existing local/forwarded command callers and support every advertised task;
never claim CC support solely because an encoder exists.

**Accept:** local commands and incoming over-the-air requests reach the same
appropriate owner with the same effective configuration. Genuine unknown
services still fail explicitly; arbitrary local commands are not sent to node 1.

### C18 — Local/remote controller identity and management endpoints

**Tasks:** operate the local controller when its ID is not 1; perform supported
secondary/inclusion-controller operations against another controller; address a
local application endpoint.

**G + SQLite identity read:** replace the hard-coded `[:gateway, 1]` test with an
explicit local-controller target and the **actual** local ID from the native
network record, validated after initialization. Keep 1 only
as a documented legacy alias where unambiguous, not as a source identity. Route
local endpoint operations through the application router with typed endpoint
metadata rather than rejecting every nonzero local destination.

**C + W + G for genuinely remote management:** audit each existing
`controller_id`/remote `node_id` use. Use real over-the-air controller-replication,
SUC/SIS or Inclusion Controller procedures where the remote role/device supports
them; implement the active handover stubs and security state transitions. Do not
assume a remote device accepts a gateway's local management CCs over RF. For a
remote *hosted* controller that needs administrative actions with no RF
procedure, provide an authenticated task-level Grizzly-to-controller service
backed by that host's Zwrap API, not Z/IP emulation or a disguised local call.
This needs an explicit deployment/protocol decision, not just an ID exception.

**Accept:** local ID 5 works everywhere; genuine remote requests reach the remote
controller, cannot reset/include on the local controller accidentally, and
unsupported remote hardware/protocol roles are identified accurately [S5], [S8].

## 4. Report/notification commands: preserve outcomes, not outbound emulation

The task behind each entry is receiving or producing the corresponding result.
These do not each need an outbound local controller RPC. The mapping below
covers every report name in the unsupported inventory. **G** creates semantic
reports/events or exposes a new backend-neutral result; **C + W** preserves
missing source data. Never serialize a legacy 8-bit report to carry an LR ID.

| Existing names | Proposed outcome/implementation | Validation |
|---|---|---|
| `default_set_complete`, `failed_node_remove_status`, `node_remove_status` | Retain existing mappings, add operation IDs and detailed raw results; clear Grizzly/native caches only after confirmed successful reset/removal. C + W + G. | Busy/failure does not erase local metadata; success updates both directory and membership. |
| `dsk_report` | Public-only DSK result with correct mode, C04. | Matches actual add/learn key. |
| `learn_mode_set_status`, `network_update_request_status` | Detailed task progress/final events, C01/C02. | Correct identities, cancellation and final failure reason. |
| `failed_node_replace_status`, `node_neighbor_update_status` | Task results for C05/C06 with affected node and operation ID. | A late completion cannot complete another operation. |
| `node_add_status`, `extended_node_add_status` | One full-width semantic inclusion result; optional legacy report adapters, richer metadata from P06. | Classic/LR, security-failed and successful results retain full data. |
| `included_nif_report` | Expose node-found/NIF progress from native inclusion; bind it to the operation/node. Add fields/events at the native NM source if absent. C + W + G. | An inclusion consumer can inspect the observed device before final completion. |
| `node_add_keys_report`, `node_add_dsk_report` | Retain interactive prompts; include operation ownership and requested key/fragment semantics, P05. | Replying to an expired/different inclusion is rejected. |
| `smart_start_join_started` | Native autonomous SmartStart-start event plus Grizzly inclusion lifecycle, P11. | Start/progress/result delivered without a pending explicit `node_add`. |
| `priority_route_report`, `rssi_report`, `statistics_report`, `zwave_long_range_channel_report` | Results of C11–C14; translate only at the facade/report boundary. | Typed units/capabilities and task outcomes, no manufactured measurements. |
| `s2_resynchronization_event` | Emit typed resynchronization reason/node from the active S2 layer; feed existing Grizzly telemetry/events. C + W + G, P12. | Real resynchronization produces one event with reason, not log scraping. |
| `failed_node_list_report`, `node_list_report` | Directory/membership results, C07/C08. | State completeness and LR IDs preserved. |
| `node_info_cached_report`, `network_management_multi_channel_capability_report`, `network_management_multi_channel_end_point_report` | Directory snapshots/refresh results, C09/C10. | Cache age, endpoint classes and partial state are accurate. |
| `node_provisioning_report`, `node_provisioning_list_iteration_report` | Full provisioning entries and iteration, P08. | TLVs/status survive set/read/restart. |
| `application_node_info_report` | Controller/application capability result, C15. | Reflects effective native and Grizzly services. |

If a caller intentionally uses a report command to implement an application CC
server, route it through the explicit local/raw application service, not the
controller-operation dispatcher (C17/D02). Rejecting unsolicited *outbound*
management reports is not itself a lost task if no operation ever required
sending them; results and application-server behavior must nevertheless work.

## 5. Device I/O / payload forms

### D01 — `no_operation` / `Grizzly.ping/2`

**Task:** test RF reachability and obtain TX statistics without changing device
state.

**W + G, C audit/fix:** permit a one-byte NOP through a dedicated ping or safe
send path. Audit command classifiers, logging and buffer code for two-byte
assumptions. The native send layer already recognizes classic NOP and converts
it for an LR destination; preserve that behavior [S6]. Do not send an arbitrary
GET as “ping,” pad a classic NOP blindly, or bypass the radio owner with raw
SAPI TX.

**Accept:** classic/LR reachability, no-ACK, sleeping-device policy and optional TX
stats all work; short input is memory-safe.

### D02 — `Grizzly.send_binary/2` / binary mode

**Task:** send custom raw CC commands, receive unimplemented frames and debug a
radio/device without implementing a Grizzly command module first.

**G using existing W initially:** add explicit `send_frame`/`subscribe_frames`
interfaces with binary CC payloads, contexts, endpoints/security options, RX/TX
metadata and ownership/cancellation. Keep frame access separate from decoded
command subscriptions. Provide migration examples or a temporary ZIP-specific
adapter only at the old API boundary; do not reinterpret a ZIP packet as CC
bytes or build a ZIP server for Zwrap.

**Accept:** unknown CC frames can be sent/received unchanged, with proper node and
endpoint information; cancellation and native death release the caller.

### D03 — Payloads above 255 bytes / device OTA

**Task:** update device firmware and send/receive larger supported application
messages.

**G first:** negotiate firmware fragment size from *both* device and backend
capabilities, accounting for command headers, CRC, security/endpoint overhead
and OTA protocol constraints. Grizzly currently defaults to 1,024-byte firmware
fragments and sends with `more_info: true`; the current Zwrap integration cannot
be called OTA-parity merely because it supports async sends [S10].

**C + W for full supported transport sizes:** audit every length/buffer across
public API, runtime, `zw_frame_buffer`, send/request, S0/S2, Transport Service,
Serial API and RX callbacks. `SendDataAppl` has a 16-bit length and Transport
Service is compiled, but that does not prove the entire path accepts a larger
frame. `ZW_SendRequest` still narrows length to `BYTE`, frame allocation has a
fixed-capacity bound, and RX has the unsafe 64-byte copy [S3], [S6]. Add validated
lengths/capability maxima and owned/bounded RX buffers before raising limits.
Do not split arbitrary CC payloads into invented messages: use actual supported
Transport Service or OTA's own fragment protocol.

**G event routing:** deliver device-initiated firmware fragment requests/status
frames to the active OTA runner/session even when they do not match a pending
GET. Currently unmatched frames go only through the global unsolicited route,
whereas the old async connection also notified its owner. Preserve both intended
session ownership and public subscriptions without duplicate processing.

**Accept:** full OTA negotiation, fragments/retries, device-initiated requests,
activation/reboot, large inbound reports, awake leases and failure cleanup on
classic/S2 devices. Test boundary sizes in native sanitizers; test LR/TS only
within the radio/device capabilities actually available.

### D04 — Endpoint bit addressing / source endpoint selection

**Task:** control multiple endpoints or a node from a chosen local application
endpoint, and receive enough metadata to reply correctly.

**C + W + G:** retain `destination: 0..127` for unicast compatibility and expose
richer typed send options derived from native `ts_param_t` (`sendpoint`,
`dendpoint`, flags, security policy), rather than requiring users to build ZIP
headers. Extend validation and local endpoint dispatch; the active
router currently drops traffic for local destination endpoints above 0. Bit
addressing must follow Multi Channel rules and must not promise a separate ACK
from every bit-addressed endpoint [S6], [S8].

**Accept:** nonzero source/destination endpoint round-trips, supported bit masks,
correct replies and RX metadata, no double encapsulation and no silent truncation.

### D05 — Unimplemented application commands

**Task:** use a new/vendor command without waiting for full codec support.

**G:** retain backend-independent Grizzly codecs, add the raw-frame escape hatch
from D02, and preserve unknown frames as optional raw events rather than dropping
them completely. Keep malformed-frame rejection/diagnostics; fuzz decoders and
allow adding a codec independently of either backend.

**Accept:** known commands decode as before; unknown well-formed frames reach raw
subscribers; malformed input cannot crash the backend or be misrepresented as a
valid semantic command.

## 6. Every partial-support item

### P01 — Sleeping-node queue delay/pings

**Task:** submit work to sleeping devices, execute it on wake-up, observe queue
progress, expire/cancel it and avoid declaring an asleep device dead.

**G — implement the mailbox entirely in Elixir:** add one supervised,
wake-up-aware scheduler in Grizzly, using native directory mode/wake-up data and
RX wake-up events. Use bounded per-node queues, request deadlines, cancellation,
fairness and accurate queued/in-flight/completed states. Persist logical work
only where the product contract requires restart survival; BEAM PIDs/references
are not durable work identities. Do not submit to the short native TX queue
until the node is awake, so the port's native send watchdog is not abused as a
multi-hour mailbox timer.

Grizzly also owns keep-awake leases and decides when to send Wake Up No More
Information. Coordinate application work, OTA and native interview activity
using existing notifications first. If required, add only W/C observations of
per-node native work or a minimal explicit probe-control primitive to establish
quiescence before sending the sleep command. Lease timers, expiration, recovery
and queue policy stay in Elixir. Keep native automatic mailbox/sleep handling
disabled; **implementing or restoring a mailbox in the core is out of scope by
design**, not an alternative approach [S8].

Estimate next wake-up from available observations but label uncertain estimates.
Expose real queue progress/deadline events; adapt old `queued_delay`/`queued_ping`
reports if useful without fabricating Z/IP NACKs or claiming exact wake times.

**Accept:** sleeping lock work runs at wake-up, multiple callers drain fairly,
queue-full/cancel/expiry/restart are deterministic, and native probes cannot put
the node to sleep midway through an application transaction.

### P02 — `more_info: true`

**Task:** keep a just-awakened node available for a multi-step transaction/OTA.

**G — Elixir keep-awake policy:** replace the flag with an explicit “keep awake
while work/lease is active” policy using P01. Grizzly delays Wake Up No More
Information until the owning transaction and relevant native work complete or
its bounded idle timeout expires. Map the old option onto this policy for
compatibility; it need not be a ZIP flag or a native lease mechanism. W/C work
is needed only if the existing API lacks a necessary native-work observation or
control; no mailbox or lease timer belongs in the core.

**Accept:** consecutive GETs/OTA fragments complete in one wake session where the
device permits; leases end on cancellation/error and cannot hold nodes forever.

### P03 — Transmission statistics and background monitor

**Task:** preserve link-quality diagnostics and application-facing signal metrics.

**G now:** make `transmission_stats: true` normalize existing `:native_tx_report`
fields into backend-neutral statistics: ticks to documented time units, route/speed decoding, hop RSSIs and
sentinels, signed power/noise where specified, and derived bars only from valid
measurements. Keep the raw native map for diagnostics. Reuse the same RSSI/bar
rules across backends rather than requiring ZIP IMA header extensions.

**C + W only for missing observations:** expose RX RSSI/security/routing metadata
and native-originated TX facts not already available. C12's cumulative accounting
and persistence stay in Elixir. C13 supplies background RSSI; schedule the monitor
in Grizzly. Never fabricate measurements unavailable on a chip or applicable
only to LR.

**Accept:** comparable existing public metrics on representative radios, explicit
unavailable values, correct units and active monitor configuration; native-only
traffic is included in full cumulative statistics.

### P04 — Inclusion options / `node_add` modes / `tx_opt`

**Task:** include securely/unsecurely, use supported range/power/explore modes,
and cancel without losing network control.

**C + W + G:** replace fixed-mode helper functions with typed inclusion options.
The active helpers hard-code `TRANSMIT_OPTION_EXPLORE` (Grizzly `:explore`) and sequence 1; expose
supported modes/options, operation identity and effective choices through the
NM FSM. Preserve validations that are actual protocol/radio restrictions, not
wrapper omissions [S5].

**Accept:** every mode/options combination currently accepted by Grizzly's
ZIPGateway backend is either performed on equivalent hardware or rejected for a
specific demonstrated capability restriction. Secure bootstrap and cancellation
remain correct under nondefault options.

### P05 — S2 DSK lengths / LR key types

**Task:** authenticate the intended including device and grant the correct
classic/LR security classes.

**G:** expand Grizzly's security key model for LR and translate names consistently,
including Grizzly `:s2_access_control` versus native `:s2_access`; the existing
wrapper already accepts LR grant keys. Treat an inclusion prompt
as an operation-scoped challenge. Support accept/reject without confusing two
concurrent/expired workflows.

**C + W:** expose an explicit DSK response with validated byte fragment/length
and acceptance, rather than only a 16-bit PIN helper. Retain current 0/2-byte
forms as convenience methods. Accept only lengths the actual S2 challenge and
protocol require; “arbitrary lengths in a legacy field” is not a useful feature.

**Accept:** unauthenticated, PIN, supported alternative challenge lengths,
rejection, CSA and LR grant combinations; no key downgrade or reply to a stale
challenge.

### P06 — Inclusion metadata / intermediate statuses / LR reports

**Task:** know what joined, with which security, why bootstrap failed and what
phase the inclusion is in.

**G reads persisted metadata; C + W expose missing transient facts:** obtain
durable security/DSK/node information from SQLite rather than requiring a new
native getter. Native events still need operation/node and origin
(manual/SmartStart/remote), raw status and any effective grant/KEX/progress data
not retained in the store. The active NM code has richer `grantedKeys`,
`kexFailType` and DSK information than the public union exposes. Preserve facts
before they are discarded, then correlate them with a consistent directory read
in Grizzly; retain operation history on the Elixir side where needed [S2], [S5].
Use full-width semantic node IDs, independent of classic/extended wire layouts.

**Accept:** successful, security-failed and aborted inclusions deliver distinct
results; persisted metadata survives restart; progress is not reported as a
completed inclusion; LR IDs and key classes are preserved.

### P07 — Abort acceptance versus completion

**Task:** stop inclusion/exclusion and reliably know when starting another
operation is safe.

**C + W + G:** add operation-scoped cancel requests, cancel-accepted and terminal
cancelled/failed outcomes, plus controller/NM state queries. Finish cancellation
only when the native FSM is idle or has a defined recovery state. Give every
operation exactly one terminal event, including races where success precedes
cancel. Replace the current synthetic `:failed`/`:done` node-0 statuses with an
explicit cancellation result (adapt old reports only at the facade if necessary).

**Accept:** stop/start loops, device-found/cancel races, watchdog recovery and
native restart never complete the wrong operation or claim an actual removal.

### P08 — Provisioning metadata reads and 44-byte builder limit

**Task:** create, inspect, modify and iterate complete SmartStart entries,
including name/location, bootstrapping/status and LR joining metadata.

**C + W + G:** expose typed provisioning records or raw TLVs directly from the
native provisioning store, with bounded owned copies and a stable iterator.
Keep known TLV decoding in Grizzly if convenient, populate `meta_extensions`
from actual data and preserve unknown TLVs. Replace the fixed 64-byte command builder with validated allocation/native-store
operations; the 44-byte current set-TLV bound is a builder limitation, not a
reason to lose the task. Do not create a second independent Grizzly provisioning
list or query the RD SQLite node table for records not yet included [S9].

**Accept:** all supported metadata round-trips across restart, updates do not erase
unrelated TLVs, iteration/delete-all have defined concurrent-mutation behavior,
and maximum lengths are validated before any native copy.

### P09 — Management concurrency / timeout reservations

**Task:** operate safely under concurrent callers and recover/retry after timeouts.

**C + W + G:** introduce opaque operation IDs or contexts for every asynchronous
management operation, not just application sends. Return accepted/busy and
provide status/cancel/completion for that ID. Grizzly can queue conflicting tasks
and allow safe concurrent directory reads; the core can still serialize its
single NM state machine. Add a recovery deadline/state query so one lost callback
does not reserve a slot forever. A caller timeout must not free buffers that C
may retain or cause unsafe automatic replay.

**Accept:** late/duplicate callbacks, client death, timeout/cancel and restart
cannot complete a new operation; clients can determine whether a timed-out
operation actually completed. Real serial/NM exclusivity is preserved.

### P10 — Response correlation

**Task:** return the correct response to each concurrent GET/custom handler.

**G first:** serialize indistinguishable requests per node/endpoint/CC/matcher,
coalesce safe identical reads, and use protocol transaction/session identifiers
where available. Keep different matching requests concurrent when unambiguous.
Define unsolicited and multipart handling explicitly.

**W/G optionally use existing `send_request`; C for stronger matching:** native
`ZW_SendRequest` carries contexts and matches node/endpoints/CC/command/security,
but has a small fixed request pool and does not distinguish arbitrary payload
matchers or identical requests. Merely using it does not create a wire-level
request ID. Expand its matching/lifecycle API if native correlation is chosen,
and avoid racing both native and Grizzly consumers for the same frame [S6].

**Accept:** overlapping GETs with differing matcher fields, identical GETs,
response-before-TX-callback and multipart replies reach the intended callers
exactly once; unrelated notifications remain visible.

### P11 — Autonomous SmartStart inclusion

**Task:** provision a device and receive the same usable inclusion lifecycle when
it joins without an explicit pending add request.

**C + W + G:** expose the SmartStart-start event from the native NM branch that
already constructs `COMMAND_SMART_START_JOIN_STARTED_REPORT`, and preserve final
classic/LR outcomes with origin/DSK/operation identity. Grizzly must create/adopt
a lifecycle for autonomous inclusion, update its inclusion/storage handlers,
and reconcile the directory after completion. Do not require a request reference
that could never have existed [S5], [S9].

**Accept:** provision then power up classic/LR devices; start/progress/final results
reach consumers once and survive application reconnect/reconciliation. No silent
security downgrade or missed automatic join.

### P12 — Native-only notifications

Every native-only name from the inventory gets an owner/consumer below. Not all
need a fake Z-Wave command report; structured Grizzly events are appropriate.

| Native event | Proposed handling |
|---|---|
| `rd_probe_event` | G consumes existing events for refresh completion, readiness detail and directory cache invalidation; C + W add revision/operation correlation where needed. |
| `application_busy` | C + W retain raw busy status and wait time currently reduced to success/error; G applies queue/backoff policy without retrying destructive operations blindly. |
| `failed_node_replace_status`, `node_neighbor_update_status`, `learn_mode_set_status`, `network_update_request_status` | C + W enrich detailed status/node/context; G completes C01/C02/C05/C06 tasks. |
| `send_request_complete` | G routes to the owning request when native correlation is selected (P10), retaining status/RX metadata and response bytes. No duplicate unsolicited completion. |
| `sapi_no_resp`, `sapi_resp` | W/G deliver privileged diagnostic request completion only to its owner, with optional redacted diagnostic events; normal task APIs should not require callers to decode SAPI buffers. |
| `native_error` | G emits a typed backend/diagnostic fault and fails affected requests where identifiable; malformed callbacks are not silently ignored. Preserve process isolation/recovery. |

Also expose native S2 resynchronization, serial health and indicator events at
their source rather than reconstructing them from verbose logs (P03/L06/Q10).

**Accept:** tests for each event prove the intended consumer is notified, request
completion is single-shot, and secrets/private diagnostic payloads do not enter
public event streams.

### P13 — Multicommand forwarding to ZIPGateway

**Task:** execute/answer every supported command inside a received Multi Command,
with proper Supervision and endpoint/security handling.

**G + C/W where the capability is native:** replace `forward_to_controller` with
explicit routing to native-controller tasks or Grizzly application handlers
(C17). Process known constituents individually without losing shared metadata;
keep Supervision success/failure based on actual execution, not unconditional
notification. Define unsupported-constituent behavior and reply order.

**Accept:** mixed Association/Version/application/native constituents receive the
same effective answers as individual commands; no command is silently discarded
because no gateway socket exists.

## 7. Helpers, diagnostics and deployment

### L01 — `start_zipgateway`, `restart_zipgateway`, `stop_zipgateway`

**Task:** control the selected radio stack lifecycle.

**G:** add backend-neutral `start_controller`/`restart_controller`/
`stop_controller` (or backend-service equivalents). For Zwrap, suspend supervisor
restart intentionally, drain/cancel work, stop the port, release serial ownership
and restart/reconcile when asked, always using the backend fixed into that
build. Keep ZIPGateway-specific names only as transitional deprecations where
needed; remove them with the legacy backend instead of maintaining permanent
aliases. Planned shutdown must be distinguishable from a crash; it is not a
backend-selection or failover operation.

**Accept:** intentional stop stays stopped; restart opens one serial owner and
preserves directory/keys; callers receive deterministic pending-work outcomes.

### L02 — `zipgateway_ready?`

**Task:** know whether Grizzly can accept work and whether the radio is responsive.

**G + W/C:** use `Grizzly.ready?` plus structured readiness reasons: initializing,
ready, probing, degraded serial, stopped, upgrading. Export native health/
initialization/serial responsiveness rather than sending a Z/IP keep-alive or
assuming a live GenServer implies a healthy radio. Directory probing may remain
active while ordinary tasks are accepted according to policy.

**Accept:** startup, blocked probes, serial unplug, stalled port, recovery and
intentional stop produce correct readiness/events. The legacy name can be
migrated without losing the operational task.

### L03 — `Grizzly.listening_mode/1`

**Task:** choose appropriate communication/wake-up behavior for a node.

**G through direct SQLite access:** decode `nodes.mode`: always-listening,
frequently-listening, wake-up, firmware-upgrade and unknown. Reuse/extract the
existing Grizzly database decoder and mask mode flags correctly. Use the
coordinated read strategy in section 2; no native listening-mode getter is
needed. Any legitimate host-managed mode edit follows the SQL maintenance and
reload contract, not a race against active native state. Virtual application
devices retain their existing always-listening semantics.

**Accept:** all mode values, unknown/not-yet-probed, restart and LR cases return
useful results without a new radio request [S2], [S4].

### L04 — `Grizzly.home_id/0`

**Task:** identify the current network, including for diagnostics/key exports.

**G through direct SQLite reads:** query `network.homeid` and `network.nodeid`
after successful native initialization and validate their network binding. Use
existing initialization information or safe serialized read-only radio access
if independent confirmation is needed; do not require a new C identity getter
for values already present in the shared store. No log parser is necessary.
An identity query must not trigger the legacy `MemoryGetID` reset-on-invalid-ID
behavior as a side effect. Refresh Grizzly's cached identity after reset/learn/
restore and preserve the old public eight-hex-character format where required
[S2], [S6]. Do not report an old database's identity during a failed startup or
rewrite its network record to pretend the NCP changed networks.

**Accept:** identical identity before/after restart, correct byte order, actual
non-1 local ID and deliberate invalidation after network change.

### L05 — `network_keys`, `zniffer_network_keys`

**Task:** export the network keys for authorized diagnostics and format a Zniffer
key file.

**G using existing W:** call `get_network_keys`, convert native key names to
Grizzly's classic/LR names and format the expected hex/key-file representation
with current Home ID. Honor the native readability mask and distinguish
unreadable/unassigned keys from all-zero data; the present mask reports
readability, not a complete security-policy model. Extend C/W metadata if that
distinction is required. Do not export the ECDH private key just to create a
network-key file [S7], [S11].

**Accept:** correct key names/formats and network binding, explicit unavailable
slots, restricted caller access, no keys in events, traces, telemetry or ordinary
logs. Disable/redact native secret debug output in production builds too.

### L06 — Direct `Grizzly.ZIPGateway.*` usage

**Task:** retain the diagnostic/maintenance abilities, not the module namespace.

**G + C/W by subtask:** inventory consumers and extract backend-neutral services:

- Database inspection (`get_node`, nodes/endpoints, listening modes, prepared
  read queries): the Elixir SQLite repository, section 2/C07–C10/L03. No native
  query wrapper is required for these persisted fields.
- Repair/delete cache entries: coordinated transactional SQL edits, followed by
  native cache invalidation/reload before resume. Do not prohibit direct edits;
  prohibit **uncoordinated** edits. Cache deletion is not RF exclusion. Protect
  the *actual* controller ID, not just hard-coded node 1.
- `clear_s2_sessions`: edit persisted session records through the coordinated
  SQL maintenance window and clear/reload affected live state before resume;
  use a controlled native stop/restart when required. Add a narrow native
  live-session invalidation primitive only if that synchronization is otherwise
  unavailable. Validate which SPAN/MPAN state must be reset to force fresh
  exchanges; deleting SQLite while stale sessions remain active is not enough.
- Log-derived identity/key data: typed native getters, L04/L05.
- SAPIMonitor, crash/retransmission telemetry and unsolicited-server health
  checks: native serial/port health events, bounded watchdogs and request metrics,
  not a monitor of a server that no longer exists.
- Pure IP address/config helpers: leave only in the ZIPGateway adapter. Replace
  their operational callers with node/controller identities and typed config.

**Accept:** support workflows can inspect/repair state, force diagnostic S2
resynchronization and detect radio failure in either backend without depending
on ZIPGateway's internal process names. Backup/repair remains auditable and does
not implicitly factory-reset the NCP [S4], [S11].

### L07 — Controller OTW update / `zw_programmer`

**Task:** upgrade/recover the controller firmware without two serial owners or
losing the network.

**G lifecycle work + C/W maintenance control where needed:** refactor the OTW
runner to acquire an exclusive maintenance lease from L01, drain/pause work,
stop and await native-process/FD exit, enter bootloader and use the existing
programmer/XMODEM/UART path. Prevent automatic supervisor restart during this
phase. Preserve relevant native persistence and take/verify an NVM backup when
supported/required. Reinitialize Zwrap, query actual firmware/capabilities and
reconcile directory after update; include interrupted-update recovery [S10].

Do not solve this by merely allowing the current runner while Zwrap owns serial.
For device **OTA**, implement D03/P01/P02 and route device-initiated messages to
its existing firmware state machine; it is a different task.

**Accept:** real-controller successful OTW, image rejection, interruption,
bootloader recovery, lease release and automatic restart; no command/radio
access during programming and no accidental network reset.

### L08 — Persistence and same-backend release upgrades

**Scope correction:** the original unsupported inventory listed cross-backend
SQLite/config migration. That is **not a deployment requirement**: each build
selects its backend at compile time and deployed systems are not intended to
change backend. Do not implement a ZIPGateway-to-Zwrap converter, reverse
exporter or bidirectional switching framework as a feature-parity gate.

**Actual task:** preserve network state through restarts, firmware/application
updates, schema evolution and recovery **within the selected backend**.

**G storage/release tooling using SQLite and existing coordination:** version
the selected backend's files and schemas, identify their network/NCP binding,
back up the relevant state and apply any same-backend schema changes through
validated transactions. Use the section 2.2 pause/edit/reload/resume contract
for native SQLite changes. Keep probing controlled during restore and verify
that initialization does not discard valid data or overwrite edits. Existing
interview import remains an optional tool where its semantics fit; do not
replace intentional Elixir database access with native CRUD APIs.

Include the selected backend's actual keys/configuration/provisioning stores
and NCP state in recovery planning: a resource-directory database alone is not
a full network backup. Validate ABI-sensitive blobs across target/firmware
upgrades. Atomic installation, recovery after interrupted writes and rollback
of an unsuccessful **same-backend** update remain useful; none implies the
ability to boot the other backend against these files [S2], [S3], [S7], [S9].

If a future product decision requires a one-time conversion of an existing
fleet, scope and validate it separately. It is not assumed by this plan and
must not grow into permanent backend-switching support.

**Accept:** deployed builds retain their network and metadata through supported
same-backend upgrades/recovery. Mismatched backend artifacts or stores are
rejected without silently converting data or starting the other stack.

### L09 — Nerves, cross-compilation, non-Linux deployment

**Task:** deploy Grizzly/native controller support on the same relevant targets
as the existing application.

**W build/package + G release work, C portability as needed:** make build scripts
honor target C compiler/sysroot, Cargo target/linker, target libclang headers,
libc and Nerves artifacts; separate build-host bindgen execution from target
compilation. Package the helper and required native libraries for the target,
with reproducible pinned core revisions and secure writable persistence paths.
Apply the compile-time profile/artifact isolation in section 2.4; builds for the
legacy backend must not pull in the native toolchain. Add supported-target CI
and run on actual ARM hardware. No BEAM NIF is required.

Do not promise native non-Linux support while the build explicitly requires
Linux. If an existing deployment runs a non-Linux Grizzly client against a Linux
radio host, provide a backend-neutral authenticated controller service rather
than reinstating Z/IP; otherwise port the native OS/serial layer and validate it.
Native macOS/Windows support beyond the old deployment capability is a separate
platform expansion, not a precondition for Linux/Nerves parity.

**Accept:** release builds and starts on the required Nerves/Linux architectures,
loads its executable without a development checkout, preserves state across
restart/update and handles supported remote-client deployment securely [S1].

## 8. Every ignored configuration item

Treat configuration as desired **task behavior**, split backend-independent
options from transport-specific ones, and fail validation when a requested
safety/behavioral setting cannot be honored. Do not silently accept an RF or
power setting that the native stack ignores.

| Existing option(s) | Proposed implementation/translation | Owner / acceptance |
|---|---|---|
| `run_zipgateway` | Keep its existing external-gateway meaning for that adapter; add selected-controller lifecycle/externally-managed-controller configuration for native mode. | G, L01; no implicit second radio owner. |
| `transport` | Device CC transport is provided by the backend. If remote hosting is needed, configure the backend-neutral controller service transport separately. | G/W; local native mode does not instantiate DTLS. |
| `zipgateway_binary` | ZIP-only path; provide a native-helper executable/artifact selection with version/capability handshake. | W/G; release contains and starts the intended helper. |
| `zipgateway_config_path` | ZIP-only serialized config path; replace operational intent with typed native config and its persistence path. | G/C/W; applied config can be queried. |
| `zipgateway_port` | Retire in local native mode; a separately hosted controller may have a task-service address, not a fake gateway port. | G; remote-host clients can still manage the radio securely. |
| `manufacturer_id`, `hardware_version`, `product_id`, `product_type` | Expose typed controller/application identity; configure native identity/NIF responses and Grizzly-owned local handlers consistently, rather than only changing an advertised report. | C/W/G, C15/C17; local and over-air identity match certification settings. |
| `serial_log` | Add bounded structured serial diagnostic capture at the native serial owner, with direction/timestamps/redaction. Do not open/tap the serial device independently. | C/W/G; useful capture, access control and no secret leakage. |
| `tun_script`, `lan_ip`, `pan_ip` | Remove TUN/IP-address setup from the native deployment; replace callers with node/controller identities. If remote access is a task, configure the controller service explicitly. | G; all radio tasks work without privileged TUN/network setup. |
| `unsolicited_destination` | Translate task intent to Grizzly subscribers/handlers, or authenticated event subscriptions on a remote controller service. No native DTLS listener is required. | G/W; unsolicited notifications and replies reach intended clients. |
| `database_file` | Resolve a backend-neutral shared-store path to `zwrap_options.core_database_path`/`data_dir`; the Elixir repository reads and performs coordinated transactional edits against that exact file. Explicit paths take precedence and migration is deliberate. | G, using existing W coordination; no shadow database or native per-field CRUD API. |
| `extra_config` | Audit actual raw ZIP config uses; promote each required behavior to a typed, validated option/capability. Preserve a ZIP-only escape hatch only for that adapter; do not silently drop required native behavior. | G/C/W; documented applied values or actionable validation failure. |
| `indicator_handler` | Emit native inclusion/exclusion/progress/ready events at the appropriate state transitions and adapt them to Grizzly indicator callbacks. | C/W/G; indicator behavior matches real states, including cancellation/failure. |
| `rf_region` | Extend native initialization/configuration to apply and read back the requested region before normal RF work; use the radio's supported setup API and safe reset ordering. Active defaults are not deployment intent. | C/W/G; correct effective region, precise unsupported-region errors, regulatory validation. |
| `power_level` | Extend typed initialization/config for normal TX power/calibration and any required LR power values; validate units/range/chip support and read back effective settings. | C/W/G; no ignored calibration or silent default-power transmission. |
| `zw_programmer_path` | Keep as a tool path behind the backend-neutral exclusive-maintenance workflow, not gateway lifecycle calls. | G, L07; programmer never competes with the helper. |
| `background_rssi_monitor` | Run the existing task against typed native RSSI reads, with bounded polling and availability events. | G + C/W query, C13/P03; monitoring works after restart and does not starve commands. |
| `unsolicited_data_path` | Inventory persisted unsolicited-server state and migrate any still-needed association/application data to Grizzly storage; native RD/provisioning paths remain explicit. Files for a removed network server need no replacement merely for their names. | G; required persisted behavior survives restart, without creating an unused server data directory. |

`zwave_firmware: %{enabled: true}` additionally becomes usable through L07 rather
than being permanently rejected. `serial_port`, inclusion/firmware handlers,
storage adapters/options, associations, virtual devices and ordinary CC codecs
remain applicable above the backend boundary. Validate interactions (especially
awake ownership and local application handlers), not just option parsing.

## 9. Proposed implementation order and completion gates

| Phase | Work | Why / exit gate |
|---|---|---|
| 0 — Safety/build contracts | Replace startup backend selection with a compile-time profile; isolate code/dependencies/artifacts and reject runtime overrides. Fix RX bounds/input validation; verify DB pause/drain/cache synchronization; establish task contracts and shutdown ownership. Honor RF/power settings and disable secret debug logging. | Each build is fixed to one backend with no runtime failover; no unsafe RX, SQL/native collision, stale-cache overwrite or silently wrong radio configuration. |
| 1 — Directory and quick parity | Extract Elixir SQL decoders and transactional read/edit repository; implement the coordinated maintenance window; node/membership/health queries, cache reads/repairs, listening mode, Home ID, key/Zniffer access, raw frames and safe ping. Add narrow C/W coordination only where verification proves necessary. | Everyday inspection and coordinated edits work after restart, including incomplete/LR/non-1-controller cases, without new native CRUD/query APIs. |
| 2 — Work scheduling and application tasks | Elixir-owned mailbox, wake-up scheduling and keep-awake leases; `more_info` behavior, correlation, raw RX/session routing, local handlers and Multi Command/Supervision; complete device OTA. Core additions are limited to demonstrated missing observations/control primitives. | Real sleepy-device transactions and OTA pass without gateway-specific behavior or a native mailbox. |
| 3 — Controller operations and metadata | Learn/update/replace/neighbor/route/RSSI/LR channel; full provisioning and inclusion metadata; autonomous SmartStart; missing native observation events and Elixir-owned IMA accounting. | Each task in C01–C18/P01–P13 has its functional tests; required secondary/remote workflows work. |
| 4 — Operations and rollout | OTW ownership/recovery, same-backend persistence upgrades, isolated release packaging, physical-radio/Nerves and failure-recovery validation. | Each deployed build operates and recovers with its fixed backend; no cross-backend migration or reverse converter is required. |
| 5 — ZIPGateway retirement | After parity/hardware validation, make Zwrap the new-build default, deprecate ZIPGateway, define legacy support policy, then remove the old backend, exclusive dependencies/configuration and obsolete compatibility APIs. | Supported new releases are Zwrap-only; the temporary dual-backend selector is no longer needed. |

Some Phase 3 work (e.g. RSSI reads) is small and can be pulled forward. Phase 1
uses the shared SQLite store as intended; it does not wait for native query/
mutation APIs for data Elixir can access directly. Validate current membership
against the NCP where needed, and require safe pause/edit/reload/resume behavior
before enabling concurrent native/host access. Phase 0 large-RX safety is
mandatory before raising any payload limit.

### Acceptance is a backend-neutral task suite

During coexistence, run the same task contracts in separate compile-time
ZIPGateway and Zwrap builds, allowing different packets and backend-specific
diagnostics. Do not test backend selection by flipping a deployed/running
supervisor. Cover:

- Build selection, recompilation and artifact/dependency isolation; runtime
  selector/config overrides are rejected and failures never start the other
  backend. Audit shared code for accidental dependencies on omitted modules.

- Classic/LR membership, non-1 controller ID, incomplete/interview-failed nodes,
  endpoints/aggregates, stale cache and explicit refresh.
- Manual S0/S2, LR security grants, SmartStart, learn mode, secondary/remote
  roles, replacement/exclusion/abort races and detailed failure outcomes.
- Sleeping nodes, wake-up deadlines, queue saturation/cancellation, concurrent
  requests, multipart/unsolicited/session traffic and unknown raw frames.
- TX/cumulative diagnostics, radio configuration, serial failures, native crashes
  and recovery without duplicated destructive operations.
- Shared SQLite reads and edits: pause during active probes/callbacks, prove
  quiescence, atomically edit dependent rows, reload native state, resume and
  verify no later stale write overwrites the edits. Cover rollback, busy/I/O
  errors, owner death, failed reload and preservation of prior block state.
- Real device OTA, controller OTW/bootloader recovery, restart persistence,
  same-backend schema/release upgrades and recovery, and Nerves execution.
- ZIPGateway retirement: remove its build profile and exclusive artifacts once
  support policy allows it; Zwrap-only release/task tests still pass.

Extend the fake NCP for deterministic protocol/failure tests, use native
sanitizers for buffer/lifetime changes and include ExUnit port-boundary tests.
Physical-radio interoperability is required for RF/security/firmware claims;
passing current mock/fake-switch tests is not feature-parity sign-off. As the
public C API grows, extend wrapper function/event coverage and ownership tests;
“all current public functions wrapped” is a moving boundary, not the parity
criterion.

## 10. Coverage of the original inventory

| Original section | Proposal coverage |
|---|---|
| Every unsupported controller request row | C01–C16 |
| Other local `:gateway` application commands | C17 |
| Remote/non-1 controller targets and local management endpoints | C18 |
| Every report/notification command name | Section 4 |
| Every device operation/payload row | D01–D05 |
| Every partial-support bullet, in its original order | P01–P13 |
| Every ZIPGateway helper/deployment row | L01–L09 |
| Every ignored configuration option, including grouped identity fields | Section 8 |

### Existing public-entrypoint migration index

These facades should delegate to the proposed task services. Renaming or
replacing a low-level API is acceptable, but losing its useful task is not.

| Current entrypoint | Task/service |
|---|---|
| `Grizzly.Inclusions.learn_mode/1`, `learn_mode_stop/0` | C01: role/network join and stop |
| `Grizzly.Network.request_network_update/1` | C02: SUC/SIS synchronization |
| `Grizzly.Node.get_dsk/3` | C04: public-only controller DSK |
| `Grizzly.Network.node_neighbor_update_request/2` | C06: topology repair |
| `Grizzly.Network.get_node_ids/1`, `get_all_node_ids/1`, `Grizzly.all_node_ids/0` | C07: reconciled membership and virtual devices |
| `Grizzly.Network.report_failed_node_ids/1`, `Grizzly.failed_node_ids/0` | C08: operational health |
| `Grizzly.Node.get_info/2`, `Grizzly.node_info/2` | C09/C10: direct SQLite reads, coordinated cache edits and targeted refresh |
| `Grizzly.send_command` with local management names or `:gateway` | C01–C18: task/local-application dispatcher, not a Z/IP implementation |
| `Grizzly.send_binary/2`, `Zwrap.send_data_appl/4` | D02: explicit raw-frame interface for custom CC/debugging |
| `Grizzly.ping/2` | D01: reachability |
| `Grizzly.start_zipgateway/0`, `restart_zipgateway/0`, `stop_zipgateway/0` | L01: selected-controller lifecycle |
| `Grizzly.zipgateway_ready?/0`, `Grizzly.ready?/0` | L02: readiness and health |
| `Grizzly.listening_mode/1`, `Grizzly.home_id/0` | L03/L04: native directory and identity |
| `Grizzly.network_keys/0`, `zniffer_network_keys/0`, `Zwrap.get_network_keys/1` | L05: restricted key export and Zniffer formatting |
| `get_ecdh_key_pair/1` | Keep as privileged low-level key export; use C04's public-only getter for ordinary DSK tasks |
| `Grizzly.Backends.Zwrap.controller/0`, `Zwrap.subscribe/2` | Remain advanced escape hatches; normal task parity must not require every application to bypass Grizzly |

Likewise, `{:error, :payload_too_large}`, `{:error, :busy}`,
`{:error, :unsupported_backend_operation}` and
`{:error, :unsupported_backend_option}` should indicate actual limits, temporary
contention or demonstrable capability restrictions after this work—not missing
implementations of tasks the selected hardware can perform. `more_info: false`
still means no explicit awake lease; `more_info: true` acquires one (P02).
Unavailable data should use the facade's documented `nil`/unavailable contract,
not fabricated defaults; readiness should be `false` for real not-ready states.

The concrete backlog is therefore not “implement the rejected ZIP commands.” It
is **read and edit the shared SQLite directory from Elixir under the intended
coordination contract, add only genuinely missing radio/control/observation
primitives, and move task policy off gateway-specific transport assumptions**.
Both mailbox policy and database-level application logic belong in Elixir; their
intentional omission from the core must not become a backlog to rebuild them in C.
The two backend implementations are temporary build alternatives. The final
architecture has no deployed backend toggle, no reverse migration subsystem
and no ZIPGateway dependency.

## Source references

Paths are relative to their respective adjacent checkouts. Symbols are more
stable reference points than line numbers.

- **[S1] Active build:** wrapper `native/zwrap_port/build.rs` (`SOURCES`,
  `DEFINES`, Linux target check); core `Makefile`. Establishes which similarly
  named native implementations/stubs actually ship.
- **[S2] Directory/SQLite:** core `pal/RD_DataStore_Sqlite.c`
  (`data_store_init`, `rd_data_store_nvm_write`, `rd_zgw_homeid_get`,
  `rd_zgw_nodeid_get`), `src/RD_internal.h`, `src/RD_internal.c`
  (`ndb[]`, `rd_node_entry_import`, `rd_get_node_dbe`),
  `src/ResourceDirectory.h`, `src/ResourceDirectory_custom.c`
  (`rd_probe_lock`, `rd_probe_in_progress`, `rd_probe_new_nodes`,
  `rd_set_failing`, `rd_node_is_unreachable`, `rd_node_is_alive`),
  `src/ResourceDirectory_extended.c` (blocked/idle import checks and memory/store
  updates).
- **[S3] Current public contract:** core `zipato_zwave_core.h`,
  `zipato_zwave_core_response_handler.h`, `zipato_zwave_core_rd_interview.c`
  (`zipatoZwaveCoreExportNodeInterviewFromRd`); wrapper
  `native/zwrap_port/API.md`, `lib/zwrap.ex`.
- **[S4] Grizzly database access:**
  `lib/grizzly/zipgateway/database.ex` (`with_database`, node/endpoint queries,
  `listening_mode`, `clear_s2_sessions`, `delete_node`, mode/state decoders).
- **[S5] Native management:** core `pal/CC_NetworkManagement_custom.c`
  (`NM_IDLE` learn branch, `NetworkManagementAction`, replacement/security/
  SmartStart branches), `pal/CC_NetworkManagement_extended.c`
  (fixed inclusion helpers and handover stubs), `zipato_zwave_core.c`,
  `zipato_zwave_core_runtime.c` (owner-loop interface and narrowed event parsing).
- **[S6] Radio/transport:** core `src/serialapi/Serialapi_custom.c`
  (`MemoryGetID`, `ZW_GetPriorityRoute`, `ZW_SetPriorityRoute`,
  `ZW_GetBackgroundRSSI`, `GetLongRangeChannel`, `SetLongRangeChannel`),
  `src/transport/ZW_SendDataAppl.h`/`.c`, `src/transport/ZW_SendRequest.c`,
  `src/transport/zw_frame_buffer.c`, `src/CC_InstallationAndMaintenance.h`.
- **[S7] Keys/DSK:** core `zipato_zwave_core_keys.c`
  (`zipatoZwaveCoreReadNetworkKeys`, `zipatoZwaveCoreReadEcdhKeyPair`),
  `pal/CC_NetworkManagement_custom.c` (`DSK_GET` add-mode selection).
- **[S8] Active platform choices and reductions:** core `pal/ZIP_Router_fake.c`
  (router defaults, `ApplicationCommandHandlerZIP`, intentionally disabled native
  mailbox/firmware awake policy), `pal/ZW_ZIPApplication_fake.c`
  (`ApplicationInitNIF`), `pal/misc_defines.c` (IMA hooks),
  `pal/CC_NetworkManagement_extended.c` (intentional mailbox omission and separate
  handover stubs).
- **[S9] Provisioning:** core `src/provisioning_list.c`,
  `pal/CC_provisioning_list_custom.c`,
  `pal/CC_provisioning_list_extended.c` (fixed `provisionBuff[64]`),
  `zipato_zwave_core_runtime.c` (DSK-only provisioning callbacks).
- **[S10] Grizzly tasks/firmware:** `lib/grizzly/network.ex`,
  `lib/grizzly/node.ex`, `lib/grizzly/inclusion_server.ex`,
  `lib/grizzly/inclusions/zwave_adapter.ex`,
  `lib/grizzly/firmware_updates/firmware_update_runner.ex`
  (1,024-byte default fragments, async ownership and `more_info`),
  `lib/grizzly/firmware_updates/otw_update_runner.ex`.
- **[S11] Grizzly diagnostics:** `lib/grizzly/zipgateway/log_monitor.ex`
  (identity/key formats and Zniffer output), `lib/grizzly/zipgateway/database.ex`,
  `lib/grizzly/zipgateway/sapi_monitor.ex`.
- **[S12] Current native integration:** `lib/grizzly/backends/zwrap.ex`,
  `lib/grizzly/backends/zwrap/connection.ex`,
  `lib/grizzly/backends/zwrap/management.ex`,
  `lib/grizzly/unsolicited_server/response_handler.ex`,
  [current implementation report](zwrap-implementation.md).

[S1]: #source-references
[S2]: #source-references
[S3]: #source-references
[S4]: #source-references
[S5]: #source-references
[S6]: #source-references
[S7]: #source-references
[S8]: #source-references
[S9]: #source-references
[S10]: #source-references
[S11]: #source-references
[S12]: #source-references

[parity-progress]: ../PARITY_IMPLEMENTATION_REPORT.md
[parity-execution]: ../PARITY_IMPLEMENTATION_PLAN.md
