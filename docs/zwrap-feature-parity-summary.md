# Zwrap feature parity — summary

> Historical prototype baseline/proposal. This worktree now has a partial
> implementation beyond that baseline. Use the current progress report for
> implemented behavior, validation and all remaining task IDs.
>
> [Current progress][parity-progress] · [Execution plan][parity-execution]

Host build/release isolation and verified native initialization settings
now have implementation and tests. Native Home ID, listening-mode and
caller-only key inspection no longer depend on gateway logs. Core TX queue
observations now include autonomous interviews; Elixir keeps these overlapping
counters separate from host application counts, not as full RF/IMA statistics.
Maintenance also guards report waits, security/fragment state, callback timers
and tracked serial data/bridge/NIF work. TS retirement retains outstanding wire
ownership; NIF now has real-helper acceptance/completion tests. Remaining serial
families, SDK ID-reuse contracts and writer/recovery audits are still open.
Other workstreams remain partial; use the progress report rather than
interpreting this baseline as completion.

**Goal:** Grizzly can perform the same useful Z-Wave tasks with Zwrap as with
ZIPGateway. **Not the goal:** emulate ZIPGateway's API, Z/IP packets or
processes.

This summarizes the [detailed parity plan]; it does not claim parity is already
implemented. See the [current unsupported-operation inventory] for today's
limitations and the [implementation report] for the initial adapter and its
validation.

## Decisions to keep fixed

- **Choose the backend at compile time.** Each firmware/release build selects
  one backend. Supervisor arguments, runtime configuration and environment
  changes must not change the backend of a deployed build.
- **Coexistence is temporary.** Keep separate ZIPGateway and Zwrap builds while
  closing parity gaps. The end state is Zwrap only: deprecate and eventually
  remove ZIPGateway, not maintain a permanent dual-backend product.
- **No deployed backend migration requirement.** Do not build runtime fallback,
  post-deployment backend toggles or bidirectional store converters. Ordinary
  persistence upgrades/recovery remain necessary within the chosen backend.
- **Elixir owns application policy:** mailbox queues, wake-up scheduling,
  keep-awake leases, application deadlines/retries, statistics and workflows.
  Do not rebuild these in the core.
- **Elixir reads and edits the shared SQLite store directly.** Reuse/extract
  Grizzly's database code; missing native getters/setters are often intentional.
  Do not add native CRUD APIs for data already available there.
- **Coordinate access:** pause/drain relevant native work → SQLite transaction
  → synchronize/reload native caches → resume. Verify the existing blocking
  mechanism's scope; a probe-block event alone does not prove every DB user is
  idle or cached records are reloaded. Coherent reads also need a verified
  consistency strategy. See the [SQL access contract].
- **Core owns low-level radio/security/encapsulation and native execution.**
  Extend it only for genuinely missing actions, observations, safe buffers or
  coordination primitives. Carry those through the wrapper's isolated port.
- **SQLite is not the entire network.** NCP membership must be reconciled when
  freshness matters; keys, native configuration and provisioning also have
  separate persistence. Editing a cache does not include/exclude a device.

## What exists versus what remains

The initial adapter currently selects its backend at supervisor startup. That
prototype **does not yet meet the compile-time-selection requirement** and must
be refactored. Its Zwrap path sends ordinary CC frames without Z/IP/DTLS, with
request/report handling and initial inclusion, exclusion, reset, failed removal
and provisioning mappings.

That is the foundation, **not full task parity**. The sections below group all
remaining proposals; partial implementations may already exist. The detail
links cover every C, D, P and L item in the full plan.

## Parity work at a glance

### 1. Directory and cache

Read nodes, endpoints, health, listening mode and Home ID directly from
SQLite; coordinate edits and native reload. Reconcile live NCP membership when
needed.

- **Owner:** Elixir; existing native coordination first
- **Details:** [C07], [C08], [C09], [C10], [L03], [L04]

### 2. Sleeping devices

Implement the mailbox, wake-up scheduling, deadlines, fairness, cancellation
and keep-awake leases. Translate `more_info` to Elixir policy.

- **Owner:** Elixir; native observations/control only if missing
- **Details:** [P01], [P02]

### 3. Commands and raw frames

Safe classic/LR ping, custom CC sends/raw subscriptions, unknown-frame access
and richer source/destination endpoint options.

- **Owner:** Elixir + wrapper; core safety/endpoint work where needed
- **Details:** [D01], [D02], [D04], [D05]

