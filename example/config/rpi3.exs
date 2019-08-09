use Mix.Config

config :grizzly,
  serial_port: "/dev/ttyACM0",
  pidof_bin: "/srv/erlang/lib/busybox-0.1.3/priv/bin/pidof"
