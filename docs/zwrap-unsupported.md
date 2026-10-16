# Zwrap: unsupported and partial operations

> Historical prototype baseline/proposal. This worktree now has a partial
> implementation beyond that baseline. Use the current progress report for
> implemented behavior, validation and all remaining task IDs.
>
> [Current progress][parity-progress] · [Execution plan][parity-execution]


This inventory describes **Grizzly's `backend: :zwrap` integration**, not missing
functions in the wrapper. Zwrap itself covers the public `zipato-zwave-core` API.
For the roadmap, start with the
[feature-parity summary](zwrap-feature-parity-summary.md). For task-by-task
proposals to close every gap without emulating ZIPGateway's wire API, see
[the detailed parity plan](zwrap-feature-parity.md). It accounts for
the native SQLite resource directory and separates Grizzly, wrapper and core
changes. The inventory below describes current behavior, not the parity goal.
The current startup-selectable prototype also needs a compile-time-selection
refactor: each deployment build has one fixed backend, both implementations
coexist only temporarily, and the goal is complete ZIPGateway removal. There is
no deployed backend-switching or cross-backend migration requirement.

Some native APIs are intentionally absent because Elixir is expected to read
and edit the shared SQLite database under the core's pause/resume coordination
mechanism. Missing facade support for that workflow is an integration gap, not
proof that the core needs new database getters/setters. Other operations require
real radio capabilities or remain accessible through
`Grizzly.Backends.Zwrap.controller/0`. See the parity plan's coordinated SQL
access contract before enabling edits; probe blocking must not be assumed to
reload cached native records automatically. Backend setup and architecture:
[backends.md](backends.md).

No unsupported operation falls back to a ZIPGateway socket. Unless stated
otherwise, unsupported command sends return `{:error,
:unsupported_backend_command}`; unsupported service operations return
`{:error, :unsupported_backend_operation}`. These are capability errors, not
transmission failures, and are not retried.

## Unsupported controller commands

These request commands are rejected rather than transmitted as application
frames. All names below are exact Grizzly command names.

| Area | Unsupported requests | Affected higher-level API / notes |
|---|---|---|
| Learn mode | `learn_mode_set` | `Grizzly.Inclusions.learn_mode/1`, `learn_mode_stop/0` when active. The core reports learn-mode events but exposes no initiation API. |
| Network update | `network_update_request` | `Grizzly.Network.request_network_update/1`. Core callback exists, no public initiating function. |
| Controller NIF | `node_information_send` | No core equivalent exposed. |
| Controller DSK | `dsk_get` | `Grizzly.Node.get_dsk/3`. ECDH keypair export is available directly, but is not translated into this command. |
| Failed replacement | `failed_node_replace` | Core callback exists, no public initiating function. Failed-node **removal** is supported. |
| Neighbor discovery | `node_neighbor_update_request` | `Grizzly.Network.node_neighbor_update_request/2`. Core callback exists, no public initiating function. |
| Node inventory | `node_list_get` | `Grizzly.Network.get_node_ids/1`, `get_all_node_ids/1`, `Grizzly.all_node_ids/0`. No automatic synthesis from SAPI or filesystem/database reads. |
| Failed-node inventory | `failed_node_list_get` | `Grizzly.Network.report_failed_node_ids/1`, `Grizzly.failed_node_ids/0`. |
| Gateway interview cache | `node_info_cached_get` | `Grizzly.Node.get_info/2`, `Grizzly.node_info/2`, including forced refresh. Native SQLite reads/coordinated edits are not yet wired into this facade; export/import/probe control remain available through Zwrap. |
| Gateway endpoint cache | `network_management_multi_channel_capability_get`, `network_management_multi_channel_end_point_get` | Endpoint information is present in native SQLite but not yet exposed through Grizzly's repository. Direct device Multi Channel queries are a refresh option, not a substitute for cached inspection. |
| Priority routes | `priority_route_get`, `priority_route_set` | No facade mapping to raw SAPI. |
| Gateway statistics | `statistics_get`, `statistics_clear` | Includes `Grizzly.Node.get_statistics/1`. Native per-transmission reports are supported, but not the ZIPGateway statistics service. |
| Background RSSI | `rssi_get` | `Grizzly.background_rssi/0`. |
| Long Range channel control | `zwave_long_range_channel_get`, `zwave_long_range_channel_set` | LR node IDs in normal application sends/removal are supported; this channel-management service is not. |
| Gateway application NIF | `application_node_info_get` | No ZIPGateway application-node-info service exists in Zwrap mode. |
| Z/IP | `zip_packet`, `keep_alive` | No socket, Z/IP headers, sequence ACK protocol, keep-alives, TUN or IP-addressed nodes. |

### Report/notification commands are not controller requests

The following local report/notification commands are also **rejected when passed
to `Grizzly.send_command`**. Some are produced as inbound Grizzly reports by the
integration; that does not make them supported outbound controller operations:

- Basic Node: `default_set_complete`, `dsk_report`, `learn_mode_set_status`,
  `network_update_request_status`.