### 4. Request and operation lifecycle

Correct concurrent/multipart matching, bounded queuing of conflicting
operations, cancellation and exactly one terminal outcome; no stale completion
of a new request.

- **Owner:** Elixir coordination; native IDs/status/cancel facts where needed
- **Details:** [P07], [P09], [P10]

### 5. Device OTA

Negotiate backend-safe fragment sizes, deliver device-initiated requests to
the OTA session, keep sleepy devices awake and handle retries/activation. Fix
native length/RX limits before larger frames.

- **Owner:** Elixir firmware workflow + wrapper/core transport safety
- **Details:** [D03]

### 6. Learn mode and network maintenance

Join/leave another controller network, synchronize with SUC/SIS, replace
failed devices without changing IDs, and update neighbors.

- **Owner:** Core radio/FSM work + wrapper; Elixir task orchestration
- **Details:** [C01], [C02], [C05], [C06]

### 7. Inclusion, security and SmartStart

Support inclusion options, correct add/learn DSK, LR key types, complete
security metadata and autonomous join events.

- **Owner:** Elixir policy/SQLite reads; missing native actions and transient
  facts
- **Details:** [C04], [P04], [P05], [P06], [P11]

### 8. Provisioning

Read/update/iterate complete records and TLVs, retain unknown metadata and
remove the fixed builder limit safely. Provisioning has a separate native
store, not the RD node table.

- **Owner:** Elixir decoding; wrapper/core store access and safe buffers
- **Details:** [P08]

### 9. Radio diagnostics and statistics

Routes, background RSSI/monitoring and LR channel control. Normalize TX
reports and calculate/persist counters in Elixir, including native-originated
traffic.

- **Owner:** Elixir statistics/polling; native radio operations and
  observations
- **Details:** [C11], [C12], [C13], [C14], [P03]

### 10. Controller application behavior

Send/inspect the actual NIF, route supported local application commands,
process Multi Command/Supervision, and use actual local controller/endpoint
identities.

- **Owner:** Elixir handlers + native radio/NIF/endpoint capabilities
- **Details:** [C03], [C15], [C17], [P13]

### 11. Remote/secondary controllers

Remove the hard-coded local ID 1 assumption. Implement real supported
handover/replication or explicit authenticated hosted-controller tasks; never
redirect a remote action locally.

- **Owner:** Elixir routing + native role/protocol work
- **Details:** [C18]

### 12. Events and service health

Expose native faults/progress/busy/serial facts to the right consumer;
backend-neutral start/stop/restart and meaningful readiness. Replace transport
health packets with actual service/radio health.

- **Owner:** Elixir lifecycle/events; missing native observations
- **Details:** [C16], [P12], [L01], [L02]

### 13. Support tools and key export

Retain inspection, coordinated SQL repair and session reset. Export authorized
network keys/Zniffer files without secret logging or unnecessary private-key
access.

- **Owner:** Elixir SQLite/formatting; existing key APIs and narrow live-state
  controls
- **Details:** [L05], [L06]

### 14. Controller OTW

Exclusive serial ownership, stop/drain the native helper, run
programmer/bootloader recovery, then restart and reconcile without losing the
network.

- **Owner:** Elixir maintenance workflow; native controls only where needed
- **Details:** [L07]

### 15. Build selection, persistence and deployment

Produce separate compile-time ZIPGateway/Zwrap builds during coexistence.
Validate same-backend persistence upgrades, backup/recovery, reproducible
packaging and actual Nerves/Linux targets. Do not require deployed systems to
change backend or convert their stores to the other backend.

- **Owner:** Elixir build/release and storage work + wrapper/core portability
- **Details:** [Build selection and retirement], [L08], [L09]

### Cross-cutting work

Two parts of the full plan apply across the workstreams:

- [Reports and notifications]:
  preserve outcomes and useful application-server behavior; do not implement an
  outbound native RPC for every ZIPGateway report name.
- [Configuration mapping]:
  carry real behavior such as RF region, power calibration, identity,
  diagnostics and persistence paths into the chosen backend. Retire ZIP-only
  TUN/network settings where their task no longer exists. Never silently ignore
  RF/power settings or advertise capabilities that are not implemented.

## Recommended order

### Phase 0: Safety and ownership

- **Work:** Compile-time backend selection and isolated build dependencies;
  RX bounds/input validation; verified SQLite pause/edit/reload/resume;
  lifecycle ownership; correct RF/power handling and secret-safe diagnostics.
