# 🐻 Grizzly

[![CircleCI](https://circleci.com/gh/smartrent/grizzly.svg?style=svg)](https://circleci.com/gh/smartrent/grizzly)

An Elixir library for Z-Wave

## Installation

```elixir
def deps do
  [
    {:grizzly, "~> 0.3", organization: "smartrent"}
  ]
end
```
## Configuration

Different systems will use different serial ports to talk to the Z-Wave controller.
In order to configure this, there is a `serial_port` option. Below is an example
for the Raspberry PI 3:

```elixir
config :grizzly,
  serial_port: "/dev/ttyACM0"
```

If you are using a base nerves system please see the documentation for your particular
system at the [Nerves Project](https://github.com/nerves-project) github page.

To run some scripts that `zipgateway` uses we need the `pidof` command line utility. 
Not all Nerves base systems provide this utility so you can use the [busybox](https://hex.pm/packages/busybox)
package to avoid having to build a custom nerves system. After adding the `busybox` package
to your `mix.exs` file, you can configure `Grizzly` to use the busybox path for the `pidof`
utility:

```elixir
config :grizzly,
  pidof_bin: "/srv/erlang/lib/busybox-0.1.2/priv/bin/pidof"
```

Be sure to check the version of the `busybox` package you are using matches
the version in the path.

If you want to run tests without running the `zipgateway` binary provided by Silicon Labs you
can configure `run_zipgateway_bin` to be `false`:

```elixir
config :grizzly,
  run_zipgateway_bin: false
```