- Inclusion: `extended_node_add_status`, `failed_node_remove_status`,
  `failed_node_replace_status`, `included_nif_report`, `node_add_dsk_report`,
  `node_add_keys_report`, `node_add_status`, `node_neighbor_update_status`,
  `node_remove_status`, `smart_start_join_started`.
- Installation/Maintenance: `priority_route_report`, `rssi_report`,
  `s2_resynchronization_event`, `statistics_report`,
  `zwave_long_range_channel_report`.
- Proxy: `failed_node_list_report`,
  `network_management_multi_channel_capability_report`,
  `network_management_multi_channel_end_point_report`, `node_info_cached_report`,
  `node_list_report`.
- Provisioning: `node_provisioning_list_iteration_report`,
  `node_provisioning_report`.
- Gateway: `application_node_info_report`.

Any **other application command sent to `:gateway`** is unsupported as a local
controller service. Normal application commands sent to a device ID still use
Grizzly's command encoders and handlers. Grizzly's pre-existing local
`version_command_class_get` responses for its extra controller command classes
remain available; they describe Grizzly's command implementation, not core
management-service parity.

Remote controller targeting is also unsupported: local management commands may
use `:gateway` or `1` (a compatibility alias for the local controller), not an
arbitrary remote controller ID. Other targets return an unsupported-operation
error. In particular, inclusion `controller_id` values other than 1 are not
implemented; use the owned native controller directly when its own inclusion
flow must be managed outside Grizzly. A nonzero `destination` endpoint on a
local management command is an unsupported option.

## Unsupported device operation / payload forms

| Operation | Behavior / reason |
|---|---|
| `no_operation`, `Grizzly.ping/2` | Explicit unsupported-command error. A NOP is one byte; the wrapper's application-send contract requires 2..255 bytes. No unsafe raw-SAPI workaround is injected. |
| `Grizzly.send_binary/2` / binary connection mode | Unsupported-operation error. This API's contract is **Z/IP-encapsulated** bytes and raw Z/IP responses; it is not silently reinterpreted as raw Z-Wave. Use `Zwrap.send_data_appl/4` directly for custom CC bytes. |
| Payloads over 255 bytes | `{:error, :payload_too_large}` before submission. Multi Channel encapsulation adds four bytes to this limit. No Transport Service fragmentation is added by Grizzly. This can limit device firmware fragment sizes. |
| Endpoint bit addressing / source endpoint selection | Only `destination: 0..127` unicast endpoint selection is supported by the facade. Nonzero destinations use Multi Channel encapsulation. Arbitrary Z/IP source/destination/header extensions are unavailable. |
| Unimplemented application commands | Remain subject to Grizzly's existing encoder/decoder support, exactly as with ZIPGateway. Unknown/malformed incoming frames are ignored with a warning; they do not terminate the controller. |

## Partial support and unavailable semantics

- **Sleeping-node queue delay/pings**: mailbox handling is intentionally absent
  from the core; queues, wake-up scheduling and keep-awake policy belong in
  Elixir/Grizzly. The current Grizzly integration does not yet implement that
  scheduler. The native API does not report Z/IP NACK-waiting, expected delay or
  queue keep-alive notifications. No `queued_ping` or genuine sleeping-device
  `queued_delay` events are synthesized.
  The initial async `queued_delay` report is retained only for Grizzly API
  compatibility; it does not prove a sleeping-device queue entry. Timeout bounds
  remain caller-controlled.
- **`more_info: true`**: `{:error, :unsupported_backend_option}`. This is a Z/IP
  flag, not a native send option. `more_info: false` works.
- **Transmission statistics**: `transmission_stats: true` returns the available
  native TX map at `:native_tx_report`. ZIPGateway IMA fields, RSSI bar
  calculations, route-speed normalization, remote power normalization and
  background-RSSI monitoring are not synthesized.
- **Inclusion options**: secure/unsecure/stop modes are supported. Other
  `node_add` modes return an unsupported-option error. Nondefault `tx_opt`
  cannot be applied by the public core API and is rejected. The default
  `:explore` is accepted as the core's own default transmission policy.
- **S2 DSK input**: length 0 (unauthenticated) and length 2 (PIN) are supported.
  Other DSK fragment lengths return an unsupported-option error. Grizzly's
  `:s2_access_control` maps to native `:s2_access`. Native LR key types have no
  equivalent in Grizzly's S2 key-selection model; use the wrapper directly when
  needed.
- **Inclusion metadata**: the native status union does not expose confirmed
  granted keys, KEX failure type or full DSK in the final status. These fields
  are not invented; the existing interactive DSK path can retain its DSK.
  Intermediate native progress statuses are not advertised as completed
  inclusions. LR IDs are retained in semantic `node_add_status` reports, not
  encoded into legacy eight-bit wire packets.
- **Abort**: Grizzly's stop calls report local abort acceptance and cancel the
  logical request; no guaranteed native abort-completion notification exists.
  An inclusion abort status is `:failed`/node 0, not a successful inclusion;
  exclusion abort uses `:done`/node 0, not proof that a particular node left.