- **Gate:** Each build is fixed to its selected backend; runtime overrides and
  fallback cannot select the other one. No memory-unsafe RX, native/SQL
  collisions, stale-cache overwrite or unintended serial owner.

### Phase 1: Everyday functionality

- **Work:** Elixir SQL repository and cache management;
  inventory/health/node/endpoint queries; listening mode, identity, key
  exports, raw frames and ping.
- **Gate:** Routine inspection, reachability and coordinated edits work after
  restart, including incomplete/LR/non-1-controller cases.

### Phase 2: Application workflows

- **Work:** Elixir mailbox/awake policy, response correlation, session event
  routing, local handlers and complete device OTA.
- **Gate:** Real sleeping-device transactions and OTA work end to end.

### Phase 3: Advanced controller tasks

- **Work:** Missing radio/FSM actions, richer
  inclusion/provisioning/SmartStart facts, radio diagnostics and Elixir
  statistics.
- **Gate:** Supported security/role/maintenance workflows pass task-level
  tests.

### Phase 4: Deployment and recovery

- **Work:** Controller OTW, same-backend persistence upgrades/recovery,
  packaging and Nerves/hardware validation for each supported build profile.
- **Gate:** Each deployed build operates and recovers reliably with its fixed
  backend. Backend switching and cross-backend store conversion are not gates.

### Phase 5: ZIPGateway retirement

- **Work:** After Zwrap passes the required task/hardware gates, make it the
  default for new builds, deprecate ZIPGateway, then remove its backend,
  exclusive dependencies/configuration and obsolete compatibility APIs.
- **Gate:** Zwrap-only releases no longer build, package or depend on
  ZIPGateway. Any remaining legacy deployments follow an explicit support
  policy, not an assumed in-place backend conversion.

Small independent tasks can move earlier. This order is not a claim that every
phase needs to wait for all work in the previous phase; safety and coordination
requirements remain prerequisites for the affected operations.

## Important checks before calling it parity

- **Database:** test active probes/callbacks, commit/rollback, owner death,
  failed reload and resume. Committed edits must not be overwritten by stale
  native memory. Keep work blocked if synchronization fails.
- **Native gaps:** learn initiation is disabled in the inspected active code;
  some handover helpers are stubs; callbacks omit useful transient metadata.
  Those need targeted fixes, not wholesale API emulation.
- **Large frames/OTA:** current native RX has an unsafe 64-byte copy, while
  Grizzly's default firmware fragments exceed the wrapper's current 255-byte
  send limit. Merely having Transport Service compiled is not proof of safety
  or OTA parity.
- **Sleep handling:** core mailbox omission is intentional. Implement it once,
  in Elixir, and coordinate native interview activity rather than adding a
  competing mailbox or native lease-policy engine.
- **Identity/security:** use actual controller IDs and full LR IDs; preserve
  effective security metadata and never leak keys through logs/events.
- **Validation:** during coexistence, run the same task contracts in separate
  builds for each backend. Verify artifact/dependency isolation and rejection
  of runtime backend changes. Include physical S0/S2/LR/sleeping-device,
  OTA/OTW and target-platform tests; mocks alone are not parity sign-off.

## How to use these documents

1. Start here to pick a workstream and owner.
2. Follow its task IDs for implementation proposals and acceptance criteria.
3. Check the [unsupported inventory] for current behavior; update it only when
   the corresponding functionality is actually implemented.
4. Use the full plan's [completion gates] to decide whether a task is done—not
   whether a particular ZIP command exists.

<!-- Link targets are collected below to keep the main text readable. -->

