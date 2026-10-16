# Native maintenance audit — guarded protocol and timer work

This is a bounded audit of concrete quiet-window gaps, not certification of
all native writers, serial callbacks or cache lifetimes. The current task
ledger remains `../PARITY_IMPLEMENTATION_REPORT.md`.

## Ownership contract

Only the Rust helper's owner thread calls the native singleton. Before a
host SQLite transaction, acquisition drains a bounded amount of process work,
checks native quiescence, preserves the probe lock and closes native SQLite.
A successful generation token freezes native polling/actions. The wrapper also
rejects queries, SAPI and other actions that would bypass the held lease.

Release validates the token and existing database identity/schema. Committed
RD edits require cache reload before polling resumes. Failure stays held and
journaled; owner death does not automatically resume. Recovery remains manual.

An empty application TX queue alone is not quiescence. A report wait, security
exchange, delayed fragment or callback retaining a directory pointer can still
be live after radio TX completion.

## Native request ownership

`src/transport/ZW_SendRequest.c` now contributes an idle predicate that includes
sending requests, report waits, multipart continuations and callback activity.
A report callback may temporarily remove an entry from the list, but its slot
stays reserved until its multipart return value is known. Terminal callbacks
can reuse a retired slot even when the pool was full; callback depth still
blocks maintenance until they return.

Terminal completion stops the timer and preserves callback/user ownership.
Node abort snapshots generations rather than following list pointers after a
callback mutates the list. It uses full-width node IDs, including LR, and does
not cancel newly submitted work. This helper aborts report waits only, not
active radio transmissions.

TX callback contexts use nonzero helper-local u32 generations instead of reused
request addresses. Duplicate/retired TX callbacks cannot finish a different
request in the same pool slot. Generations wrap after UINT32_MAX; these are
internal callback tokens, not Z-Wave protocol IDs or a public cancellation API.

Initialization stops old request timers and preserves generation monotonicity.
Reinitialization underneath an executing request callback fails the helper.
Otherwise initialization retains its legacy discard behavior, not normal
terminal task completion. Reset/identity/restart workflows remain unfinished.

## Callback timers

`ctimer_pending` means registered or dispatching, including an expiry already
queued for delivery. It must not be replaced with a deadline/expired check.
A callback is still work while it runs, even after removal from the timer list.

A queued expiry can outlive `ctimer_stop`. If the same timer address is rearmed,
the old event must not invoke the new callback early. Dispatch now also checks
that the current event-timer registration has actually expired. If the new
registration already has a valid expiry queued, it is delivered only once.

These guards preserve clock/deadline semantics; they do not implement a native
mailbox, application retry policy or automatic maintenance recovery.

## S0 and S2

S0 transport must have no TX session, session timeout, live RX assembly or live
nonce. The periodic empty nonce-table timer is housekeeping, not active work.
Live tick-aged nonces block the lease so a long pause cannot extend their usable
lifetime. Acquisition can therefore return busy after an S0 exchange until its
nonces expire. Passive replay-blacklist entries are not active callbacks.

The S0 inclusion FSM and its registered timeout must also be idle. S2 requires
idle transport and inclusion FSMs, no send callback/multicast work, no pending
transport/inclusion timer and no owned nonce-report buffers. Negotiated SPAN
cache entries are passive state, not proof of a live transaction.

RD reload does not reload SPAN, security keys or provisioning. These guards do
not make arbitrary SQL changes to those stores safe.

The touched S2 wrapper also had independent input-bound violations:

- Ordinary two-byte commands were inspected as Multi Command frames.
- Short Multi Channel frames could be inspected at bytes 4 and 5.
- Oversized nonce reports warned but still copied into a 50-byte buffer.

Length/class checks and bounded subcommand iteration now prevent those reads
and copies. This is not complete Multi Command/Supervision or authorization
parity, nor an audit of every native command decoder.

## Tracked serial callback ownership