- **Provisioning metadata reads**: set accepts TLVs (within the native 44-byte
  limit), but native get/iteration callbacks expose only DSK/remaining count.
  Returned `meta_extensions` is empty; name/location/bootstrapping/status TLVs
  cannot be read back through this facade. Native validation failures are
  returned, not hidden.
- **Management concurrency**: callbacks have no request context. Same-kind
  overlapping management requests return `{:error, :busy}`. After a timeout the
  slot stays reserved until native completion (or backend restart); it cannot
  be safely reused immediately. Inclusion and exclusion are mutually exclusive.
- **Response correlation**: identical simultaneous GETs with no command-level
  response matcher are inherently ambiguous on a raw Z-Wave link. The oldest
  matching request consumes the response; there is no Z/IP request sequence.
- **Automatic SmartStart inclusion reports**: provisioning is supported, but
  unsolicited native inclusions not initiated through Grizzly are not
  reconstructed into Grizzly's inclusion state machine. Subscribe directly to
  Zwrap notifications. There is no `smart_start_join_started` core callback.
- **Native-only notifications**: `rd_probe_event`, `application_busy`,
  `failed_node_replace_status`, `node_neighbor_update_status`,
  `learn_mode_set_status`, `network_update_request_status`, `send_request_complete`,
  `sapi_no_resp`, `sapi_resp` and `native_error` are not translated into Grizzly
  event subjects/reports by this integration. Direct `Zwrap.subscribe/2` still
  exposes them. In particular, no precise busy wait time is available.
- **Multicommand forwarding to ZIPGateway**: no `forward_to_controller` action
  is sent to a missing gateway. Raw Multi Command constituents are instead
  handled locally/notified individually. Gateway-owned command services from
  the unsupported table remain unavailable.

## ZIPGateway-specific public helpers and deployment

| Operation | Zwrap-mode behavior / alternative |
|---|---|
| `Grizzly.start_zipgateway/0`, `restart_zipgateway/0`, `stop_zipgateway/0` | Explicit unsupported-operation error. The supervisor owns/restarts Zwrap instead. |
| `Grizzly.zipgateway_ready?/0` | `false`; use `Grizzly.ready?/0`. |
| `Grizzly.listening_mode/1` | Explicit unsupported-operation error; the current helper is ZIPGateway-gated. Native SQLite already contains the mode; the Grizzly SQL integration is missing. |
| `Grizzly.home_id/0` | `nil`; the current facade does not read native SQLite's network record and there is no ZIPGateway log monitor. |
| `Grizzly.network_keys/0`, `zniffer_network_keys/0` | `nil`; no ZIPGateway log monitor. Direct `Zwrap.get_network_keys/1` and `get_ecdh_key_pair/1` exist, with different schemas and strict secret-handling requirements. |
| Direct `Grizzly.ZIPGateway.*` services | No gateway Supervisor, database server, LogMonitor, ready checker or unsolicited health check is started. Direct calls to those internal services are unsupported, even if a pure helper function can still run. |
| Automatic/controller OTW firmware update and `zw_programmer` orchestration | Not integrated with native port ownership. Startup rejects `zwave_firmware: %{enabled: true}` instead of competing for the serial device. Do not manually run the ZIPGateway-specific OTW runner against the owned port. Device OTA application commands are distinct and reuse the direct async request path, subject to payload limits; physical-device OTA has not been validated. |
| Existing ZIPGateway SQLite database/config migration | Not implemented and not a deployment requirement. Backend choice is fixed per build; do not add deployed-system switching or reverse converters for parity. Same-backend persistence upgrades/recovery remain necessary; scope any future fleet conversion separately. |
| Nerves/cross-compilation and non-Linux deployment | Not validated/supported by this local native build integration. No precompiled native artifacts or automatic upstream fetch are supplied. |

### Configuration that does not configure the native stack

In Zwrap mode the ZIPGateway options below have **no effect** on native operation:
`run_zipgateway`, `transport`, `zipgateway_binary`, `zipgateway_config_path`,
`zipgateway_port`, `manufacturer_id`, `hardware_version`, `product_id`,
`product_type`, `serial_log`, `tun_script`, `lan_ip`, `pan_ip`,
`unsolicited_destination`, `database_file`, `extra_config`, `indicator_handler`,
`rf_region`, `power_level`, `zw_programmer_path`, `background_rssi_monitor`.
There is no automatic equivalent configuration of RF region, TX power,
certification identity, indicator/log-derived events or network interface setup.
`unsolicited_data_path` also has no native persistence meaning. Use the wrapper's
supported `zwrap_options` for its own persistence/log/probe settings.

Grizzly handlers, storage adapters/options, associations, virtual devices and
ordinary application command codecs remain above the backend boundary.

[parity-progress]: ../PARITY_IMPLEMENTATION_REPORT.md
[parity-execution]: ../PARITY_IMPLEMENTATION_PLAN.md