[detailed parity plan]: zwrap-feature-parity.md
[current unsupported-operation inventory]: zwrap-unsupported.md
[implementation report]: zwrap-implementation.md
[SQL access contract]: zwrap-feature-parity.md#22-direct-sqlite-access-with-coordinated-ownership
[Build selection and retirement]: zwrap-feature-parity.md#24-compile-time-selection-and-zipgateway-retirement
[Reports and notifications]: zwrap-feature-parity.md#4-reportnotification-commands-preserve-outcomes-not-outbound-emulation
[Configuration mapping]: zwrap-feature-parity.md#8-every-ignored-configuration-item
[unsupported inventory]: zwrap-unsupported.md
[completion gates]: zwrap-feature-parity.md#9-proposed-implementation-order-and-completion-gates
[C01]: zwrap-feature-parity.md#c01--learn-mode-learn_mode_set
[C02]: zwrap-feature-parity.md#c02--network-update-network_update_request
[C03]: zwrap-feature-parity.md#c03--controller-nif-send-node_information_send
[C04]: zwrap-feature-parity.md#c04--controller-dsk-dsk_get
[C05]: zwrap-feature-parity.md#c05--failed-replacement-failed_node_replace
[C06]: zwrap-feature-parity.md#c06--neighbor-discovery-node_neighbor_update_request
[C07]: zwrap-feature-parity.md#c07--node-inventory-node_list_get
[C08]: zwrap-feature-parity.md#c08--failed-node-inventory-failed_node_list_get
[C09]: zwrap-feature-parity.md#c09--node-information-and-refresh-node_info_cached_get
[C10]: zwrap-feature-parity.md#c10--endpoint-cache
[C11]: zwrap-feature-parity.md#c11--priority-routes-priority_route_get-priority_route_set
[C12]: zwrap-feature-parity.md#c12--statistics-statistics_get-statistics_clear
[C13]: zwrap-feature-parity.md#c13--background-rssi-rssi_get
[C14]: zwrap-feature-parity.md#c14--lr-channel-zwave_long_range_channel_get-zwave_long_range_channel_set
[C15]: zwrap-feature-parity.md#c15--applicationcontroller-capabilities-application_node_info_get
[C16]: zwrap-feature-parity.md#c16--zip-artifacts-zip_packet-keep_alive
[C17]: zwrap-feature-parity.md#c17--other-local-application-commands-sent-to-gateway
[C18]: zwrap-feature-parity.md#c18--localremote-controller-identity-and-management-endpoints
[D01]: zwrap-feature-parity.md#d01--no_operation--grizzlyping2
[D02]: zwrap-feature-parity.md#d02--grizzlysend_binary2--binary-mode
[D03]: zwrap-feature-parity.md#d03--payloads-above-255-bytes--device-ota
[D04]: zwrap-feature-parity.md#d04--endpoint-bit-addressing--source-endpoint-selection
[D05]: zwrap-feature-parity.md#d05--unimplemented-application-commands
[L01]: zwrap-feature-parity.md#l01--start_zipgateway-restart_zipgateway-stop_zipgateway
[L02]: zwrap-feature-parity.md#l02--zipgateway_ready
[L03]: zwrap-feature-parity.md#l03--grizzlylistening_mode1
[L04]: zwrap-feature-parity.md#l04--grizzlyhome_id0
[L05]: zwrap-feature-parity.md#l05--network_keys-zniffer_network_keys
[L06]: zwrap-feature-parity.md#l06--direct-grizzlyzipgateway-usage
[L07]: zwrap-feature-parity.md#l07--controller-otw-update--zw_programmer
[L08]: zwrap-feature-parity.md#l08--persistence-and-same-backend-release-upgrades
[L09]: zwrap-feature-parity.md#l09--nerves-cross-compilation-non-linux-deployment
[P01]: zwrap-feature-parity.md#p01--sleeping-node-queue-delaypings
[P02]: zwrap-feature-parity.md#p02--more_info-true
[P03]: zwrap-feature-parity.md#p03--transmission-statistics-and-background-monitor
[P04]: zwrap-feature-parity.md#p04--inclusion-options--node_add-modes--tx_opt
[P05]: zwrap-feature-parity.md#p05--s2-dsk-lengths--lr-key-types
[P06]: zwrap-feature-parity.md#p06--inclusion-metadata--intermediate-statuses--lr-reports
[P07]: zwrap-feature-parity.md#p07--abort-acceptance-versus-completion
[P08]: zwrap-feature-parity.md#p08--provisioning-metadata-reads-and-44-byte-builder-limit
[P09]: zwrap-feature-parity.md#p09--management-concurrency--timeout-reservations
[P10]: zwrap-feature-parity.md#p10--response-correlation
[P11]: zwrap-feature-parity.md#p11--autonomous-smartstart-inclusion
[P12]: zwrap-feature-parity.md#p12--native-only-notifications
[P13]: zwrap-feature-parity.md#p13--multicommand-forwarding-to-zipgateway

[parity-progress]: ../PARITY_IMPLEMENTATION_REPORT.md
[parity-execution]: ../PARITY_IMPLEMENTATION_PLAN.md
