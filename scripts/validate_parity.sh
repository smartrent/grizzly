#!/usr/bin/env bash
# Host validation only. Does not claim physical-radio or Nerves acceptance.
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
export ZWAVE_CORE_ROOT=${ZWAVE_CORE_ROOT:-"$ROOT/../zipato-zwave-core-parity"}
export GRIZZLY_ZWRAP_PATH=${GRIZZLY_ZWRAP_PATH:-"$ROOT/../zipato-zwrap-parity"}
ZWAVE_CORE_ROOT=$(realpath "$ZWAVE_CORE_ROOT")
GRIZZLY_ZWRAP_PATH=$(realpath "$GRIZZLY_ZWRAP_PATH")
export ZWAVE_CORE_ROOT GRIZZLY_ZWRAP_PATH
OUT=${ARTIFACT_DIR:-/tmp/zwrap-parity-validation}
mkdir -p "$OUT"
run() {
  local name=$1; shift
  printf 'Running %s\n' "$name"
  if ! "$@" >"$OUT/$name.log" 2>&1; then
    tail -80 "$OUT/$name.log"
    return 1
  fi
}
cd "$ZWAVE_CORE_ROOT"
run c-sanitizers make test-host-bounds
run c-tx-sanitizers make test-host-tx
run c-maintenance-sanitizers make test-host-maintenance
run c-serial-sanitizers make test-host-serial
run core-diff git -c core.whitespace=blank-at-eol,blank-at-eof,space-before-tab,cr-at-eol diff --check
cd "$GRIZZLY_ZWRAP_PATH"
run rust-format cargo fmt --manifest-path native/zwrap_port/Cargo.toml -- --check
run rust-tests cargo test --locked --manifest-path native/zwrap_port/Cargo.toml
run clippy cargo clippy --locked --manifest-path native/zwrap_port/Cargo.toml --all-targets -- -D warnings
run wrapper-format mix format --check-formatted
run wrapper-tests mix test --include integration
run wrapper-diff git diff --check
cd "$ROOT"
run zipgateway-deps env GRIZZLY_BACKEND=zipgateway mix deps.get
run zipgateway-tests env GRIZZLY_BACKEND=zipgateway mix test
run grizzly-format mix format --check-formatted
run credo env GRIZZLY_BACKEND=zipgateway mix credo --strict
run zwrap-deps env GRIZZLY_BACKEND=zwrap mix deps.get
run zwrap-tests env GRIZZLY_BACKEND=zwrap mix test --include zwrap_integration
run production-builds scripts/check_backend_builds.sh
run grizzly-diff git diff --check
python3 - "$ROOT" "$GRIZZLY_ZWRAP_PATH" "$ZWAVE_CORE_ROOT" "$OUT" <<'PY'
import hashlib, json, pathlib, subprocess, sys
records = []
for root in sys.argv[1:4]:
    paths = subprocess.check_output(
        ['git', '-C', root, 'ls-files', '-z', '--cached', '--others', '--exclude-standard']
    ).split(b'\0')
    files = {}
    for raw in sorted(set(paths)):
        if raw:
            name = raw.decode()
            path = pathlib.Path(root, name)
            if path.is_file():
                files[name] = hashlib.sha256(path.read_bytes()).hexdigest()
    records.append({'root': root, 'revision': subprocess.check_output(
        ['git', '-C', root, 'rev-parse', 'HEAD'], text=True).strip(), 'files': files})
output = pathlib.Path(sys.argv[4], 'source-manifest.json')
output.write_text(json.dumps({'worktrees': records}, indent=2) + '\n')
PY
printf 'Host validation passed. Logs and manifest: %s\n' "$OUT"
