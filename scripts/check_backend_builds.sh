#!/usr/bin/env bash
# Production application artifacts; physical radio / Nerves acceptance is separate.
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
export ZWAVE_CORE_ROOT=${ZWAVE_CORE_ROOT:-"$ROOT/../zipato-zwave-core-parity"}
export GRIZZLY_ZWRAP_PATH=${GRIZZLY_ZWRAP_PATH:-"$ROOT/../zipato-zwrap-parity"}
ZWAVE_CORE_ROOT=$(realpath "$ZWAVE_CORE_ROOT")
GRIZZLY_ZWRAP_PATH=$(realpath "$GRIZZLY_ZWRAP_PATH")
export ZWAVE_CORE_ROOT GRIZZLY_ZWRAP_PATH
cd "$ROOT"
export MIX_ENV=prod
for profile in zipgateway zwrap; do
  export GRIZZLY_BACKEND=$profile
  mix deps.get
  mix compile --warnings-as-errors
  mix grizzly.check_build
done

# Simulate a cached build predating isolation: add a real inactive BEAM and
# declare it in grizzly.app, plus a legacy private file in the native app.
cp _build/zipgateway/prod/lib/grizzly/ebin/Elixir.Grizzly.ZIPGateway.beam \
   _build/zwrap/prod/lib/grizzly/ebin/
cp _build/zwrap/prod/lib/grizzly/ebin/Elixir.Grizzly.Backends.Zwrap.beam \
   _build/zipgateway/prod/lib/grizzly/ebin/
printf 'stale legacy asset\n' > _build/zwrap/prod/lib/grizzly/priv/stale.pem
elixir -e '
for {profile, module} <- [{"zwrap", Grizzly.ZIPGateway}, {"zipgateway", Grizzly.Backends.Zwrap}] do
  path = "_build/#{profile}/prod/lib/grizzly/ebin/grizzly.app"
  {:ok, [{:application, :grizzly, props}]} = :file.consult(String.to_charlist(path))
  props = Keyword.update!(props, :modules, &[module | &1])
  File.write!(path, :io_lib.format(~c"~tp.~n", [{:application, :grizzly, props}]))
end'
for profile in zwrap zipgateway; do
  GRIZZLY_BACKEND=$profile mix grizzly.check_build
done
printf 'Both production profiles and stale-artifact repair passed.\n'

# Assemble both host OTP releases and verify their actual shipped dependency tree.
for profile in zipgateway zwrap; do
  export GRIZZLY_BACKEND=$profile
  mix release --overwrite
  release="_build/$profile/prod/rel/grizzly"
  if [[ "$profile" == zwrap ]]; then
    for dependency in muontrap thousand_island beam_notify ctr_drbg; do
      if compgen -G "$release/lib/$dependency-*" >/dev/null; then
        echo "Inactive dependency shipped in native release: $dependency" >&2
        exit 1
      fi
    done
    opposite=zipgateway
  else
    if compgen -G "$release/lib/zwrap-*" >/dev/null; then
      echo 'Native helper dependency shipped in legacy release' >&2
      exit 1
    fi
    opposite=zwrap
  fi
  # Changing the selector environment after assembly must not change the backend.
  GRIZZLY_BACKEND=$opposite "$release/bin/grizzly" eval \
    "expected = :$profile; unless Grizzly.Backend.name() == expected, do: System.halt(1); IO.puts(expected)"
done
printf 'Both assembled host releases retain their compiled backend.\n'
(
  cd "$GRIZZLY_ZWRAP_PATH"
  log=$(mktemp)
  trap 'rm -f "$log"' EXIT
  if env -u CARGO_BUILD_TARGET MIX_TARGET=parity_probe mix compile >"$log" 2>&1; then
    echo 'Unspecified cross target was accepted' >&2
    exit 1
  fi
  grep -q 'CARGO_BUILD_TARGET is required' "$log"
)
printf 'Unspecified cross-target packaging is rejected.\n'
