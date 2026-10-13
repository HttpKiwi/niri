#!/usr/bin/env bash
# Vanilla Discord on Wayland + PipeWire (Niri). Prefer this if Equibop Go Live stays flaky.
exec /usr/bin/discord \
  --ozone-platform=wayland \
  --enable-features=WebRTCPipeWireCapturer,WaylandWindowDecorations \
  --disable-gpu-memory-buffer-video-frames \
  --disable-features=VaapiVideoEncoder,VaapiVideoDecoder \
  "$@"
