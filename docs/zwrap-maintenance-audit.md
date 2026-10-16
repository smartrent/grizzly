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

## Transport Service

Idle requires an idle FSM and no registered reset, delayed-restart,
inter-fragment, fragment-completion or RX timeout. The reset grace timer can
conservatively keep maintenance busy after apparent frame completion.

The module now uses the real full-width controller identity and bridge API
declarations instead of incompatible private BYTE prototypes. Transport
Service still has direct serial-send paths. These predicates are not proof of
complete serial callback correlation, physical interoperability or full RF
accounting in application-pipeline TX observations.

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

The wrapper's actual helper/fake-NCP tests prove that successful TX leaves
maintenance busy until the unmatched report wait times out, and that aborting
inclusion retires the operation timer before a quiet window can be acquired.
Full host validation includes this harness alongside the existing bounds/TX
sanitizers, both Grizzly profiles, wrapper/Rust tests and host releases.

## Remaining audit and acceptance

- Full native writer/reference/timer coverage and raw serial callback lifetimes.
- Late/missing callbacks, actual NCP activity and serial ownership across reset.
- Planned helper replacement, identity refresh and maintenance recovery.
- Security/provisioning persistence and synchronization outside RD reload.
- Backups, same-backend upgrades and interrupted-transaction reconciliation.
- Physical S0/S2/LR/sleeping-device and interrupted-update acceptance.
- Actual ARM/Nerves deployment and target sanitizer/toolchain acceptance.

Do not remove an interrupted maintenance journal or bypass a busy guard merely
to restore progress. Host/fake-NCP tests do not establish these remaining gates.
