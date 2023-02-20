#!/usr/bin/env bash

talosctl reset --graceful=false --reboot --nodes ${1} --system-labels-to-wipe STATE --system-labels-to-wipe EPHEMERAL