SendData (0x13), bridge/TS (0xA9) and NIF (0x12) own a slot until genuine
completion, even with a NULL user callback. Same-command overlap rejects
before overwriting its callback or command buffer. Command and nonzero SDK
callback ID must both match. Retiring before callback invocation permits
reentrant sends; dispatch depth still prevents maintenance during the callback.

Serial quiet also requires no queued RX, partial frame or pending serial ACK.
A definitive FALSE admission releases an unaccepted data/bridge submission.
Lost/malformed admission, a matching callback without status, NCP restart
under tracked work or an unresolved 65-second safety deadline ends the helper.
Blocking SDK calls can delay deadline checks. None of these paths confirms
radio cancellation, adds application retry or resets the radio to regain idle.
UART framing retries remain unchanged. Queue overflow/allocation failure also
fails the helper rather than silently dropping an owned completion.

Raw SAPI rejects these three managed command IDs with request failure. Other
raw SAPI remains privileged and is not certified safe for arbitrary commands.
Older/partial TX extensions retain status but omit unavailable report fields.
Serial bounds reserve space for both framing and the inbound length byte.

NIF now reports serial acceptance correctly, followed by one matched native
completion with actual target/status. Acceptance alone is not radio success.

The SDK echoes only eight bits. IDs wrap without zero or active-ID reuse; there
is no lifetime-255 cap. An arbitrary ancient duplicate after ID reuse cannot
be distinguished from new work. Qualified NCP callback lifetime/reuse behavior
is therefore still a production gate, not proven by wrap/duplicate host tests.
This slice does not certify other Serial API callback families.

### SUC-ID and SUC-return-route continuation

SendSUCID (0x57) and AssignSUCReturnRoute (0x51) now use the same retained
wire ownership, command/ID checks, admission validation, reset guards and
65-second safety deadline. Raw SAPI refuses these IDs too. SDK node-ID width
is preserved, but classic SUC actions reject ineligible LR targets.

The RD walk retains only a numeric cursor, not a cached record pointer. It
waits for genuine completion, not a one-second synthetic failure. Immediate
rejection advances iteratively, including slave assignment rejection. Duplicate
starts/probe-resume cannot skip a pending node or announce ALL_NODES_PROBED.
A later genuine walk resets the cursor; self/deleted/LR nodes are skipped.

Active walk ownership independently blocks maintenance even if its timer is
stopped. Timeout or RD teardown/reinitialization under that owner fails the
helper; it does not fabricate a radio outcome or silently release ownership.

NM reset detaches only its own matching SUC-return-route observer, without
clearing the SDK wire slot or detaching an RD/other owner's callback. A late
SUC-route completion cannot finish a newer NM task. This internal coordination
primitive is not exposed as a public task cancellation API.

The current helper startup does not enter this legacy propagation workflow.
Its C code is exercised directly under sanitizers; real-helper coverage here
only proves raw bypass refusal. No gated startup/learn/NIF branch or test-only
port operation was enabled. Complete SUC role/workflow parity remains open.

## Transport Service

Idle requires an idle FSM, no owned sender/wire callback and no registered
reset, delayed-restart, inter-fragment, fragment-completion or RX timeout.
The reset grace timer can conservatively delay maintenance.

The bridge adapter preserves wire ownership after a datagram finishes or
resets. Datagram epochs prevent an outstanding callback from resurrecting a
retired datagram. Sender retirement stops its timers, clears parent ownership
before callback reentry and delivers at most one completion. Missing optional
TX reports stay unavailable instead of becoming zero RF measurements.

Host admission rejection cannot enter the old unbounded busy-spin. Rejected
submissions do not mutate existing datagrams or call their completion. Accepted
work that fails synchronously cannot leave the low-level caller inspecting an
already retired session. A protocol reset/failure is not confirmed RF abort:
maintenance remains busy until the outstanding wire completion is consumed.

The module uses full-width controller identity and bridge declarations. These
guards do not certify every TS/security FSM path, source/session matching,
physical interoperability or full RF accounting in pipeline observations.

## Resource directory and network management

RD readiness rejects:

- An active probe or retained NIF endpoint pointer.
- Node/endpoint probe-retry timers retaining cached records.
- NIF and endpoint-find timers retaining endpoint/node pointers.
- The SUC-ID timer waiting for controller callbacks.
- Any cached node with an outstanding reference count.

Reload rechecks readiness before invalidating pointers. The periodic dead-node
worker is different: its argument is a numeric starting node ID, and it looks
up the current cache when dispatched. It retains no old RD record pointer,
executes only after resume and uses elapsed clock time for its checks.

NM idle now includes operation, asynchronous-cancellation and SmartStart timers,
as well as the existing state/middleware conditions. Resetting a completed NM
operation stops its operation/cancellation timers, so those callbacks cannot
later affect a different task. This does not turn compatibility stop reports
into confirmed task cancellation.

## Validation

`make test-host-maintenance` in the core worktree runs the real production
request, application-send, S0, S2 and Transport Service implementations under
ASan, UBSan and leak detection. The test translation unit inspects private
state; no test hooks or new CRUD functions enter the port ABI.

It exercises pending/dispatching/rearmed timers, report waits, callback
reentrancy, multipart reports, LR abort, stale TX generations, request
reinitialization, security/fragment state, RD retry timers and S2 bounds.
It also exercises partial serial/ACK quiet guards, TS reset with outstanding
wire work, late callbacks, bounded admission rejection and optional reports.

`make test-host-serial` scripts the connection layer while running production
Serial API send/dispatch code. It covers overlapping/reentrant submissions,
callback-free bridge work, wrong IDs/commands, delayed duplicates, early queued
callbacks, SDK ID wrap and fail-closed malformed/missing replies or restart.
The TX harness covers synchronous TS retirement before its caller returns.

The wrapper's actual helper/fake-NCP tests prove that successful TX leaves
maintenance busy until the unmatched report wait times out, and that aborting
inclusion retires the operation timer before a quiet window can be acquired.
Real-helper regressions also cover delayed/duplicate/mismatched callbacks,
missing callbacks keeping maintenance busy and NIF acceptance/completion.
Grizzly exercises NIF through its public command/report path for IDs 1 and 7.
`make test-host-suc` adds production RD walk coverage with mocked radio
boundaries: retained ownership, repeated resume, genuine completion, bounded
rejection, repeat walks, eligibility and fail-closed timeout/teardown.
The SDK harness also exercises actual NM reset and matching observer detachment.

Host sanitizer builds replace Contiki's log-only assertions with fatal ones
and disable sanitizer recovery. A plain-control-flow self-check verifies that
assertion failure terminates the test. Production assertions are unchanged.
The stricter policy found a TS 15-entry array for 16 session IDs; it now holds
all 16 and the harness explicitly sends with session ID 15.

Earlier zero-exit harness labels did not establish clean assertions/UBSan.
They are superseded by rerunning all five harnesses with fatal checks. Exported
core `57dd2eb` reproduces pending-walk/timeout assertion failures and the
session-15 UBSan bound violation under that same strict policy.
Full host validation includes five sanitizer harnesses, both Grizzly profiles,
wrapper/Rust tests and host releases.

## Remaining audit and acceptance

- Full writer/reference/timer coverage and remaining serial callback families,
  including other return routes, neighbor progress, network update, NM and
  higher security/fragment lifetimes. Production assertions remain log-only
  unless separately fail-closed; audit invariants rather than trusting ASSERT.
- NCP callback lifetime/reuse contracts, ancient duplicates across SDK ID wrap,
  actual NCP activity and serial ownership across reset.
- Planned helper replacement, identity refresh and maintenance recovery.
- Security/provisioning persistence and synchronization outside RD reload.
- Backups, same-backend upgrades and interrupted-transaction reconciliation.
- Physical S0/S2/LR/sleeping-device and interrupted-update acceptance.
- Actual ARM/Nerves deployment and target sanitizer/toolchain acceptance.

Do not remove an interrupted maintenance journal or bypass a busy guard merely
to restore progress. Host/fake-NCP tests do not establish these remaining gates.
