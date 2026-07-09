# ell/iwd (and iwctl) need DBUS_SYSTEM_BUS_ADDRESS explicit; systemd injects it,
# sinit does not, so set it for interactive/login shells too (manual iwctl).
export DBUS_SYSTEM_BUS_ADDRESS=unix:path=/run/dbus/system_bus_socket
