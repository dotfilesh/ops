#!/usr/bin/env python3

talosctl reset --graceful=false --reboot --nodes ${1} --system-labels-to-wipe STATE --system-labels-to-wipe EPHEMERAL
